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

$rgName = read-host "Enter the resource Group Name";
$id_scope = read-host "Enter the ID scope from IoT Central Device";
$registration_id = read-host "Enter the Device ID from IoT Central Device";
$symmetric_key = read-host "Enter the Primary key from IoT Central Device";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$deploymentId = $init
$subscriptionId = (Get-AzContext).Subscription.Id
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$tenantId = (Get-AzContext).Tenant.Id
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$PbiDatasetUrl = (Get-AzResourceGroup -Name $rgName).Tags["PbiDatasetUrl"]
$suffix = "$random-$init"
$keyVaultName = "kv-$init";
$app_name_demohealthcare = "app-demohealthcare-$suffix"
$healthcare_poc_app_service_name = $app_name_demohealthcare
$searchName = "srch-healthcaredemo-$suffix";
$searchKey = $(az search admin-key show --resource-group $rgName --service-name $searchName | ConvertFrom-Json).primarykey;
$functionappIomt="func-app-iomt-processor-$suffix"
$functionappMongoData = "func-app-mongo-data-$suffix"
$app_name_iomt_simulator = "app-iomt-simulator-$suffix"
$synapseWorkspaceName = "synapsehealthcare$init$random"
$CurrentTime = Get-Date
$AADAppClientSecretExpiration = $CurrentTime.AddDays(365)
$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
$userName = ((az ad signed-in-user show --output json) | ConvertFrom-Json).UserPrincipalName
Write-Host "Setting Key Vault Access Policy"
#Import-Module Az.KeyVault
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,get,list
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

#$sqlPassword = $(Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword").SecretValueText
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText

Write-Host  "-----------------deploy poc web app ---------------"
RefreshTokens
$spname="Healthcare Demo $deploymentId"
$clientsecpwd ="Smoothie@Smoothie@2020"

$appId = az ad app create --password $clientsecpwd --end-date $AADAppClientSecretExpiration --display-name $spname --query "appId" -o tsv
          
az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "objectId" -o tsv
start-sleep -s 60

#https://docs.microsoft.com/en-us/power-bi/developer/embedded/embed-service-principal
#Allow service principals to user PowerBI APIS must be enabled - https://app.powerbi.com/admin-portal/tenantSettings?language=en-U
RefreshTokens
#add PowerBI App to workspace as an admin to group
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

RefreshTokens
#add PowerBI App to workspace as an admin to group
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

RefreshTokens
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

RefreshTokens
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

$zips = @("iomt_simulator","demohealthcare_web_app")
foreach($zip in $zips)
{
    expand-archive -path "../artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

(Get-Content -path demohealthcare_web_app/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`
        } | Set-Content -Path demohealthcare_web_app/appsettings.json
(Get-Content -path demohealthcare_web_app/wwwroot/config.js -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`
				-replace '#SERVER_NAME#', $healthcare_poc_app_service_name`
        } | Set-Content -Path demohealthcare_web_app/wwwroot/config.js	

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
$ht.add("#SEARCH_QUERY_KEY#", $searchKey)
$ht.add("#SEARCH_SERVICE#", $searchName)
$ht.add("#HEALTHCARE_TERM_INDEX#", $($reportList | where {$_.name -eq "healthcare term index"}).id)
$ht.add("#CONSOLIDATED_REPORT#", $($reportList | where {$_.name -eq "Consolidated Report"}).id)
$ht.add("#MIAMI_HOSPITAL_OVERVIEW#", $($reportList | where {$_.name -eq "Miami hospital overview"}).id)
$ht.add("#GLOBAL_OVERVIEW_TILES#", $($reportList | where {$_.name -eq "Global overview tiles"}).id)
$ht.add("#HTAP_LAB_DATA#", $($reportList | where {$_.name -eq "HTAP-Lab-Data"}).id)
$ht.add("#CT_SCAN_ANOMALY_DETECTION_REPORT#", $($reportList | where {$_.name -eq "CT Scan Anomaly Detection Report"}).id)
$ht.add("#US_MAP_WITH_HEADER#", $($reportList | where {$_.name -eq "US Map with header"}).id)
$ht.add("#HEALTHCARE_PREDCTIVE_ANALYTICS_V1#", $($reportList | where {$_.name -eq "HealthCare Predctive Analytics_V1"}).id)

$filePath = "./demohealthcare_web_app/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./demohealthcare_web_app/*" -DestinationPath "./demohealthcare_web_app.zip"

az webapp stop --name $healthcare_poc_app_service_name --resource-group $rgName
try{
az webapp deployment source config-zip --resource-group $rgName --name $healthcare_poc_app_service_name --src "./demohealthcare_web_app.zip"
}
catch
{
}

az webapp start --name $healthcare_poc_app_service_name --resource-group $rgName

Write-Host  "-----------------Deploying iomt data gen web app--------------"
RefreshTokens

#Replace connection string in config
(Get-Content -path ./iomt_simulator/configMain.json -Raw) | Foreach-Object { $_ `
                -replace '#ID_SCOPE#', $id_scope`
                -replace '#DEVICE_KEY#', $symmetric_key`
				-replace '#DEVICE_ID#', $registration_id`
} | Set-Content -Path ./iomt_simulator/configMain.json

(Get-Content -path ./iomt_simulator/config.json -Raw) | Foreach-Object { $_ `
				-replace '#POWERBI_STREAMING_DATASET_URL#', $PbiDatasetUrl`
} | Set-Content -Path ./iomt_simulator/config.json

# deploy the codes on app services  
Write-Information "Deploying web app"
cd iomt_simulator
az webapp up --resource-group $rgName --name $app_name_iomt_simulator
cd ..
Start-Sleep -s 10
az webapp start  --name $app_name_iomt_simulator --resource-group $rgName

foreach($zip in $zips)
{
	if($zip -eq "demohealthcare_web_app")
	{
    remove-item -path "./$($zip).zip" -recurse -force
	}
    remove-item -path "./$($zip)" -recurse -force
}

#function apps
Write-Host "----function apps zip deploy------"

az webapp stop --name $functionappMongoData --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $functionappMongoData --src "../artifacts/binaries/mongo_data.zip"	
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$Storage_CS = "DefaultEndpointsProtocol=https;AccountName=" + $dataLakeAccountName + ";AccountKey="+ $storage_account_key + ";EndpointSuffix=core.windows.net"
Update-AzFunctionAppSetting -Name $functionappMongoData -ResourceGroupName $rgName -AppSetting @{"STORAGE_CONNECTION_STRING" = "$($Storage_CS)"}
az webapp start --name $functionappMongoData --resource-group $rgName

az webapp stop --name $functionappIomt --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $functionappIomt --src "../artifacts/binaries/iomt_function_app.zip"	
az webapp start --name $functionappIomt --resource-group $rgName

az webapp restart --name $functionappMongoData --resource-group $rgName
az webapp restart --name $functionappIomt --resource-group $rgName  

$FunctionURL = "https://" + $app_name_iomt_simulator+ ".azurewebsites.net/"
try{
Invoke-RestMethod $FunctionURL -Method GET -Headers @{}
}
catch
{
Write-Host "Please click this URL : " $FunctionURL
}

Write-Host  "-----------------Execution Complete----------------"
