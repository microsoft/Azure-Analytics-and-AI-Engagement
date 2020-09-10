function Check-HttpRedirect($uri)
{
    $httpReq = [system.net.HttpWebRequest]::Create($uri)
    $httpReq.Accept = "text/html, application/xhtml+xml, */*"
    $httpReq.method = "GET"   
    $httpReq.AllowAutoRedirect = $false;
    
    #use them all...
    #[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls;

    $global:httpCode = -1;
    
    $response = "";            

    try
    {
        $res = $httpReq.GetResponse();

        $statusCode = $res.StatusCode.ToString();
        $global:httpCode = [int]$res.StatusCode;
        $cookieC = $res.Cookies;
        $resHeaders = $res.Headers;  
        $global:rescontentLength = $res.ContentLength;
        $global:location = $null;
                                
        try
        {
            $global:location = $res.Headers["Location"].ToString();
            return $global:location;
        }
        catch
        {
        }

        return $null;

    }
    catch
    {
        $res2 = $_.Exception.InnerException.Response;
        $global:httpCode = $_.Exception.InnerException.HResult;
        $global:httperror = $_.exception.message;

        try
        {
            $global:location = $res2.Headers["Location"].ToString();
            return $global:location;
        }
        catch
        {
        }
    } 

    return $null;
}

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

function GetAccessTokens($context)
{
    $global:synapseToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://dev.azuresynapse.net").AccessToken
    $global:synapseSQLToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://sql.azuresynapse.net").AccessToken
    $global:managementToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://management.azure.com").AccessToken
    $global:powerbitoken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://analysis.windows.net/powerbi/api").AccessToken
}

#cloud shell can't be full - check for 5GB limit...
#TODO

#should auto for this.
az login

#for powershell...
Connect-AzAccount

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
    Write-Information "Selecting the $selectedSubName subscription"
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
}

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
#$rgName = "cjg-sanjay-2";

$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$deploymentId = $init

#$sqlPassword = Read-Host "Please enter the SQL Password";
#$sqlPassword = "Smoothie@2020";

$iot_hub_car = "raceCarIotHub-$suffix"
$iot_hub_telemetry = "mfgiothubTelemetry-$suffix"
$iot_hub = "mfgiothub-$suffix"
$iot_hub_sendtohub = "mfgiothubCosmosDB-$suffix"

$synapseWorkspaceName = "manufacturingdemo$init$random"
$sqlPoolName = "ManufacturingDW"
$concatString = "$init$random"
$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))
$sqlUser = "ManufacturingUser"

$mfgasaName = "mfgasa-$suffix"
$carasaName = "race-car-asa-$suffix"
$concatString = "$random$init"
$cosmos_account_name_mfgdemo = "cosmosdb-mfgdemo-$random$init" #+($concatString.substring(0,26))
$cosmos_database_name_mfgdemo_manufacturing = "manufacturing"

$mfgasaCosmosDBName = "mfgasaCosmosDB-$suffix"
$mfgASATelemetryName = "mfgASATelemetry-$suffix"

$app_name_telemetry_car = "car-telemetry-app-$suffix"
$app_name_telemetry = "datagen-telemetry-app-$suffix"
$app_name_hub = "sku2-telemetry-app-$suffix"
$app_name_sendtohub = "sendtohub-telemetry-app-$suffix"

$ai_name_telemetry_car = "car-telemetry-ai-$suffix"
$ai_name_telemetry = "datagen-telemetry-ai-$suffix"
$ai_name_hub = "sku2-telemetry-ai-$suffix"
$ai_name_sendtohub = "sendtohub-telemetry-ai-$suffix"

$sparkPoolName = "MFGDreamPool"
$manufacturing_poc_app_service_name = "manufacturing-poc-$suffix"
$wideworldimporters_app_service_name = "wideworldimporters-$suffix"

#$forms_cogs_name = "forms-$suffix";
$forms_cogs_name = "stcognitivesearch001"
$keyVaultName = "kv-$suffix";
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

