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
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$deploymentId = $init
$suffix = "$random-$init"
$concatString = "$init$random"
$keyVaultName = "kv-$suffix";
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$vi_account_id = (Get-AzResourceGroup -Name $rgName).Tags["VideoIndexerAccountId"]
$vi_account_key = (Get-AzResourceGroup -Name $rgName).Tags["VideoIndexerApiKey"]
$vi_location = "trial"
$media_poc_app_service_name = "app-demomedia-$suffix"
$media_search_app_service_name = "app-media-search-$suffix"
$functionapplivestreaming="func-app-media-livestreaming-$suffix"
$functionapprecommender="func-app-media-recommendation-$suffix"
$functionappmodelbuilder="func-app-model-builder-$suffix"
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

#function apps
Add-Content log.txt "-----function apps zip deploy-------"
Write-Host  "--------------function apps zip deploy---------------"
RefreshTokens
$zips = @("recommender","model_builder","app_media_search","demomedia_web_app")
foreach($zip in $zips)
{
    expand-archive -path "../artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

az webapp stop --name $functionapplivestreaming --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $functionapplivestreaming --src "../artifacts/binaries/func_media_livestreaming.zip"	
az webapp start --name $functionapplivestreaming --resource-group $rgName

Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------deploy poc web app ---------------"
RefreshTokens
$spname="Media Demo $deploymentid"
$app = Get-AzADApplication -DisplayName $spname
$clientsecpwd ="Smoothie@Smoothie@2020"
$secret = ConvertTo-SecureString -String $clientsecpwd -AsPlainText -Force

if (!$app)
{
    $app = New-AzADApplication -DisplayName $spname -IdentifierUris "http://fabmedical-sp-$deploymentId" -Password $secret;
}

$appId = $app.ApplicationId;
$objectId = $app.ObjectId;

$sp = Get-AzADServicePrincipal -ApplicationId $appId;

if (!$sp)
{
    $sp = New-AzADServicePrincipal -ApplicationId $appId -DisplayName "http://fabmedical-sp-$deploymentId" -Scope "/subscriptions/$subscriptionId" -Role "Admin";
}

#https://docs.microsoft.com/en-us/power-bi/developer/embedded/embed-service-principal
#Allow service principals to user PowerBI APIS must be enabled - https://app.powerbi.com/admin-portal/tenantSettings?language=en-U
#add PowerBI App to workspace as an admin to group
$url = "https://api.powerbi.com/v1.0/myorg/groups";
$result = Invoke-WebRequest -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
$homeCluster = $result.Headers["home-cluster-uri"]
#$homeCluser = "https://wabi-west-us-redirect.analysis.windows.net";

$url = "$homeCluster/metadata/tenantsettings"
$post = "{`"featureSwitches`":[{`"switchId`":306,`"switchName`":`"ServicePrincipalAccess`",`"isEnabled`":true,`"isGranular`":true,`"allowedSecurityGroups`":[],`"deniedSecurityGroups`":[]}],`"properties`":[{`"tenantSettingName`":`"ServicePrincipalAccess`",`"properties`":{`"HideServicePrincipalsNotification`":`"false`"}}]}"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $powerbiToken")
$headers.Add("X-PowerBI-User-Admin", "true")
#$result = Invoke-RestMethod -Uri $url -Method PUT -body $post -ContentType "application/json" -Headers $headers -ea SilentlyContinue;

#add PowerBI App to workspace as an admin to group
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/users";
$post = "{
    `"identifier`":`"$($sp.Id)`",
    `"groupUserAccessRight`":`"Admin`",
    `"principalType`":`"App`"
    }";

$result = Invoke-RestMethod -Uri $url -Method POST -body $post -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;

#get the power bi app...
$powerBIApp = Get-AzADServicePrincipal -DisplayNameBeginsWith "Power BI Service"
$powerBiAppId = $powerBIApp.Id;

#setup powerBI app...
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
		
(Get-Content -path demomedia_web_app/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`
        } | Set-Content -Path demomedia_web_app/appsettings.json
