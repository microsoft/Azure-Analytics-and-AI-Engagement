
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
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$deploymentId = $init
$concatString = "$init$random"
$dataLakeAccountName = "stfintax$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

$bot_qnamaker_fintax_name= "botmultilingual-$suffix";
$accounts_immersive_reader_fintax_name = "immersive-reader-fintax-$suffix";
$app_immersive_reader_fintax_name = "immersive-reader-fintax-app-$suffix";
$app_fintaxdemo_name = "fintaxdemo-app-$suffix";
$iot_hub_name = "iothub-fintax-$suffix";
$sites_app_multiling_fintax_name = "multiling-fintax-app-$suffix";
$asp_multiling_fintax_name = "multiling-fintax-asp-$suffix";
$sites_app_taxcollection_realtime_name = "taxcollectionrealtime-fintax-app-$suffix";
$sites_app_vat_custsat_eventhub_name = "vat-custsat-eventhub-fintax-app-$suffix";
$sites_app_iotfoottraffic_sensor_name = "iot-foottraffic-sensor-fintax-app-$suffix";
$storageAccountName = $dataLakeAccountName
$asa_name_fintax = "fintaxasa-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$AADApp_Immnersive_DisplayName = "FintaxImmersiveReader-$suffix"
$CurrentTime = Get-Date
$AADAppClientSecretExpiration = $CurrentTime.AddDays(365)
$AADAppClientSecret = "Smoothie@2021@2021"
$AADApp_Multiling_DisplayName = "FintaxMultiling-$suffix"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#Web app
Write-Host  "-----------------Deploy web apps ---------------"
RefreshTokens

#########################

Add-Content log.txt "----Bot and multilingual App-----"
Write-Host "----Bot and multilingual App----"

$app = az ad app create --display-name $sites_app_multiling_fintax_name --password "Smoothie@2021@2021" --available-to-other-tenants | ConvertFrom-Json
$appId = $app.appId

az deployment group create --resource-group $rgName --template-file "../artifacts/qnamaker/bot-multiling-template.json" --parameters appId=$appId appSecret=$AADAppClientSecret botId=$bot_qnamaker_fintax_name newWebAppName=$sites_app_multiling_fintax_name newAppServicePlanName=$asp_multiling_fintax_name appServicePlanLocation=$location

az webapp deployment source config-zip --resource-group $rgName --name $sites_app_multiling_fintax_name --src "../artifacts/qnamaker/chatbot.zip"

#################

$zips = @("immersive-reader-app","app-iotfoottraffic-sensor", "app-taxcollection-realtime", "app-vat-custsat-eventhub")
foreach($zip in $zips)
{
    expand-archive -path "../artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}


############
Add-Content log.txt "----Immersive Reader----"
Write-Host "----Immersive Reader-----"
#immersive reader
$resourceId = az cognitiveservices account show --resource-group $rgName --name $accounts_immersive_reader_fintax_name --query "id" -o tsv    
    
$clientId = az ad app create --password $AADAppClientSecret --end-date $AADAppClientSecretExpiration --display-name $AADApp_Immnersive_DisplayName --query "appId" -o tsv
             
az ad sp create --id $clientId | Out-Null    
$principalId = az ad sp show --id $clientId --query "objectId" -o tsv
        
az role assignment create --assignee $principalId --scope $resourceId --role "Cognitive Services User"    
   
$tenantId = az account show --query "tenantId" -o tsv

# Collect the information needed to obtain an Azure AD token into one object    
$immersive_properties = @{}    
$immersive_properties.TenantId = $tenantId    
$immersive_properties.ClientId = $clientId    
$immersive_properties.ClientSecret = $AADAppClientSecret    
$immersive_properties.Subdomain = $accounts_immersive_reader_fintax_name
$immersive_properties.PrincipalId = $principalId
$immersive_properties.ResourceId = $resourceId

(Get-Content -path immersive-reader-app/appsettings.json -Raw) | Foreach-Object { $_ `
    -replace '#CLIENT_ID#', $immersive_properties.ClientId`
    -replace '#CLIENT_SECRET#', $immersive_properties.ClientSecret`
    -replace '#TENANT_ID#', $immersive_properties.TenantId`
    -replace '#SUBDOMIAN#', $immersive_properties.Subdomain`
} | Set-Content -Path immersive-reader-app/appsettings.json
Compress-Archive -Path "./immersive-reader-app/*" -DestinationPath "./immersive-reader-app.zip"
# deploy the codes on app services  
Write-Information "Deploying immersive reader app"
try{
    az webapp deployment source config-zip --resource-group $rgName --name $app_immersive_reader_fintax_name --src "./immersive-reader-app.zip"
}
catch
{
}

# IOT FootTraffic
$device_conn_string= $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub_name -DeviceId trf-foottraffic-device).ConnectionString
$shared_access_key = $device_conn_string.Split(";")[2]
$device_primary_key= $shared_access_key.Substring($shared_access_key.IndexOf("=")+1)

$iot_hub_config = '"{\"frequency\":1,\"connection\":{\"provisioning_host\":\"global.azure-devices-provisioning.net\",\"symmetric_key\":\"' + $device_primary_key + '\",\"IoTHubConnectionString\":\"' + $device_conn_string + '\"}}"'

Write-Information "Deploying IOT FootTraffic Fintax App"
cd app-iotfoottraffic-sensor
az webapp up --resource-group $rgName --name $sites_app_iotfoottraffic_sensor_name
cd ..
Start-Sleep -s 10

$config = az webapp config appsettings set -g $rgName -n $sites_app_iotfoottraffic_sensor_name --settings IoTHubConfig=$iot_hub_config

# Tax Collection Realtime Fintax App
Write-Information "Deploying Tax Collection Realtime Fintax App"
cd app-taxcollection-realtime
az webapp up --resource-group $rgName --name $sites_app_taxcollection_realtime_name
cd ..
Start-Sleep -s 10

# Vat Custsat Eventhub 
Write-Information "Deploying Vat Custsat Eventhub Fintax App"
cd app-vat-custsat-eventhub
az webapp up --resource-group $rgName --name $sites_app_vat_custsat_eventhub_name
cd ..
Start-Sleep -s 10

RefreshTokens

az webapp start --name $app_immersive_reader_fintax_name --resource-group $rgName
az webapp start --name $sites_app_multiling_fintax_name --resource-group $rgName
az webapp start  --name $sites_app_iotfoottraffic_sensor_name --resource-group $rgName
az webapp start --name $sites_app_taxcollection_realtime_name --resource-group $rgName
az webapp start --name $sites_app_vat_custsat_eventhub_name --resource-group $rgName

foreach($zip in $zips)
{
    if ($zip -eq  "immersive-reader-app" ) 
    {
        remove-item -path "./$($zip).zip" -recurse -force
    }
    remove-item -path "./$($zip)" -recurse -force
}

#start ASA
Write-Host "----Starting ASA-----"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_fintax -OutputStartMode 'JobStartTime'

Write-Host  "Click the following URL-  https://$($sites_app_iotfoottraffic_sensor_name).azurewebsites.net"
Write-Host  "Click the following URL-  https://$($sites_app_taxcollection_realtime_name).azurewebsites.net"
Write-Host  "Click the following URL-  https://$($sites_app_vat_custsat_eventhub_name).azurewebsites.net"

Write-Host "Please ask your admin to execute the following command for proper execution of Immersive Reader : "

Write-Host 'az role assignment create --assignee' $immersive_properties.PrincipalId '--scope' $immersive_properties.ResourceId '--role "Cognitive Services User"'   

