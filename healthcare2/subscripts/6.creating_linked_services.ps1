function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

az login

#for powershell...
Connect-AzAccount -DeviceCode

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
if ($subs.GetType().IsArray -and $subs.length -gt 1) {
    $subOptions = [System.Collections.ArrayList]::new()
    for ($subIdx = 0; $subIdx -lt $subs.length; $subIdx++) {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    $title = 'Subscription selection'
    $question = 'Are you sure you want to select this subscription for this lab?'
    $choices = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
    else {
        $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
        $selectedSubName = $subs[$selectedSubIdx]
        Write-Host "Selecting the subscription : $selectedSubName "
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
}

$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"] 
$suffix = "$random-$init"
$concatString = "$init$random"
$synapseWorkspaceName = "synhealthcare2$concatString"
$sqlPoolName = "HealthcareDW"
$dataLakeAccountName = "sthealthcare2$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$sqlUser = "labsqladmin"
$mssql_server_name = "mssqlhc2-$suffix"
$sqlDatabaseName = "InventoryDB"
$cosmos_healthcare2_name = "cosmos-healthcare2-$random$init"
if ($cosmos_healthcare2_name.length -gt 43) {
    $cosmos_healthcare2_name = $cosmos_healthcare2_name.substring(0, 43)
}
$keyVaultName = "kv-hc2-$concatString"
if($keyVaultName.length -gt 24)
{
$keyVaultName = $keyVaultName.substring(0,24)
}

$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value

$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
$secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText

#Cosmos keys
$cosmos_account_key = az cosmosdb keys list -n $cosmos_healthcare2_name -g $rgName | ConvertFrom-Json
$cosmos_account_key = $cosmos_account_key.primarymasterkey


    Add-Content log.txt "------linked Services------"
    Write-Host "----linked Services------"
    #Creating linked services
    RefreshTokens
    $templatepath = "../artifacts/linkedService/"

    # AutoResolveIntegrationRuntime
    $FilePathRT = "../artifacts/linkedService/AutoResolveIntegrationRuntime.json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization = "Bearer $managementToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # IR-SAPHANA
    $FilePathRT = "../artifacts/linkedService/IR-SAPHANA.json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/IR-SAPHANA?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization = "Bearer $managementToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureBlobStorage
    Write-Host "Creating linked Service: AzureBlobStorage"
    $filepath = $templatepath + "AzureBlobStorage.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureBlobStorage?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureBlobStorage1
    Write-Host "Creating linked Service: AzureBlobStorage1"
    $filepath = $templatepath + "AzureBlobStorage1.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureBlobStorage1?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureCosmosDb
    Write-Host "Creating linked Service: AzureCosmosDb"
    $filepath = $templatepath + "AzureCosmosDb.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#COSMOSDB_NAME#", $cosmos_healthcare2_name).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureCosmosDb?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureDataLakeStorageTwitterData
    Write-Host "Creating linked Service: AzureDataLakeStorageTwitterData"
    $filepath = $templatepath + "AzureDataLakeStorageTwitterData.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDataLakeStorageTwitterData?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # # AzureDatabricksAnalyticsSolutions
    # Write-Host "Creating linked Service: AzureDatabricksAnalyticsSolutions"
    # $filepath=$templatepath+"AzureDatabricksAnalyticsSolutions.json"
    # $itemTemplate = Get-Content -Path $filepath
    # $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token)
    # $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksAnalyticsSolutions?api-version=2019-06-01-preview"
    # $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    # Add-Content log.txt $result          

    # # AzureDatabricksDeltaLake
    # Write-Host "Creating linked Service: AzureDatabricksDeltaLake"
    # $filepath=$templatepath+"AzureDatabricksDeltaLake.json"
    # $itemTemplate = Get-Content -Path $filepath
    # $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token).Replace("#CLUSTER_ID#", $clusterId)
    # $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksDeltaLake?api-version=2019-06-01-preview"
    # $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    # Add-Content log.txt $result

    # # AzureDatabricksDeltaLakeTwitterData
    # Write-Host "Creating linked Service: AzureDatabricksDeltaLakeTwitterData"
    # $filepath=$templatepath+"AzureDatabricksDeltaLakeTwitterData.json"
    # $itemTemplate = Get-Content -Path $filepath
    # $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token).Replace("#CLUSTER_ID#", $clusterId)
    # $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksDeltaLakeTwitterData?api-version=2019-06-01-preview"
    # $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    # Add-Content log.txt $result

    # AzureSqlDatabase
    Write-Host "Creating linked Service: AzureSqlDatabase"
    $filepath = $templatepath + "AzureSqlDatabase.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#SERVER_NAME#", $mssql_server_name).Replace("#DATABASE_NAME#", $sqlDatabaseName).Replace("#USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureSqlDatabase?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # DynamicsHealthCare linked services
    Write-Host "Creating linked Service: DynamicsHealthCare"
    $filepath=$templatepath+"DynamicsHealthCare.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/DynamicsHealthCare?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # LS_SapHana linked services
    Write-Host "Creating linked Service: LS_SapHana"
    $filepath=$templatepath+"LS_SapHana.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/LS_SapHana?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # OracleDB linked services
    Write-Host "Creating linked Service: OracleDB"
    $filepath = $templatepath + "OracleDB.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/OracleDB?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
    
    # PowerBIWorkspace
    Write-Host "Creating linked Service: PowerBIWorkspace"
    $filepath = $templatepath + "PowerBIWorkspace.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_ID#", $wsId).Replace("#TENANT_ID#", $tenantId)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/PowerBIWorkspace?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # ProfiseeRestService linked services
    Write-Host "Creating linked Service: ProfiseeRestService"
    $filepath = $templatepath + "ProfiseeRestService.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/ProfiseeRestService?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # Snowflake linked services
    Write-Host "Creating linked Service: Snowflake"
    $filepath = $templatepath + "Snowflake.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Snowflake?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
    
    # SynapseAnalyticsProd
    Write-Host "Creating linked Service: SynapseAnalyticsProd"
    $filepath = $templatepath + "SynapseAnalyticsProd.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SynapseAnalyticsProd?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
    
    # synhealthcare2-WorkspaceDefaultSqlServer
    Write-Host "Creating linked Service: synhealthcare2-WorkspaceDefaultSqlServer"
    $filepath = $templatepath + "synhealthcare2-WorkspaceDefaultSqlServer.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synhealthcare2-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
    
    # synhealthcare2prod-WorkspaceDefaultSqlServer
    Write-Host "Creating linked Service: synhealthcare2prod-WorkspaceDefaultSqlServer"
    $filepath = $templatepath + "synhealthcare2prod-WorkspaceDefaultSqlServer.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synhealthcare2prod-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # synhealthcare2prod-WorkspaceDefaultStorage
    Write-Host "Creating linked Service: synhealthcare2prod-WorkspaceDefaultStorage"
    $filepath = $templatepath + "synhealthcare2prod-WorkspaceDefaultStorage.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synhealthcare2prod-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
