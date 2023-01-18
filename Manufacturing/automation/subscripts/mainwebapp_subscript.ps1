function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api --output json) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net --output json) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com --output json) | ConvertFrom-Json).accessToken
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

#getting user details

$response=az ad signed-in-user show | ConvertFrom-Json
$date=get-date
$demoType="Manufacturing"
$body= '{"demoType":"#demoType#","userPrincipalName":"#userPrincipalName#","displayName":"#displayName#","companyName":"#companyName#","mail":"#mail#","date":"#date#"}'
$body = $body.Replace("#userPrincipalName#", $response.userPrincipalName)
$body = $body.Replace("#displayName#", $response.displayName)
$body = $body.Replace("#companyName#", $response.companyName)
$body = $body.Replace("#mail#", $response.mail)
$body = $body.Replace("#date#", $date)
$body = $body.Replace("#demoType#", $demoType)

$uri ="https://registerddibuser.azurewebsites.net/api/registeruser?code=pTrmFDqp25iVSxrJ/ykJ5l0xeTOg5nxio9MjZedaXwiEH8oh3NeqMg=="
$result = Invoke-RestMethod  -Uri $uri -Method POST -Body $body -Headers @{} -ContentType "application/json"

#User Inputs
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$deploymentId = $init

$rglocation = (Get-AzResourceGroup -Name $rgName).Location
$manufacturing_poc_app_service_name = "manufacturing-poc-$suffix"
$synapseWorkspaceName = "manufacturingdemo$init$random"
$sqlPoolName = "ManufacturingDW"
$concatString = "$init$random"
$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))

$concatString = "$random$init"
$cosmos_account_name_mfgdemo = "cosmosdb-mfgdemo-$random$init"
$manufacturing_poc_app_service_name = "manufacturing-poc-$suffix"
$wideworldimporters_app_service_name = "wideworldimporters-$suffix"
$searchName = "search-$suffix";
$keyVaultName = "kv-$init";
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$userName = ((az ad signed-in-user show --output json) | ConvertFrom-Json).UserPrincipalName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$searchKey = $(az search admin-key show --resource-group $rgName --service-name $searchName  --output json | ConvertFrom-Json).primarykey;

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

#$sqlPassword = $(Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword").SecretValueText
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#uploading powerbi reports
RefreshTokens

Add-Content log.txt "------powerbi reports upload------"
Write-Host "-----------------powerbi reports upload ---------------"
Write-Host "Uploading power BI reports"
#Connect-PowerBIServiceAccount
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
        @{Name = "SourceServer"; Expression = {"manufacturingdemo.sql.azuresynapse.net"}}, 
        @{Name = "SourceDatabase"; Expression = {"ManufacturingDW"}}
		                        
        # get dataset                         
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets";
        $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
		
        Add-Content log.txt $dataSets
        
        $temp.ReportId = $reportId;

        foreach($res in $dataSets.value)
        {
            if($res.name -eq $name.BaseName)
            {
                $temp.PowerBIDataSetId = $res.id;
            }
       }
                
       $reportList.Add($temp)
}
Start-Sleep -s 60

RefreshTokens
#Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "--------- pbi connections update---------"	
$powerBIDataSetConnectionTemplate = Get-Content -Path "../artifacts/templates/powerbi_dataset_connection.json"

#$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "HelloWorld.sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String
$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "$($synapseWorkspaceName).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String

$sourceServers = @("manufacturingdemor16gxwbbra4mtbmu.sql.azuresynapse.net", "manufacturingdemo.sql.azuresynapse.net", "dreamdemosynapse.sql.azuresynapse.net","manufacturingdemocjgnpnq4eqzbflgi.sql.azuresynapse.net", "manufacturingdemodemocwbennanrpo5s.sql.azuresynapse.net", "HelloWorld.sql.azuresynapse.net","manufacturingdemosep5n2tdtctkwpyjc.sql.azuresynapse.net")

