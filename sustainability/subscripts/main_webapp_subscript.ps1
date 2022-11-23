
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
$rglocation = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$deploymentId = $init
$concatString = "$init$random"
$dataLakeAccountName = "stsustain$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$app_sustainabilitydemo_name = "sustainabilitydemo-app-$suffix";
$tenantId = (Get-AzContext).Tenant.Id

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#Web app
Write-Host  "-----------------Deploy web app ---------------"
RefreshTokens

expand-archive -path "../artifacts/binaries/app-sustainabilitydemo" -destinationpath "./app-sustainabilitydemo" -force

$spname="Sustainability Demo $deploymentId"

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

(Get-Content -path app-sustainabilitydemo/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path app-sustainabilitydemo/appsettings.json

$filepath="./app-sustainabilitydemo/wwwroot/config-poc.js"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName).Replace("#SERVER_NAME#", $app_sustainabilitydemo_name)
Set-Content -Path $filepath -Value $item

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
$reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$reportList = $reportList.Value
#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable   
$ht.add("#NYC_AQI#", $($reportList | where {$_.name -eq "NYC_AQI"}).id)
$ht.add("#Transport_Deep_Dive#", $($reportList | where {$_.name -eq "Transport Deep Dive"}).id)
$ht.add("#Budget_dashboard#", $($reportList | where {$_.name -eq "Budget dashboard"}).id)
$ht.add("#Demand_and_Bus_Frequency#", $($reportList | where {$_.name -eq "Demand and Bus Frequency"}).id)
# $ht.add("#Campaign_Analytics_Deep_Dive#", $($reportList | where {$_.name -eq "Fleet Manager Dashboard"}).id)
# $ht.add("#Campaign_Analytics#", $($reportList | where {$_.name -eq "Master Images"}).id)
# $ht.add("#Location_Analytics#", $($reportList | where {$_.name -eq "Mayor Dashboard"}).id)
# $ht.add("#Product_Recommendation#", $($reportList | where {$_.name -eq "Power Management"}).id)
# $ht.add("#World_Map#", $($reportList | where {$_.name -eq "Realtime Air Quality Report Static"}).id)
# $ht.add("#Twitter_Sentiment_Analytics#", $($reportList | where {$_.name -eq "Transportation Head Dashboard"}).id)
# $ht.add("#Acquisition_Impact_Report#", $($reportList | where {$_.name -eq "Twitter Report Static"}).id)

$filePath = "./app-sustainabilitydemo/wwwroot/config-poc.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./app-sustainabilitydemo/*" -DestinationPath "./app-sustainabilitydemo.zip"

az webapp stop --name $app_sustainabilitydemo_name --resource-group $rgName
try{
az webapp deployment source config-zip --resource-group $rgName --name $app_sustainabilitydemo_name --src "./app-sustainabilitydemo.zip"
}
catch
{
}

az webapp start  --name $app_sustainabilitydemo_name --resource-group $rgName