Write-Information "Setting Key Vault Access Policy"
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,delete,get,list
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,delete,get,list

$sqlPassword = $(Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword").SecretValueText

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

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
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
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

#Publish-AzWebApp -WebApp $app -ArchivePath "./MfgAI/Manufacturing/automation/carTelemetry.zip" -Force
#
#$app = Get-AzWebApp -ResourceGroupName $rgName -Name $app_name_telemetry
#Publish-AzWebApp -WebApp $app -ArchivePath "./MfgAI/Manufacturing/automation/datagenTelemetry.zip" -AsJob
#
#$app = Get-AzWebApp -ResourceGroupName $rgName -Name $app_name_hub
#Publish-AzWebApp -WebApp $app -ArchivePath "./MfgAI/Manufacturing/automation/sku2.zip" -AsJob
#
#$app = Get-AzWebApp -ResourceGroupName $rgName -Name $app_name_sendtohub
#Publish-AzWebApp -WebApp $app -ArchivePath "./MfgAI/Manufacturing/automation/sendtohub.zip" -AsJob
#
#$app = Get-AzWebApp -ResourceGroupName $rgName -Name $wideworldimporters_app_service_name
#Publish-AzWebApp -WebApp $app -ArchivePath "./MfgAI/Manufacturing/automation/wideworldimporters.zip" -AsJob


#uploading Cosmos data
#$cosmosDbAccountName = $cosmos_account_name_mfgdemo

#$databaseName = $cosmos_database_name_mfgdemo_manufacturing

#$cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

#foreach($name in $cosmos)
#{
#    $collection = $name.BaseName
#    $cosmosDb = Get-AzCosmosDBAccount -ResourceGroupName $rgName -Name $cosmosDbAccountName
#
#    $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $rgNameName
#    #New-CosmosDbCollection -Context $cosmosDbContext -Id $collection -OfferThroughput 400 -PartitionKey 'PartitionKey' -DefaultTimeToLive 604800
#    $path="./artifacts/cosmos/"+$name.BaseName+".json"
#    $document=Get-Content -Raw -Path $path
#    $document=ConvertFrom-Json $document
#
#    foreach($json in $document)
#    {
#        $key=$json.SyntheticPartitionKey
#        $id = New-Guid
#       if(![bool]($json.PSobject.Properties.name -match "id"))
 #       {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
  #      if(![bool]($json.PSobject.Properties.name -match "SyntheticPartitionKey"))
 #       {$json | Add-Member -MemberType NoteProperty -Name 'SyntheticPartitionKey' -Value $id}
#        $body=ConvertTo-Json $json
#        New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
#    }
#} 

RefreshTokens

New-Item log.txt
#Add-Content log.txt "------asa powerbi connection-----"
#connecting asa and powerbi
# $principal=az resource show -g $rgName -n $mfgasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs" |ConvertFrom-Json
# $principalId=$principal.identity.principalId
# $uri="https://api.powerbi.com/v1.0/myorg/groups/$wsId/users"
# $body=@"
# {
  # "identifier": "$principalId",
  # "principalType": "App",
  # "groupUserAccessRight": "Admin"
# }
# "@
# $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"
# Add-Content log.txt $result
# $principal=az resource show -g $rgName -n $carasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs" |ConvertFrom-Json
# $principalId=$principal.identity.principalId
# $uri="https://api.powerbi.com/v1.0/myorg/groups/$wsId/users"
# $body=@"
# {
  # "identifier": "$principalId",
  # "principalType": "App",
  # "groupUserAccessRight": "Admin"
# }
# "@
# $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"
# Add-Content log.txt $result
#start ASA
Install-Module -Name MicrosoftPowerBIMgmt -Force
Login-PowerBI
$principal=az resource show -g $rgName -n $mfgasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

$principal=az resource show -g $rgName -n $carasaName --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgASATelemetryName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgasaName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $carasaName -OutputStartMode 'JobStartTime'
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $mfgasaCosmosDBName -OutputStartMode 'JobStartTime'

Add-Content log.txt "------sql schema-----"

#creating sql schema

Write-Information "Create tables in $($sqlPoolName)"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
$sqlquery = $sqlquery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result


$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [SalesStaff] FOR LOGIN [SalesStaff] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [InventoryManager] FOR LOGIN [InventoryManager] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [SalesStaffSanDiego] FOR LOGIN [SalesStaffSanDiego] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [SalesStaffMiami] FOR LOGIN [SalesStaffMiami] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="GRANT SELECT ON dbo.[CustomerInformation] TO [SalesStaff]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="GRANT SELECT ON dbo.[MFG-FactSales] TO [SalesStaffSanDiego]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="GRANT SELECT ON dbo.[MFG-FactSales] TO [InventoryManager]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="GRANT SELECT ON dbo.[MFG-FactSales] TO [SalesStaffMiami]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result
	
 
#uploading Sql Scripts
$scripts=Get-ChildItem "./artifacts/sqlscripts" | Select BaseName
$TemplatesPath="./artifacts/templates";	

#$cosmosAccount = Get-AzCosmosDBAccount -ResourceGroupName $rgName -Name $cosmos_account_name_mfgdemo;
#$keys = Get-AzCosmosDBAccountKey -ResourceGroupName $rgName -Name $cosmos_account_name_mfgdemo;
#$cosmos_account_key = $keys["PrimaryMasterKey"];
$cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name_mfgdemo -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

foreach ($name in $scripts) 
{
    if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "sqluser")
    {
        continue;
    }

    $item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
    $item = $item.Replace("#SQL_SCRIPT_NAME#", $name.BaseName)
    $item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
    $jsonItem = ConvertFrom-Json $item
    
    $ScriptFileName="./artifacts/sqlscripts/"+$name.BaseName+".sql"
    
    $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
    $query = $query.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
    $query = $query.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_mfgdemo)
    $query = $query.Replace("#COSMOS_KEY#", $cosmos_account_key)
	
    if ($Parameters -ne $null) 
    {
        foreach ($key in $Parameters.Keys) 
        {
            $query = $query.Replace("#$($key)#", $Parameters[$key])
        }
    }

    $query = ConvertFrom-Json (ConvertTo-Json $query)
    $jsonItem.properties.content.query = $query
    $item = ConvertTo-Json $jsonItem -Depth 100
    
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name.BaseName)?api-version=2019-06-01-preview"

   
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
}

