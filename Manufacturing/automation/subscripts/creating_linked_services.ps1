function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#will be done as part of the cloud shell start - README

#remove-item MfgAI -recurse -force
#git clone -b real-time https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git MfgAI

#cd 'MfgAI/Manufacturing/automation'

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
$cosmos_account_name_mfgdemo = "cosmosdb-mfgdemo-$random$init" 
$synapseWorkspaceName = "manufacturingdemo$init$random"
$concatString = "$init$random"
$sqlPoolName = "ManufacturingDW"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))
$cosmos_database_name_mfgdemo_manufacturing = "manufacturing"
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value

$cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name_mfgdemo -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

Add-Content log.txt "------linked Services------"
Write-Host "----linked Services------"
#Creating linked services
RefreshTokens

$templatepath="../artifacts/templates/"

##cosmos linked services
$filepath=$templatepath+"cosmos_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $cosmos_account_name_mfgdemo).Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_mfgdemo).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key).Replace("#COSMOS_DATABASE#", $cosmos_database_name_mfgdemo_manufacturing)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($cosmos_account_name_mfgdemo)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##Datalake linked services
$filepath=$templatepath+"data_lake_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($dataLakeAccountName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##blob linked services
$filepath=$templatepath+"blob_storage_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$name=$dataLakeAccountName+"blob"
$blobLinkedService=$name
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $name).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($name)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##powerbi linked services
$filepath=$templatepath+"powerbi_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "ManufacturingDemo").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/ManufacturingDemo?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##sql pool linked services
$filepath=$templatepath+"sql_pool_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $sqlPoolName).Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($sqlPoolName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##sap hana linked services
$filepath=$templatepath+"sap_hana_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "SapHana")
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##teradata linked services
$filepath=$templatepath+"teradata_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "TeraData")
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/TeraData?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##oracle linked services
$filepath=$templatepath+"oracle_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "oracle")
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/oracle?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
