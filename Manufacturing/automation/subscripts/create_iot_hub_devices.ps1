function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#will be done as part of the cloud shell start - README

#remove-item MfgAI -recurse -force
#git clone -b real-time https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git MfgAI

#cd 'MfgAI/Manufacturing/automation'

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
$suffix = "$random-$init"

$iot_hub = "mfgiothub-$suffix"
$iot_hub_sendtohub = "mfgiothubCosmosDB-$suffix"
$iot_hub_telemetry = "mfgiothubTelemetry-$suffix"
$iot_hub_car = "raceCarIotHub-$suffix"

$ai_name_telemetry_car = "car-telemetry-ai-$suffix"
$ai_name_telemetry = "datagen-telemetry-ai-$suffix"
$ai_name_hub = "sku2-telemetry-ai-$suffix"
$ai_name_sendtohub = "sendtohub-telemetry-ai-$suffix"

$app_name_telemetry_car = "car-telemetry-app-$suffix"
$app_name_telemetry = "datagen-telemetry-app-$suffix"
$app_name_hub = "sku2-telemetry-app-$suffix"
$app_name_sendtohub = "sendtohub-telemetry-app-$suffix"

$wideworldimporters_app_service_name = "wideworldimporters-$suffix"

Write-Host "----Web apps zip deploy------"
RefreshTokens
#Create iot hub devices
$dev = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iot_hub_car -DeviceId race-car 
$iot_device_connection_car = $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub_car -DeviceId race-car).ConnectionString

$dev = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iot_hub_telemetry -DeviceId telemetry-data
$iot_device_connection_telemetry = $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub_telemetry -DeviceId telemetry-data).ConnectionString

$dev = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iot_hub_sendtohub -DeviceId send-to-hub
$iot_device_connection_sku2 = $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub_sendtohub -DeviceId send-to-hub).ConnectionString

$dev = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iot_hub -DeviceId data-device
$iot_device_connection_sendtohub = $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub -DeviceId data-device).ConnectionString

#get App insights instrumentation keys
$app_insights_instrumentation_key_car = $(Get-AzApplicationInsights -ResourceGroupName $rgName -Name $ai_name_telemetry_car).InstrumentationKey
$app_insights_instrumentation_key_telemetry = $(Get-AzApplicationInsights -ResourceGroupName $rgName -Name $ai_name_telemetry).InstrumentationKey
$app_insights_instrumentation_key_sku2 = $(Get-AzApplicationInsights -ResourceGroupName $rgName -Name $ai_name_hub).InstrumentationKey
$app_insights_instrumentation_key_sendtohub = $(Get-AzApplicationInsights -ResourceGroupName $rgName -Name $ai_name_sendtohub).InstrumentationKey

$zips = @("carTelemetry", "datagenTelemetry", "sku2", "sendtohub", "mfg-webapp", "wideworldimporters");

foreach($zip in $zips)
{
    expand-archive -path "../artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

#Replace connection string in config
(Get-Content -path carTelemetry/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_car`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_car`				
        } | Set-Content -Path carTelemetry/appsettings.json
		
(Get-Content -path datagenTelemetry/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_telemetry`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_telemetry`				
        } | Set-Content -Path datagenTelemetry/appsettings.json
		
(Get-Content -path sku2/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_sku2`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_sku2`				
        } | Set-Content -Path sku2/appsettings.json
		
(Get-Content -path sendtohub/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#connection_string#', $iot_device_connection_sendtohub`
				-replace '#app_insights_key#', $app_insights_instrumentation_key_sendtohub`				
        } | Set-Content -Path sendtohub/appsettings.json

	
#make zip for app service deployment
Compress-Archive -Path "./carTelemetry/*" -DestinationPath "./carTelemetry.zip"
Compress-Archive -Path "./sendtohub/*" -DestinationPath "./sendtohub.zip"
Compress-Archive -Path "./sku2/*" -DestinationPath "./sku2.zip"
Compress-Archive -Path "./datagenTelemetry/*" -DestinationPath "./datagenTelemetry.zip"
Compress-Archive -Path "./wideworldimporters/*" -DestinationPath "./wideworldimporters.zip"

# deploy the codes on app services
$webappTelemtryCar = Get-AzWebApp -ResourceGroupName $rgName -Name $app_name_telemetry_car
az webapp stop --name $app_name_telemetry_car --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $app_name_telemetry_car --src "./carTelemetry.zip"
az webapp start --name $app_name_telemetry_car --resource-group $rgName

$webappTelemtry = Get-AzWebApp -ResourceGroupName $rgName -Name $app_name_telemetry
az webapp stop --name $app_name_telemetry --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $app_name_telemetry --src "./datagenTelemetry.zip"
az webapp start --name $app_name_telemetry --resource-group $rgName

$webappHub = Get-AzWebApp -ResourceGroupName $rgName -Name $app_name_hub
az webapp stop --name $app_name_hub --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $app_name_hub --src "./sku2.zip"
az webapp start --name $app_name_hub --resource-group $rgName

$webappSendToHub = Get-AzWebApp -ResourceGroupName $rgName -Name $app_name_sendtohub
az webapp stop --name $app_name_sendtohub --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $app_name_sendtohub --src "./sendtohub.zip"
az webapp start --name $app_name_sendtohub --resource-group $rgName

$webappWWW = Get-AzWebApp -ResourceGroupName $rgName -Name $wideworldimporters_app_service_name
az webapp stop --name $wideworldimporters_app_service_name --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $wideworldimporters_app_service_name --src "./wideworldimporters.zip"
az webapp start --name $wideworldimporters_app_service_name --resource-group $rgName

foreach($zip in $zips)
{
	if($zip -eq "mfg-webapp")
	{
	continue
	}
    remove-item -path "./$($zip)" -recurse -force
    remove-item -path "./$($zip).zip" -recurse -force
}