#download azcopy command
if ([System.Environment]::OSVersion.Platform -eq "Unix")
{
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-linux"

        if (!$azCopyLink)
        {
                $azCopyLink = "https://azcopyvnext.azureedge.net/release20200709/azcopy_linux_amd64_10.5.0.tar.gz"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.tar.gz"
        tar -xf "azCopy.tar.gz"
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy).Directory.FullName

        if ($azCopyCommand.count -gt 1)
        {
            $azCopyCommand = $azCopyCommand[0];
        }

        cd $azCopyCommand
        chmod +x azcopy
        cd ..
        $azCopyCommand += "\azcopy"
}
else
{
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

        if (!$azCopyLink)
        {
                $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
        Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName

        if ($azCopyCommand.count -gt 1)
        {
            $azCopyCommand = $azCopyCommand[0];
        }

        $azCopyCommand += "\azcopy"
}
 
#Uploading to storage containers
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$containers=Get-ChildItem "./artifacts/storageassets" | Select BaseName

foreach($container in $containers)
{
    $destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
    $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
    & $azCopyCommand copy "./artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive
}

RefreshTokens
 
$destinationSasKey = New-AzStorageContainerSASToken -Container "mfgdemodata" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/mfgdemodata/$($destinationSasKey)"
& $azCopyCommand copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-csv/telemetryp.csv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
$dataLakeStorageBlobUrl = "https://$($dataLakeAccountName).blob.core.windows.net/"

$dataDirectories = @{
   b2ccsv = "customcsv,customcsv/Manufacturing B2C Scenario Dataset /" #space after container name is intentional since thats how the name is in public storage
   b2bcsv = "customcsv,customcsv/Manufacturing B2B Scenario Dataset/"
}

$publicDataUrl = "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/";

foreach ($dataDirectory in $dataDirectories.Keys) {

        $vals = $dataDirectories[$dataDirectory].tostring().split(",");

        $source = $publicDataUrl + $vals[1];

        $path = $vals[0];

        $destination = $dataLakeStorageBlobUrl + $path + $destinationSasKey
        Write-Information "Copying directory $($source) to $($destination)"
        & $azCopyCommand copy $source $destination --recursive=true
}

# $destinationSasKey = New-AzStorageContainerSASToken -Container "forms" -Context $dataLakeContext -Permission rwdl
# $dataLakeStorageBlobUrl = "https://$($dataLakeAccountName).blob.core.windows.net/"

# $dataDirectories = @{
   # data1 = "forms,forms/formupload/"
   # data2 = "forms,forms/formrecogoutput/"
   # data3 = "forms,forms/english-form-model/"
# }

# $publicDataUrl = "https://stcognitivesearch001.blob.core.windows.net/";

# foreach ($dataDirectory in $dataDirectories.Keys) {

        # $vals = $dataDirectories[$dataDirectory].tostring().split(",");

        # $source = $publicDataUrl + $vals[1];

        # $path = $vals[0];

        # $destination = $dataLakeStorageBlobUrl + $path + $destinationSasKey
        # Write-Information "Copying directory $($source) to $($destination)"
        # & $azCopyCommand copy $source $destination --recursive=true
# }

<#
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Campaign.csv"  $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /CampaignData_Bubble.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /CampaignData.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Campaignproducts.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Campaignsales.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /customer.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Date.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /historical-data-adf.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /location.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /mfg-AlertAlarm.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /mfg-MachineAlert.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /mfg-OEE-Agg.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /mfg-OEE.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /Product.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /sales.csv" $destinationUri --recursive
azcopy copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/customcsv/Manufacturing B2C Scenario Dataset /vCampaignSales.csv" $destinationUri --recursive
#>

#$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
#$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/webappassets/$($destinationSasKey)"
#azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/Intro_product.mp4" $destinationUri --recursive
#azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/Machine%20Maintenance%20Demo.mp4" $destinationUri --recursive
#azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/factory_safety_video.mp4" $destinationUri --recursive
#azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/Hololens_Stretch.mp4" $destinationUri --recursive
#azcopy copy "https://solliancepublicdata.blob.core.windows.net/cdp/manufacturing-videos/RioDeJaneiro_video.mp4" $destinationUri --recursive
 
Add-Content log.txt "------linked Services------"
#Creating linked services
RefreshTokens

$templatepath="./artifacts/templates/"

##cosmos linked services
$filepath=$templatepath+"cosmos_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $cosmos_account_name_mfgdemo).Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_mfgdemo).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key).Replace("#COSMOS_DATABASE#", $cosmos_database_name_mfgdemo_manufacturing)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($cosmos_account_name_mfgdemo)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##Datalake linked services
$filepath=$templatepath+"data_lake_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($dataLakeAccountName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##blob linked services
$filepath=$templatepath+"blob_storage_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$name=$dataLakeAccountName+"blob"
$blobLinkedService=$name
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $name).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($name)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##powerbi linked services
$filepath=$templatepath+"powerbi_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "ManufacturingDemo").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/ManufacturingDemo?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##sql pool linked services
$filepath=$templatepath+"sql_pool_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $sqlPoolName).Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/$($sqlPoolName)?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##sap hana linked services
$filepath=$templatepath+"sap_hana_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "SapHana")
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##teradata linked services
$filepath=$templatepath+"teradata_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "TeraData")
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/TeraData?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##oracle linked services
$filepath=$templatepath+"oracle_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "oracle")
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/oracle?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

