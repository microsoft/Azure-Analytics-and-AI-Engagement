
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
$app_immersive_reader_fintax_name = "immersive-reader-fintax-app-$suffix";
$app_fintaxdemo_name = "fintaxdemo-app-$suffix";
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$CurrentTime = Get-Date
$AADAppClientSecretExpiration = $CurrentTime.AddDays(365)
$media_search_app_service_name = "app-media-search-$suffix"
$bot_qnamaker_retail_name= "botmultilingual-$suffix"
$app_retaildemo_name = "retaildemo-app-$suffix";

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#Web app
Write-Host  "-----------------Deploy web app ---------------"
RefreshTokens

expand-archive -path "../artifacts/binaries/retaildemo-app.zip" -destinationpath "./retaildemo-app" -force

$spname="Retail Demo $deploymentId"
$clientsecpwd ="Smoothie@Smoothie@2020"

$appId = az ad app create --password $clientsecpwd --end-date $AADAppClientSecretExpiration --display-name $spname --query "appId" -o tsv
          
az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "objectId" -o tsv
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
				
(Get-Content -path retaildemo-app/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path retaildemo-app/appsettings.json

$filepath="./retaildemo-app/wwwroot/config.js"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName).Replace("#SERVER_NAME#", $app_retaildemo_name).Replace("#SEARCH_APP_NAME#", $media_search_app_service_name)
Set-Content -Path $filepath -Value $item
   
#bot qna maker
$bot_detail = az bot webchat show --name $bot_qnamaker_retail_name --resource-group $rgName --with-secrets true | ConvertFrom-Json
$bot_key = $bot_detail.properties.properties.sites[0].key

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
$reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$reportList = $reportList.Value

#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable   
$ht.add("#Bing_Map_Key#", "AhBNZSn-fKVSNUE5xYFbW_qajVAZwWYc8OoSHlH8nmchGuDI6ykzYjrtbwuNSrR8")
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
#$ht.add("#SPEECH_REGION#", $rglocation)

$filePath = "./retaildemo-app/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./retaildemo-app/*" -DestinationPath "./retaildemo-app.zip"

az webapp stop --name $app_retaildemo_name --resource-group $rgName

try{
    az webapp deployment source config-zip --resource-group $rgName --name $app_retaildemo_name --src "./retaildemo-app.zip"
    }
    catch
    {
    }
    
az webapp start  --name $app_retaildemo_name --resource-group $rgName

