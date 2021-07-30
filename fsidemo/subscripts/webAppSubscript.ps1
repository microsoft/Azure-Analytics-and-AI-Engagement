function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

function ReplaceTokensInFile($ht, $filePath)
{
    $template = Get-Content -Raw -Path $filePath
	
    foreach ($paramName in $ht.Keys) 
    {
		$template = $template.Replace($paramName, $ht[$paramName])
	}

    return $template;
}

function GetAccessTokens($context)
{
    $global:synapseToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://dev.azuresynapse.net").AccessToken
    $global:synapseSQLToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://sql.azuresynapse.net").AccessToken
    $global:managementToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://management.azure.com").AccessToken
    $global:powerbitoken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://analysis.windows.net/powerbi/api").AccessToken
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

$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$after_scenario_financial_hcrr_url = (Get-AzResourceGroup -Name $rgName).Tags["after_scenario_financial_hcrr_url"]
$before_scenario_financial_hcrr_url = (Get-AzResourceGroup -Name $rgName).Tags["before_scenario_financial_hcrr_url"]
$before_scenario_cco_url = (Get-AzResourceGroup -Name $rgName).Tags["before_scenario_cco_url"]
$before_and_after_scenario_group_ceo_url = (Get-AzResourceGroup -Name $rgName).Tags["before_and_after_scenario_group_ceo_url"]
$tenantId = (Get-AzContext).Tenant.Id
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$dataLakeAccountName = "stfsi$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$suffix = "$random-$init"
$fsi_poc_app_service_name = "app-demofsi-$suffix"
$deploymentId = $init
$app_name_realtime_kpi_simulator ="app-fsi-realtime-kpi-simulator-$suffix"
$iot_hub_name = "iothub-fsi-$suffix"
$cog_fsiluis_name = "cog-luis-$suffix"
$cog_fsiluis_key = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $cog_fsiluis_name
$spname="Fsi Demo $deploymentid"
$app = Get-AzADApplication -DisplayName $spname
$clientsecpwd ="Smoothie@Smoothie@2020"
$secret = ConvertTo-SecureString -String $clientsecpwd -AsPlainText -Force

if (!$app)
{
    $app = New-AzADApplication -DisplayName $spname -IdentifierUris "http://fabmedical-sp-$deploymentId" -Password $secret;
}

$appId = $app.ApplicationId;

$zips = @("app_fsidemo","realtime_kpi_simulator")
foreach($zip in $zips)
{
    expand-archive -path "../artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}


$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "../artifacts/reports" | Select BaseName 

foreach($name in $reports)
{
       $FilePath="../artifacts/reports/$($name.BaseName)"+".pbix"
       #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
       
       #write-host "Uploading PowerBI Report $name";
       $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/imports?datasetDisplayName=$($name.BaseName)&nameConflict=CreateOrOverwrite";
		$fullyQualifiedPath=Resolve-Path -path $FilePath
       $fileBytes = [System.IO.File]::ReadAllBytes($fullyQualifiedPath);
       $fileEnc = [system.text.encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes);
       $boundary = [System.Guid]::NewGuid().ToString();
       $LF = "`r`n";
       $bodyLines = (
           "--$boundary",
           "Content-Disposition: form-data",
           "",
           $fileEnc,
           "--$boundary--$LF"
       ) -join $LF

       $result = Invoke-RestMethod -Uri $url -Method POST -Body $bodyLines -ContentType "multipart/form-data; boundary=`"--$boundary`"" -Headers @{ Authorization="Bearer $powerbitoken" }
		Start-Sleep -s 5 
		
       Add-Content log.txt $result
       $reportId = $result.id;

       $temp = "" | select-object @{Name = "FileName"; Expression = {"$($name.BaseName)"}}, 
		@{Name = "Name"; Expression = {"$($name.BaseName)"}}, 
       @{Name = "PowerBIDataSetId"; Expression = {""}},
       @{Name = "ReportId"; Expression = {""}},
       @{Name = "SourceServer"; Expression = {""}}, 
       @{Name = "SourceDatabase"; Expression = {""}}
		                        
       # get dataset                         
       $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
       $reportIds = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
		
       Add-Content log.txt $dataSets
       
    #    $temp.ReportId = $reportId;

        
       foreach($res in $reportIds.value)
       {
           if($res.name -eq $name.BaseName)
           {
               $temp.ReportId = $res.id;
           }
       }

      $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets";
      $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };

       foreach($res in $dataSets.value)
       {
           if($res.name -eq $name.BaseName)
           {
               $temp.PowerBIDataSetId = $res.id;
           }
      }

               
      $reportList.Add($temp)
}

(Get-Content -path app_fsidemo/appsettings.json -Raw) | Foreach-Object { $_ `
    -replace '#WORKSPACE_ID#', $wsId`
    -replace '#APP_ID#', $appId`
    -replace '#APP_SECRET#', $clientsecpwd`
    -replace '#TENANT_ID#', $tenantId`
} | Set-Content -Path app_fsidemo/appsettings.json

$filepath="./app_fsidemo/wwwroot/config.js"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName).Replace("#SERVER_NAME#", $fsi_poc_app_service_name).Replace("#SEARCH_APP_NAME#", $fsi_search_app_service_name).Replace("#APP_NAME#", $fsi_poc_app_service_name)
Set-Content -Path $filepath -Value $item 


#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable
$ht.add("#Blob_Base_Url#", "https://fsicdn.azureedge.net/webappassets/")
$ht.add("#Bing_Map_Key#", "AhBNZSn-fKVSNUE5xYFbW_qajVAZwWYc8OoSHlH8nmchGuDI6ykzYjrtbwuNSrR8")
$ht.add("#Api_Url#", "https://app-fsidemo-prod.azurewebsites.net")
$ht.add("#DashboardTopReportId#", $($reportList | where {$_.Name -eq "FSI CEO Dashboard"}).ReportId)
$ht.add("#PageID_Twitter#", $($reportList | where {$_.Name -eq "FSI_Twitter_report"}).ReportId)
$ht.add("#PAGE_ID#", $($reportList | where {$_.Name -eq "Finance Report"}).ReportId)
$ht.add("#MSCIBeforeReportId#", $($reportList | where {$_.Name -eq "MSCI Report"}).ReportId)
$ht.add("#MSCIAfterReportId#", $($reportList | where {$_.Name -eq "MSCI Report"}).ReportId)
$ht.add("#PredictiveanalyticsReportId#", $($reportList | where {$_.Name -eq "FSI Predictive Analytics"}).ReportId)
$ht.add("#HTAPReportId#", $($reportList | where {$_.Name -eq "FSI HTAP"}).ReportId)
$ht.add("#ESGReportId#", $($reportList | where {$_.Name -eq "ESG Report Synapse Import Mode"}).ReportId)
$ht.add("#AfterEsgReportId#", $($reportList | where {$_.Name -eq "ESG Metrics for Woodgrove"}).ReportId)
$ht.add("#USMapReportId#", $($reportList | where {$_.Name -eq "US Map with header"}).ReportId)
$ht.add("#gb_reportId#", $($reportList | where {$_.Name -eq "Global overview tiles"}).ReportId)
$ht.add("#Assets_Management_Report_ID#", $($reportList | where {$_.Name -eq "globalmarkets"}).ReportId)
$ht.add("#fc_reportId#", $($reportList | where {$_.Name -eq ""}).ReportId)
$ht.add("#GeoSpacialFraudDetectionId#", $($reportList | where {$_.Name -eq "Geospatial Fraud Detection Miami"}).ReportId)
$ht.add("#Fraud_Incident_ReportId#", $($reportList | where {$_.Name -eq "FSI Incident Report"}).ReportId)

$filePath = "./app_fsidemo/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./app_fsidemo/*" -DestinationPath "./app_fsidemo.zip"

az webapp stop --name $fsi_poc_app_service_name --resource-group $rgName
az webapp stop --name $fsi_search_app_service_name --resource-group $rgName
try{
az webapp deployment source config-zip --resource-group $rgName --name $fsi_poc_app_service_name --src "./app_fsidemo.zip"
}
catch
{
}

$iot_device_connection= $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub_name -DeviceId realtime-traffic-device).ConnectionString

