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
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$location = (Get-AzResourceGroup -Name $rgName).Location
$suffix = "$random-$init"
$amlworkspacename = "amlws-$suffix"
$cpuShell = "cpuShell$init"
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$storageAccountName = $dataLakeAccountName
$cognitive_services_name = "cog-healthcare-$init"
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$StartTime = Get-Date
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "form-datasets" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime
$forms_cogs_name = "cog-formrecognition-$suffix";
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_cogs_name
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$storage_account_connection_string = "DefaultEndpointsProtocol=https;AccountName=" + $dataLakeAccountName + ";AccountKey="+ $storage_account_key + ";EndpointSuffix=core.windows.net"
#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cognitive_services_name -g $rgName --output json |ConvertFrom-json
$destinationKey=$key.key1
$url = "https://$($location).api.cognitive.microsoft.com/customvision/v3.2/training/projects"
$projects = Invoke-RestMethod -Uri $url -Method GET  -ContentType "application/json" -Headers @{ "Training-key"="$($destinationKey)" };


#Form Recognizer
Write-Host "-----Form Recognizer-----"
#Replace values in create_model.py
(Get-Content -path ../artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
				-replace '#LOCATION#', $location`
				-replace '#FORM_RECOGNIZER_NAME#', $forms_cogs_name`
				-replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
				-replace '#CONTAINER_NAME#', "form-datasets"`
				-replace '#SAS_TOKEN#', $sasToken`
				-replace '#APIM_KEY#',  $forms_cogs_keys.Key1`
			} | Set-Content -Path artifacts/formrecognizer/create_model1.py
			
$modelUrl = python "../artifacts/formrecognizer/create_model1.py"
$modelId= $modelUrl.split("/")
$modelId = $modelId[7]


Write-Host  "-----------------AML Workspace ---------------"
RefreshTokens
#AML Workspace
#create aml workspace
az extension add -n azure-cli-ml

(Get-Content -path ../artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT_CONNECTION_STRING#', $storage_account_connection_string`
				-replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName`
				-replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key`
				-replace '#LOCATION#', $location`
				-replace '#FORM_RECOGNIZER_NAME#', $forms_cogs_name`
				-replace '#FORM_RECOGNIZER_MODEL_ID#', $modelId`
                -replace '#COGNITIVE_SERVICES_NAME#', $cognitive_services_name`
			} | Set-Content -Path ../artifacts/amlnotebooks/GlobalVariables.py

foreach($project in $projects)
{
$projectId=$project.id
	$projectName=$project.name
	if($projectName -eq "CT-Scan-Classification")
	{
		(Get-Content -path ../artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#PROJECT_CTSCAN_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path ../artifacts/amlnotebooks/GlobalVariables.py
	}
	elseif($projectName -eq "Hospital_Safety_Mask_Detection")
	{
				(Get-Content -path ../artifacts/amlnotebooks/GlobalVariables.py -Raw) | Foreach-Object { $_ `
                -replace '#PROJECT_FACE_MASK_ID#', $projectId`
				-replace '#PREDICTION_KEY#', $destinationKey`
			} | Set-Content -Path ../artifacts/amlnotebooks/GlobalVariables.py
	}
}

az ml workspace create -w $amlworkspacename -g $rgName

#attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
az ml folder attach -w $amlworkspacename -g $rgName -e aml

#create and delete a compute instance to get the code folder created in default store
az ml computetarget create computeinstance -n $cpuShell -s "STANDARD_DS2_V2" -v
#az ml computetarget delete -n $cpuShell -v

#get default data store
$defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
$defaultdatastoreaccname = $defaultdatastore.account_name

#get fileshare and code folder within that
$storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
$share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context 
$shareName = $share[0].Name
$notebooks=Get-ChildItem "./artifacts/amlnotebooks" | Select BaseName
foreach($notebook in $notebooks)
{
	if($notebook.BaseName -eq "GlobalVariables")
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".py"
		$path="/Users/"+$notebook.BaseName+".py"
	}
	else
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path="/Users/"+$notebook.BaseName+".ipynb"
	}

Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}
#create aks compute
#az ml computetarget create aks --name  "new-aks" --resource-group $rgName --workspace-name $amlWorkSpaceName
az ml computetarget delete -n $cpuShell -v
