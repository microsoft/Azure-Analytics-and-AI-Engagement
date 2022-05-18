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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$rglocation = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$suffix = "$random-$init"
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$storageAccountName = $dataLakeAccountName
$forms_fintax_name = "retail-form-recognizer-$suffix";
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_fintax_name
$forms_cogs_key = $forms_cogs_keys.Key1
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$StartTime = Get-Date
$amlworkspacename = "amlws-$suffix"
$cpuShell = "cpuShell$random"
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "incidentpdftraining" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime
$forms_cogs_endpoint = "https://"+$rglocation+".api.cognitive.microsoft.com/"

Write-Host "----Form Recognizer-----"
#form Recognizer
#Replace values in create_model.py
(Get-Content -path ../artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
                -replace '#LOCATION#', $rglocation`
				-replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
				-replace '#CONTAINER_NAME#', "incidentpdftraining"`
				-replace '#SAS_TOKEN#', $sasToken`
				-replace '#APIM_KEY#',  $forms_cogs_key`
			} | Set-Content -Path ../artifacts/formrecognizer/create_model1.py

$modelUrl = python "../artifacts/formrecognizer/create_model1.py"
$modelId = $modelUrl.split("/")
$modelId = $modelId[7]

Write-Host  "-----------------AML Workspace ---------------"
RefreshTokens

(Get-Content -path ../artifacts/amlnotebooks/Config.py -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName`
    -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key`
    -replace '#FORM_RECOGNIZER_ENDPOINT#', $forms_cogs_endpoint`
    -replace '#FORM_RECOGNIZER_API_KEY#', $forms_cogs_keys.Key1`
    -replace '#FORM_RECOGNIZER_MODEL_ID#', $modelId`
    -replace '#SUBSCRIPTION_ID#', $subscriptionId`
    -replace '#RESOURCE_GROUP#', $rgName`
    -replace '#WORKSPACE_NAME#', $amlworkspacename`
    -replace '#COMPUTE_NAME#', $cpuShell`
    -replace '#TRANSLATION_API_KEY#', $translator_key`
    -replace '#LOCATION#', $rglocation`
} | Set-Content -Path ../artifacts/amlnotebooks/GlobalVariables.py

#AML Workspace
#create aml workspace
az extension add -n azure-cli-ml
# az ml workspace create -w $amlworkspacename -g $rgName

#attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
az ml folder attach -w $amlworkspacename -g $rgName -e aml
start-sleep -s 10

#create and delete a compute instance to get the code folder created in default store
az ml computetarget create computeinstance -n $cpuShell -s "STANDARD_DS2_V2" -v

#get default data store
$defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
$defaultdatastoreaccname = $defaultdatastore.account_name

#get fileshare and code folder within that
$storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
$share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context 
$shareName = $share[0].Name

$notebooks=Get-ChildItem "../artifacts/amlnotebooks" | Select BaseName
foreach($notebook in $notebooks)
{
	if($notebook.BaseName -eq "GlobalVariables")
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".py"
		$path=$notebook.BaseName+".py"
	}
    elseif($notebook.BaseName -eq "prepared_customer_churn_data" -or $notebook.BaseName  -eq "data" -or $notebook.BaseName  -eq "retail_customer_churn_data"   -or $notebook.BaseName  -eq "retail_sales_dataset" -or $notebook.BaseName  -eq "retail_sales_datasetv2" -or $notebook.BaseName  -eq "Channel_attribution" -or $notebook.BaseName  -eq "OnlineRetailData" -or $notebook.BaseName  -eq "wait_time_forecasted" -or $notebook.BaseName  -eq "Markov - Output - Conversion values")
    {
        $source="../artifacts/amlnotebooks/"+$notebook.BaseName+".csv"
		$path=$notebook.BaseName+".csv"
	}
    elseif($notebook.BaseName -eq "Config")
	{
     continue;
	}
	else
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path=$notebook.BaseName+".ipynb"
	}

Write-Host " Uploading AML assets : $($notebook.BaseName)"
Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}

#delete aks compute
#az ml computetarget create aks --name  "new-aks" --resource-group $rgName --workspace-name $amlWorkSpaceName
az ml computetarget delete -n $cpuShell -v
