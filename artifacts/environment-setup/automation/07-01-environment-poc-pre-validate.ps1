Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB
# Install-Module -Name SqlServer -AllowClobber

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

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($result.properties.status -ne "Online") {
    Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
    Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

$tables = [ordered]@{
        "wwi.SaleSmall" = @{
                Count = 1863080489
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

                Write-Information "Counting table $($fullName)..."

                try {
                    $countQuery = "select count_big(*) from $($fullName)"
                    
                    #$countResult = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $countQuery
                    #count = [int64]$countResult[0][0].data[0].Get(0)
                    $countResult = Invoke-Sqlcmd -Query $countQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
                    $count = $countResult[0][0]

                    Write-Information "    Count result $($count)"

                    if ($count -eq $tables[$fullName]["Count"]) {
                            Write-Information "    Records counted is correct."
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


$dataLakeItems = [ordered]@{
        "data-generators\generator-customer.csv" = "file path"
        "sale-poc\sale-20170501.csv" = "file path"
        "sale-poc\sale-20170502.csv" = "file path"
        "sale-poc\sale-20170503.csv" = "file path"
        "sale-poc\sale-20170504.csv" = "file path"
        "sale-poc\sale-20170505.csv" = "file path"
        "sale-poc\sale-20170506.csv" = "file path"
        "sale-poc\sale-20170507.csv" = "file path"
        "sale-poc\sale-20170508.csv" = "file path"
        "sale-poc\sale-20170509.csv" = "file path"
        "sale-poc\sale-20170510.csv" = "file path"
        "sale-poc\sale-20170511.csv" = "file path"
        "sale-poc\sale-20170512.csv" = "file path"
        "sale-poc\sale-20170513.csv" = "file path"
        "sale-poc\sale-20170514.csv" = "file path"
        "sale-poc\sale-20170515.csv" = "file path"
        "sale-poc\sale-20170516.csv" = "file path"
        "sale-poc\sale-20170517.csv" = "file path"
        "sale-poc\sale-20170518.csv" = "file path"
        "sale-poc\sale-20170519.csv" = "file path"
        "sale-poc\sale-20170520.csv" = "file path"
        "sale-poc\sale-20170521.csv" = "file path"
        "sale-poc\sale-20170522.csv" = "file path"
        "sale-poc\sale-20170523.csv" = "file path"
        "sale-poc\sale-20170524.csv" = "file path"
        "sale-poc\sale-20170525.csv" = "file path"
        "sale-poc\sale-20170526.csv" = "file path"
        "sale-poc\sale-20170527.csv" = "file path"
        "sale-poc\sale-20170528.csv" = "file path"
        "sale-poc\sale-20170529.csv" = "file path"
        "sale-poc\sale-20170530.csv" = "file path"
        "sale-poc\sale-20170531.csv" = "file path"
}


Write-Information "Checking datalake account $($dataLakeAccountName)..."
$dataLakeAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName
if ($dataLakeAccount -eq $null) {
        Write-Warning "    The datalake account $($dataLakeAccountName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"

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


if ($overallStateIsValid -eq $true) {
    Write-Information "Validation Passed"
}
else {
    Write-Warning "Validation Failed - see log output"
}