$filepath="./realtime_kpi_simulator/prod.env"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#PBI_STREAMING_URL_BEFOREANDAFTER_SCENARIO_GROUPCEO_REALTIME#", $before_and_after_scenario_group_ceo_url).Replace("#PBI_STREAMING_URL_BEFORE_SCENARIO_CCOREALTIME#", $before_scenario_cco_url).Replace("#PBI_STREAMING_URL_BEFORE_SCENARIO_FINANCIAL_HEADANDCHIEF_RISLREALTIME#", $before_scenario_financial_hcrr_url).Replace("#PBI_STREAMING_URL_AFTER_SCENARIO_FINANCIAL_HEADANDCHIEF_RISLREALTIME#", $after_scenario_financial_hcrr_url)
Set-Content -Path $filepath -Value $item 

# deploy the codes on app services  
Write-Information "Deploying web app"
cd realtime_kpi_simulator
az webapp up --resource-group $rgName --name $app_name_realtime_kpi_simulator
cd ..
Start-Sleep -s 10

$AfterScenarioFinancialHeadAndChiefRislRealtimeConfig   = '{\"main_data_frequency_seconds\":1,\"urlString\":\"'+$after_scenario_financial_hcrr_url+'\",\"data\":[{\"InvestigationResponseTime\":{\"minValue\":1,\"maxValue\":3}},{\"TargetInvestigationResponseTime\":{\"minValue\":7,\"maxValue\":7}},{\"PerfvsEfficiency\":{\"minValue\":54,\"maxValue\":60}},{\"TargetPerfvsEfficiency\":{\"minValue\":30,\"maxValue\":30}},{\"SanctionsAlertRate\":{\"minValue\":1.1,\"maxValue\":1.5}},{\"TargetSanctionsAlertRate\":{\"minValue\":1.3,\"maxValue\":1.3}},{\"OpenTransactionsAlertLevel1\":{\"minValue\":2144,\"maxValue\":2368}},{\"TargetOpenTransactionsAlertLevel1\":{\"minValue\":2256,\"maxValue\":2256}},{\"OpenTransactionsAlertLevel2\":{\"minValue\":17,\"maxValue\":19}},{\"TargetOpenTransactionsAlertLevel2\":{\"minValue\":18,\"maxValue\":18}},{\"AlertsClosedWithSLA\":{\"minValue\":96,\"maxValue\":97}},{\"TargetAlertsClosedWithSLA\":{\"minValue\":95,\"maxValue\":95}},{\"KYCAlertinSanctions\":{\"minValue\":1.2,\"maxValue\":1.9}},{\"TargetKYCAlertinSanctions\":{\"minValue\":1.82,\"maxValue\":1.82}},{\"KYCAlertinPEP\":{\"minValue\":3.1,\"maxValue\":3.9}},{\"TargetKYCAlertinPEP\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"KYCAlertinMedia\":{\"minValue\":3.1,\"maxValue\":3.9}},{\"TargetKYCAlertinMedia\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"Vulnerabilities\":{\"minValue\":213,\"maxValue\":319}},{\"TargetVulnerabilities\":{\"minValue\":325,\"maxValue\":325}},{\"InvestigationResponseTimeCyberSec\":{\"minValue\":1,\"maxValue\":3}},{\"TargetInvestigationResponseTimeCyberSec\":{\"minValue\":3,\"maxValue\":3}},{\"TerminatedEmployeesAccess\":{\"minValue\":1.1,\"maxValue\":2}},{\"TargetTerminatedEmployeesAccess\":{\"minValue\":1.5,\"maxValue\":1.5}},{\"UnauthorizedEmployees\":{\"minValue\":0,\"maxValue\":2}},{\"TargetUnauthorizedEmployees\":{\"minValue\":6,\"maxValue\":6}},{\"NoHardwareSecurity\":{\"minValue\":4,\"maxValue\":9}},{\"TargetNoHardwareSecurity\":{\"minValue\":0,\"maxValue\":0}},{\"CreditRiskExposure\":{\"minValue\":10,\"maxValue\":20}},{\"TargetCreditRiskExposure\":{\"minValue\":15,\"maxValue\":15}},{\"FinancialCrime\":{\"minValue\":0.5,\"maxValue\":3}},{\"TargetFinancialCrime\":{\"minValue\":2,\"maxValue\":2}},{\"TradingExposure\":{\"minValue\":1,\"maxValue\":3}},{\"TargetTradingExposure\":{\"minValue\":5.5,\"maxValue\":5.5}},{\"ESGAssets\":{\"minValue\":35,\"maxValue\":45}},{\"TargetESGAssets\":{\"minValue\":25,\"maxValue\":25}},{\"ClaimsProcessingCycleTime\":{\"minValue\":1,\"maxValue\":2}},{\"TargetClaimsProcessingCycleTime\":{\"minValue\":1,\"maxValue\":1}},{\"UnderwritingEfficiency\":{\"minValue\":50,\"maxValue\":57}},{\"TargetUnderwritingEfficiency\":{\"minValue\":55,\"maxValue\":55}},{\"OverallCreditRisk\":{\"minValue\":30,\"maxValue\":55}},{\"TargetOverallCreditRisk\":{\"minValue\":50,\"maxValue\":50}},{\"OverallOperationalRisk\":{\"minValue\":1,\"maxValue\":18}},{\"TargetOverallOperationalRisk\":{\"minValue\":10,\"maxValue\":10}}]}'
az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings AfterScenarioFinancialHeadAndChiefRislRealtimeConfig=$AfterScenarioFinancialHeadAndChiefRislRealtimeConfig

