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
$rglocation = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$deploymentId = $init
$concatString = "$init$random"
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$bot_qnamaker_retail_name= "botmultilingual-$suffix";
$app_retaildemo_name = "retaildemo-app-$suffix";
$sites_app_product_search = "app-product-search-ui-$suffix"
$iot_hub_name = "iothub-retail-$suffix";
$sites_app_iotfoottraffic_sensor_name = "iot-foottraffic-sensor-retail-app-$suffix";
$storageAccountName = $dataLakeAccountName
$asa_name_retail = "retailasa-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$CurrentTime = Get-Date
$AADAppClientSecretExpiration = $CurrentTime.AddDays(365)
$AADAppClientSecret = "Smoothie@2021@2021"
$iothub_foottraffic = "iothub-foottraffic-$suffix"
$sites_app_multiling_retail_name = "multiling-retail-app-$suffix";
$asp_multiling_retail_name = "multiling-retail-asp-$suffix";
$media_search_app_service_name = "app-media-search-$suffix"
$namespaces_adx_thermostat_occupancy_name = "adx-thermostat-occupancy-$suffix"
$thermostat_telemetry_Realtime_URL =  (Get-AzResourceGroup -Name $rgName).Tags["thermostat_telemetry_Realtime_URL"]
$occupancy_data_Realtime_URL =  (Get-AzResourceGroup -Name $rgName).Tags["occupancy_data_Realtime_URL"]
$sites_adx_thermostat_realtime_name = "app-realtime-kpi-retail-$suffix"
$sites_app_product_search = "app-product-search-ui-$suffix"
$search_srch_retail_name = "srch-retail-product-$suffix";

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#########################

Add-Content log.txt "----Bot and multilingual App-----"
Write-Host "----Bot and multilingual App----"

$app = az ad app create --display-name $sites_app_multiling_retail_name | ConvertFrom-Json
$appId = $app.appId

$appCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$appPassword = $appCredential.password

az deployment group create --resource-group $rgName --template-file "../artifacts/qnamaker/bot-multiling-template.json" --parameters appId=$appId appSecret=$appPassword botId=$bot_qnamaker_retail_name newWebAppName=$sites_app_multiling_retail_name newAppServicePlanName=$asp_multiling_retail_name appServicePlanLocation=$rglocation

az webapp deployment source config-zip --resource-group $rgName --name $sites_app_multiling_retail_name --src "../artifacts/qnamaker/chatbot.zip"
az webapp start --name $sites_app_multiling_retail_name --resource-group $rgName 

#################

$zips = @("retaildemo-app", "app-iotfoottraffic-sensor", "app-adx-thermostat-realtime", "app_media_search", "func-product-search", "app-product-search")
foreach($zip in $zips)
{
    expand-archive -path "../artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

#Web app
Write-Host  "-----------------Deploy web apps ---------------"
RefreshTokens

$device = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iothub_foottraffic -DeviceId retail-foottraffic-device

$spname="Retail Demo $deploymentId"

$app = az ad app create --display-name $spname | ConvertFrom-Json
$appId = $app.appId

$mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$clientsecpwd = $mainAppCredential.password

az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "id" -o tsv
start-sleep -s 60

#https://docs.microsoft.com/en-us/power-bi/developer/embedded/embed-service-principal
#Allow service principals to user PowerBI APIS must be enabled - https://app.powerbi.com/admin-portal/tenantSettings?language=en-U
#add PowerBI App to workspace as an admin to group
RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups";
$result = Invoke-WebRequest -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
$homeCluster = $result.Headers["home-cluster-uri"]
#$homeCluser = "https://wabi-west-us-redirect.analysis.windows.net";

RefreshTokens
$url = "$homeCluster/metadata/tenantsettings"
$post = "{`"featureSwitches`":[{`"switchId`":306,`"switchName`":`"ServicePrincipalAccess`",`"isEnabled`":true,`"isGranular`":true,`"allowedSecurityGroups`":[],`"deniedSecurityGroups`":[]}],`"properties`":[{`"tenantSettingName`":`"ServicePrincipalAccess`",`"properties`":{`"HideServicePrincipalsNotification`":`"false`"}}]}"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $powerbiToken")
$headers.Add("X-PowerBI-User-Admin", "true")
#$result = Invoke-RestMethod -Uri $url -Method PUT -body $post -ContentType "application/json" -Headers $headers -ea SilentlyContinue;

