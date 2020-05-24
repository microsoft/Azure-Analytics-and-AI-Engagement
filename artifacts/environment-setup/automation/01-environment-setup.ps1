Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser

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

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*CDP-Demo*" }).ResourceGroupName
$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$global:logindomain = (Get-AzContext).Tenant.Id

$templatesPath = ".\artifacts\environment-setup\templates"
$datasetsPath = ".\artifacts\environment-setup\datasets"
$dataflowsPath = ".\artifacts\environment-setup\dataflows"
$pipelinesPath = ".\artifacts\environment-setup\pipelines"
$sqlScriptsPath = ".\artifacts\environment-setup\sql"
$workspaceName = "asaexpworkspace$($uniqueId)"
$dataLakeAccountName = "asaexpdatalake$($uniqueId)"
$blobStorageAccountName = "asaexpstore$($uniqueId)"
$keyVaultName = "asaexpkeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASAEXP"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$sparkPoolName = "SparkPool01"
$amlWorkspaceName = "amlworkspace$($uniqueId)"
$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asaexp.sql.admin"


$ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
$global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
$global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
$global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
        Synapse    = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

Write-Information "Assign Ownership to Proctors on Synapse Workspace"
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "6e4bf58a-b8e1-4cc3-bbf9-d73143322b78" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Workspace Admin
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "7af0c69a-a548-47d6-aea3-d00e69bd83aa" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # SQL Admin
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "c3a6d2f1-a26f-4810-9b0f-591308d5cbf1" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Apache Spark Admin

Write-Information "Create KeyVault linked service $($keyVaultName)"

$result = Create-KeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $keyVaultName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create Integration Runtime $($integrationRuntimeName)"

$result = Create-IntegrationRuntime -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $integrationRuntimeName -CoreCount 16 -TimeToLive 60
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create Data Lake linked service $($dataLakeAccountName)"

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName
$result = Create-DataLakeLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $dataLakeAccountName  -Key $dataLakeAccountKey
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Copy TwitterData to Data Lake"

$publicDataUrl = "https://solliancepublicdata.blob.core.windows.net/"
$dataLakeStorageUrl = "https://"+ $dataLakeAccountName + ".dfs.core.windows.net/"
$dataLakeStorageBlobUrl = "https://"+ $dataLakeAccountName + ".blob.core.windows.net/"

$dataLakeStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $dataLakeStorageAccountKey

if(Get-AzStorageContainer -Name "twitterdata" -Context $dataLakeContext -ErrorAction SilentlyContinue)  
    {  
        Write-Host -ForegroundColor Magenta "twitterdata container already exists."  
    }  
    else  
    {  
       Write-Host -ForegroundColor Magenta "twitterdata container does not exist."   
       $dataLakeContainer = New-AzStorageContainer -Name "twitterdata" -Permission Container -Context $dataLakeContext  
    }       
$destinationSasKey = New-AzStorageContainerSASToken -Container "twitterdata" -Context $dataLakeContext -Permission rwdl