$BeforeAndAfterScenarioGroupCEORealtimeConfigs   = '{\"main_data_frequency_seconds\":1,\"urlString\":\"'+$before_and_after_scenario_group_ceo_url+'\",\"data\":[{\"CSAT\":{\"minValue\":1,\"maxValue\":5}},{\"AverageAttrition\":{\"minValue\":11,\"maxValue\":15}},{\"ComplianceScore\":{\"minValue\":1,\"maxValue\":4}},{\"CustomerChurn\":{\"minValue\":18,\"maxValue\":23}},{\"CustomerChurnAfter\":{\"minValue\":9,\"maxValue\":15}},{\"EmployeeSatisfaction\":{\"minValue\":2.5,\"maxValue\":2.75}},{\"EmployeeSatisfactionAfter\":{\"minValue\":3.5,\"maxValue\":3.75}},{\"TargetCustomerChurn\":{\"minValue\":24,\"maxValue\":24}},{\"TargetCustomerChurnAfter\":{\"minValue\":10,\"maxValue\":10}},{\"TargetAverageAttrition\":{\"minValue\":14,\"maxValue\":14}},{\"TargetEmployeeSatisfaction\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"TargetEmployeeSatisfactionAfter\":{\"minValue\":3.75,\"maxValue\":3.75}},{\"TargetComplianceScore\":{\"minValue\":4,\"maxValue\":4}},{\"RelativePerformancetoS&P500\":{\"minValue\":-25,\"maxValue\":-5}},{\"RelativePerformancetoS&P500After\":{\"minValue\":1,\"maxValue\":8}},{\"TargetRelativePerformancetoS&P500\":{\"minValue\":-15,\"maxValue\":-15}},{\"TargetRelativePerformancetoS&P500After\":{\"minValue\":5,\"maxValue\":5}},{\"QuarterlyClaimsProcessingEfficiency\":{\"minValue\":-36,\"maxValue\":-20}},{\"QuarterlyClaimsProcessingEfficiencyAfter\":{\"minValue\":1,\"maxValue\":15}},{\"TargetQuarterlyClaimsProcessingEfficiency\":{\"minValue\":-28,\"maxValue\":-28}},{\"TargetQuarterlyClaimsProcessingEfficiencyAfter\":{\"minValue\":9,\"maxValue\":9}},{\"CSRRating\":{\"minValue\":3.6,\"maxValue\":4}},{\"CSRRatingAfter\":{\"minValue\":4.1,\"maxValue\":4.7}},{\"TargetCSRRating\":{\"minValue\":3.8,\"maxValue\":3.8}},{\"TargetCSRRatingAfter\":{\"minValue\":4.4,\"maxValue\":4.4}},{\"ChannelEngagementRiskofChurn\":{\"minValue\":40,\"maxValue\":45}},{\"ChannelEngagementRiskofChurnAfter\":{\"minValue\":30,\"maxValue\":34}},{\"TargetChannelEngagementRiskofChurn\":{\"minValue\":42,\"maxValue\":42}},{\"TargetChannelEngagementRiskofChurnAfter\":{\"minValue\":32,\"maxValue\":32}},{\"ProjectedAnnualGrowthMarketShare\":{\"minValue\":-19,\"maxValue\":-13}},{\"ProjectedAnnualGrowthMarketShareAfter\":{\"minValue\":7,\"maxValue\":12}},{\"TargetProjectedAnnualGrowthMarketShare\":{\"minValue\":-15,\"maxValue\":-15}},{\"TargetProjectedAnnualGrowthMarketShareAfter\":{\"minValue\":11,\"maxValue\":11}},{\"ProjectedAnnualGrowthEmployeeStrength\":{\"minValue\":-18,\"maxValue\":-11}},{\"ProjectedAnnualGrowthEmployeeStrengthAfter\":{\"minValue\":15,\"maxValue\":25}},{\"TargetProjectedAnnualGrowthEmployeeStrength\":{\"minValue\":-13,\"maxValue\":-13}},{\"TargetProjectedAnnualGrowthEmployeeStrengthAfter\":{\"minValue\":22,\"maxValue\":22}},{\"ActiveSensors\":{\"minValue\":43000,\"maxValue\":45000}},{\"TargetActiveSensors\":{\"minValue\":40000,\"maxValue\":40000}},{\"InvestmentBefore\":{\"minValue\":100,\"maxValue\":130}},{\"InvestmentAfter\":{\"minValue\":200,\"maxValue\":250}},{\"CreditCardTransactionVolume\":{\"minValue\":8,\"maxValue\":10,\"Behaviour\":\"increament\",\"SpikeValue\":0.0022}},{\"EmployeeOnboardCycle\":{\"minValue\":15,\"maxValue\":30}},{\"EmployeeOnboardCycleAfter\":{\"minValue\":1,\"maxValue\":7}},{\"TargetEmployeeOnboardCycle\":{\"minValue\":7,\"maxValue\":7}},{\"CreditCardTransactionAmount\":{\"minValue\":120,\"maxValue\":225,\"Behaviour\":\"increament\",\"SpikeValue\":0.1166}},{\"S&P500IndexValue\":{\"minValue\":3400,\"maxValue\":4250,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"randomMin\":-0.1,\"randomMax\":1.1,\"SpikeValue\":21.25,\"ReleaseValue\":42.5,\"relatableTo\":[{\"WoodgrovePortfolioIndexValue\":{\"minValue\":3280,\"maxValue\":3900,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"relationship\":\"SmallerNumber\",\"randomMin\":0.5,\"randomMax\":1,\"SpikeValue\":15.5,\"ReleaseValue\":31}}]}},{\"S&P500IndexValueMid\":{\"minValue\":3280,\"maxValue\":3900,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"randomMin\":-0.1,\"randomMax\":1.1,\"SpikeValue\":21.25,\"ReleaseValue\":42.5,\"relatableTo\":[{\"WoodgrovePortfolioIndexValueMid\":{\"minValue\":3350,\"maxValue\":3970,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"relationship\":\"BiggerNumber\",\"randomMin\":0.5,\"randomMax\":1,\"SpikeValue\":21.25,\"ReleaseValue\":42.5}}]}},{\"S&P500IndexValueAfter\":{\"minValue\":3280,\"maxValue\":3900,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"randomMin\":-0.1,\"randomMax\":1.1,\"SpikeValue\":15.5,\"ReleaseValue\":31,\"relatableTo\":[{\"WoodgrovePortfolioIndexValueAfter\":{\"minValue\":3400,\"maxValue\":4250,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"relationship\":\"BiggerNumber\",\"randomMin\":0.5,\"randomMax\":1,\"SpikeValue\":21.25,\"ReleaseValue\":42.5}}]}}]}'
az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings BeforeAndAfterScenarioGroupCEORealtimeConfigs=$BeforeAndAfterScenarioGroupCEORealtimeConfigs