RefreshTokens
 
#Creating Datasets
Add-Content log.txt "------datasets------"
Write-Information "Creating Datasets"
$datasets = @{
    CosmosIoTToADLS = $dataLakeAccountName
	AzureSynapseAnalyticsTable1=$sqlPoolName
	MfgSAPHanaDataset=$sqlPoolName
	historical_drill=$dataLakeAccountName
	MFGAzureSynapseDrill=$sqlPoolName
	MachineInstanceSynapse=$sqlPoolName
	MFGIoTHistoricalSynapse=$sqlPoolName
	MfgIoTSynapseSink=$sqlPoolName
	MfgLocationSynapse=$sqlPoolName
	MfgOperationDataset=$sqlPoolName
	mfgcosmosdbqualityds=$cosmos_account_name_mfgdemo
	tblcosmosdbqualityds=$sqlPoolName
	SapHanaSalesData="SapHana"
	SAPSourceDataset="SapHana"
	MarketingDB_Processed=$dataLakeAccountName
	MarketingDB_Stage=$dataLakeAccountName
	MfgCampaignSynapseAnalyticsOutput=$sqlPoolName
	Teradata_MarketingDB="TeraData"
	TeradataMarketingDB="TeraData"
	MfgSalesdatasetsink=$sqlPoolName
	Oracle_SalesDB="oracle"
	OracleSalesDB="oracle"
	CosmosDbSqlApiCollection1=$cosmos_account_name_mfgdemo
	DS_AzureSynapse_Telemetry=$sqlPoolName
	IotData=$dataLakeAccountName
	ArchiveTwitterParquet=$dataLakeAccountName
	DeleteTweeterFiles=$dataLakeAccountName
	DS_MFG_AzureSynapse_TwitterAnalytics=$sqlPoolName
	TweetsParquet=$dataLakeAccountName
	MFGazuresyanapseDW=$sqlPoolName
	MFGParquettoSynapseSource=$dataLakeAccountName
	AzureSynapseAnalyticsTable6=$sqlPoolName
	AzureSynapseAnalyticsTable7=$sqlPoolName
	AzureSynapseAnalyticsTable8=$sqlPoolName
	AzureSynapseAnalyticsTable9=$sqlPoolName
	AzureSynapseAnalyticsTable10=$sqlPoolName
	CustomCampaignproducts=$dataLakeAccountName
	Custom_CampaignData=$sqlPoolName
	Custom_CampaignData_bubble=$sqlPoolName
	Custom_Campaignproducts=$sqlPoolName
	Custom_Product=$sqlPoolName
	CustomCampaignData=$dataLakeAccountName
	CustomCampaignData_Bubble=$dataLakeAccountName
	CustomProduct=$dataLakeAccountName
	Sales=$dataLakeAccountName
	SalesData=$sqlPoolName
}

