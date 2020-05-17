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

Write-Information "Checking datalake account $($dataLakeAccountName)..."
$dataLakeAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName
if ($dataLakeAccount -eq $null) {
        Write-Warning "    The datalake account $($dataLakeAccountName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"

        Write-Information "Checking data lake file system wwi-02"
        $dataLakeFileSystem = Get-AzDataLakeGen2Item -Context $dataLakeAccount.Context -FileSystem "wwi-02"
        if ($dataLakeFileSystem -eq $null) {
                Write-Warning "    The data lake file system wwi-02 was not found"
                $overallStateIsValid = $false
        } else {
                Write-Information "OK"

                $dataLakeItems = [ordered]@{
                        "sale-small" = "folder path"
                        "online-user-profiles-02" = "folder path"
                        "sale-small\Year=2014" = "folder path"
                        "sale-small\Year=2015" = "folder path"
                        "sale-small\Year=2016" = "folder path"
                        "sale-small\Year=2017" = "folder path"
                        "sale-small\Year=2018" = "folder path"
                        "sale-small\Year=2019" = "folder path"
                        "sale-small\Year=2016\Quarter=Q4\Month=12\Day=20161231\sale-small-20161231-snappy.parquet" = "file path"
                        "campaign-analytics\dailycounts.txt" = "file path"
                        "campaign-analytics\sale-20161230-snappy.parquet" = "file path"
                        "campaign-analytics\campaignanalytics.csv" = "file path"
                }
        
                foreach ($dataLakeItemName in $dataLakeItems.Keys) {
        
                        Write-Information "Checking data lake $($dataLakeItems[$dataLakeItemName]) $($dataLakeItemName)..."
                        $dataLakeItem = Get-AzDataLakeGen2Item -Context $dataLakeAccount.Context -FileSystem "wwi-02" -Path $dataLakeItemName
                        if ($dataLakeItem -eq $null) {
                                Write-Warning "    The data lake $($dataLakeItems[$dataLakeItemName]) $($dataLakeItemName) was not found"
                                $overallStateIsValid = $false
                        } else {
                                Write-Information "OK"
                        }
        
                }  
        }      
}

Write-Information "Counting Cosmos DB item in database $($cosmosDbDatabase), container $($cosmosDbContainer)"
$documentCount = Count-CosmosDbDocuments -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -CosmosDbAccountName $cosmosDbAccountName `
                -CosmosDbDatabase $cosmosDbDatabase -CosmosDbContainer $cosmosDbContainer

if ($documentCount -ne 100000 -and $overallStateIsValid) {
        # Start copy only if storage account data is good and count not 100000

        Write-Warning "    Invalid number of CosmosDb documents. Expected 100000 but found $($documentCount)."
        Write-Information "Rebuild Cosmos DB container $($cosmosDbContainer) in $($cosmosDbDatabase) database"

        $container = Get-AzCosmosDBSqlContainer `
                -ResourceGroupName $resourceGroupName `
                -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
                -Name $cosmosDbContainer

        if ($container) {

                $lockName = "DeleteLock"
                $rgLock = Get-AzResourceLock -LockName $lockName -ResourceGroupName $resourceGroupName
                if ($rgLock) {
                        Remove-AzResourceLock -LockId $rgLock.LockId -Force
                }

                Write-Information "Deleting $($cosmosDbContainer) from $($cosmosDbDatabase) Cosmos DB database"

                Remove-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
                        -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
                        -Name $cosmosDbContainer

                New-AzResourceLock -LockName $lockName -LockLevel CanNotDelete -ResourceGroupName $resourceGroupName -Force
        }

        Write-Information "Creating $($cosmosDbContainer) in $($cosmosDbDatabase) Cosmos DB database"

        Set-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
                -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
                -Name $cosmosDbContainer -Throughput 10000 `
                -PartitionKeyKind $container.Resource.PartitionKey.Kind `
                -PartitionKeyPath $container.Resource.PartitionKey.Paths

        $name = "wwi02_online_user_profiles_01_adal"
        Write-Information "Create dataset $($name)"
        $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $name -LinkedServiceName $dataLakeAccountName
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

        Write-Information "Create Cosmos DB linked service $($cosmosDbAccountName)"
        $cosmosDbAccountKey = List-CosmosDBKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName
        $result = Create-CosmosDBLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $cosmosDbAccountName -Database $cosmosDbDatabase -Key $cosmosDbAccountKey
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

        $name = "customer_profile_cosmosdb"
        Write-Information "Create dataset $($name)"
        $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $name -LinkedServiceName $cosmosDbAccountName
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

        $name = "Setup - Import User Profile Data into Cosmos DB"
        $fileName = "import_customer_profiles_into_cosmosdb"
        Write-Information "Create pipeline $($name)"
        $result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $name -FileName $fileName
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

        Write-Information "Running pipeline $($name)"
        $pipelineRunResult = Run-Pipeline -WorkspaceName $workspaceName -Name $name
        $result = Wait-ForPipelineRun -WorkspaceName $workspaceName -RunId $pipelineRunResult.runId
        $result

        #
        # =============== WAIT HERE FOR PIPELINE TO FINISH - TAKES ~8 MINUTES ====================
        #                         
        #                    COPY 100000 records to CosmosDB ==> SELECT VALUE COUNT(1) FROM C
        #

        $container = Get-AzCosmosDBSqlContainer `
                -ResourceGroupName $resourceGroupName `
                -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
                -Name $cosmosDbContainer

        Write-Information "Scaling down $($cosmosDbContainer) from $($cosmosDbDatabase) Cosmos DB database to 400 RUs"

        Set-AzCosmosDBSqlContainer -ResourceGroupName $resourceGroupName `
                -AccountName $cosmosDbAccountName -DatabaseName $cosmosDbDatabase `
                -Name $cosmosDbContainer -Throughput 400 `
                -PartitionKeyKind $container.Resource.PartitionKey.Kind `
                -PartitionKeyPath $container.Resource.PartitionKey.Paths

        $name = "Setup - Import User Profile Data into Cosmos DB"
        Write-Information "Delete pipeline $($name)"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "pipelines" -Name $name
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

        $name = "customer_profile_cosmosdb"
        Write-Information "Delete dataset $($name)"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

        $name = "wwi02_online_user_profiles_01_adal"
        Write-Information "Delete dataset $($name)"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $name
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

        $name = $cosmosDbAccountName
        Write-Information "Delete linked service $($name)"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "linkedServices" -Name $name
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

        $documentCount = Count-CosmosDbDocuments -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -CosmosDbAccountName $cosmosDbAccountName `
                -CosmosDbDatabase $cosmosDbDatabase -CosmosDbContainer $cosmosDbContainer
        
        if ($documentCount -ne 100000) {
                Write-Warning "    Invalid number of CosmosDb documents. Expected 100000 but found $($documentCount)."
                $overallStateIsValid = $false
        } 
}            

if ($overallStateIsValid -eq $true) {
    Write-Information "Validation Passed"
}
else {
    Write-Warning "Validation Failed - see log output"
}