$BeforeScenarioCCORealtimeConfig   = '{\"main_data_frequency_seconds\":1,\"urlString\":\"'+$before_scenario_cco_url+'\",\"data\":[{\"NPS\":{\"minValue\":-20,\"maxValue\":-5}},{\"TargetNPS\":{\"minValue\":-10,\"maxValue\":-10}},{\"CustomerChurn\":{\"minValue\":35,\"maxValue\":45}},{\"TargetCustomerChurn\":{\"minValue\":30,\"maxValue\":30}},{\"AccountOpeningTime\":{\"minValue\":24,\"maxValue\":50}},{\"TargetAccountOpeningTime\":{\"minValue\":30,\"maxValue\":30}},{\"RequestsWithinSLA\":{\"minValue\":50,\"maxValue\":55}},{\"TargetRequestsWithinSLA\":{\"minValue\":52,\"maxValue\":52}},{\"SocialSentiment\":{\"minValue\":[\"Negative\",\"Neutral\"]}},{\"NPSAfter\":{\"minValue\":7,\"maxValue\":12}},{\"TargetNPSAfter\":{\"minValue\":10,\"maxValue\":10}},{\"CustomerChurnAfter\":{\"minValue\":15,\"maxValue\":20}},{\"TargetCustomerChurnAfter\":{\"minValue\":25,\"maxValue\":25}},{\"AccountOpeningTimeAfter\":{\"minValue\":8,\"maxValue\":12}},{\"TargetAccountOpeningTimeAfter\":{\"minValue\":10,\"maxValue\":10}},{\"RequestsWithinSLAAfter\":{\"minValue\":55,\"maxValue\":65}},{\"TargetRequestsWithinSLAAfter\":{\"minValue\":55,\"maxValue\":55}},{\"SocialSentimentAfter\":{\"minValue\":[\"Good\",\"Neutral\"]}}]}'
az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings BeforeScenarioCCORealtimeConfig=$BeforeScenarioCCORealtimeConfig