$DatasetsPath="./artifacts/datasets";	

foreach ($dataset in $datasets.Keys) 
{
    Write-Information "Creating dataset $($dataset)"
	$LinkedServiceName=$datasets[$dataset]
	$itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset).json"
	$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $LinkedServiceName)
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	Add-Content log.txt $result
}
 
#Creating spark notebooks
Add-Content log.txt "------Notebooks------"
Write-Information "Creating Spark notebooks..."

$notebooks=Get-ChildItem "./artifacts/notebooks" | Select BaseName 

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $rgName
        "#WORKSPACE_NAME#"  = $synapseWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
		"#SPARK_POOL_NAME#"= $sparkPoolName
		"#STORAGE_ACCOUNT_KEY#"=$storage_account_key
		"#COSMOS_LINKED_SERVICE#"=$cosmos_account_name_mfgdemo
}

foreach($name in $notebooks)
{
	$template=Get-Content -Raw -Path "./artifacts/templates/spark_notebook.json"
	foreach ($paramName in $cellParams.Keys) 
    {
		$template = $template.Replace($paramName, $cellParams[$paramName])
	}
	
    $jsonItem = ConvertFrom-Json $template
	$path="./artifacts/notebooks/"+$name.BaseName+".ipynb"
	$notebook=Get-Content -Raw -Path $path
	$jsonNotebook = ConvertFrom-Json $notebook
	$jsonItem.properties.cells = $jsonNotebook.cells
	
    if ($CellParams) 
    {
        foreach ($cellParamName in $cellParams.Keys) 
        {
            foreach ($cell in $jsonItem.properties.cells) 
            {
                for ($i = 0; $i -lt $cell.source.Count; $i++) 
                {
                    $cell.source[$i] = $cell.source[$i].Replace($cellParamName, $CellParams[$cellParamName])
                }
            }
        }
    }

	$item = ConvertTo-Json $jsonItem -Depth 100
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/notebooks/$($name.BaseName)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	#waiting for operation completion
	Start-Sleep -Seconds 10
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
	Add-Content log.txt $result
}	

