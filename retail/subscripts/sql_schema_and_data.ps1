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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$location = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$sqlPoolName = "RetailDW"
$sqlUser = "labsqladmin"
$synapseWorkspaceName = "synapseretail$init$random"
$suffix = "$random-$init"
$concatString = "$init$random"
$keyVaultName = "kv-$suffix";

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
Write-Host "Setting Key Vault Access Policy"
#Import-Module Az.KeyVault
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,get,list
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

Write-Host "----Sql Schema------"
RefreshTokens
#creating sql schema
Write-Host "Create tables in $($sqlPoolName)"
$SQLScriptsPath="../artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/storedprocedures.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
(Get-Content -path "$($SQLScriptsPath)/sqluser.sql" -Raw) | Foreach-Object { $_ `
                -replace '#SQL_PASSWORD#', $sqlPassword`		
        } | Set-Content -Path "$($SQLScriptsPath)/sqluser.sql"		
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sql_user_retail.sql"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery  = "CREATE DATABASE RetailSqlOnDemand"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result	


Write-Host  "-------------Uploading Sql Data ---------------"
RefreshTokens
#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgCompanyVsTopicProbability"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgCompanyVsTopicProbability"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGOrgConnections"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGOrgConnections"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgContribution"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgContribution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgDetractors"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgDetractors"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgWordCloudData"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgWordCloudData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGScores"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGScores"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgSentimentAndCustomerChurn"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgSentimentAndCustomerChurn"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgSentimentVsMarketPerformance"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgSentimentVsMarketPerformance"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGWeightedScore"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGWeightedScore"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"AggregatedSales_SAPHANA"}} , @{Name = "TABLE_NAME"; Expression = {"AggregatedSales_SAPHANA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics_New"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalyticLatest"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalyticLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaigns"}} , @{Name = "TABLE_NAME"; Expression = {"Campaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ConflictofInterest"}} , @{Name = "TABLE_NAME"; Expression = {"ConflictofInterest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Country"}} , @{Name = "TABLE_NAME"; Expression = {"Country"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerInfo"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerSalesHana"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerSalesHana"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerVisitF"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerVisitF"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"customerVisitsInPersonByLocation"}} , @{Name = "TABLE_NAME"; Expression = {"customerVisitsInPersonByLocation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DailyStockData"}} , @{Name = "TABLE_NAME"; Expression = {"DailyStockData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Dim_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Dim_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DimData"}} , @{Name = "TABLE_NAME"; Expression = {"DimData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"EmailAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"EmailAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Engagement_ActualVsForecast"}} , @{Name = "TABLE_NAME"; Expression = {"Engagement_ActualVsForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ESGOrganisation"}} , @{Name = "TABLE_NAME"; Expression = {"ESGOrganisation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinalRevenue"}} , @{Name = "TABLE_NAME"; Expression = {"FinalRevenue"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinanceSales"}} , @{Name = "TABLE_NAME"; Expression = {"FinanceSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FPA"}} , @{Name = "TABLE_NAME"; Expression = {"FPA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HeaderWIP"}} , @{Name = "TABLE_NAME"; Expression = {"HeaderWIP"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Location_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Location_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Address"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Address"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_CustomerGender"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_CustomerGender"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Order"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Order"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_OrderLineStatus_New"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_OrderLineStatus_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Product_New"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Product_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"MillennialCustomers"}} , @{Name = "TABLE_NAME"; Expression = {"MillennialCustomers"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"NewsAndSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"NewsAndSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OperatingExpenses"}} , @{Name = "TABLE_NAME"; Expression = {"OperatingExpenses"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBalanceSheet"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBalanceSheet"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBankCustomerRanking"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBankCustomerRanking"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBedOccupancyForecasted"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBedOccupancyForecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiCustomer"}} , @{Name = "TABLE_NAME"; Expression = {"pbiCustomer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiESG"}} , @{Name = "TABLE_NAME"; Expression = {"pbiESG"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgArticleSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgArticleSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgBigram"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgBigram"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgDetractor"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgDetractor"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgInitiativesComparison"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgInitiativesComparison"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgInstitutionUnitPolicyScore"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgInstitutionUnitPolicyScore"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgPolicy"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgPolicy"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitution"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitutionUnit"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitutionUnit"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiKPI"}} , @{Name = "TABLE_NAME"; Expression = {"pbiKPI"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiRegion"}} , @{Name = "TABLE_NAME"; Expression = {"pbiRegion"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiWaitTimeForecast"}} , @{Name = "TABLE_NAME"; Expression = {"PbiWaitTimeForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pred_anomaly"}} , @{Name = "TABLE_NAME"; Expression = {"pred_anomaly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductLink2"}} , @{Name = "TABLE_NAME"; Expression = {"ProductLink2"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductRecommendations"}} , @{Name = "TABLE_NAME"; Expression = {"ProductRecommendations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Products"}} , @{Name = "TABLE_NAME"; Expression = {"Products"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RevenueVsMarketingCost"}} , @{Name = "TABLE_NAME"; Expression = {"RevenueVsMarketingCost"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Role"}} , @{Name = "TABLE_NAME"; Expression = {"Role"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMaster"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMaster"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMasters"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMasters"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMasterUpdated"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMasterUpdated"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SiteSecurity"}} , @{Name = "TABLE_NAME"; Expression = {"SiteSecurity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SortedCampaigns"}} , @{Name = "TABLE_NAME"; Expression = {"SortedCampaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Travel_Entertainment"}} , @{Name = "TABLE_NAME"; Expression = {"Travel_Entertainment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterRawData"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterRawData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VTBByChannel"}} , @{Name = "TABLE_NAME"; Expression = {"VTBByChannel"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"vwPbiESGSlicerOrganizations"}} , @{Name = "TABLE_NAME"; Expression = {"vwPbiESGSlicerOrganizations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WWIBrands"}} , @{Name = "TABLE_NAME"; Expression = {"WWIBrands"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WWIProducts"}} , @{Name = "TABLE_NAME"; Expression = {"WWIProducts"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiReadmissionPrediction"}} , @{Name = "TABLE_NAME"; Expression = {"PbiReadmissionPrediction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductLink"}} , @{Name = "TABLE_NAME"; Expression = {"ProductLink"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBankGlobalRanking"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBankGlobalRanking"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CohortAnalysis"}} , @{Name = "TABLE_NAME"; Expression = {"CohortAnalysis"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Wait_Time_Forecasted"}} , @{Name = "TABLE_NAME"; Expression = {"Wait_Time_Forecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesVsExpense"}} , @{Name = "TABLE_NAME"; Expression = {"SalesVsExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Automotive"}} , @{Name = "TABLE_NAME"; Expression = {"Automotive"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Sales"}} , @{Name = "TABLE_NAME"; Expression = {"Sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)

$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
foreach ($dataTableLoad in $dataTableList) {
    Write-output "Loading data for $($dataTableLoad.TABLE_NAME)"
    $sqlQuery = Get-Content -Raw -Path "../artifacts/templates/load_csv.sql"
    $sqlQuery = $sqlQuery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
    $Parameters =@{
            CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
            TABLE_NAME = $dataTableLoad.TABLE_NAME
            DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
     }
    foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
    Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
}
