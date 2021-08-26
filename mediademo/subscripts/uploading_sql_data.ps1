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
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$synapseWorkspaceName = "synapsemedia$init$random"
$concatString = "$init$random"
$sqlPoolName = "MediaDW"
$keyVaultName = "kv-$suffix";
$sqlUser = "labsqladmin"
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText

if($concatString.length -gt 16)
{
$dataLakeAccountName = "stmedia"+($concatString.substring(0,17))
}
else
{
	$dataLakeAccountName = "stmedia"+ $concatString
}


Add-Content log.txt "------uploading sql data------"
Write-Host  "-----------------Uploading sql data ---------------"
RefreshTokens
#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics_New"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ConflictofInterest"}} , @{Name = "TABLE_NAME"; Expression = {"ConflictofInterest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Country"}} , @{Name = "TABLE_NAME"; Expression = {"Country"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerInfo"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Media-FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"Media-FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"MediaEmpPIIData"}} , @{Name = "TABLE_NAME"; Expression = {"MediaEmpPIIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_CampaignAnalyticLatest"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_CampaignAnalyticLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_CampaignData_exl"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_CampaignData_exl"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_CampaignData"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_CampaignData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_CampaignNew4"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_CampaignNew4"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_Campaignproducts"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_Campaignproducts"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_Campaigns"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_Campaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_CustomerNew"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_CustomerNew"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_Date"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_Date"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_Location"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_Location"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_OperationsCaseData"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_OperationsCaseData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_Orders"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_Orders"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_Product"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_Product"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_ProductNew"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_ProductNew"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_Sales"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_Sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_SalesNew"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_SalesNew"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_vCampaignSales"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_vCampaignSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_WebsiteSocialAnalyticsPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_WebsiteSocialAnalyticsPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OperatingExpenses"}} , @{Name = "TABLE_NAME"; Expression = {"OperatingExpenses"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Sales"}} , @{Name = "TABLE_NAME"; Expression = {"Sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesVsExpense"}} , @{Name = "TABLE_NAME"; Expression = {"SalesVsExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SiteSecurity"}} , @{Name = "TABLE_NAME"; Expression = {"SiteSecurity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"brands"}} , @{Name = "TABLE_NAME"; Expression = {"brands"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"faces"}} , @{Name = "TABLE_NAME"; Expression = {"faces"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"jsona"}} , @{Name = "TABLE_NAME"; Expression = {"jsona"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"keywords"}} , @{Name = "TABLE_NAME"; Expression = {"keywords"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"transcript"}} , @{Name = "TABLE_NAME"; Expression = {"transcript"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp) 

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterRawData"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterRawData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VTBByChannel"}} , @{Name = "TABLE_NAME"; Expression = {"VTBByChannel"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VideoCategoriesDistribution"}} , @{Name = "TABLE_NAME"; Expression = {"VideoCategoriesDistribution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"AudienceAnalyticsGeneralKPIs"}} , @{Name = "TABLE_NAME"; Expression = {"AudienceAnalyticsGeneralKPIs"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Rolling7DaysSession"}} , @{Name = "TABLE_NAME"; Expression = {"Rolling7DaysSession"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Rolling7DaysUniqueSession"}} , @{Name = "TABLE_NAME"; Expression = {"Rolling7DaysUniqueSession"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Rolling7DaysViewership"}} , @{Name = "TABLE_NAME"; Expression = {"Rolling7DaysViewership"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ViewershipTrend"}} , @{Name = "TABLE_NAME"; Expression = {"ViewershipTrend"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"BrandRecognitionDistribution"}} , @{Name = "TABLE_NAME"; Expression = {"BrandRecognitionDistribution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Margin"}} , @{Name = "TABLE_NAME"; Expression = {"Margin"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"MonthlyMargin"}} , @{Name = "TABLE_NAME"; Expression = {"MonthlyMargin"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RegionalViewershipDistribution"}} , @{Name = "TABLE_NAME"; Expression = {"RegionalViewershipDistribution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)


$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
foreach ($dataTableLoad in $dataTableList) {
    Write-output "Loading data for $($dataTableLoad.TABLE_NAME)"
    $sqlQuery = Get-Content -Raw -Path "../artifacts/templates/load_csv.sql"
    $sqlquery = $sqlquery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
    $Parameters =@{
            CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
            TABLE_NAME = $dataTableLoad.TABLE_NAME
            DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
     }
    foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
    Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Write-output "Data for $($dataTableLoad.TABLE_NAME) loaded."
}