$azCopyLink = (curl https://aka.ms/downloadazcopy-v10-windows -MaximumRedirection 0 -ErrorAction silentlycontinue).headers.location
Invoke-WebRequest $azCopyLink -OutFile "C:\LabFiles\azCopy.zip"
Expand-Archive "C:\LabFiles\azCopy.zip" -DestinationPath "C:\LabFiles" -Force

$azCopyCommand = (Get-ChildItem -Path C:\LabFiles -Recurse azcopy.exe).Directory.FullName
$Env:Path += ";"+ $azCopyCommand

$AnonContext = New-AzStorageContext -StorageAccountName "solliancepublicdata" -Anonymous
$singleFiles = Get-AzStorageBlob -Container "cdp" -Context $AnonContext | Where-Object Length -GT 0 | select-object @{Name = "SourcePath"; Expression = {"cdp/"+$_.Name}} , @{Name = "TargetPath"; Expression = {$_.Name}}

foreach ($singleFile in $singleFiles) {
        Write-Information $singleFile
        $source = $publicDataUrl + $singleFile.SourcePath
        $destination = $dataLakeStorageBlobUrl + $singleFile.TargetPath + $destinationSasKey
        Write-Information "Copying file $($source) to $($destination)"
        azcopy copy $source $destination 
}

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($result.properties.status -ne "Online") {
        Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
        Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

Write-Information "Create tables in $($sqlPoolName)"

$params = @{ }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "01-create-tables" -Parameters $params 
$result

Write-Information "Loading data"

$dataTableList = New-Object System.Collections.ArrayList
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"dimcustomer"}} , @{Name = "TABLE_NAME"; Expression = {"Dim_Customer"}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"millennialcustomer"}} , @{Name = "TABLE_NAME"; Expression = {"MillennialCustomers"}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"sale"}} , @{Name = "TABLE_NAME"; Expression = {"Sales"}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"product"}} , @{Name = "TABLE_NAME"; Expression = {"Products"}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"twitteranalytics"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterAnalytics"}}
$dataTableList.Add($temp)

foreach ($dataTableLoad in $dataTableList) {
        Write-Information "Loading data for $($dataTableLoad.TABLE_NAME)"
        $result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "02-load-csv" -Parameters @{
                CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
                TABLE_NAME = $dataTableLoad.TABLE_NAME
         }
        $result
        Write-Information "Data for $($dataTableLoad.TABLE_NAME) loaded."
}

Write-Information "Loading 30 Billion Records"

Write-Information "Scale up the $($sqlPoolName) SQL pool to DW3000c to prepare for 30 Billion Rows."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW3000c
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online

$start = Get-Date
[nullable[double]]$secondsRemaining = $null
$maxIterationCount = 9

For ($count=0; $count -le $maxIterationCount; $count++) {

        $percentComplete = ($count / $maxIterationCount) * 100
        $progressParameters = @{
                Activity = "Loading data [$($count)/$($maxIterationCount)] $($secondsElapsed.ToString('hh\:mm\:ss'))"
                Status = 'Processing'
                PercentComplete = $percentComplete
            }

        if ($secondsRemaining) {
                $progressParameters.SecondsRemaining = $secondsRemaining
            }

        Write-Progress @progressParameters

        $params = @{ }
        $result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "03-Billion_Records" -Parameters $params 
        $result

        $secondsElapsed = (Get-Date) - $start
        $secondsRemaining = ($secondsElapsed.TotalSeconds / ($count +1)) * ($maxIterationCount - $count)
}

Write-Information "Scale down the $($sqlPoolName) SQL pool to DW500c after 30 Billion Rows."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW500c
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online

Write-Information "Create data sets for Lab 08"

$datasets = @{
        DestinationDataset_d89 = $dataLakeAccountName
        SourceDataset_d89 = $dataLakeAccountName
        AzureSynapseAnalyticsTable8 = $workspaceName + "-WorkspaceDefaultSqlServer"
        AzureSynapseAnalyticsTable9 = $workspaceName + "-WorkspaceDefaultSqlServer"
        DelimitedText1 = $dataLakeAccountName 
        TeradataMarketingDB = $dataLakeAccountName 
        MarketingDB_Stage = $dataLakeAccountName 
        Synapse = $workspaceName + "-WorkspaceDefaultSqlServer"
        OracleSalesDB = $workspaceName + "-WorkspaceDefaultSqlServer" 
        AzureSynapseAnalyticsTable1 = $workspaceName + "-WorkspaceDefaultSqlServer"
        Parquet1 = $dataLakeAccountName
        Parquet2 = $dataLakeAccountName
        Parquet3 = $dataLakeAccountName
}

foreach ($dataset in $datasets.Keys) {
        Write-Information "Creating dataset $($dataset)"
        $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $dataset -LinkedServiceName $datasets[$dataset]
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

Write-Information "Create DataFlow for SAP to HANA Pipeline"
$params = @{
        LOAD_TO_SYNAPSE = "AzureSynapseAnalyticsTable8"
        LOAD_TO_AZURE_SYNAPSE = "AzureSynapseAnalyticsTable9"
        DATA_FROM_SAP_HANA = "DelimitedText1"
}
$workloadDataflows = [ordered]@{
        ingest_data_from_sap_hana_to_azure_synapse = "ingest_data_from_sap_hana_to_azure_synapse"
}

foreach ($dataflow in $workloadDataflows.Keys) {
        Write-Information "Creating dataflow $($workloadDataflows[$dataflow])"
        $result = Create-Dataflow -DataflowPath $dataflowsPath -WorkspaceName $workspaceName -Name $workloadDataflows[$dataflow] -Parameters $params
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

Write-Information "Create pipelines for Lab 08"

$params = @{
        DATA_LAKE_STORAGE_NAME = $dataLakeAccountName
        DEFAULT_STORAGE = $workspaceName + "-WorkspaceDefaultStorage"
}
$workloadPipelines = [ordered]@{
        sap_hana_to_adls = "SAP HANA TO ADLS"
        marketing_db_migration = "MarketingDBMigration"
        sales_db_migration = "SalesDBMigration"
        twitter_data_migration = "TwitterDataMigration"
}

foreach ($pipeline in $workloadPipelines.Keys) {
        Write-Information "Creating workload pipeline $($workloadPipelines[$pipeline])"
        $result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $workloadPipelines[$pipeline] -FileName $pipeline -Parameters $params
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

Write-Information "Creating Spark notebooks..."

$notebooks = [ordered]@{
        "3 Campaign Analytics Data Prep"    = ".\artifacts\environment-setup\notebooks"
        "1 Products Recommendation"   = ".\artifacts\environment-setup\notebooks"
}

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $resourceGroupName
        "#AML_WORKSPACE_NAME#"  = $amlWorkspaceName
}

foreach ($notebookName in $notebooks.Keys) {

        $notebookFileName = "$($notebooks[$notebookName])\$($notebookName).ipynb"
        Write-Information "Creating notebook $($notebookName) from $($notebookFileName)"
        
        $result = Create-SparkNotebook -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName `
                -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName -Name $notebookName -NotebookFileName $notebookFileName -CellParams $cellParams
        $result = Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
        $result
}

Write-Information "Create SQL scripts for Lab 05"

$sqlScripts = [ordered]@{
        "8 External Data To Synapse Via Copy Into" = ".\artifacts\environment-setup\sql"
        "1 SQL Query With Synapse"  = ".\artifacts\environment-setup\sql"
        "2 JSON Extractor"    = ".\artifacts\environment-setup\sql"
}

$params = @{
        STORAGE_ACCOUNT_NAME = $dataLakeAccountName
        SAS_KEY = $destinationSasKey
}

foreach ($sqlScriptName in $sqlScripts.Keys) {
        
        $sqlScriptFileName = "$($sqlScripts[$sqlScriptName])\$($sqlScriptName).sql"
        Write-Information "Creating SQL script $($sqlScriptName) from $($sqlScriptFileName)"
        
        $result = Create-SQLScript -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $sqlScriptName -ScriptFileName $sqlScriptFileName -Parameters $params
        $result = Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
        $result
}

#>