#add PowerBI App to workspace as an admin to group
RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/users";
$post = "{
    `"identifier`":`"$($sp)`",
    `"groupUserAccessRight`":`"Admin`",
    `"principalType`":`"App`"
    }";

$result = Invoke-RestMethod -Uri $url -Method POST -body $post -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;

#get the power bi app...
$powerBIApp = Get-AzADServicePrincipal -DisplayNameBeginsWith "Power BI Service"
$powerBiAppId = $powerBIApp.Id;

#setup powerBI app...
RefreshTokens
$url = "https://graph.microsoft.com/beta/OAuth2PermissionGrants";
$post = "{
    `"clientId`":`"$appId`",
    `"consentType`":`"AllPrincipals`",
    `"resourceId`":`"$powerBiAppId`",
    `"scope`":`"Dataset.ReadWrite.All Dashboard.Read.All Report.Read.All Group.Read Group.Read.All Content.Create Metadata.View_Any Dataset.Read.All Data.Alter_Any`",
    `"expiryTime`":`"2021-03-29T14:35:32.4943409+03:00`",
    `"startTime`":`"2020-03-29T14:35:32.4933413+03:00`"
    }";

$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $graphtoken" } -ea SilentlyContinue;

#setup powerBI app...
RefreshTokens
$url = "https://graph.microsoft.com/beta/OAuth2PermissionGrants";
$post = "{
    `"clientId`":`"$appId`",
    `"consentType`":`"AllPrincipals`",
    `"resourceId`":`"$powerBiAppId`",
    `"scope`":`"User.Read Directory.AccessAsUser.All`",
    `"expiryTime`":`"2021-03-29T14:35:32.4943409+03:00`",
    `"startTime`":`"2020-03-29T14:35:32.4933413+03:00`"
    }";

$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $graphtoken" } -ea SilentlyContinue;
	
(Get-Content -path app_media_search/appsettings.json -Raw) | Foreach-Object { $_ `
    -replace '#WORKSPACE_ID#', $wsId`
    -replace '#APP_ID#', $appId`
    -replace '#APP_SECRET#', $clientsecpwd`
    -replace '#TENANT_ID#', $tenantId`				
} | Set-Content -Path app_media_search/appsettings.json

(Get-Content -path app_media_search/wwwroot/config.js -Raw) | Foreach-Object { $_ `
    -replace '#VI_ACCOUNT_ID#', $vi_account_id`
    -replace '#VI_API_KEY#', $vi_account_key`
    -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`
    -replace '#VI_LOCATION#', $vi_location`
} | Set-Content -Path app_media_search/wwwroot/config.js	

(Get-Content -path retaildemo-app/appsettings.json -Raw) | Foreach-Object { $_ `
    -replace '#WORKSPACE_ID#', $wsId`
    -replace '#APP_ID#', $appId`
    -replace '#APP_SECRET#', $clientsecpwd`
    -replace '#TENANT_ID#', $tenantId`				
} | Set-Content -Path retaildemo-app/appsettings.json

$filepath="./retaildemo-app/wwwroot/config.js"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName).Replace("#SERVER_NAME#", $app_retaildemo_name).Replace("#APP_NAME#", $app_retaildemo_name).Replace("#SEARCH_APP_NAME#", $media_search_app_service_name)
Set-Content -Path $filepath -Value $item

