function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

function GetAccessTokens($context)
{
    $global:synapseToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://dev.azuresynapse.net").AccessToken
    $global:synapseSQLToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://sql.azuresynapse.net").AccessToken
    $global:managementToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://management.azure.com").AccessToken
    $global:powerbitoken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://analysis.windows.net/powerbi/api").AccessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

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
$location = (Get-AzResourceGroup -Name $rgName).Location
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$suffix = "$random-$init"
$amlworkspacename = "amlws-$suffix"
$cog_speech_name = "speech-service-$suffix"
$cog_translator_name = "translator-$suffix"
$cpuShell = "cpuShell$random"
$searchName = "srch-fsi-$suffix";
$forms_cogs_name = "forms-$suffix";
$concatString = "$init$random"
$dataLakeAccountName = "stfsi$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$subscriptionId = (Get-AzContext).Subscription.Id

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_cogs_name
$forms_cogs_key = $forms_cogs_keys.Key1
$cog_speech_key = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $cog_speech_name
$searchKey = $(az search admin-key show --resource-group $rgName --service-name $searchName | ConvertFrom-Json).primarykey;
$cog_translator_key =  Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $cog_translator_name
$key=az cognitiveservices account keys list --name $cog_marketdatacgsvc_name -g $rgName|ConvertFrom-json
$cog_marketdatacgsvc_key=$key.key1
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$StartTime = Get-Date
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "form-datasets" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime

#form Recognizer
Write-Host "----Form Recognizer-----"
#Replace values in create_model.py
(Get-Content -path ../artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
    -replace '#LOCATION#', $location`
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName`
    -replace '#CONTAINER_NAME#', "form-datasets"`
    -replace '#SAS_TOKEN#', $sasToken`
    -replace '#APIM_KEY#',  $forms_cogs_key`
} | Set-Content -Path ../artifacts/formrecognizer/create_model.py

$modelUrl = python "../artifacts/formrecognizer/create_model.py"
$modelId= $modelUrl.split("/")
$modelId = $modelId[7]

Write-Host  "-----------------AML Workspace ---------------"
RefreshTokens

$forms_cogs_endpoint = "https://"+$forms_cogs_name+".cognitiveservices.azure.com"
$search_uri = "https://"+$searchName+".search.windows.net"

$filepath="../artifacts/amlnotebooks/GlobalVariables.py"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key).Replace("#SEARCH_API_KEY#", $searchKey).Replace("#SEARCH_URI#", $search_uri).Replace("#FORM_RECOGNIZER_ENDPOINT#", $forms_cogs_endpoint).Replace("#FORM_RECOGNIZER_API_KEY#", $forms_cogs_key).Replace("#ACCOUNT_OPENING_FORM_RECOGNIZER_MODEL_ID#", $modelId).Replace("#INCIDENT_FORM_RECOGNIZER_MODEL_ID#", $modelId).Replace("#SUBSCRIPTION_ID#", $subscriptionId).Replace("#RESOURCE_GROUP_NAME#", $rgName).Replace("#WORKSPACE_NAME#", $amlworkspacename).Replace("#TRANSLATOR_SERVICE_NAME#", $cog_translator_name).Replace("#TRANSLATOR_SERVICE_KEY#", $cog_translator_key.Key1).Replace("#CPU_SHELL#",$cpuShell)
Set-Content -Path $filepath -Value $item

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
		$path="/Users/"+$notebook.BaseName+".py"
	}
     elseif($notebook.BaseName -eq "retail_banking_customer_churn_for_model" -or $notebook.BaseName  -eq "retail_banking_customer_churn_data" -or $notebook.BaseName  -eq "prepared_customer_churn_data")
    {
        $source="../artifacts/amlnotebooks/"+$notebook.BaseName+".csv"
		$path="/Users/"+$notebook.BaseName+".csv"
	}
    elseif($notebook.BaseName -eq "202045000" -or $notebook.BaseName  -eq "202045001" -or $notebook.BaseName  -eq "202045002" -or $notebook.BaseName  -eq "202045003"  )
    {
        $source="../artifacts/amlnotebooks/"+$notebook.BaseName+".json"
		$path="/Users/"+$notebook.BaseName+".json"
	}
	else
	{
		$source="../artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path="/Users/"+$notebook.BaseName+".ipynb"
	}

Write-Host " Uplaoding AML assets : $($notebook.BaseName)"
Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}

#create aks compute
#az ml computetarget create aks --name  "new-aks" --resource-group $rgName --workspace-name $amlWorkSpaceName
az ml computetarget delete -n $cpuShell -v

