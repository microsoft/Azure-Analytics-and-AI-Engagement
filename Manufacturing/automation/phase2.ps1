#Custom Vision 
pip install -r ./artifacts/copyCV/requirements.txt
$key=az cognitiveservices account keys list --name $customVisionName -g $rgName|ConvertFrom-json
$destinationKey=$key.key1
$sourceKey="7f743d4b8d6d459fb2bb0e8648dfa38e"  #todo: find a way to get this securely
$sourceProjectId="b2e4f4ce-d9f1-4fb7-aa0c-2f50fdc14d1b"
$destinationregion= "https://$($location).api.cognitive.microsoft.com"
$sourceregion= "https://westus2.api.cognitive.microsoft.com"
python ./artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion
$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects"
$projects = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
$resource=az resource show -g $rgName -n $customVisionName --resource-type "Microsoft.CognitiveServices/accounts"|ConvertFrom-Json
$resourceId=$resource.id
foreach($project in $projects)
{
	$projectId=$project.id
	$projectName=$project.name
	$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects/$($project.id)/tags"
	$tags = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
	$tagList = New-Object System.Collections.ArrayList
	foreach($tag in $tags)
	{
		$tagList.Add($tag.id)
	}
	$body = "{
      `"selectedTags`": []
		}"
	$body=	$body |ConvertFrom-Json
	$body.selectedTags=$tagList	
	$body=	$body |ConvertTo-Json
	$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects/$($projectId)/train"
	$Result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{"Training-key"="$($destinationKey)"}
	
	$url="https://$($location).api.cognitive.microsoft.com/customvision/v3.3/Training/projects/$($projectId)/iterations"
	$iterations=Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };
	$iterationId=$iterations[0].id
	$url="https://$($location).api.cognitive.microsoft.com/customvision/v3.3/Training/projects/$($projectId)/iterations/$($iterationId)/publish?publishName=$($projectName)&predictionId=$($resourceId)"  #TODO Prediction ID
	$body = "{}"
	$Result = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{"Training-key"="$($destinationKey)"}
	
}


#AML Workspace
#create aml workspace
az extension add -n azure-cli-ml

$amlworkspacename = "amlws-$suffix"
az ml workspace create -w $amlworkspacename -g $rgName
az ml computetarget create aks --name  "new-aks" --resource-group $rgName --workspace-name $amlWorkSpaceName 

#attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
az ml folder attach -w $amlworkspacename -g $rgName

#create and delete a compute instance to get the code folder created in default store
az ml computetarget create computeinstance -n cpuShell -s "STANDARD_D3_V2" -v
#az ml computetarget delete -n cpuShell -v

#get default data store
$defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
$defaultdatastoreaccname = $defaultdatastore.account_name

#get fileshare and code folder within that
$storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
$share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context 
$shareName = $share.Name
$shareName

#create Users folder ( it wont be there unless we launch the workspace in UI)
New-AzStorageDirectory -Context $storageAcct.Context -ShareName $shareName -Path "Users"

#copy notebooks to ml workspace
$notebooks=Get-ChildItem "./artifacts/amlnotebooks" | Select BaseName
foreach($notebook in $notebooks)
{
	if($notebook.BaseName -eq "config")
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".py"
		$path="/Users/"+$notebook.BaseName+".py"
	}
	else
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path="/Users/"+$notebook.BaseName+".ipynb"
	}

Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}
   
az ml computetarget delete -n cpuShell -v

