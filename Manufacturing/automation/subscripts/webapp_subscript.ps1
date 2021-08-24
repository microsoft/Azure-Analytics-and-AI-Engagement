function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
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
$deploymentId = $init
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$suffix = "$random-$init"
$concatString = "$init$random"
$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))
$searchName = "search-$suffix";
$searchKey = $(az search admin-key show --resource-group $rgName --service-name $searchName | ConvertFrom-Json).primarykey;

$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText

$manufacturing_poc_app_service_name = "manufacturing-poc-$suffix"
$wideworldimporters_app_service_name = "wideworldimporters-$suffix"

RefreshTokens

Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------deploy poc web app ---------------"

$app = Get-AzADApplication -DisplayName "Mfg Demo $deploymentid"
$secretpassword="Smoothie@Smoothie@2020"
$secret = ConvertTo-SecureString -String $secretpassword -AsPlainText -Force

if (!$app)
{
    $app = New-AzADApplication -DisplayName "Mfg Demo $deploymentId" -IdentifierUris "http://fabmedical-sp-$deploymentId" -Password $secret;
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

(Get-Content -path mfg-webapp/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $secretpassword`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path mfg-webapp/appsettings.json
(Get-Content -path mfg-webapp/wwwroot/config.js -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`
				-replace '#SERVER_NAME#', $manufacturing_poc_app_service_name`
				-replace '#WWI_SITE_NAME#', $wideworldimporters_app_service_name`				
        } | Set-Content -Path mfg-webapp/wwwroot/config.js	

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
$reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$reportList = $reportList.Value

        #update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable
$ht.add("#REPORT_SQL_DASHBOARD_BEFORE_ID#", $($reportList | where {$_.name -eq "1_Billion rows demo"}).id)
$ht.add("#REPORT_SQL_DASHBOARD_DURING_ID#", $($reportList | where {$_.name -eq "3_MFG Dynamic Data Masking (Azure Synapse)"}).id)
$ht.add("#REPORT_SQL_DASHBOARD_AFTER_ID#", $($reportList | where {$_.name -eq "4_MFG Column Level Security (Azure Synapse)"}).id)
$ht.add("#REPORT_DASHBOARD_AFTER_ID#", $($reportList | where {$_.name -eq "5_MFG Row Level Security (Azure Synapse)"}).id)
$ht.add("#REPORT_ANOMALY_ID#", $($reportList | where {$_.name -eq "anomaly detection with images"}).id)
$ht.add("#REPORT_CAMPAIGN_ID#", $($reportList | where {$_.name -eq "Campaign - Option C"}).id)
$ht.add("#REPORT_FACTORY_ID#", $($reportList | where {$_.name -eq "Factory-Overview - Option A"}).id)
$ht.add("#REPORT_FINANCE_ID#", $($reportList | where {$_.name -eq "1_Billion rows demo"}).id)
$ht.add("#REPORT_GLOBALBING_ID#", $($reportList | where {$_.name -eq "VP-Global-Overview"}).id)
$ht.add("#REPORT_SAFETY_ID#", $($reportList | where {$_.name -eq "Factory-Overview - Option A"}).id)
$ht.add("#REPORT_MACHINE_ID#", $($reportList | where {$_.name -eq "Equipment View Report"}).id)
$ht.add("#REPORT_MACHINE_ANOMOLY_ID#", $($reportList | where {$_.name -eq "anomaly detection with images"}).id)
$ht.add("#REPORT_HTAP_ID#", $($reportList | where {$_.name -eq "6_Production Quality- HTAP Synapse Link"}).id)
$ht.add("#REPORT_SALES_CAMPAIGN_ID#", $($reportList | where {$_.name -eq "Campaign Sales Operations"}).id)
$ht.add("#WWI_SITE_NAME#", $wideworldimporters_app_service_name)
$ht.add("#STORAGE_ACCOUNT#", $dataLakeAccountName)
$ht.add("#WORKSPACE_ID#", $wsId)
$ht.add("#APP_ID#", $appId)
$ht.add("#APP_SECRET#", $sqlPassword)
$ht.add("#TENANT_ID#", $tenantId)
$ht.add("#SEARCH_QUERY_KEY#", $searchKey)
$ht.add("#SEARCH_SERVICE#", $searchName)


$filePath = "./mfg-webapp/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)


Compress-Archive -Path "./mfg-webapp/*" -DestinationPath "./mfg-webapp.zip"

az webapp stop --name $manufacturing_poc_app_service_name --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $manufacturing_poc_app_service_name --src "./mfg-webapp.zip"
az webapp start --name $manufacturing_poc_app_service_name --resource-group $rgName

foreach($zip in $zips)
{
	if($zip -eq "mfg-webapp")
	{
    remove-item -path "./$($zip)" -recurse -force
    remove-item -path "./$($zip).zip" -recurse -force
	}
}
