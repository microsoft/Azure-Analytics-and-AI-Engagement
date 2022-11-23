
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
    Write-Host "Selecting the subscription : $selectedSubName "
	$title    = 'Subscription selection'
	$question = 'Are you sure you want to select this subscription for this lab?'
	$choices  = '&Yes', '&No'
	$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
	if($decision -eq 0)
	{
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
	}
	else
	{
	$selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
	Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
	}
}
#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$location = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$deploymentId = $init
$concatString = "$init$random"
$dataLakeAccountName = "stsynapsesustain$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

$bot_qnamaker_sustain_name= "botmultilingual-$suffix";
$accounts_immersive_reader_sustain_name = "immersive-reader-sustain-$suffix";
$app_immersive_reader_sustain_name = "immersive-reader-sustain-app-$suffix";
$app_sustaindemo_name = "sustaindemo-app-$suffix";
$iot_hub_name = "iothub-sustain-$suffix";
$sites_app_multiling_sustain_name = "multiling-sustain-app-$suffix";
$asp_multiling_sustain_name = "multiling-sustain-asp-$suffix";
$sites_app_taxcollection_realtime_name = "taxcollectionrealtime-sustain-app-$suffix";
$sites_app_vat_custsat_eventhub_name = "vat-custsat-eventhub-sustain-app-$suffix";
$sites_app_iotfoottraffic_sensor_name = "iot-foottraffic-sensor-sustain-app-$suffix";
$storageAccountName = $dataLakeAccountName
$asa_name_sustain = "sustainasa-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$AADApp_Immnersive_DisplayName = "sustainImmersiveReader-$suffix"
$CurrentTime = Get-Date
$AADAppClientSecretExpiration = $CurrentTime.AddDays(365)
$AADAppClientSecret = "Smoothie@2021@2021"
$AADApp_Multiling_DisplayName = "sustainMultiling-$suffix"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#Web app
Write-Host  "-----------------Deploy web apps ---------------"
RefreshTokens

#################

$zips = @("app-sustainabilitydemo", "app-airqualitydata", "app-iot-sustainability")
foreach($zip in $zips)
{
    expand-archive -path "../artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

# IOT Sustainability
$device_conn_string= $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub_sustainability -DeviceId iot-sustainability-device).ConnectionString
$shared_access_key = $device_conn_string.Split(";")[2]
$device_primary_key= $shared_access_key.Substring($shared_access_key.IndexOf("=")+1)

$iot_hub_config = '"{\"frequency\":1,\"connection\":{\"provisioning_host\":\"global.azure-devices-provisioning.net\",\"symmetric_key\":\"' + $device_primary_key + '\",\"IoTHubConnectionString\":\"' + $device_conn_string + '\"}}"'

(Get-Content -path app-iot-sustainability/prod.env -Raw) | Foreach-Object { $_ `
     -replace '#DEVICE_PRIMARY_KEY#', $device_primary_key`
     -replace '#DEVICE_CONN_STRING#', $device_conn_string`
 } | Set-Content -Path app-iot-sustainability/prod.env

Write-Information "Deploying IOT Sustainability App"
cd app-iot-sustainability
az webapp up --resource-group $rgName --name $sites_iotsustainability_name
cd ..
Start-Sleep -s 10

$config = az webapp config appsettings set -g $rgName -n $sites_iotsustainability_name --settings IoTHubConfig=$iot_hub_config

# App Airqualitydata
$chicago_AQIReports_Config = '"{\"main_data_frequency_seconds\":1,\"urlStringPowerBI\":\"' + $Realtime_Air_Quality_API + '\",\"diff_After_Mid_AQI\":20.0,\"diff_After_Mid_PM1\":7.0,\"diff_After_Mid_PM10\":7.0,\"diff_After_Mid_PM25\":7.0,\"diff_After_Before_AQI\":35.0,\"diff_After_Before_PM10\":10.0,\"diff_After_Before_PM1\":10.0,\"diff_After_Before_PM25\":10.0,\"mean_AQI_Target\":40.0,\"mean_PM1_Target\":5.0,\"mean_PM10_Target\":5.0,\"mean_PM25_Target\":5.0,\"data\":[{\"mean_AQI\":{\"minValue\":10.0,\"maxValue\":25.0}},{\"mean_PM1\":{\"minValue\":1.0,\"maxValue\":5.0}},{\"mean_PM25\":{\"minValue\":1.0,\"maxValue\":5.0}},{\"mean_PM10\":{\"minValue\":1.0,\"maxValue\":5.0}}]}"'

(Get-Content -path app-airqualitydata/prod.env -Raw) | Foreach-Object { $_ `
    -replace '#AIR_QUALITY_STREAMING_URL#', $Realtime_Air_Quality_API`
} | Set-Content -Path app-airqualitydata/prod.env

Write-Information "Deploying Airqualitydata App"
cd app-airqualitydata
az webapp up --resource-group $rgName --name $sites_airquality_name
cd ..
Start-Sleep -s 10

$config = az webapp config appsettings set -g $rgName -n $sites_airquality_name --settings ChicagoAQIReportsConfig=$chicago_AQIReports_Config

RefreshTokens

az webapp start  --name $sites_iotsustainability_name --resource-group $rgName
az webapp start --name $sites_airquality_name --resource-group $rgName

foreach($zip in $zips)
{
    remove-item -path "./$($zip)" -recurse -force
}

#start ASA
Write-Host "----Starting ASA-----"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_sustainability -OutputStartMode 'JobStartTime'

