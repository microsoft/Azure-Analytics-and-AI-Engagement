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

$overallStateIsValid = $true

$knownIssuesMessage = @"
The cleanup validator does not support currently the following checks:

- RESULT_SET_CACHING database setting
"@

Write-Information $knownIssuesMessage


$asaArtifacts = [ordered]@{

        "asacosmosdb01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "asal400_customerprofile_cosmosdb" = @{
                Category = "datasets"
                Valid = $false
        }
        "asal400_sales_adlsgen2" = @{
                Category = "datasets"
                Valid = $false
        }
        "asal400_ecommerce_userprofiles_source" = @{
                Category = "datasets"
                Valid = $false
        }
        "asal400_december_sales" = @{
                Category = "datasets"
                Valid = $false
        }
        "asal400_saleheap_asa" = @{
                Category = "datasets"
                Valid = $false
        }
        "asal400_campaign_analytics_source" = @{
                Category = "datasets"
                Valid = $false
        }
        "asal400_wwi_campaign_analytics_asa" = @{
                Category = "datasets"
                Valid = $false
        }
        "asal400_wwi_userproductreviews_asa" = @{
                Category = "datasets"
                Valid = $false
        }
        "asal400_wwi_usertopproductpurchases_asa" = @{
                Category = "datasets"
                Valid = $false
        }
        "ASAL400 - Copy December Sales" = @{
                Category = "pipelines"
                Valid = $false
        }
        "ASAL400 - Lab 2 - Write Campaign Analytics to ASA" = @{
                Category = "dataFlows"
                Valid = $false
        }
        "ASAL400 - Lab 2 - Write User Profile Data to ASA" = @{
                Category = "dataFlows"
                Valid = $false
        }
}

$asaArtifacts2 = [ordered] @{

        "ASAL400 - Lab 2 - Write Campaign Analytics to ASA" = @{
                Category = "pipelines"
                Valid = $false
        }
        "ASAL400 - Lab 2 - Write User Profile Data to ASA" = @{
                Category = "pipelines"
                Valid = $false
        }
}

foreach ($asaArtifactName in $asaArtifacts.Keys) {
        try {
                Write-Information "Checking $($asaArtifactName) in $($asaArtifacts[$asaArtifactName]["Category"])"
                $result = Get-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts[$asaArtifactName]["Category"] -Name $asaArtifactName
                $asaArtifacts[$asaArtifactName]["Valid"] = $true
                Write-Warning "The artifact was not removed."

                $overallStateIsValid = $false
        }
        catch { 
                Write-Information "OK - the artifact is not present"
        }
}

foreach ($asaArtifactName in $asaArtifacts2.Keys) {
        try {
                Write-Information "Checking $($asaArtifactName) in $($asaArtifacts2[$asaArtifactName]["Category"])"
                $result = Get-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts2[$asaArtifactName]["Category"] -Name $asaArtifactName
                $asaArtifacts2[$asaArtifactName]["Valid"] = $true
                Write-Warning "The artifact was not removed."

                $overallStateIsValid = $false
        }
        catch { 
                Write-Information "OK - the artifact is not present"
        }
}

Write-Information "Checking SQLPool $($sqlPoolName)..."
$sqlPool = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($sqlPool -eq $null) {
        Write-Information "    The SQL pool $($sqlPoolName) was not found"
} else {

        $sqlObjects = [ordered]@{
                "wwi_staging" = @{ Category = "schema" }
                "wwi_external" = @{ Category = "schema" }
                "wwi_staging.saleheap" = @{ Category = "table" }
                "wwi_staging.sale" = @{ Category = "table" }
                "wwi_staging.dailysalescounts" = @{ Category = "table" }
                "wwi_external.sales" = @{ Category = "table" }
                "wwi_external.dailysalescounts" = @{ Category = "table" }
                "wwi.campaignanalytics" = @{ Category = "table" }
                "wwi.userproductreviews" = @{ Category = "table" }
                "wwi.usertopproductpurchases" = @{ Category = "table" }
                "wwi_perf.sale_hash" = @{ Category = "table" }
                "wwi_perf.sale_hash_projection" = @{ Category = "table" }
                "wwi_perf.sale_hash_projectio2" = @{ Category = "table" }
                "wwi_perf.sale_hash_projection_big" = @{ Category = "table" }
                "wwi_perf.sale_hash_projection_big2" = @{ Category = "table" }
                "wwi_perf.sale_hash_v2" = @{ Category = "table" }
                "wwi_ml.productpca" = @{ Category = "table" }
                "wwi.recommendations" = @{ Category = "table" }
                "abss" = @{ Category = "externaldatasource" }
                "parquetformat" = @{ Category = "externalfileformat" }
                "csv_dailysales" = @{ Category = "externalfileformat" }
                "bigdataload" = @{ Category = "workloadgroup" }
                "ceodemo" = @{ Category = "workloadgroup" }
                "heavyloader" = @{ Category = "workloadclassifier" }
                "ceo" = @{ Category = "workloadclassifier" }
                "ceodreamdemo" = @{ Category = "workloadclassifier" }
                "wwi_perf.mvcustomersales" = @{ Category = "view" }
                "wwi_perf.vtablesizes" = @{ Category = "view" }
                "wwi_perf.vcolumnstorerowgroupstats" = @{ Category = "view" }
                "wwi_perf.mvtransactionitemscounts" = @{ Category = "view" }
                "sale_hash_customer_id" = @{ Category = "statistic" }
                "store_index" = @{ Category = "index" }
                "wwi_security.fn_securitypredicate" = @{ Category = "function" }
                "salesfilter" = @{ Category = "securitypolicy" }
                "wwi_security.customerinfo.email" = @{ Category = "maskedcolumn" }
                "wwi_security.customerinfo.creditcard" = @{ Category = "maskedcolumn" }
        }
        
        $query = Get-Content -Raw -Path ".\artifacts\environment-setup\sql\18-get-sql-pool-artifacts.sql"
        $result = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $query
        
        
        foreach ($dataRow in $result.data) {
                $objectName = $dataRow[0].ToString().ToLower()
                $objectType = $dataRow[1].ToString().ToLower()

                if ($sqlObjects[$objectName] -and ($sqlObjects[$objectName]["Category"] -eq $objectType)) {
                        
                        Write-Warning "Object $($objectName) of type $($objectType) was not properly removed."
                        $overallStateIsValid = $false
                }
        }
}

$secretName = "PipelineSecret"
Write-Information "Checking $($secretName) key vault secret..."
$kvSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName
if ($kvSecret) {
        Write-Warning "The $($secretName) key vault secret was not properly removed"
        $overallStateIsValid = $false
} else {
        Write-Information "OK - the key vault secret was not found"
}

$largeIntegrationRuntimeName = "AzureLargeComputeOptimizedIntegrationRuntime"
Write-Information "Checking $($largeIntegrationRuntimeName) integration runtime..."
$result = Get-IntegrationRuntime -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $largeIntegrationRuntimeName
if ($result) {
        Write-Warning "The $($largeIntegrationRuntimeName) integration runtime was not properly removed"
        $overallStateIsValid = $false
} else {
        Write-Information "OK - integration runtime not found"
}

if ($overallStateIsValid -eq $true) {
    Write-Information "Validation Passed"
}
else {
    Write-Warning "Validation Failed - see log output"
}