$BeforeScenarioFinancialHeadAndChiefRislRealtimeConfig   = '"{\"main_data_frequency_seconds\":1,\"urlString\":\"'+$before_scenario_financial_hcrr_url+'",\"data\":[{\"InvestigationResponseTime\":{\"minValue\":5,\"maxValue\":12}},{\"TargetInvestigationResponseTime\":{\"minValue\":7,\"maxValue\":7}},{\"PerfvsEfficiency\":{\"minValue\":28,\"maxValue\":32}},{\"TargetPerfvsEfficiency\":{\"minValue\":30,\"maxValue\":30}},{\"SanctionsAlertRate\":{\"minValue\":3.7,\"maxValue\":4.5}},{\"TargetSanctionsAlertRate\":{\"minValue\":1.3,\"maxValue\":1.3}},{\"OpenTransactionsAlertLevel1\":{\"minValue\":2368,\"maxValue\":2481}},{\"TargetOpenTransactionsAlertLevel1\":{\"minValue\":2256,\"maxValue\":2256}},{\"OpenTransactionsAlertLevel2\":{\"minValue\":20,\"maxValue\":24}},{\"TargetOpenTransactionsAlertLevel2\":{\"minValue\":18,\"maxValue\":18}},{\"AlertsClosedWithSLA\":{\"minValue\":85,\"maxValue\":94}},{\"TargetAlertsClosedWithSLA\":{\"minValue\":95,\"maxValue\":95}},{\"KYCAlertinSanctions\":{\"minValue\":3.2,\"maxValue\":3.7}},{\"TargetKYCAlertinSanctions\":{\"minValue\":1.82,\"maxValue\":1.82}},{\"KYCAlertinPEP\":{\"minValue\":3.1,\"maxValue\":3.9}},{\"TargetKYCAlertinPEP\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"KYCAlertinMedia\":{\"minValue\":3.1,\"maxValue\":3.9}},{\"TargetKYCAlertinMedia\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"Vulnerabilities\":{\"minValue\":700,\"maxValue\":851}},{\"TargetVulnerabilities\":{\"minValue\":750,\"maxValue\":750}},{\"InvestigationResponseTimeCyberSec\":{\"minValue\":11,\"maxValue\":24}},{\"TargetInvestigationResponseTimeCyberSec\":{\"minValue\":3,\"maxValue\":3}},{\"TerminatedEmployeesAccess\":{\"minValue\":5,\"maxValue\":15}},{\"TargetTerminatedEmployeesAccess\":{\"minValue\":1.5,\"maxValue\":1.5}},{\"UnauthorizedEmployees\":{\"minValue\":5,\"maxValue\":15}},{\"TargetUnauthorizedEmployees\":{\"minValue\":6,\"maxValue\":6}},{\"NoHardwareSecurity\":{\"minValue\":30,\"maxValue\":45}},{\"TargetNoHardwareSecurity\":{\"minValue\":0,\"maxValue\":0}},{\"CreditRiskExposure\":{\"minValue\":35,\"maxValue\":75}},{\"TargetCreditRiskExposure\":{\"minValue\":55,\"maxValue\":55}},{\"FinancialCrime\":{\"minValue\":12,\"maxValue\":16}},{\"TargetFinancialCrime\":{\"minValue\":2,\"maxValue\":2}},{\"TradingExposure\":{\"minValue\":11,\"maxValue\":15}},{\"TargetTradingExposure\":{\"minValue\":5.5,\"maxValue\":5.5}},{\"ESGAssets\":{\"minValue\":12,\"maxValue\":15}},{\"TargetESGAssets\":{\"minValue\":25,\"maxValue\":25}},{\"ClaimsProcessingCycleTime\":{\"minValue\":3,\"maxValue\":7}},{\"TargetClaimsProcessingCycleTime\":{\"minValue\":1,\"maxValue\":1}},{\"UnderwritingEfficiency\":{\"minValue\":33,\"maxValue\":46}},{\"TargetUnderwritingEfficiency\":{\"minValue\":55,\"maxValue\":55}},{\"OverallCreditRisk\":{\"minValue\":60,\"maxValue\":75}},{\"TargetOverallCreditRisk\":{\"minValue\":50,\"maxValue\":50}},{\"OverallOperationalRisk\":{\"minValue\":40,\"maxValue\":65}},{\"TargetOverallOperationalRisk\":{\"minValue\":10,\"maxValue\":10}}]}'
az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings BeforeScenarioFinancialHeadAndChiefRislRealtimeConfig=$BeforeScenarioFinancialHeadAndChiefRislRealtimeConfig

$IoTSimulatorConfigs = '"{\"main_data_frequency_seconds\":1,\"data\":[{\"before-foottraffic\":{\"minValue\":18,\"maxValue\":25}},{\"after-foottraffic\":{\"minValue\":35,\"maxValue\":45}}]}"'
az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings IoTSimulatorConfigs=$IoTSimulatorConfigs

$IoTHubConfig = '"{\"frequency\":1,\"connection\":{\"provisioning_host\":\"global.azure-devices-provisioning.net\",\"id_scope\":\"0ne001BF93E\",\"registration_id\":\"7jqqgjhj0j\",\"symmetric_key\":\"ctSxPAs\\/r9f99k+NPsTADiEwmodz6lmBXJpagDXPE7o=\",\"IoTHubConnectionString\":\"'+$iot_device_connection+'\"}}"'
az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings IoTHubConfig=$IoTHubConfig

az webapp start  --name $app_name_realtime_kpi_simulator --resource-group $rgName
az webapp start --name $fsi_poc_app_service_name --resource-group $rgName
