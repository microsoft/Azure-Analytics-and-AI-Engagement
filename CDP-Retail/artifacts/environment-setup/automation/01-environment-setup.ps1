$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser

#
# TODO: Keep all required configuration in C:\LabFiles\AzureCreds.ps1 file
# This is for Spektra Environment.
$IsCloudLabs = Test-Path C:\LabFiles\AzureCreds.ps1;

$title = "Data Size"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "30 &Billion", "Loads 30 billion records into the Sales table. Scales SQL Pool to DW3000c during data loading. Approxiamate loading time is 4 hours."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "3 &Million", "Loads 3 million records into the Sales table."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $host.ui.PromptForChoice($title, "Choose how much data you want to load.", $options, 1)

switch($result)
{
0 { $Load30Billion = 1 }
1 { $Load30Billion = 0 }
}

if($IsCloudLabs){
        Remove-Module solliance-synapse-automation
        Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

        . C:\LabFiles\AzureCreds.ps1

        $userName = $AzureUserName                # READ FROM FILE
        $password = $AzurePassword                # READ FROM FILE
        $clientId = $TokenGeneratorClientId       # READ FROM FILE
        $global:sqlPassword = $AzureSQLPassword          # READ FROM FILE

        $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
        
        Connect-AzAccount -Credential $cred | Out-Null

        $ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
        $global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
        $global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
        $global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"
        $global:ropcBodyPowerBI = "$($ropcBodyCore)&scope=https://analysis.windows.net/powerbi/api/.default"

        $templatesPath = ".\artifacts\environment-setup\templates"
        $datasetsPath = ".\artifacts\environment-setup\datasets"
        $dataflowsPath = ".\artifacts\environment-setup\dataflows"
        $pipelinesPath = ".\artifacts\environment-setup\pipelines"
        $sqlScriptsPath = ".\artifacts\environment-setup\sql"
} else {
        if(Get-Module -Name solliance-synapse-automation){
                Remove-Module solliance-synapse-automation
        }
        Import-Module "..\solliance-synapse-automation"

        #Different approach to run automation in Cloud Shell
        $subs = Get-AzSubscription | Select-Object -ExpandProperty Name
        if($subs.GetType().IsArray -and $subs.length -gt 1){
                $subOptions = [System.Collections.ArrayList]::new()
                for($subIdx=0; $subIdx -lt $subs.length; $subIdx++){
                        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
                        $subOptions.Add($opt)
                }
                $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
                $selectedSubName = $subs[$selectedSubIdx]
                Write-Information "Selecting the $selectedSubName subscription"
                Select-AzSubscription -SubscriptionName $selectedSubName
        }
        
        $userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
        $global:sqlPassword = Read-Host -Prompt "Enter the SQL Administrator password you used in the deployment" -AsSecureString
        $global:sqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($sqlPassword))

        $reportsPath = "..\reports"
        $templatesPath = "..\templates"
        $datasetsPath = "..\datasets"
        $dataflowsPath = "..\dataflows"
        $pipelinesPath = "..\pipelines"
        $sqlScriptsPath = "..\sql"
        $functionsSourcePath = "..\functions"
}

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*WWI-Lab*" }).ResourceGroupName
$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$global:logindomain = (Get-AzContext).Tenant.Id

$workspaceName = "asaexpworkspace$($uniqueId)"
$dataLakeAccountName = "asaexpdatalake$($uniqueId)"
$keyVaultName = "asaexpkeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASAEXP"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$sparkPoolName = "SparkPool01"
$amlWorkspaceName = "amlworkspace$($uniqueId)"
$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asaexp.sql.admin"
$twitterFunction="twifunction$($uniqueId)"
$locationFunction="locfunction$($uniqueId)"
$asaName="TweetsASA"
Install-Module -Name MicrosoftPowerBIMgmt
Login-PowerBI

Write-Information "Deploying Azure functions"
az functionapp deployment source config-zip `
        --resource-group $resourceGroupName `
        --name $twitterFunction `
        --src "../functions/powershell-functions/Twitter_Function_Publish_Package.zip"
		
az functionapp deployment source config-zip `
        --resource-group $resourceGroupName `
        --name $locationFunction `
        --src "../functions/powershell-functions/LocationAnalytics_Publish_Package.zip"
$principal=az resource show -g $resourceGroupName -n $asaName --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
$wsId=Read-Host "Enter your powerBi workspace Id entered during template deployment"
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Contributor
#$valid = Test-SQLConnection -InstanceName $global:sqlEndpoint

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""
$global:powerbiToken = "";