foreach($report in $reportList)
{

    #skip some...cosmos or nothing to update.
    #campaign sales operations = COSMOS
    #Azure Cognitive Search = AZURE TABLE
    #anomaly detection with images = AZURE TABLE
    if ($report.Name -eq "sample_test" -or $report.Name -eq "Azure Cognitive Search" -or $report.Name -eq "Campaign Sales Operations" -or $report.Name -eq "anomaly detection with images" -or $report.Name -eq "6_Production Quality- HTAP Synapse Link")
    {
        if($report.Name -eq "anomaly detection with images")
		{
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"StorageAccount`",
									`"newValue`": `"$dataLakeAccountName`"
								}
							]
					}"
			$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
           $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"};
		}
		if($report.Name -eq "Azure Cognitive Search")
		{
			$body = "{
			`"updateDetails`": [
								{
									`"name`": `"KnowledgeStoreStorageAccount`",
									`"newValue`": `"$dataLakeAccountName`"
								},
								{
									`"name`": `"SkillsetName`",
									`"newValue`": `"osha-formrecogoutput-skillset`"
								}
							]
					}"
			$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
           $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"};
		}
		 if($report.Name -eq "6_Production Quality- HTAP Synapse Link")
		{
			$body = "
					{
						`"updateDetails`":
						[
							{
								`"name`": `"CosmosAccountName`",
								`"newValue`": `"https://$($cosmos_account_name_mfgdemo).documents.azure.com:443/`"
							},
							{
								`"name`": `"SynapseWarehouseDatabaseName`",
								`"newValue`": `"$($sqlPoolName)`"
							},
							{
								`"name`": `"SynapseWarehouseServerName`",
								`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
							}
						]
					}
					";
			$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
           $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"};
		}
    }
       
	Write-Host "Setting database connection for $($report.Name)"
    foreach($source in $sourceServers)
    {

        #ManufacturingDW
        $powerBIReportDataSetConnectionUpdateRequest = $powerBIDataSetConnectionUpdateRequest.Replace("#SOURCE_SERVER#", $source).Replace("#SOURCE_DATABASE#", $report.SourceDatabase) |Out-String
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets/$($report.PowerBIDataSetId)/Default.UpdateDatasources";
        try
        {
            $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $powerBIReportDataSetConnectionUpdateRequest -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
            Add-Content log.txt $pbiResult  
        }
        catch
        {
        }
    }
	Start-Sleep -s 5
}

expand-archive -path "../artifacts/binaries/mfg-webapp.zip" -destinationpath "./mfg-webapp" -force

Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------deploy poc web app ---------------"

$spname="Manufacturing Demo $deploymentId"

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

(Get-Content -path mfg-webapp/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path mfg-webapp/appsettings.json

(Get-Content -path mfg-webapp/wwwroot/config.js -Raw) | Foreach-Object { $_ `
                -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`
				-replace '#SERVER_NAME#', $manufacturing_poc_app_service_name`
				-replace '#WWI_SITE_NAME#', $wideworldimporters_app_service_name`				
        } | Set-Content -Path mfg-webapp/wwwroot/config.js	

#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable
$ht.add("#REPORT_SQL_DASHBOARD_BEFORE_ID#", $($reportList | where {$_.Name -eq "1_Billion rows demo"}).ReportId)
$ht.add("#REPORT_SQL_DASHBOARD_DURING_ID#", $($reportList | where {$_.Name -eq "3_MFG Dynamic Data Masking (Azure Synapse)"}).ReportId)
$ht.add("#REPORT_SQL_DASHBOARD_AFTER_ID#", $($reportList | where {$_.Name -eq "4_MFG Column Level Security (Azure Synapse)"}).ReportId)
$ht.add("#REPORT_DASHBOARD_AFTER_ID#", $($reportList | where {$_.Name -eq "5_MFG Row Level Security (Azure Synapse)"}).ReportId)
$ht.add("#REPORT_ANOMALY_ID#", $($reportList | where {$_.Name -eq "anomaly detection with images"}).ReportId)
$ht.add("#REPORT_CAMPAIGN_ID#", $($reportList | where {$_.Name -eq "Campaign - Option C"}).ReportId)
$ht.add("#REPORT_FACTORY_ID#", $($reportList | where {$_.Name -eq "Factory-Overview - Option A"}).ReportId)
$ht.add("#REPORT_FINANCE_ID#", $($reportList | where {$_.Name -eq "1_Billion rows demo"}).ReportId)
$ht.add("#REPORT_GLOBALBING_ID#", $($reportList | where {$_.Name -eq "VP-Global-Overview"}).ReportId)
$ht.add("#REPORT_SAFETY_ID#", $($reportList | where {$_.Name -eq "Factory-Overview - Option A"}).ReportId)
$ht.add("#REPORT_MACHINE_ID#", $($reportList | where {$_.Name -eq "Equipment View Report"}).ReportId)
$ht.add("#REPORT_MACHINE_ANOMOLY_ID#", $($reportList | where {$_.Name -eq "anomaly detection with images"}).ReportId)
$ht.add("#REPORT_HTAP_ID#", $($reportList | where {$_.Name -eq "6_Production Quality- HTAP Synapse Link"}).ReportId)
$ht.add("#REPORT_SALES_CAMPAIGN_ID#", $($reportList | where {$_.Name -eq "Campaign Sales Operations"}).ReportId)
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
