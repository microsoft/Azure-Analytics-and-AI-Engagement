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
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$synapseWorkspaceName = "synapsefsi$init$random"
$sqlPoolName = "FsiDW"
$sqlUser = "labsqladmin"
$mssql_server_name = "dbserver-marketingdata-$suffix"
$mssql_administrator_login = "labsqladmin"
$mssql_database_name = "db-geospatial-dev"
$subscriptionId = (Get-AzContext).Subscription.Id
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$concatString = "$init$random"
$dataLakeAccountName = "stfsi$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$concatString1 = "$random$init"
$cosmos_account_name = "cosmosdb-fsi-$concatString1"
if($cosmos_account_name.length -gt 43 )
{
$cosmos_account_name = $cosmos_account_name.substring(0,43)
}
$cosmos_database_name = "fsi-marketdata"

#Cosmos keys
$cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

$suffix = "$random-$init"
$keyVaultName = "kv-$suffix";
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText
$mssqlPassword = $sqlPassword

Write-Host "----linked Services------"
#Creating linked services
RefreshTokens

$templatepath="../artifacts/templates/"

##cosmos linked services
Write-Host "Creating linked Service: Cosmosmarketdata"
$filepath=$templatepath+"Cosmosmarketdata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key).Replace("#COSMOS_DATABASE#", $cosmos_database_name)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Cosmosmarketdata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result
 
##Datalake linked services
Write-Host "Creating linked Service: 0_marketdatadl"
$filepath=$templatepath+"0_marketdatadl.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/0_marketdatadl?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result

##SQL server linked services
Write-Host "Creating linked Service: AzureSqlDatabase"
$filepath=$templatepath+"AzureSqlDatabase.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#MSSQL_SERVER_NAME#", $mssql_server_name).Replace("#MSSQL_DATABASE_NAME#", $mssql_database_name).Replace("#MSSQL_USERNAME#", $mssql_administrator_login).Replace("#MSSQL_PASSWORD#", $mssqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureSqlDatabase?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result

##blob linked services
Write-Host "Creating linked Service: marketdatadl"
$filepath=$templatepath+"marketdatadl.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/marketdatadl?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result

##blob linked services
Write-Host "Creating linked Service: marketdatasynapse-WorkspaceDefaultStorage"
$filepath=$templatepath+"marketdatasynapse-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/marketdatasynapse-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result

##AzureSql linked services
Write-Host "Creating linked Service: FSIRiskDW"
$filepath=$templatepath+"FSIRiskDW.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/FSIRiskDW?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result

##sap hana linked services
Write-Host "Creating linked Service: SapHana"
$filepath=$templatepath+"SapHana.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result
 
##powerbi linked services
Write-Host "Creating linked Service: powerbi_linked_service"
$filepath=$templatepath+"powerbi_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/powerbi_linked_service?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result

##Teradata linked services
Write-Host "Creating linked Service: Teradata"
$filepath=$templatepath+"Teradata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "Teradata").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host  $result

# AutoResolveIntegrationRuntime
$FilePathRT="../artifacts/templates/AutoResolveIntegrationRuntime.json" 
$itemRT = Get-Content -Path $FilePathRT
$uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
Write-Host  $result