$global:tokenTimes = [ordered]@{
        Synapse    = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
        PowerBI = (Get-Date -Year 1)
}

Write-Information "Assign Ownership to Proctors on Synapse Workspace"
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "6e4bf58a-b8e1-4cc3-bbf9-d73143322b78" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Workspace Admin
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "7af0c69a-a548-47d6-aea3-d00e69bd83aa" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # SQL Admin
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "c3a6d2f1-a26f-4810-9b0f-591308d5cbf1" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Apache Spark Admin

#add the permission to the datalake to workspace
$id = (Get-AzADServicePrincipal -DisplayName $workspacename).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.MachineLearningServices/workspaces/$amlWorkspaceName" -ErrorAction SilentlyContinue;

Write-Information "Setting Key Vault Access Policy"
Set-AzKeyVaultAccessPolicy -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,delete,get,list

$ws = Get-Workspace $SubscriptionId $ResourceGroupName $WorkspaceName;
$upid = $ws.identity.principalid
Set-AzKeyVaultAccessPolicy -ResourceGroupName $resourceGroupName -VaultName $keyVaultName -ObjectId $upid -PermissionsToSecrets set,delete,get,list

Write-Information "Create SQL-USER-ASA Key Vault Secret"
$secretValue = ConvertTo-SecureString $sqlPassword -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $keyVaultSQLUserSecretName -SecretValue $secretValue

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

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asaexp.sql.admin"

$linkedServiceName = $sqlPoolName.ToLower()
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asaexp.sql.admin" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Copy TwitterData to Data Lake"

$publicDataUrl = "https://solliancepublicdata.blob.core.windows.net/"
$dataLakeStorageUrl = "https://"+ $dataLakeAccountName + ".dfs.core.windows.net/"
$dataLakeStorageBlobUrl = "https://"+ $dataLakeAccountName + ".blob.core.windows.net/"

Ensure-ValidTokens

$dataLakeStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $dataLakeStorageAccountKey

$storageContainers = @{
        twitterData = "twitterdata"
        financeDb = "financedb"
        salesData = "salesdata"
        customerInsights = "customer-insights"
        sapHana = "saphana"
        campaignData = "campaigndata"
        iotContainer = "iotcontainer"
        recommendations = "recommendations"
        customCsv = "customcsv"
        machineLearning = "machine-learning"
}

foreach ($storageContainer in $storageContainers.Keys) {        
        Write-Information "Creating container: $($storageContainers[$storageContainer])"
        if(Get-AzStorageContainer -Name $storageContainers[$storageContainer] -Context $dataLakeContext -ErrorAction SilentlyContinue)  {  
                Write-Information "$($storageContainers[$storageContainer]) container already exists."  
        }else{  
                Write-Information "$($storageContainers[$storageContainer]) container created."   
                New-AzStorageContainer -Name $storageContainers[$storageContainer] -Permission Container -Context $dataLakeContext  
        }
}          

$StartTime = Get-Date
$EndTime = $startTime.AddDays(365)  
$destinationSasKey = New-AzStorageContainerSASToken -Container "twitterdata" -Context $dataLakeContext -Permission rwdl -ExpiryTime $EndTime

$azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

if (!$azCopyLink)
{
    $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
}

Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
$azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName
$Env:Path += ";"+ $azCopyCommand

$AnonContext = New-AzStorageContext -StorageAccountName "solliancepublicdata" -Anonymous
$singleFiles = Get-AzStorageBlob -Container "cdp" -Blob twitter* -Context $AnonContext | Where-Object Length -GT 0 | select-object @{Name = "SourcePath"; Expression = {"cdp/"+$_.Name}} , @{Name = "TargetPath"; Expression = {$_.Name}}

foreach ($singleFile in $singleFiles) {
        Write-Information $singleFile
        $source = $publicDataUrl + $singleFile.SourcePath
        $destination = $dataLakeStorageBlobUrl + $singleFile.TargetPath + $destinationSasKey
        Write-Information "Copying file $($source) to $($destination)"
        azcopy copy $source $destination 
}

$destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl -ExpiryTime $EndTime
$singleFiles = Get-AzStorageBlob -Container "cdp" -Blob customcsv* -Context $AnonContext | Where-Object Length -GT 0 | select-object @{Name = "SourcePath"; Expression = {"cdp/"+$_.Name}} , @{Name = "TargetPath"; Expression = {$_.Name}}

