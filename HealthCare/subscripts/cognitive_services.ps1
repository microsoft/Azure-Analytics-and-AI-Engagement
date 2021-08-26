function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#will be done as part of the cloud shell start - README

#if they have many subs...
$subs = Get-AzSubscription | Select-Object -ExpandProperty Name

if($subs.GetType().IsArray -and $subs.length -gt 1)
{
    $subOptions = [System.Collections.ArrayList]::new()
    for($subIdx=0; $subIdx -lt $subs.length; $subIdx++)
    {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the $selectedSubName subscription"
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
}

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$cognitive_services_name = "cog-healthcare-$init"
$location = (Get-AzResourceGroup -Name $rgName).Location
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$suffix = "$random-$init"
$forms_cogs_name = "cog-formrecognition-$suffix";
$modelUrl = python "../artifacts/formrecognizer/create_model.py"
$modelId= $modelUrl.split("/")
$modelId = $modelId[7]

Add-Content log.txt "-----------------Cognitive Services ---------------"
Write-Host "----Cognitive Services ------"
RefreshTokens
#Custom Vision 
pip install -r ../artifacts/copyCV/requirements.txt
$sourceKey="0ea6df654a9f47a4b9a3da65988f461e"  #todo: find a way to get this securely

#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cognitive_services_name -g $rgName|ConvertFrom-json
$destinationKey=$key.key1

#CT scan project
$sourceProjectId="7b58bba3-f88e-43c8-bdf9-8cd62e6c4a37"
$destinationregion= "https://$($location).api.cognitive.microsoft.com"
#$destinationregion= "https://$($cognitive_services_name).cognitiveservices.azure.com/"
$sourceregion= "https://westus2.api.cognitive.microsoft.com"
python ../artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

#Hospital mask project
$sourceProjectId="7f83145b-8f94-4198-b9eb-3bab1d813fc5"
python ../artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion

#mask compliance project
$sourceProjectId="68971cc7-bcd6-415f-b0c5-2dfa25c82c36"
python ../artifacts/copyCV/migrate_project.py -p $sourceProjectId -s $sourceKey -se $sourceregion -d $destinationKey -de $destinationregion


$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects"
$projects = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$storage_account_connection_string = "DefaultEndpointsProtocol=https;AccountName=" + $dataLakeAccountName + ";AccountKey="+ $storage_account_key + ";EndpointSuffix=core.windows.net"

(Get-Content -path artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT_CONNECTION_STRING#', $storage_account_connection_string`
				-replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName`
				-replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key`
				-replace '#LOCATION#', $location`
				-replace '#FORM_RECOGNIZER_NAME#', $forms_cogs_name`
				-replace '#FORM_RECOGNIZER_MODEL_ID#', $modelId`
                -replace '#COGNITIVE_SERVICES_NAME#', $cognitive_services_name`
			} | Set-Content -Path artifacts/amlnotebooks/GlobalVariables.py
			
foreach($project in $projects)
{
	$projectId=$project.id
	$projectName=$project.name
	if($projectName -eq "CT-Scan-Classification")
	{
		(Get-Content -path artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#PROJECT_CTSCAN_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path artifacts/amlnotebooks/GlobalVariables.py
	}
	elseif($projectName -eq "Hospital_Safety_Mask_Detection")
	{
				(Get-Content -path artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#PROJECT_FACE_MASK_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path artifacts/amlnotebooks/GlobalVariables.py
	}
	
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
}   