#creating Dataflows
Add-Content log.txt "------dataflows-----"
# $params = @{
        # LOAD_TO_SYNAPSE = "AzureSynapseAnalyticsTable8"
        # LOAD_TO_AZURE_SYNAPSE = "AzureSynapseAnalyticsTable9"
        # DATA_FROM_SAP_HANA = "DelimitedText1"
# }
$workloadDataflows = [ordered]@{
        MFG_Ingest_data_from_SAP_HANA_to_Azure_Synapse = "1 MFG Ingest data from SAP HANA to Azure Synapse"
		Ingest_data_from_SAP_HANA_to_Common_Data_Service="2 Ingest data from SAP HANA to Common Data Service"
		MFGDataFlowADLStoSynapse="2 MFGDataFlowADLStoSynapse"
		MFG_IoT_dataflow="7 MFG IoT_dataflow"
		MFGCosmosdbquality="MFGCosmosdbquality"
}

$DataflowPath="./artifacts/dataflows"

foreach ($dataflow in $workloadDataflows.Keys) 
{
		$Name=$workloadDataflows[$dataflow]
        Write-Information "Creating dataflow $($workloadDataflows[$dataflow])"
		 $item = Get-Content -Path "$($DataflowPath)/$($Name).json"
    
    # if ($params -ne $null) {
        # foreach ($key in $params.Keys) {
            # $item = $item.Replace("#$($key)#", $params[$key])
        # }
    # }
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/dataflows/$($Name)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
	Start-Sleep -Seconds 10

	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
	Add-Content log.txt $result
}

RefreshTokens

#creating Pipelines
Add-Content log.txt "------pipelines------"
Write-Information "Creating pipelines"
$pipelines=Get-ChildItem "./artifacts/pipelines" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList
foreach($name in $pipelines)
{
    $FilePath="./artifacts/pipelines/"+$name.BaseName+".json"
    
    $temp = "" | select-object @{Name = "FileName"; Expression = {$name.BaseName}} , @{Name = "Name"; Expression = {$name.BaseName.ToUpper()}}, @{Name = "PowerBIReportName"; Expression = {""}}
    $pipelineList.Add($temp)
    $item = Get-Content -Path $FilePath
    $item=$item.Replace("#DATA_LAKE_STORAGE_NAME#",$dataLakeAccountName)
    $item=$item.Replace("#BLOB_LINKED_SERVICE#",$blobLinkedService)
    $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
    $item=$item.Replace("#DEFAULT_STORAGE#",$defaultStorage)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
    Start-Sleep -Seconds 10
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    Add-Content log.txt $result 
}

#uploading powerbi reports
RefreshTokens

Add-Content log.txt "------powerbi reports------"
Write-Information "Uploading power BI reports"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "./artifacts/reports" | Select BaseName 

