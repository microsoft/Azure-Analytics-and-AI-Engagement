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

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$synapseWorkspaceName = "synapsehealthcare$init$random"
$sqlPoolName = "HealthCareDW"
$sqlUser = "labsqladmin"
$keyVaultName = "kv-$init";
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText

Write-Host "------uploading sql data------"
Write-Host  "-----------------Uploading sql data ---------------"
RefreshTokens
#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RoleNew"}} , @{Name = "TABLE_NAME"; Expression = {"RoleNew"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PatientInformation"}} , @{Name = "TABLE_NAME"; Expression = {"PatientInformation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics_New"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiPatient"}} , @{Name = "TABLE_NAME"; Expression = {"pbiPatient"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiDepartment"}} , @{Name = "TABLE_NAME"; Expression = {"pbiDepartment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiManagementEmployee"}} , @{Name = "TABLE_NAME"; Expression = {"pbiManagementEmployee"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_CampaignAnalyticLatest"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_CampaignAnalyticLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Mkt_WebsiteSocialAnalyticsPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"Mkt_WebsiteSocialAnalyticsPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaignreport_Top5hospitalsbysatisfactionscore"}} , @{Name = "TABLE_NAME"; Expression = {"Campaignreport_Top5hospitalsbysatisfactionscore"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pred_anomaly"}} , @{Name = "TABLE_NAME"; Expression = {"pred_anomaly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"GlobalOverviewReport_Bed Occupancy"}} , @{Name = "TABLE_NAME"; Expression = {"GlobalOverviewReport_Bed Occupancy"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"GlobalOverviewReport_Margin Rate"}} , @{Name = "TABLE_NAME"; Expression = {"GlobalOverviewReport_Margin Rate"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"GlobalOverviewReport_Patient Experience"}} , @{Name = "TABLE_NAME"; Expression = {"GlobalOverviewReport_Patient Experience"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiHospitalMetaData"}} , @{Name = "TABLE_NAME"; Expression = {"pbiHospitalMetaData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiHospitalInfo"}} , @{Name = "TABLE_NAME"; Expression = {"pbiHospitalInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiWaitTimeForecast"}} , @{Name = "TABLE_NAME"; Expression = {"PbiWaitTimeForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBedOccupancyForecasted"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBedOccupancyForecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pred_anomaly"}} , @{Name = "TABLE_NAME"; Expression = {"pred_anomaly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiReadmissionPrediction"}} , @{Name = "TABLE_NAME"; Expression = {"PbiReadmissionPrediction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Miamihospitaloverview_Bed Occupancy"}} , @{Name = "TABLE_NAME"; Expression = {"Miamihospitaloverview_Bed Occupancy"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"USHeaderMapReport"}} , @{Name = "TABLE_NAME"; Expression = {"USHeaderMapReport"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerSalesHana"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerSalesHana"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HospitalEmpPIIData"}} , @{Name = "TABLE_NAME"; Expression = {"HospitalEmpPIIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynPatient"}} , @{Name = "TABLE_NAME"; Expression = {"synpatient"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HealthCare-FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"HealthCare-FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Healthcare-Iomt-Data"}} , @{Name = "TABLE_NAME"; Expression = {"Healthcare-Iomt-Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HealthCare-iomt-parameterized"}} , @{Name = "TABLE_NAME"; Expression = {"HealthCare-iomt-parameterized"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"healthcare-pcr-json"}} , @{Name = "TABLE_NAME"; Expression = {"healthcare-pcr-json"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"healthcare-tablevalued"}} , @{Name = "TABLE_NAME"; Expression = {"healthcare-tablevalued"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Healthcare-Twitter-Data"}} , @{Name = "TABLE_NAME"; Expression = {"Healthcare-Twitter-Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Iot-Iomt-Data"}} , @{Name = "TABLE_NAME"; Expression = {"Iot-Iomt-Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PatientInformation"}} , @{Name = "TABLE_NAME"; Expression = {"PatientInformation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynCondition"}} , @{Name = "TABLE_NAME"; Expression = {"SynCondition"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynObservation"}} , @{Name = "TABLE_NAME"; Expression = {"SynObservation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynapseLinkLabData"}} , @{Name = "TABLE_NAME"; Expression = {"SynapseLinkLabData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp) 

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynthiaPatient"}} , @{Name = "TABLE_NAME"; Expression = {"SynthiaPatient"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynthiaEncounter"}} , @{Name = "TABLE_NAME"; Expression = {"SynthiaEncounter"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiPatientSurvey"}} , @{Name = "TABLE_NAME"; Expression = {"pbiPatientSurvey"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Observations"}} , @{Name = "TABLE_NAME"; Expression = {"Observations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynEncounter"}} , @{Name = "TABLE_NAME"; Expression = {"SynEncounter"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynPatientsFinal"}} , @{Name = "TABLE_NAME"; Expression = {"SynPatientsFinal"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
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
