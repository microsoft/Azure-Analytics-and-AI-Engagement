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
$resourceGroupName = read-host "Enter the resource Group Name";

$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$subscriptionId = (Get-AzContext).Subscription.Id
$keyVaultName = "asaexpkeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASAEXP"
$sqlPoolName = "SQLPool01"
$wsId=Read-Host "Enter your powerBi workspace Id entered during template deployment"
$dataLakeAccountName = "asaexpdatalake$($uniqueId)"
$dataLakeAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $dataLakeAccountName)[0].Value


$workspaceName = "asaexpworkspace$($uniqueId)"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$powerBIName = "asaexppowerbi$($uniqueId)"
$linkedServiceName = $sqlPoolName.ToLower()


Add-Content log.txt "------linked Services------"
Write-Host "----linked Services------"
#Creating linked services
RefreshTokens

$templatepath = "..\templates\"

##key_vault_linked_service
$filepath=$templatepath+"key_vault_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $keyVaultName).Replace("#KEY_VAULT_NAME#", $keyVaultName)
$uri = "https://$($workspaceName).dev.azuresynapse.net/linkedservices/$($keyVaultName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host "uploading linked service key_vault_linked_service.json"
Write-Host $result

##powerbi linked services
$filepath=$templatepath+"powerbi_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "PowerBI_LinkedService").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($workspaceName).dev.azuresynapse.net/linkedservices/$($powerBIName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host "uploading linked service powerbi_linked_service.json"
Write-Host $result
 
##Datalake linked services
$filepath=$templatepath+"data_lake_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $dataLakeAccountKey)
$uri = "https://$($workspaceName).dev.azuresynapse.net/linkedservices/$($dataLakeAccountName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host "uploading linked service data_lake_linked_service.json"
Write-Host $result

##sql pool linked services
$filepath=$templatepath+"sql_pool_key_vault_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $linkedServiceName).Replace("#WORKSPACE_NAME#", $workspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#USER_NAME#", "asaexp.sql.admin").Replace("#KEY_VAULT_LINKED_SERVICE_NAME#", $keyVaultName).Replace("#SECRET_NAME#", $keyVaultSQLUserSecretName) 
$uri = "https://$($workspaceName).dev.azuresynapse.net/linkedservices/$($sqlPoolName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host "uploading linked service sql_pool_key_vault_linked_service.json"
Write-Host $result
 
##integration_runtime linked services
$filepath=$templatepath+"integration_runtime.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#INTEGRATION_RUNTIME_NAME#", $integrationRuntimeName).Replace("#CORE_COUNT#", 16).Replace("#TIME_TO_LIVE#", 16)
$uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourcegroups/$($resourceGroupName)/providers/Microsoft.Synapse/workspaces/$($workspaceName)/integrationruntimes/$($integrationRuntimeName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
Write-Host "uploading linked service integration_runtime.json"
Write-Host $result