foreach($name in $reports)
{
        $FilePath="./artifacts/reports/$($name.BaseName)"+".pbix"
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

RefreshTokens

#Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections------"
Write-Information "Uploading power BI reports"	
$powerBIDataSetConnectionTemplate = Get-Content -Path "./artifacts/templates/powerbi_dataset_connection.json"

#$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "HelloWorld.sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String
$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "$($synapseWorkspaceName).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String

$sourceServers = @("manufacturingdemor16gxwbbra4mtbmu.sql.azuresynapse.net", "manufacturingdemo.sql.azuresynapse.net", "dreamdemosynapse.sql.azuresynapse.net","manufacturingdemocjgnpnq4eqzbflgi.sql.azuresynapse.net", "manufacturingdemodemocwbennanrpo5s.sql.azuresynapse.net", "HelloWorld.sql.azuresynapse.net","manufacturingdemosep5n2tdtctkwpyjc.sql.azuresynapse.net")

foreach($report in $reportList)
{

    #skip some...cosmos or nothing to update.
    #campaign sales operations = COSMOS
    #Azure Cognitive Search = AZURE TABLE
    #anomaly detection with images = AZURE TABLE
    if ($report.Name -eq "sample_test" -or $report.Name -eq "Azure Cognitive Search" -or $report.Name -eq "Campaign Sales Operations" -or $report.Name -eq "anomaly detection with images")
    {
        #continue;
    }

    foreach($source in $sourceServers)
    {
        Write-Information "Setting database connection for $($report.Name)"
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

    <#
    #cosmobased ones require different endpoint - TODO
    $body = "{
      `"updateDetails`": [
        {
          `"name`": `"DatabaseName`",
          `"newValue`": `"NewDB`"
        },
        {
          `"name`": `"MaxId`",
          `"newValue`": `"5678`"
        }
      ]
    }"

    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" };
    Add-Content log.txt $pbiResult  
    #>
}

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports"
$pbiResult = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
Add-Content log.txt $pbiResult  

foreach($r in $pbiResult.value)
{
    $report = $reportList | where {$_.Name -eq $r.name}
    $report.ReportId = $r.id;
}

#$cogSvcForms = Get-AzCongnitiveServicesAccount -resourcegroupname $rgName -Name $form_cogs_name;

Add-Content log.txt "------deploy web app------"