#bot qna maker
$bot_detail = az bot webchat show --name $bot_qnamaker_retail_name --resource-group $rgName --with-secrets true | ConvertFrom-Json
$bot_key = $bot_detail.properties.properties.sites[0].key

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
$reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$reportList = $reportList.Value
$sites_app_product_search_url = "https://$($sites_app_product_search).azurewebsites.net"
#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable    
$ht.add("#BOT_QNAMAKER_RETAIL_NAME#", $bot_qnamaker_retail_name)
$ht.add("#BOT_KEY#", $bot_key)
$ht.add("#Retail_Group_CEO_KPI#", $($reportList | where {$_.name -eq "Retail Group CEO KPI"}).id)
$ht.add("#Retail_Predictive_Analytics#", $($reportList | where {$_.name -eq "Retail Predictive Analytics"}).id)
$ht.add("#Campaign_Analytics_Deep_Dive#", $($reportList | where {$_.name -eq "Campaign Analytics Deep Dive"}).id)
$ht.add("#Campaign_Analytics#", $($reportList | where {$_.name -eq "Campaign Analytics"}).id)
$ht.add("#Location_Analytics#", $($reportList | where {$_.name -eq "Location Analytics"}).id)
$ht.add("#Global_Occupational_Safety_Report#", $($reportList | where {$_.name -eq "Global Occupational Safety Report"}).id)
$ht.add("#Product_Recommendation#", $($reportList | where {$_.name -eq "Product Recommendation"}).id)
$ht.add("#World_Map#", $($reportList | where {$_.name -eq "World Map"}).id)
$ht.add("#Twitter_Sentiment_Analytics#", $($reportList | where {$_.name -eq "Twitter Sentiment Analytics"}).id)
$ht.add("#Acquisition_Impact_Report#", $($reportList | where {$_.name -eq "Acquisition Impact Report"}).id)
$ht.add("#ADX_Thermostat_and_Occupancy#", $($reportList | where {$_.name -eq "ADX Thermostat and Occupancy"}).id)
$ht.add("#Revenue_and_Profiability#", $($reportList | where {$_.name -eq "Revenue and Profiability"}).id)
$ht.add("#ADX_dashboard_8AM#", $($reportList | where {$_.name -eq "ADX dashboard 8AM"}).id)
$ht.add("#Retail_HTAP#", $($reportList | where {$_.name -eq "Retail HTAP"}).id)
$ht.add("#PRODUCT_AI_SEARCH_APP_URL#", $sites_app_product_search_url)
#$ht.add("#SPEECH_REGION#", $rglocation)

$filePath = "./retaildemo-app/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./retaildemo-app/*" -DestinationPath "./retaildemo-app.zip"
Compress-Archive -Path "./app_media_search/*" -DestinationPath "./app_media_search.zip"

az webapp stop --name $app_retaildemo_name --resource-group $rgName
az webapp stop --name $media_search_app_service_name --resource-group $rgName
try{
az webapp deployment source config-zip --resource-group $rgName --name $app_retaildemo_name --src "./retaildemo-app.zip"
}
catch
{
}
try{
az webapp deployment source config-zip --resource-group $rgName --name $media_search_app_service_name --src "./app_media_search.zip"
}
catch
{
}

# IOT FootTraffic
$device_conn_string= $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iothub_foottraffic -DeviceId retail-foottraffic-device).ConnectionString
$shared_access_key = $device_conn_string.Split(";")[2]
$device_primary_key= $shared_access_key.Substring($shared_access_key.IndexOf("=")+1)

$iot_hub_config = '"{\"frequency\":1,\"connection\":{\"provisioning_host\":\"global.azure-devices-provisioning.net\",\"symmetric_key\":\"' + $device_primary_key + '\",\"IoTHubConnectionString\":\"' + $device_conn_string + '\"}}"'