(Get-Content -path demomedia_web_app/wwwroot/config.js -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`
				-replace '#SERVER_NAME#', $media_poc_app_service_name`
				-replace '#SEARCH_APP_NAME#', $media_search_app_service_name`
        } | Set-Content -Path demomedia_web_app/wwwroot/config.js	

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
$reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$reportList = $reportList.Value

    #update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable
$ht.add("#STORAGE_ACCOUNT#", $dataLakeAccountName)
$ht.add("#WORKSPACE_ID#", $wsId)
$ht.add("#APP_ID#", $appId)
$ht.add("#APP_SECRET#", $sqlPassword)
$ht.add("#TENANT_ID#", $tenantId)
$ht.add("#MEDIA_KEYWORD_REPORT#", $($reportList | where {$_.name -eq "Audience Analytics"}).id)
$ht.add("#MEDIA_BRAND_REPORT#", $($reportList | where {$_.name -eq "Finance Report"}).id)
$ht.add("#TWITTER_REPORT#", $($reportList | where {$_.name -eq "Realtime Twitter Analytics"}).id)
$ht.add("#REVENUE_REPORT#", $($reportList | where {$_.name -eq "Video Revenue Analytics"}).id)
$ht.add("#REALTIME_ANALYTICS_REPORT#", $($reportList | where {$_.name -eq "Realtime Operational Analytics Static"}).id)


$filePath = "../demomedia_web_app/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "../demomedia_web_app/*" -DestinationPath "../demomedia_web_app.zip"
Compress-Archive -Path "../app_media_search/*" -DestinationPath "../app_media_search.zip"

az webapp stop --name $media_poc_app_service_name --resource-group $rgName
az webapp stop --name $media_search_app_service_name --resource-group $rgName
try{
az webapp deployment source config-zip --resource-group $rgName --name $media_poc_app_service_name --src "../demomedia_web_app.zip"
}
catch
{
}
try{
az webapp deployment source config-zip --resource-group $rgName --name $media_search_app_service_name --src "../app_media_search.zip"
}
catch
{
}
az webapp start --name $media_search_app_service_name --resource-group $rgName
az webapp start --name $media_poc_app_service_name --resource-group $rgName


Add-Content log.txt "-----python function apps zip deploy-------"
Write-Host "----python function apps zip deploy------"

cd recommender
az webapp up --resource-group $rgName --name $functionapprecommender
cd ..
Start-Sleep -s 30
az functionapp deployment source config-zip --resource-group $rgName --name $functionapprecommender --src "../artifacts/binaries/recommender.zip" --build-remote true
Start-Sleep -s 30
az webapp start  --name $functionapprecommender --resource-group $rgName

cd model_builder
az webapp up --resource-group $rgName --name $functionappmodelbuilder
cd ..
Start-Sleep -s 30
az functionapp deployment source config-zip --resource-group $rgName --name $functionappmodelbuilder --src "../artifacts/binaries/model_builder.zip" --build-remote true
Start-Sleep -s 30
$vi_indexer_url = "https://api.videoindexer.ai/"+$vi_location+"/Accounts/"+$vi_account_id+"/Videos/{}/Index?reTranslate=False&includeStreamingUrls=True"
Update-AzFunctionAppSetting -Name $functionappmodelbuilder -ResourceGroupName $rgName -AppSetting @{"VIDEO_INDEXER_URL" = "$($vi_indexer_url)"}


az webapp start  --name $functionappmodelbuilder --resource-group $rgName

az webapp restart --name $functionapplivestreaming --resource-group $rgName  
az webapp restart --name $functionappmodelbuilder --resource-group $rgName 
az webapp restart --name $functionapprecommender --resource-group $rgName 

Add-Content log.txt "-----------------Execution Complete---------------"
Write-Host  "-----------------Execution Complete----------------"