$app = Get-AzADApplication -DisplayName "Mfg Demo $deploymentid"
$secret = ConvertTo-SecureString -String $sqlPassword -AsPlainText -Force

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
$result = Invoke-RestMethod -Uri $url -Method PUT -body $post -ContentType "application/json" -Headers $headers -ea SilentlyContinue;

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
				-replace '#APP_SECRET#', $sqlPassword`
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
$ht.add("#COGS_FORMS_NAME#", $forms_cogs_name)
$ht.add("#WORKSPACE_ID#", $wsId)
$ht.add("#APP_ID#", $appId)
$ht.add("#APP_SECRET#", $sqlPassword)
$ht.add("#TENANT_ID#", $tenantId)
$ht.add("#SERVER_NAME#", $manufacturing_poc_app_service_name)

$filePath = "./mfg-webapp/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)


Compress-Archive -Path "./mfg-webapp/*" -DestinationPath "./mfg-webapp.zip"

az webapp stop --name $manufacturing_poc_app_service_name --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $manufacturing_poc_app_service_name --src "./mfg-webapp.zip"
az webapp start --name $manufacturing_poc_app_service_name --resource-group $rgName

foreach($zip in $zips)
{
    remove-item -path "./$($zip)" -recurse -force
    remove-item -path "./$($zip).zip" -recurse -force
}

#$app = Get-AzWebApp -ResourceGroupName $rgName -Name $manufacturing_poc_app_service_name
#Publish-AzWebApp -WebApp $app -ArchivePath "./MfgAI/Manufacturing/automation/mfg-webapp.zip" -Force

Add-Content log.txt "------uploading sql data------"

#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignData_Bubble"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignData_Bubble"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignData"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"customer"}} , @{Name = "TABLE_NAME"; Expression = {"customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"historical-data-adf"}} , @{Name = "TABLE_NAME"; Expression = {"historical-data-adf"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"location"}} , @{Name = "TABLE_NAME"; Expression = {"location"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-AlertAlarm"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-AlertAlarm"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-MachineAlert"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-MachineAlert"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-OEE"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-OEE"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-OEE-Agg"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-OEE-Agg"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaignproducts"}} , @{Name = "TABLE_NAME"; Expression = {"Campaignproducts"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignData_exl"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignData_exl"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Product"}} , @{Name = "TABLE_NAME"; Expression = {"Product"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"sales"}} , @{Name = "TABLE_NAME"; Expression = {"sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"vCampaignSales"}} , @{Name = "TABLE_NAME"; Expression = {"vCampaignSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Date"}} , @{Name = "TABLE_NAME"; Expression = {"Date"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"MFGFactSales"}} , @{Name = "TABLE_NAME"; Expression = {"MFG-FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-iot-json"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-iot-json"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerInformation"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerInformation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)


$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-EmergencyEvent"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-EmergencyEvent"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-emergencyeventperson"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-emergencyeventperson"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"racingcars"}} , @{Name = "TABLE_NAME"; Expression = {"racingcars"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"milling-canning"}} , @{Name = "TABLE_NAME"; Expression = {"milling-canning"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"jobquality"}} , @{Name = "TABLE_NAME"; Expression = {"jobquality"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-ProductQuality"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-ProductQuality"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactoryOverviewTable"}} , @{Name = "TABLE_NAME"; Expression = {"FactoryOverviewTable"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-MaintenanceCost"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-MaintenanceCost"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-MaintenanceCode"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-MaintenanceCode"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-PlannedMaintenanceActivity"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-PlannedMaintenanceActivity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-UnplannedMaintenanceActivity"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-UnplannedMaintenanceActivity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"mfg-location"}} , @{Name = "TABLE_NAME"; Expression = {"mfg-Location"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics_New"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Role"}} , @{Name = "TABLE_NAME"; Expression = {"Role"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$dataTableList.Add($temp)

$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
foreach ($dataTableLoad in $dataTableList) {
    Write-output "Loading data for $($dataTableLoad.TABLE_NAME)"
    $sqlQuery = Get-Content -Raw -Path "./artifacts/templates/load_csv.sql"
    $sqlquery = $sqlquery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
    $Parameters =@{
            CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
            TABLE_NAME = $dataTableLoad.TABLE_NAME
            DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
     }
    foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
    Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Write-output "Data for $($dataTableLoad.TABLE_NAME) loaded."
}

#<#P2 #>

#<#Ignore#>

##get search resource
#install-module az.search -scope CurrentUser;
#
#$searchName = "mfg-search-$init-$random";
#$searchKey = $(az search admin-key show --resource-group $rgName --service-name $searchName | ConvertFrom-Json).primarykey;
##$searchkey = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $searchName; - because somone needs to be fired
#
##Search setup
#$indexName = "demoindex";
#
#$headers = @();
#$headers.Add("api-key",$searchKey);
#
#$body = Get-Content -path search/index_base.json -Raw
##create index
#$uri = "https://$searchName.search.windows.net/indexes/demoindex?api-version=2019-05-06"
#$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"
#
##create indexer
#$body = Get-Content -path search/indexer_base.json -Raw
#$url = "https://$serviceName.search.windows.net/indexers/demoindexer?api-version=2019-05-06"
#$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"
#
#$post = "";
#
##create pipeline
#$body = Get-Content -path search/indexer_base.json -Raw
#$url = "https://$searchName.search.windows.net/indexes/demoindex?api-version=2019-05-06"
#$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $powerbitoken" } -ContentType "application/json"

Add-Content log.txt "-----------------Execution Complete---------------"