(Get-Content -path app-iotfoottraffic-sensor/.env -Raw) | Foreach-Object { $_ `
     -replace '#DEVICE_PRIMARY_KEY#', $device_primary_key`
     -replace '#DEVICE_CONN_STRING#', $device_conn_string`
 } | Set-Content -Path app-iotfoottraffic-sensor/.env

Write-Information "Deploying IOT FootTraffic Retail App"
cd app-iotfoottraffic-sensor
az webapp up --resource-group $rgName --name $sites_app_iotfoottraffic_sensor_name
cd ..
Start-Sleep -s 10

$config = az webapp config appsettings set -g $rgName -n $sites_app_iotfoottraffic_sensor_name --settings IoTHubConfig=$iot_hub_config

# ADX Thermostat Realtime
$occupancy_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name occupancy --name occupancy | ConvertFrom-Json
$occupancy_endpoint = $occupancy_endpoint.primaryConnectionString
$thermostat_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name thermostat --name thermostat | ConvertFrom-Json
$thermostat_endpoint = $thermostat_endpoint.primaryConnectionString

# (Get-Content -path app-adx-thermostat-realtime/dev.env -Raw) | Foreach-Object { $_ `
#     -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_THERMOSTAT_ENDPOINT#', $thermostat_endpoint`
#     -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_OCCUPANCY_ENDPOINT#', $occupancy_endpoint`
#    -replace '#THERMOSTATTELEMETRY_URL#', $thermostat_telemetry_Realtime_URL`
#    -replace '#OCCUPANCYDATA_URL#', $occupancy_data_Realtime_URL`
# } | Set-Content -Path app-adx-thermostat-realtime/dev.env

(Get-Content -path adx-config-appsetting.json -Raw) | Foreach-Object { $_ `
    -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_THERMOSTAT_ENDPOINT#', $thermostat_endpoint`
    -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_OCCUPANCY_ENDPOINT#', $occupancy_endpoint`
   -replace '#THERMOSTATTELEMETRY_URL#', $thermostat_telemetry_Realtime_URL`
   -replace '#OCCUPANCYDATA_URL#', $occupancy_data_Realtime_URL`
} | Set-Content -Path adx-config-appsetting-with-replacement.json

$config = az webapp config appsettings set -g $rgName -n $sites_adx_thermostat_realtime_name --settings @adx-config-appsetting-with-replacement.json

Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_adx_thermostat_realtime_name -ArchivePath ../artifacts/binaries/app-adx-thermostat-realtime.zip -Force

# Write-Information "Deploying ADX Thermostat Realtime App"
# cd app-adx-thermostat-realtime
# az webapp up --resource-group $rgName --name $sites_adx_thermostat_realtime_name
# cd ..
# Start-Sleep -s 10

$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $search_srch_retail_name
$primaryAdminKey = $adminKeyPair.Primary

# Product Seach Function App adn WebApp deployment
Write-Information "Deploying Product Seach Function App"
try{
az functionapp create --resource-group $rgName --consumption-plan-location $rglocation --runtime node --runtime-version 16 --functions-version 4 --name $func_product_search_name --storage-account $dataLakeAccountName
}
catch
{
az functionapp create --resource-group $rgName --consumption-plan-location $rglocation --runtime node --runtime-version 16 --functions-version 4 --name $func_product_search_name --storage-account $dataLakeAccountName
}
Start-Sleep -s 30

$config = az webapp config appsettings set -g $rgName -n $func_product_search_name --settings SearchApiKey=$primaryAdminKey
$config = az webapp config appsettings set -g $rgName -n $func_product_search_name --settings SearchFacets="category1, category2, category3"
$config = az webapp config appsettings set -g $rgName -n $func_product_search_name --settings SearchIndexName="fabrikam-fashion"
$config = az webapp config appsettings set -g $rgName -n $func_product_search_name --settings SearchServiceName=$search_srch_retail_name

az functionapp cors add -g $rgName -n $func_product_search_name  --allowed-origins "*"

az webapp stop --name $func_product_search_name --resource-group $rgName 
az functionapp deployment source config-zip -g $rgName -n $func_product_search_name --src "./artifacts/binaries/product-search-func-app.zip"
az webapp start --name $func_product_search_name --resource-group $rgName 

(Get-Content -path app-product-search/config-prod.js -Raw) | Foreach-Object { $_ `
    -replace '#FUNCTION_PRODUCT_SEARCH#', $func_product_search_name`
    -replace '#BOT_NAME#', $bot_qnamaker_retail_name`
    -replace '#BOT_KEY#', $bot_key`
} | Set-Content -Path app-product-search/config-prod.js

Write-Information "Deploying Product Seach Web App"
cd app-product-search
az webapp up --resource-group $rgName --name $sites_app_product_search --html;
cd ..
Start-Sleep -s 10

RefreshTokens

az webapp restart --name $functionapplivestreaming --resource-group $rgName 
az webapp start --name $func_product_search_name --resource-group $rgName 
az webapp start  --name $app_retaildemo_name --resource-group $rgName
az webapp start --name $media_search_app_service_name --resource-group $rgName
az webapp start  --name $sites_app_iotfoottraffic_sensor_name --resource-group $rgName
az webapp start --name $sites_adx_thermostat_realtime_name --resource-group $rgName
az webapp start --name $sites_app_product_search --resource-group $rgName

foreach($zip in $zips)
{
    if ($zip -eq  "immersive-reader-app"  -or $zip -eq  "retaildemo-app" ) 
    {
        remove-item -path "./$($zip).zip" -recurse -force
    }
    if ($zip -eq "retaildemo-app" ) 
    {
        continue;
    }
    remove-item -path "./$($zip)" -recurse -force
}

#start ASA
Write-Host "----Starting ASA-----"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_retail -OutputStartMode 'JobStartTime'
