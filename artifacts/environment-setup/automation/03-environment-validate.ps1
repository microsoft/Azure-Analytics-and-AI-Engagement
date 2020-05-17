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
$global:sqlPassword = $AzureSQLPassword          # READ FROM FILE

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
$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asa.sql.admin"

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

$asaArtifacts = [ordered]@{

        "wwi02_sale_small_workload_01_asa" = @{ 
                Category = "datasets"
                Valid = $false
        }
        "wwi02_sale_small_workload_02_asa" = @{ 
                Category = "datasets"
                Valid = $false
        }
        "Lab 08 - Execute Business Analyst Queries" = @{
                Category = "pipelines"
                Valid = $false
        }
        "Lab 08 - Execute Data Analyst and CEO Queries" = @{
                Category = "pipelines"
                Valid = $false
        }
        "Lab 06 - Machine Learning" = @{
                Category = "notebooks"
                Valid = $false
        }
        "Lab 07 - Spark ML" = @{
                Category = "notebooks"
                Valid = $false
        }
        "Activity 05 - Model Training" = @{
                Category = "notebooks"
                Valid = $false
        }
        "Lab 05 - Exercise 3 - Column Level Security" = @{
                Category = "sqlscripts"
                Valid = $false
        }
        "Lab 05 - Exercise 3 - Dynamic Data Masking" = @{
                Category = "sqlscripts"
                Valid = $false
        }
        "Lab 05 - Exercise 3 - Row Level Security" = @{
                Category = "sqlscripts"
                Valid = $false
        }
        "Activity 03 - Data Warehouse Optimization" = @{
                Category = "sqlscripts"
                Valid = $false
        }
        "sqlpool01_import01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01_highperf" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01_workload01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01_workload02" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "$($blobStorageAccountName)" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "$($dataLakeAccountName)" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "$($keyVaultName)" = @{
                Category = "linkedServices"
                Valid = $false
        }
}

foreach ($asaArtifactName in $asaArtifacts.Keys) {
        try {
                Write-Information "Checking $($asaArtifactName) in $($asaArtifacts[$asaArtifactName]["Category"])"
                $result = Get-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts[$asaArtifactName]["Category"] -Name $asaArtifactName
                $asaArtifacts[$asaArtifactName]["Valid"] = $true
                Write-Information "OK"
        }
        catch { 
                Write-Warning "Not found!"
                $overallStateIsValid = $false
        }
}

# the $asaArtifacts contains the current status of the workspace

Write-Information "Checking SQLPool $($sqlPoolName)..."
$sqlPool = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($sqlPool -eq $null) {
        Write-Warning "    The SQL pool $($sqlPoolName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"

        $tables = [ordered]@{
                "wwi.Date" = @{
                        Count = 3652
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi.Product" = @{
                        Count = 5000
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi.SaleSmall" = @{
                        Count = 1863080489
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Hash_Ordered" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Heap" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Index" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Partition01" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Partition02" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_security.CustomerInfo" = @{
                        Count = 110
                        StrictCount = $false
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_security.Sale" = @{
                        Count = 52
                        StrictCount = $false
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_ml.MLModelExt" = @{
                        Count = 1
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_ml.MLModel" = @{
                        Count = 0
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
        }
        
$query = @"
SELECT
        S.name as SchemaName
        ,T.name as TableName
FROM
        sys.tables T
        join sys.schemas S on
                T.schema_id = S.schema_id
"@

        #$result = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $query
        $result = Invoke-SqlCmd -Query $query -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword

        #foreach ($dataRow in $result.data) {
        foreach ($dataRow in $result) {
                $schemaName = $dataRow[0]
                $tableName = $dataRow[1]
        
                $fullName = "$($schemaName).$($tableName)"
        
                if ($tables[$fullName]) {
                        
                        $tables[$fullName]["Valid"] = $true
                        $strictCount = $tables[$fullName]["StrictCount"]
        
                        Write-Information "Counting table $($fullName) with StrictCount = $($strictCount)..."
        
                        try {
                            $countQuery = "select count_big(*) from $($fullName)"

                            #$countResult = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $countQuery
                            #count = [int64]$countResult[0][0].data[0].Get(0)
                            $countResult = Invoke-Sqlcmd -Query $countQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
                            $count = $countResult[0][0]
        
                            Write-Information "    Count result $($count)"
        
                            if (
                                ($strictCount -and ($count -eq $tables[$fullName]["Count"])) -or
                                ((-not $strictCount) -and ($count -ge $tables[$fullName]["Count"]))) {

                                    Write-Information "    OK - Records counted is correct."
                                    $tables[$fullName]["ValidCount"] = $true
                            }
                            else {
                                Write-Warning "    Records counted is NOT correct."
                                $overallStateIsValid = $false
                            }
                        }
                        catch { 
                            Write-Warning "    Error while querying table."
                            $overallStateIsValid = $false
                        }
        
                }
        }
        
        # $tables contains the current status of the necessary tables
        foreach ($tableName in $tables.Keys) {
                if (-not $tables[$tableName]["Valid"]) {
                        Write-Warning "Table $($tableName) was not found."
                        $overallStateIsValid = $false
                }
        }

        $users = [ordered]@{
                "CEO" = @{ Valid = $false }
                "DataAnalystMiami" = @{ Valid = $false }
                "DataAnalystSanDiego" = @{ Valid = $false }
                "asa.sql.workload01" = @{ Valid = $false }
                "asa.sql.workload02" = @{ Valid = $false }
                "asa.sql.import01" = @{ Valid = $false }
                "asa.sql.import02" = @{ Valid = $false }
                "asa.sql.highperf" = @{ Valid = $false }
                "$($userName)" = @{ Valid = $false }
        }

$query = @"
select name from sys.sysusers
"@
        #$result = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $query
        $result = Invoke-SqlCmd -Query $query -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword

        #foreach ($dataRow in $result.data) {
        foreach ($dataRow in $result) {
                $name = $dataRow[0]

                if ($users[$name]) {
                        Write-Information "Found user $($name)."
                        $users[$name]["Valid"] = $true
                }
        }

        foreach ($name in $users.Keys) {
                if (-not $users[$name]["Valid"]) {
                        Write-Warning "User $($name) was not found."
                        $overallStateIsValid = $false
                }
        }
}

Write-Information "Checking Spark pool $($sparkPoolName)"
$sparkPool = Get-SparkPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName
if ($sparkPool -eq $null) {
        Write-Warning "    The Spark pool $($sparkPoolName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"
}

Write-Information "Counting Cosmos DB item in database $($cosmosDbDatabase), container $($cosmosDbContainer)"
$documentCount = Count-CosmosDbDocuments -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -CosmosDbAccountName $cosmosDbAccountName `
                -CosmosDbDatabase $cosmosDbDatabase -CosmosDbContainer $cosmosDbContainer

if ($documentCount -ne 100000) {
        Write-Warning "    Invalid number of CosmosDb documents. Expected 100000 but found $($documentCount)."
        $overallStateIsValid = $false
}            

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


if ($overallStateIsValid -eq $true) {
    Write-Information "Validation Passed"
}
else {
    Write-Warning "Validation Failed - see log output"
}


