Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB

#
# TODO: Keep all required configuration in C:\LabFiles\AzureCreds.ps1 file
. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                # READ FROM FILE
$password = $AzurePassword                # READ FROM FILE
$clientId = $TokenGeneratorClientId       # READ FROM FILE
$sqlPassword = $AzureSQLPassword          # READ FROM FILE

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*L400*" }).ResourceGroupName
$uniqueId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

$templatesPath = ".\artifacts\environment-setup\templates"
$datasetsPath = ".\artifacts\environment-setup\datasets"
$pipelinesPath = ".\artifacts\environment-setup\pipelines"
$sqlScriptsPath = ".\artifacts\environment-setup\sql"
$workspaceName = "asaworkspace$($uniqueId)"
$cosmosDbAccountName = "asacosmosdb$($uniqueId)"
$cosmosDbDatabase = "CustomerProfile"
$cosmosDbContainer = "OnlineUserProfile01"
$dataLakeAccountName = "asadatalake$($uniqueId)"
$blobStorageAccountName = "asastore$($uniqueId)"
$keyVaultName = "asakeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASA"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$sparkPoolName = "SparkPool01"
$amlWorkspaceName = "amlworkspace$($uniqueId)"


$ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
$global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
$global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
$global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

$kvSecretName = "PipelineSecret"
$kvSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $kvSecretName
if ($kvSecret) {
        Remove-AzKeyVaultSecret -VaultName $keyVaultName -Name $kvSecretName -Force
}

$lockName = "DeleteLock"
$rgLock = Get-AzResourceLock -LockName $lockName -ResourceGroupName $resourceGroupName
if ($rgLock) {
        Remove-AzResourceLock -LockId $rgLock.LockId -Force
}

$largeIntegrationRuntimeName = "AzureLargeComputeOptimizedIntegrationRuntime"
Write-Information "Removing $($largeIntegrationRuntimeName) integration runtime..."
$result = Get-IntegrationRuntime -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $largeIntegrationRuntimeName
if ($result) {
        $result = Delete-IntegrationRuntime -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $largeIntegrationRuntimeName
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

if ($rgLock) {
        New-AzResourceLock -LockName $lockName -LockLevel CanNotDelete -ResourceGroupName $resourceGroupName -Force
}

Write-Information "Removing workspace artifacts"

$asaArtifacts = [ordered] @{

        "ASAL400 - Lab 2 - Write Campaign Analytics to ASA" = "pipelines"
        "ASAL400 - Lab 2 - Write User Profile Data to ASA" = "pipelines"
        "ASAL400 - Copy December Sales" = "pipelines"
}

$asaArtifacts2 = [ordered]@{

        "ASAL400 - Lab 2 - Write Campaign Analytics to ASA" = "dataflows"
        "ASAL400 - Lab 2 - Write User Profile Data to ASA" = "dataflows"
        "asal400_customerprofile_cosmosdb" = "datasets"
        "asal400_sales_adlsgen2" = "datasets"
        "asal400_ecommerce_userprofiles_source" = "datasets"
        "asal400_december_sales" = "datasets"
        "asal400_saleheap_asa" = "datasets"
        "asal400_campaign_analytics_source" = "datasets"
        "asal400_wwi_campaign_analytics_asa" = "datasets"
        "asal400_wwi_userproductreviews_asa" = "datasets"
        "asal400_wwi_usertopproductpurchases_asa" = "datasets"
        "asacosmosdb01" = "linkedServices"
}

foreach ($asaArtifactName in $asaArtifacts.Keys) {
        Write-Information "Deleting $($asaArtifactName) in $($asaArtifacts[$asaArtifactName])"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts[$asaArtifactName] -Name $asaArtifactName
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

foreach ($asaArtifactName in $asaArtifacts2.Keys) {
        Write-Information "Deleting $($asaArtifactName) in $($asaArtifacts2[$asaArtifactName])"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts2[$asaArtifactName] -Name $asaArtifactName
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}
