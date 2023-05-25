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
    $Region = (Get-AzResourceGroup -Name $rgName).Location
    $init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
    $random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
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
    $sites_open_ai_name = "app-open-ai-$suffix"
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
    $usercred = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName

    $id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
    New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
    New-AzRoleAssignment -SignInName $usercred -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

    Write-Host "Setting Key Vault Access Policy"
    #Import-Module Az.KeyVault
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $usercred -PermissionsToSecrets set,get,list
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

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
    
    #mssql data upload
    Add-Content log.txt "-----Ms Sql-----"
    Write-Host "----Ms Sql----"
    $SQLScriptsPath = "../artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/SalesDataAfterCampaign.sql"
    $sqlEndpoint = "$($mssql_server_name).database.windows.net"
    $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlDatabaseName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    # SQL schema section
    Add-Content log.txt "------sql schema-----"
    Write-Host "----Sql Schema------"
    RefreshTokens
    #creating sql schema
    Write-Host "Create tables in $($sqlPoolName)"
    $SQLScriptsPath = "../artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    Write-Host "Create storedProcedure in $($sqlPoolName)"
    $SQLScriptsPath = "../artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/storedProcedure.sql"
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    Write-Host "Create view in $($sqlPoolName)"
    $SQLScriptsPath = "../artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/viewDedicatedPool.sql"
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    Write-Host "Create configurable table in $($sqlPoolName)"
    $SQLScriptsPath = "../artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/configurableTableQuery.sql"
    $openAIAppEndpoint = "https://" + $sites_open_ai_name + ".azurewebsites.net/"
    $query = $sqlQuery.Replace("#OPEN_AI_APP_ENDPOINT#", $openAIAppEndpoint).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $query -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
    (Get-Content -path "$($SQLScriptsPath)/sqluser.sql" -Raw) | Foreach-Object { $_ `
                    -replace '#SQL_PASSWORD#', $sqlPassword`
            } | Set-Content -Path "$($SQLScriptsPath)/sqluser.sql"		
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
    $sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sql_user_hc2.sql"
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    ## Running a sql script in Sql serverless Pool
    $name = "SchemaForExternalTable"
    $ScriptFileName = "../artifacts/sqlscripts/" + $name + ".sql"

    $sqlQuery = "Create DATABASE SQLServerlessPool"
    $sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
    try {
        $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
    }
    catch {
        $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
    }
    Add-Content log.txt $result	
 
    $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
    $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmos_healthcare2_name)
    $query = $query.Replace("#REGION#", $Region)
    $query = $query.Replace("#COSMOSDB_ACCOUNT_KEY#", $cosmos_account_key)
    $query = $query.Replace("#SAS_TOKEN#", $sasTokenAcc)
    $sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $query -ServerInstance $sqlEndpoint -Database SQLServerlessPool -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result	

    Add-Content log.txt "------uploading sql data------"
    Write-Host  "-------------Uploading Sql Data ---------------"
    RefreshTokens
    #uploading sql data
    $dataTableList = New-Object System.Collections.ArrayList

    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Campaign_Analytics" } } , @{Name = "TABLE_NAME"; Expression = { "Campaign_Analytics" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Campaign_Analytics_New" } } , @{Name = "TABLE_NAME"; Expression = { "Campaign_Analytics_New" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "City and Race Data" } } , @{Name = "TABLE_NAME"; Expression = { "City and Race Data" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Claim" } } , @{Name = "TABLE_NAME"; Expression = { "Claim" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Diagnostic Report" } } , @{Name = "TABLE_NAME"; Expression = { "Diagnostic Report" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Document Reference" } } , @{Name = "TABLE_NAME"; Expression = { "Document Reference" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "dump" } } , @{Name = "TABLE_NAME"; Expression = { "dump" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "encounter" } } , @{Name = "TABLE_NAME"; Expression = { "encounter" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Fact_Airquality" } } , @{Name = "TABLE_NAME"; Expression = { "Fact_Airquality" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "HealthCare-FactSales" } } , @{Name = "TABLE_NAME"; Expression = { "HealthCare-FactSales" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "healthcare-pcr-json" } } , @{Name = "TABLE_NAME"; Expression = { "healthcare-pcr-json" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "healthcare-tablevalued" } } , @{Name = "TABLE_NAME"; Expression = { "healthcare-tablevalued" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Healthcare-Twitter-Data" } } , @{Name = "TABLE_NAME"; Expression = { "Healthcare-Twitter-Data" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "HospitalEmpPIIData" } } , @{Name = "TABLE_NAME"; Expression = { "HospitalEmpPIIData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "ImmunizationData" } } , @{Name = "TABLE_NAME"; Expression = { "ImmunizationData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Media" } } , @{Name = "TABLE_NAME"; Expression = { "Media" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "medication request" } } , @{Name = "TABLE_NAME"; Expression = { "medication request" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Miamihospitaloverview_Bed Occupancy" } } , @{Name = "TABLE_NAME"; Expression = { "Miamihospitaloverview_Bed Occupancy" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Mkt_CampaignAnalyticLatest" } } , @{Name = "TABLE_NAME"; Expression = { "Mkt_CampaignAnalyticLatest" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Mkt_WebsiteSocialAnalyticsPBIData" } } , @{Name = "TABLE_NAME"; Expression = { "Mkt_WebsiteSocialAnalyticsPBIData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "new race" } } , @{Name = "TABLE_NAME"; Expression = { "new race" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "observation" } } , @{Name = "TABLE_NAME"; Expression = { "observation" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "patient" } } , @{Name = "TABLE_NAME"; Expression = { "patient" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PatientInformation" } } , @{Name = "TABLE_NAME"; Expression = { "PatientInformation" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiBedOccupancyForecasted" } } , @{Name = "TABLE_NAME"; Expression = { "pbiBedOccupancyForecasted" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiDepartment" } } , @{Name = "TABLE_NAME"; Expression = { "pbiDepartment" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiManagementEmployee" } } , @{Name = "TABLE_NAME"; Expression = { "pbiManagementEmployee" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiPatient" } } , @{Name = "TABLE_NAME"; Expression = { "pbiPatient" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiPatientSurvey" } } , @{Name = "TABLE_NAME"; Expression = { "pbiPatientSurvey" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PbiReadmissionPrediction" } } , @{Name = "TABLE_NAME"; Expression = { "PbiReadmissionPrediction" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PbiWaitTimeForecast" } } , @{Name = "TABLE_NAME"; Expression = { "PbiWaitTimeForecast" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pred_anomaly" } } , @{Name = "TABLE_NAME"; Expression = { "pred_anomaly" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "race mapping" } } , @{Name = "TABLE_NAME"; Expression = { "race mapping" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "RoleNew" } } , @{Name = "TABLE_NAME"; Expression = { "RoleNew" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkCosmosDBKPIs" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkCosmosDBKPIs" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkCosmosDBLast3HoursQuality" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkCosmosDBLast3HoursQuality" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkCosmosDBLast7HoursQualityVerified" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkCosmosDBLast7HoursQualityVerified" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkCosmosDBWorkload" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkCosmosDBWorkload" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkLabData" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkLabData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynPatient" } } , @{Name = "TABLE_NAME"; Expression = { "SynPatient" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Vitals Graph" } } , @{Name = "TABLE_NAME"; Expression = { "Vitals Graph" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Web table" } } , @{Name = "TABLE_NAME"; Expression = { "Web table" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
     
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    foreach ($dataTableLoad in $dataTableList) {
        Write-output "Loading data for $($dataTableLoad.TABLE_NAME)"
        $sqlQuery = Get-Content -Raw -Path "../artifacts/templates/load_csv.sql"
        $sqlQuery = $sqlQuery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
        $Parameters = @{
            CSV_FILE_NAME         = $dataTableLoad.CSV_FILE_NAME
            TABLE_NAME            = $dataTableLoad.TABLE_NAME
            DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
        }
        foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
        Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    }