foreach ($singleFile in $singleFiles) {
        Write-Information $singleFile
        $source = $publicDataUrl + $singleFile.SourcePath
        $destination = $dataLakeStorageBlobUrl + $singleFile.TargetPath + $destinationSasKey
        Write-Information "Copying file $($source) to $($destination)"
        azcopy copy $source $destination 
}


$destinationSasKey = New-AzStorageContainerSASToken -Container "machine-learning" -Context $dataLakeContext -Permission rwdl -ExpiryTime $EndTime
$singleFiles = Get-AzStorageBlob -Container "cdp" -Blob machine* -Context $AnonContext | Where-Object Length -GT 0 | select-object @{Name = "SourcePath"; Expression = {"cdp/"+$_.Name}} , @{Name = "TargetPath"; Expression = {$_.Name}}

foreach ($singleFile in $singleFiles) {
        Write-Information $singleFile
        $source = $publicDataUrl + $singleFile.SourcePath
        $destination = $dataLakeStorageBlobUrl + $singleFile.TargetPath + $destinationSasKey
        Write-Information "Copying file $($source) to $($destination)"
        azcopy copy $source $destination 
}

if(!$IsCloudLabs)
{
    Install-Module -Name SqlServer
}

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($result.properties.status -ne "Online") {
        Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
        Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

Write-Information "Create tables in $($sqlPoolName)"

$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "01-create-tables" -Parameters $params 
$result

Write-Information "Loading data"

$dataTableList = New-Object System.Collections.ArrayList
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Dim_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Dim_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"MillennialCustomers"}} , @{Name = "TABLE_NAME"; Expression = {"MillennialCustomers"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"sale"}} , @{Name = "TABLE_NAME"; Expression = {"Sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Products"}} , @{Name = "TABLE_NAME"; Expression = {"Products"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"10millionrows"}} , @{Name = "TABLE_NAME"; Expression = {"IDS"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterRawData"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterRawData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"department_visit_customer"}} , @{Name = "TABLE_NAME"; Expression = {"department_visit_customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Category"}} , @{Name = "TABLE_NAME"; Expression = {"Category"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProdChamp"}} , @{Name = "TABLE_NAME"; Expression = {"ProdChamp"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaigns"}} , @{Name = "TABLE_NAME"; Expression = {"Campaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignNew4"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignNew4"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerVisitF"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerVisitF"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinanceSales"}} , @{Name = "TABLE_NAME"; Expression = {"FinanceSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"LocationAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"LocationAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductLink2"}} , @{Name = "TABLE_NAME"; Expression = {"ProductLink2"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductRecommendations"}} , @{Name = "TABLE_NAME"; Expression = {"ProductRecommendations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"BrandAwareness"}} , @{Name = "TABLE_NAME"; Expression = {"BrandAwareness"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductLink"}} , @{Name = "TABLE_NAME"; Expression = {"ProductLink"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMaster"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMaster"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesVsExpense"}} , @{Name = "TABLE_NAME"; Expression = {"SalesVsExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FPA"}} , @{Name = "TABLE_NAME"; Expression = {"FPA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Country"}} , @{Name = "TABLE_NAME"; Expression = {"Country"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Books"}} , @{Name = "TABLE_NAME"; Expression = {"Books"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"BookConsumption"}} , @{Name = "TABLE_NAME"; Expression = {"BookConsumption"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"EmailAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"EmailAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DimDate"}} , @{Name = "TABLE_NAME"; Expression = {"DimDate"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Popularity"}} , @{Name = "TABLE_NAME"; Expression = {"Popularity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinalRevenue"}} , @{Name = "TABLE_NAME"; Expression = {"FinalRevenue"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ConflictofInterest"}} , @{Name = "TABLE_NAME"; Expression = {"ConflictofInterest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SiteSecurity"}} , @{Name = "TABLE_NAME"; Expression = {"SiteSecurity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"BookList"}} , @{Name = "TABLE_NAME"; Expression = {"BookList"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalyticLatest"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalyticLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"location_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"location_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DimData"}} , @{Name = "TABLE_NAME"; Expression = {"DimData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"salesPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"salesPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Customer_SalesLatest"}} , @{Name = "TABLE_NAME"; Expression = {"Customer_SalesLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"department_visit_customer"}} , @{Name = "TABLE_NAME"; Expression = {"department_visit_customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

foreach ($dataTableLoad in $dataTableList) {
        Write-Information "Loading data for $($dataTableLoad.TABLE_NAME)"
        $result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "02-load-csv" -Parameters @{
                CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
                TABLE_NAME = $dataTableLoad.TABLE_NAME
                DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
         }
        $result
        Write-Information "Data for $($dataTableLoad.TABLE_NAME) loaded."
}

if($Load30Billion -eq 1)
{
        Write-Information "Loading 30 Billion Records"

        Write-Information "Scale up the $($sqlPoolName) SQL pool to DW3000c to prepare for 30 Billion Rows."
        
        Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW3000c
        Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
        
        $start = Get-Date
        [nullable[double]]$secondsRemaining = $null
        $maxIterationCount = 3000
        
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
                $result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -UseAPI (!$IsCloudLabs) -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "03-Billion_Records" -Parameters $params 
                $result
        
                $secondsElapsed = (Get-Date) - $start
                $secondsRemaining = ($secondsElapsed.TotalSeconds / ($count +1)) * ($maxIterationCount - $count)
        }

        Write-Information "Scale down the $($sqlPoolName) SQL pool to DW500c after 30 Billion Rows."

        Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW500c
        Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

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
        CampaignAnalyticLatest = "NA"
        CampaignNew4 = "NA"
        Campaigns = "NA"
        location_Analytics = "NA"
        WebsiteSocialAnalyticsPBIData = "NA"
        CustomerVisitF = "NA"
        FinanceSales = "NA"
        EmailAnalytics = "NA"
        ProductLink2 = "NA"
        ProductRecommendations = "NA"
        SalesMaster = "NA"
        CustomerVisitF_Spark = "NA"
        Customer_SalesLatest = "NA"
        Product_Recommendations_Spark_v2 = "NA"
        department_visit_customer = "NA"
        CustomCampaignAnalyticLatestDataset = $dataLakeAccountName 
        CustomCampaignCollection = $dataLakeAccountName 
        CustomCampaignSchedules = $dataLakeAccountName 
        CustomWebsiteSocialAnalyticsPBIData = $dataLakeAccountName 
        CustomLocationAnalytics = $dataLakeAccountName 
        CustomCustomerVisitF = $dataLakeAccountName 
        CustomFinanceSales = $dataLakeAccountName 
        CustomEmailAnalytics = $dataLakeAccountName 
        CustomProductLink2 = $dataLakeAccountName 
        CustomProductRecommendations = $dataLakeAccountName 
        CustomSalesMaster = $dataLakeAccountName 
        Department_Visits_DL = $dataLakeAccountName 
        Department_Visits_Predictions_DL = $dataLakeAccountName  
        Product_Recommendations_ML = $dataLakeAccountName  
        Customer_Sales_Latest_ML = $dataLakeAccountName  
        CustomCustomer_SalesLatest = $dataLakeAccountName  
        Customdepartment_visit_customer = $dataLakeAccountName  
}
$dataLakeAccountName 

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

Write-Information "Creating Spark notebooks..."

if($IsCloudLabs){
        $notebooks = [ordered]@{
                "3 Campaign Analytics Data Prep"    = ".\artifacts\environment-setup\notebooks"
                "1 Products Recommendation"   = ".\artifacts\environment-setup\notebooks"
                "2 AutoML Number of Customer Visit to Department" = ".\artifacts\environment-setup\notebooks"
        }
} else {
        $notebooks = [ordered]@{
                "3 Campaign Analytics Data Prep"    = "..\notebooks"
                "1 Products Recommendation"   = "..\notebooks"
                "2 AutoML Number of Customer Visit to Department" = "..\notebooks"
        }
}

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $resourceGroupName
        "#AML_WORKSPACE_NAME#"  = $amlWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
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

if($IsCloudLabs){
        $sqlScripts = [ordered]@{
                "8 External Data To Synapse Via Copy Into" = ".\artifacts\environment-setup\sql"
                "1 SQL Query With Synapse"  = ".\artifacts\environment-setup\sql"
                "2 JSON Extractor"    = ".\artifacts\environment-setup\sql"
        }
} else {
        $sqlScripts = [ordered]@{
                "8 External Data To Synapse Via Copy Into" = "..\sql"
                "1 SQL Query With Synapse"  = "..\sql"
                "2 JSON Extractor"    = "..\sql"
        }
}

if($Load30Billion -eq 1) {
        $salesRowNumberCount = "30,023,443,487"
} else {
        $salesRowNumberCount = "3,443,487"
}
$params = @{
        STORAGE_ACCOUNT_NAME = $dataLakeAccountName
        SAS_KEY = $destinationSasKey
        ROW_NUMBER_COUNT = $salesRowNumberCount
}

foreach ($sqlScriptName in $sqlScripts.Keys) {
        
        $sqlScriptFileName = "$($sqlScripts[$sqlScriptName])\$($sqlScriptName).sql"
        Write-Information "Creating SQL script $($sqlScriptName) from $($sqlScriptFileName)"
        
        $result = Create-SQLScript -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $sqlScriptName -ScriptFileName $sqlScriptFileName -Parameters $params
        $result = Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
        $result
}

Write-Information "Starting PowerBI Artifact Provisioning"

$wsname = "asa-exp-$uniqueId";

$wsid = Get-PowerBIWorkspaceId $wsname;

if (!$wsid)
{
    $wsid = New-PowerBIWS $wsname;
}

Write-Information "Uploading PowerBI Reports"

$reportList = New-Object System.Collections.ArrayList
$temp = "" | select-object @{Name = "FileName"; Expression = {"1. CDP Vision Demo"}}, 
                                @{Name = "Name"; Expression = {"1-CDP Vision Demo"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}}, 
                                @{Name = "SourceServer"; Expression = {"cdpvisionworkspace.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"AzureSynapseDW"}}
$reportList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"2. Billion Rows Demo"}}, 
                                @{Name = "Name"; Expression = {"2-Billion Rows Demo"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}}, 
                                @{Name = "SourceServer"; Expression = {"cdpvisionworkspace.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"AzureSynapseDW"}}
$reportList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"29_June_Number-Customers-Forecast.pbix"}}, 
                                @{Name = "Name"; Expression = {"Engagement Accelerator Demo Reports"}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}},
                                @{Name = "SourceServer"; Expression = {"asaexpworkspacewwi543.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"SQLPool01"}}
$reportList.Add($temp)

$powerBIDataSetConnectionTemplate = Get-Content -Path "$templatesPath/powerbi_dataset_connection.json"
$powerBIName = "asaexppowerbi$($uniqueId)"
$workspaceName = "asaexpworkspace$($uniqueId)"

foreach ($powerBIReport in $reportList) {

    Write-Information "Uploading $($powerBIReport.Name) Report"

    $i = Get-Item -Path "$reportsPath/$($powerBIReport.FileName).pbix"
    $reportId = Upload-PowerBIReport $wsId $powerBIReport.Name $i.fullname
    #Giving some time to the PowerBI Servic to process the upload.
    Start-Sleep -s 5
    $powerBIReport.PowerBIDataSetId = Get-PowerBIDatasetId $wsid $powerBIReport.Name
}

Write-Information "Create PowerBI linked service $($keyVaultName)"

$result = Create-PowerBILinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $powerBIName -WorkspaceId $wsid
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Setting Powershell Azure Functions for PowerBI Data Refresh" 

Refresh-Token -TokenType PowerBI
$azureCLITokens = Get-Content -Path \tmp\accessTokens.json | ConvertFrom-Json
$powerBIRefreshToken = $azureCLITokens | where { $_.resource -eq "https://analysis.windows.net/powerbi/api" } | select -ExpandProperty refreshToken
az keyvault secret set -n "PowerBIRefreshToken" --vault-name $keyVaultName --value $powerBIRefreshToken
$secretId = az keyvault secret show -n "PowerBIRefreshToken" --vault-name $keyVaultName --query "id" -o tsv
az functionapp identity assign -n "psfunctions$($uniqueId)" -g $resourceGroupName
$principalId = az functionapp identity show -n "psfunctions$($uniqueId)" -g $resourceGroupName --query principalId -o tsv
az keyvault set-policy -n $keyVaultName -g $resourceGroupName --object-id $principalId --secret-permissions get
az functionapp config appsettings set --name "psfunctions$($uniqueId)" --resource-group $resourceGroupName --settings "powerBIRefreshToken=@Microsoft.KeyVault(SecretUri=$secretId)"
az functionapp config appsettings set --name "psfunctions$($uniqueId)" --resource-group $resourceGroupName --settings "tenantId=$($tenantId)"
az functionapp deployment source config-zip -g $resourceGroupName -n "psfunctions$($uniqueId)" --src "../functions/powershell-functions/powershell-functions.zip"

$powerBIDatasetRefreshFunctionKey = ((az rest --method post `
                     --uri "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Web/sites/psfunctions$($uniqueId)/functions/PowerBIDataSetRefresh/listKeys?api-version=2018-11-01") | ConvertFrom-Json).default
$powerBIDatasetRefreshFunctionUri = "https://psfunctions$($uniqueId).azurewebsites.net/api/PowerBIDataSetRefresh?code=$($powerBIDatasetRefreshFunctionKey)"

Write-Information "Create pipelines"

$pipelineList = New-Object System.Collections.ArrayList
$temp = "" | select-object @{Name = "FileName"; Expression = {"sap_hana_to_adls"}} , @{Name = "Name"; Expression = {"SAP HANA TO ADLS"}}, @{Name = "PowerBIReportName"; Expression = {""}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"marketing_db_migration"}} , @{Name = "Name"; Expression = {"MarketingDBMigration"}}, @{Name = "PowerBIReportName"; Expression = {""}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"sales_db_migration"}} , @{Name = "Name"; Expression = {"SalesDBMigration"}}, @{Name = "PowerBIReportName"; Expression = {""}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"twitter_data_migration"}} , @{Name = "Name"; Expression = {"TwitterDataMigration"}}, @{Name = "PowerBIReportName"; Expression = {""}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_campaign_analytics"}} , @{Name = "Name"; Expression = {"Customize Campaign Analytics"}}, @{Name = "PowerBIReportName"; Expression = {"(Phase 2) CDP Vision Demo v1"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_decomposition_tree"}} , @{Name = "Name"; Expression = {"Customize Decomposition Tree"}}, @{Name = "PowerBIReportName"; Expression = {"(Phase 2) CDP Vision Demo v1"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_location_analytics"}} , @{Name = "Name"; Expression = {"Customize Location Analytics"}}, @{Name = "PowerBIReportName"; Expression = {"(Phase 2) CDP Vision Demo v1"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_revenue_profitability"}} , @{Name = "Name"; Expression = {"Customize Revenue Profitability"}}, @{Name = "PowerBIReportName"; Expression = {"(Phase 2) CDP Vision Demo v1"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"ML_Department_Visits_Predictions"}} , @{Name = "Name"; Expression = {"ML Department Visits Predictions"}}, @{Name = "PowerBIReportName"; Expression = {""}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"ML_Product_Recommendation"}} , @{Name = "Name"; Expression = {"ML Product Recommendation"}}, @{Name = "PowerBIReportName"; Expression = {""}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_recommendation_insights_ml"}} , @{Name = "Name"; Expression = {"Customize Recommendation Insights ML"}}, @{Name = "PowerBIReportName"; Expression = {""}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_email_analytics"}} , @{Name = "Name"; Expression = {"Customize EMail Analytics"}}, @{Name = "PowerBIReportName"; Expression = {""}}
$pipelineList.Add($temp)

foreach ($pipeline in $pipelineList) {
        Write-Information "Creating workload pipeline $($pipeline.Name)"
        $result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $pipeline.Name -FileName $pipeline.FileName -Parameters @{
                DATA_LAKE_STORAGE_NAME = $dataLakeAccountName
                DEFAULT_STORAGE = $workspaceName + "-WorkspaceDefaultStorage"
                PSFUNCTION_ENDPOINT = "$($powerBIDatasetRefreshFunctionUri)&DataSetId=$($reportList | where Name -eq $pipeline.PowerBIReportName | select -ExpandProperty PowerBIDataSetId)"
         }
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

Write-Information "Setting PowerBI Report Data Connections" 

<# WARNING : Make sure Connection Changes are executed after report uploads are completed. 
             Based on testing so far, findings indicate that there has to be an unknown amount 
             of time between the two operations. Having those operations sequentially run in a 
             single loop resulted in inconsistent results. Pushing the two activities far away 
             from each other in separate loops helped. #>

$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "asaexpworkspace$($uniqueId).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", "SQLPool01") |Out-String

foreach ($powerBIReport in $reportList) {
    Write-Information "Setting database connection for $($powerBIReport.Name)"
    $powerBIReportDataSetConnectionUpdateRequest = $powerBIDataSetConnectionUpdateRequest.Replace("#SOURCE_SERVER#", $powerBIReport.SourceServer).Replace("#SOURCE_DATABASE#", $powerBIReport.SourceDatabase) |Out-String
    Update-PowerBIDatasetConnection $wsId $powerBIReport.PowerBIDataSetId $powerBIReportDataSetConnectionUpdateRequest;
}

Write-Information "Environment setup complete." 

