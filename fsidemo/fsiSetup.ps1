$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","I accept the license agreement."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","I do not accept and wish to stop execution."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$title = "Agreement"
$message = "By typing [Y], I hereby confirm that I have read the license ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/license.md ) and disclaimers ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/README.md ) and hereby accept the terms of the license and agree that the terms and conditions set forth therein govern my use of the code made available hereunder. (Type [Y] for Yes or [N] for No and press enter)"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
if($result -eq 1)
{
write-host "Thank you. Please ensure you delete the resources created with template to avoid further cost implications."
}

else
{
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
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api --output json) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net --output json) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com --output json) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com --output json) | ConvertFrom-Json).accessToken
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
$after_scenario_financial_hcrr_url = (Get-AzResourceGroup -Name $rgName).Tags["after_scenario_financial_hcrr_url"]
$before_scenario_financial_hcrr_url = (Get-AzResourceGroup -Name $rgName).Tags["before_scenario_financial_hcrr_url"]
$before_scenario_cco_url = (Get-AzResourceGroup -Name $rgName).Tags["before_scenario_cco_url"]
$before_and_after_scenario_group_ceo_url = (Get-AzResourceGroup -Name $rgName).Tags["before_and_after_scenario_group_ceo_url"]
          
$deploymentId = $init
$cpuShell = "cpuShell$random"
$synapseWorkspaceName = "synapsefsi$init$random"
$sqlPoolName = "FsiDW"
$concatString = "$init$random"
$dataLakeAccountName = "stfsi$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$sqlUser = "labsqladmin"
$concatString = "$random$init"
$cosmos_account_name = "cosmosdb-fsi-$concatString"
if($cosmos_account_name.length -gt 43 )
{
$cosmos_account_name = $cosmos_account_name.substring(0,43)
}
$cosmos_database_name = "fsi-marketdata"

$app_name_realtime_kpi_simulator ="app-fsi-realtime-kpi-simulator-$suffix"
$fsi_poc_app_service_name = "app-demofsi-$suffix"
$app_maps_service_name = "app-maps-$suffix"
$forms_cogs_name = "forms-$suffix";
$searchName = "srch-fsi-$suffix";
$cog_marketdatacgsvc_name =  "cog-all-$suffix";
$sparkPoolName = "fsi"
$databricks_workspace_name = "fsi-dbrs-$suffix"
$iot_hub_name = "iothub-fsi-$suffix"
$asa_name_fsi = "fsiasa-$suffix"
$eventhub_evh_namespace_name = "evh-namespace--$suffix"
$storageAccountName = $dataLakeAccountName
$keyVaultName = "kv-$suffix";
$amlworkspacename = "amlws-$suffix"
$cog_speech_name = "speech-service-$suffix"
$cog_translator_name = "translator-$suffix"
$mssql_server_name = "dbserver-marketingdata-$suffix"
$server  = $mssql_server_name+".database.windows.net"
$mssql_administrator_login = "labsqladmin"
$mssql_database_name = "db-geospatial"
$accounts_maps_name = "mapsfsi-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$userName = ((az ad signed-in-user show --output json) | ConvertFrom-Json).UserPrincipalName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_cogs_name
$cog_speech_key = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $cog_speech_name
$searchKey = $(az search admin-key show --resource-group $rgName --service-name $searchName --output json | ConvertFrom-Json).primarykey;
$map_key = az maps account keys list --name $accounts_maps_name --resource-group $rgName --output json |ConvertFrom-Json
$accounts_map_key = $map_key.primaryKey
$cog_translator_key =  Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $cog_translator_name

$key=az cognitiveservices account keys list --name $cog_marketdatacgsvc_name -g $rgName|ConvertFrom-json
$cog_marketdatacgsvc_key=$key.key1

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

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
$mssqlPassword = $sqlPassword
$mssql_administrator_password = $mssqlPassword

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

#Cosmos keys
$cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

###################################################################
New-Item log.txt

Install-Module -Name MicrosoftPowerBIMgmt -Force
Login-PowerBI

RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$StartTime = Get-Date
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "form-datasets" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime

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
Add-Content log.txt "-----------Uploading to storage containers-----------------"
Write-Host "----Uploading to Storage Containers-----"
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

RefreshTokens
 
$destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
& $azCopyCommand copy "https://fsipoc.blob.core.windows.net/customcsv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/webappassets$($destinationSasKey)"
& $azCopyCommand copy "https://fsipoc.blob.core.windows.net/webappassets" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "risk" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/risk$($destinationSasKey)"
& $azCopyCommand copy "https://fsipoc.blob.core.windows.net/risk" $destinationUri --recursive

#storage assests copy
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

Add-Content log.txt "----Form Recognizer-----"
Write-Host "----Form Recognizer-----"
#form Recognizer
#Replace values in create_model.py
(Get-Content -path artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
				-replace '#LOCATION#', $location`
				-replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
				-replace '#CONTAINER_NAME#', "form-datasets"`
				-replace '#SAS_TOKEN#', $sasToken`
				-replace '#APIM_KEY#',  $forms_cogs_keys.Key1`
			} | Set-Content -Path artifacts/formrecognizer/create_model1.py
			
$modelUrl = python "./artifacts/formrecognizer/create_model1.py"
$modelId= $modelUrl.split("/")
$modelId = $modelId[7]

############################
Add-Content log.txt "------sql schema-----"
Write-Host "----Sql Schema------"
RefreshTokens
#creating sql schema
Write-Host "Create tables in $($sqlPoolName)"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

#$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
(Get-Content -path "$($SQLScriptsPath)/sqluser.sql" -Raw) | Foreach-Object { $_ `
                -replace '#SQL_PASSWORD#', $sqlPassword`		
        } | Set-Content -Path "$($SQLScriptsPath)/sqluser.sql"		
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery="CREATE USER [MarketingOfficer] FOR LOGIN [MarketingOfficer] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword

$sqlQuery="CREATE USER [MarketingOfficerMiami] FOR LOGIN [MarketingOfficerMiami] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword


$sqlQuery="CREATE USER [MarketingOfficerSanDiego] FOR LOGIN [MarketingOfficerSanDiego] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword


$sqlQuery="CREATE USER [HeadOfFinancialIntelligence] FOR LOGIN [HeadOfFinancialIntelligence] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword

$sqlQuery  = "CREATE DATABASE FsiSqlOnDemand"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database master -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result	
  
#uploading Sql Scripts
Add-Content log.txt "-----------uploading Sql Scripts-----------------"
Write-Host "----Sql Scripts------"
RefreshTokens
$scripts=Get-ChildItem "./artifacts/sqlscripts" | Select BaseName
$TemplatesPath="./artifacts/templates";	

foreach ($name in $scripts) 
{
    if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sql-geospatial-data" -or $name.BaseName -eq "sql-geospatial-schema" -or $name.BaseName -eq "sqlOnDemandSchema" )
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
     $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $query = $query.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name)
    $query = $query.Replace("#COSMOS_KEY#", $cosmos_account_key)

    $query = $query.Replace("#LOCATION#", $location)
	
    if ($Parameters -ne $null) 
    {
        foreach ($key in $Parameters.Keys) 
        {
            $query = $query.Replace("#$($key)#", $Parameters[$key])
        }
    }

    Write-Host "Uploading Sql Script : $($name.BaseName)"
    $query = ConvertFrom-Json (ConvertTo-Json $query)
    $jsonItem.properties.content.query = $query
    $item = ConvertTo-Json $jsonItem -Depth 100
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
}
 
Add-Content log.txt "------linked Services------"
Write-Host "----linked Services------"
#Creating linked services
RefreshTokens

$templatepath="./artifacts/templates/"

##cosmos linked services
Write-Host "Creating linked Service: Cosmosmarketdata"
$filepath=$templatepath+"Cosmosmarketdata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key).Replace("#COSMOS_DATABASE#", $cosmos_database_name)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Cosmosmarketdata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
##Datalake linked services
Write-Host "Creating linked Service: 0_marketdatadl"
$filepath=$templatepath+"0_marketdatadl.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/0_marketdatadl?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##SQL server linked services
Write-Host "Creating linked Service: AzureSqlDatabase"
$filepath=$templatepath+"AzureSqlDatabase.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#MSSQL_SERVER_NAME#", $mssql_server_name).Replace("#MSSQL_DATABASE_NAME#", $mssql_database_name).Replace("#MSSQL_USERNAME#", $mssql_administrator_login).Replace("#MSSQL_PASSWORD#", $mssqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureSqlDatabase?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##blob linked services
Write-Host "Creating linked Service: marketdatadl"
$filepath=$templatepath+"marketdatadl.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/marketdatadl?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##blob linked services
Write-Host "Creating linked Service: marketdatasynapse-WorkspaceDefaultStorage"
$filepath=$templatepath+"marketdatasynapse-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/marketdatasynapse-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##AzureSql linked services
Write-Host "Creating linked Service: FSIRiskDW"
$filepath=$templatepath+"FSIRiskDW.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/FSIRiskDW?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##sap hana linked services
Write-Host "Creating linked Service: SapHana"
$filepath=$templatepath+"SapHana.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
 
 ##powerbi linked services
 Write-Host "Creating linked Service: powerbi_linked_service"
$filepath=$templatepath+"powerbi_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/powerbi_linked_service?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

 ##Teradata linked services
 Write-Host "Creating linked Service: Teradata"
$filepath=$templatepath+"Teradata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "Teradata").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result


# AutoResolveIntegrationRuntime
    $FilePathRT="./artifacts/templates/AutoResolveIntegrationRuntime.json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
 Add-Content log.txt $result


#Creating Datasets
Add-Content log.txt "------datasets------"
Write-Host "--------Datasets--------"
RefreshTokens
$DatasetsPath="./artifacts/datasets";	
$datasets=Get-ChildItem "./artifacts/datasets" | Select BaseName
foreach ($dataset in $datasets) 
{
    Write-Host "Creating dataset : $($dataset.BaseName)"
	$LinkedServiceName=$datasets[$dataset.BaseName]
	$itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset.BaseName).json"
	$item = $itemTemplate #.Replace("#LINKED_SERVICE_NAME#", $LinkedServiceName)
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset.BaseName)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	Add-Content log.txt $result
}
 
#Creating spark notebooks
Add-Content log.txt "--------------Spark Notebooks---------------"
Write-Host "--------Spark notebooks--------"
RefreshTokens
$notebooks=Get-ChildItem "./artifacts/notebooks" | Select BaseName 

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $rgName
        "#WORKSPACE_NAME#"  = $synapseWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
		"#SPARK_POOL_NAME#" = $sparkPoolName
		"#STORAGE_ACCOUNT_KEY#" = $storage_account_key
		"#COSMOS_LINKED_SERVICE#" = $cosmos_account_name
		"#STORAGE_ACCOUNT_NAME#" = $dataLakeAccountName
		"#LOCATION#"=$location
		"#ML_WORKSPACE_NAME#"=$amlWorkSpaceName
        "#COGNITIVE_SERVICE_NAME#" = $cog_marketdatacgsvc_name
        "#COGNITIVE_SERVICE_KEY#" = $cog_marketdatacgsvc_key
        "#SEARCH_KEY#" = $searchKey
}

foreach($name in $notebooks)
{
	$template=Get-Content -Raw -Path "./artifacts/templates/spark_notebook.json"
	foreach ($paramName in $cellParams.Keys) 
    {
		$template = $template.Replace($paramName, $cellParams[$paramName])
	}
	$template=$template.Replace("#NOTEBOOK_NAME#",$name.BaseName)
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

    Write-Host "Creating notebook : $($name.BaseName)"
	$item = ConvertTo-Json $jsonItem -Depth 100
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/notebooks/$($name.BaseName)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	#waiting for operation completion
	Start-Sleep -Seconds 10
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
	#$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
	Add-Content log.txt $result
}	

#creating Dataflows
Add-Content log.txt "------Dataflows-----"
Write-Host "--------Dataflows--------"
RefreshTokens
$workloadDataflows = Get-ChildItem "./artifacts/dataflow" | Select BaseName 

$DataflowPath="./artifacts/dataflow"

foreach ($dataflow in $workloadDataflows) 
{
    $Name=$dataflow.BaseName
    Write-Host "Creating dataflow : $($Name)"
    $item = Get-Content -Path "$($DataflowPath)/$($Name).json"
    
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/dataflows/$($Name)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
	Start-Sleep -Seconds 10
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
	Add-Content log.txt $result
}

#creating Pipelines
Add-Content log.txt "------pipelines------"
Write-Host "-------Pipelines-----------"
RefreshTokens
$pipelines=Get-ChildItem "./artifacts/pipeline" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList
foreach($name in $pipelines)
{
    $FilePath="./artifacts/pipeline/"+$name.BaseName+".json"
    Write-Host "Creating pipeline : $($name.BaseName)"

    $item = Get-Content -Path $FilePath
    $item=$item.Replace("#DATA_LAKE_STORAGE_NAME#",$dataLakeAccountName)
    #$item=$item.Replace("#BLOB_LINKED_SERVICE#",$blobLinkedService)
    $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
    #$item=$item.Replace("#DEFAULT_STORAGE#",$defaultStorage)
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

Add-Content log.txt "------powerbi reports upload------"
Write-Host "------------Powerbi Reports Upload ------------"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "./artifacts/reports" | Select BaseName 
foreach($name in $reports)
{
        $FilePath="./artifacts/reports/$($name.BaseName)"+".pbix"
        #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
        
        write-host "Uploading PowerBI Report : $($name.BaseName)";
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
        @{Name = "SourceServer"; Expression = {""}}, 
        @{Name = "SourceDatabase"; Expression = {""}}
		                        
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
                
      $list = $reportList.Add($temp)
}
Start-Sleep -s 60

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports"
$pbiResult = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
Add-Content log.txt $pbiResult  

foreach($r in $pbiResult.value)
{
    $report = $reportList | where {$_.Name -eq $r.name}
    $report.ReportId = $r.id;
}


Add-Content log.txt "------uploading sql data------"
Write-Host  "-------------Uploading Sql Data ---------------"
RefreshTokens
#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_AllTransactions"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_AllTransactions"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgCompanyVsTopicProbability"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgCompanyVsTopicProbability"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGOrgConnections"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGOrgConnections"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgContribution"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgContribution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgDetractors"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgDetractors"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgWordCloudData"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgWordCloudData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGScores"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGScores"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgSentimentAndCustomerChurn"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgSentimentAndCustomerChurn"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgSentimentVsMarketPerformance"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgSentimentVsMarketPerformance"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGWeightedScore"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGWeightedScore"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_RyanTransactions"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_RyanTransactions"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_SuspiciousTransactionsMiami"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_SuspiciousTransactionsMiami"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_SuspiciousTransactionsSantorini"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_SuspiciousTransactionsSantorini"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Carbon-Emission"}} , @{Name = "TABLE_NAME"; Expression = {"Carbon-Emission"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Climate-Risk"}} , @{Name = "TABLE_NAME"; Expression = {"Climate-Risk"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ConflictofInterest"}} , @{Name = "TABLE_NAME"; Expression = {"ConflictofInterest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Country"}} , @{Name = "TABLE_NAME"; Expression = {"Country"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Countrys"}} , @{Name = "TABLE_NAME"; Expression = {"Countrys"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CroGlobalMarkets"}} , @{Name = "TABLE_NAME"; Expression = {"CroGlobalMarkets"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CroInsurance"}} , @{Name = "TABLE_NAME"; Expression = {"CroInsurance"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CroMacroeconomicTrend"}} , @{Name = "TABLE_NAME"; Expression = {"CroMacroeconomicTrend"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CroRetailBank"}} , @{Name = "TABLE_NAME"; Expression = {"CroRetailBank"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CroRiskDashboard"}} , @{Name = "TABLE_NAME"; Expression = {"CroRiskDashboard"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerInfo"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerTransactions"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerTransactions"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DailyStockData"}} , @{Name = "TABLE_NAME"; Expression = {"DailyStockData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DailyStockDataLatest"}} , @{Name = "TABLE_NAME"; Expression = {"DailyStockDataLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"EnvMgmtPractices"}} , @{Name = "TABLE_NAME"; Expression = {"EnvMgmtPractices"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ESGOrganisation"}} , @{Name = "TABLE_NAME"; Expression = {"ESGOrganisation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Finance-FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"Finance-FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FPA"}} , @{Name = "TABLE_NAME"; Expression = {"FPA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FPA1"}} , @{Name = "TABLE_NAME"; Expression = {"FPA1"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp) 
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HistoricalNewsAndSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"HistoricalNewsAndSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HistoricalStock"}} , @{Name = "TABLE_NAME"; Expression = {"HistoricalStock"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HofAntiMoneyLaundering"}} , @{Name = "TABLE_NAME"; Expression = {"HofAntiMoneyLaundering"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HofCyberSecurity"}} , @{Name = "TABLE_NAME"; Expression = {"HofCyberSecurity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HofSanctionsScreening"}} , @{Name = "TABLE_NAME"; Expression = {"HofSanctionsScreening"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Institution"}} , @{Name = "TABLE_NAME"; Expression = {"Institution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"InstitutionUnit"}} , @{Name = "TABLE_NAME"; Expression = {"InstitutionUnit"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"NewsAndSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"NewsAndSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"NewsAndSentimentNew"}} , @{Name = "TABLE_NAME"; Expression = {"NewsAndSentimentNew"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OFACSyanapseLinkData"}} , @{Name = "TABLE_NAME"; Expression = {"OFACSyanapseLinkData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OFACSyanapseLinkData1"}} , @{Name = "TABLE_NAME"; Expression = {"OFACSyanapseLinkData1"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OFACSyanapseLinkData2"}} , @{Name = "TABLE_NAME"; Expression = {"OFACSyanapseLinkData2"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OFACTType"}} , @{Name = "TABLE_NAME"; Expression = {"OFACTType"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OperatingExpenses"}} , @{Name = "TABLE_NAME"; Expression = {"OperatingExpenses"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBalanceSheet"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBalanceSheet"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBankCustomerRanking"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBankCustomerRanking"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBankGlobalRanking"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBankGlobalRanking"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBedOccupancyForecasted"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBedOccupancyForecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiComplianceReport"}} , @{Name = "TABLE_NAME"; Expression = {"pbiComplianceReport"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiCustomer"}} , @{Name = "TABLE_NAME"; Expression = {"pbiCustomer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiCustomerInsurance"}} , @{Name = "TABLE_NAME"; Expression = {"pbiCustomerInsurance"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiCustomerTransactions"}} , @{Name = "TABLE_NAME"; Expression = {"pbiCustomerTransactions"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEmployee"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEmployee"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgArticleSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgArticleSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgBigram"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgBigram"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgDetractor"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgDetractor"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgInitiativesComparison"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgInitiativesComparison"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgInstitutionUnitPolicyScore"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgInstitutionUnitPolicyScore"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgPolicy"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgPolicy"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiGlobalMarketPerformance"}} , @{Name = "TABLE_NAME"; Expression = {"pbiGlobalMarketPerformance"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiGlobalRisk"}} , @{Name = "TABLE_NAME"; Expression = {"pbiGlobalRisk"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitution"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitutionDetails"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitutionDetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitutionUnit"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitutionUnit"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInsuranceRisk"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInsuranceRisk"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiReadmissionPrediction"}} , @{Name = "TABLE_NAME"; Expression = {"PbiReadmissionPrediction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiRegion"}} , @{Name = "TABLE_NAME"; Expression = {"pbiRegion"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiRetailBankRisk"}} , @{Name = "TABLE_NAME"; Expression = {"pbiRetailBankRisk"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiROE"}} , @{Name = "TABLE_NAME"; Expression = {"pbiROE"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiVulnerabilities"}} , @{Name = "TABLE_NAME"; Expression = {"pbiVulnerabilities"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiWaitTimeForecast"}} , @{Name = "TABLE_NAME"; Expression = {"PbiWaitTimeForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Portfolio"}} , @{Name = "TABLE_NAME"; Expression = {"Portfolio"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pred_anomaly"}} , @{Name = "TABLE_NAME"; Expression = {"pred_anomaly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Region"}} , @{Name = "TABLE_NAME"; Expression = {"Region"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Sales"}} , @{Name = "TABLE_NAME"; Expression = {"Sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesVsExpense"}} , @{Name = "TABLE_NAME"; Expression = {"SalesVsExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SiteSecurity"}} , @{Name = "TABLE_NAME"; Expression = {"SiteSecurity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"States"}} , @{Name = "TABLE_NAME"; Expression = {"States"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Stockprice"}} , @{Name = "TABLE_NAME"; Expression = {"Stockprice"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TEST3"}} , @{Name = "TABLE_NAME"; Expression = {"TEST3"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Travel_Entertainment"}} , @{Name = "TABLE_NAME"; Expression = {"Travel_Entertainment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VTBByChannel"}} , @{Name = "TABLE_NAME"; Expression = {"VTBByChannel"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"AccountHeads"}} , @{Name = "TABLE_NAME"; Expression = {"AccountHeads"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ApplicationCollaterals"}} , @{Name = "TABLE_NAME"; Expression = {"ApplicationCollaterals"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Bank"}} , @{Name = "TABLE_NAME"; Expression = {"Bank"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Branches"}} , @{Name = "TABLE_NAME"; Expression = {"Branches"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Categorytypesrelation"}} , @{Name = "TABLE_NAME"; Expression = {"Categorytypesrelation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Churnlevelconfig"}} , @{Name = "TABLE_NAME"; Expression = {"Churnlevelconfig"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CreditCheck"}} , @{Name = "TABLE_NAME"; Expression = {"CreditCheck"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ExternalFinancialInstitute"}} , @{Name = "TABLE_NAME"; Expression = {"ExternalFinancialInstitute"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Financialholdinginstrument"}} , @{Name = "TABLE_NAME"; Expression = {"Financialholdinginstrument"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinYears"}} , @{Name = "TABLE_NAME"; Expression = {"FinYears"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FORMAT"}} , @{Name = "TABLE_NAME"; Expression = {"FORMAT"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FORMAT2"}} , @{Name = "TABLE_NAME"; Expression = {"FORMAT2"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FSI-Twitter-Data"}} , @{Name = "TABLE_NAME"; Expression = {"FSI-Twitter-Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Group"}} , @{Name = "TABLE_NAME"; Expression = {"Group"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"GroupFinancialHolding"}} , @{Name = "TABLE_NAME"; Expression = {"GroupFinancialHolding"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"GroupMembers"}} , @{Name = "TABLE_NAME"; Expression = {"GroupMembers"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Incomes"}} , @{Name = "TABLE_NAME"; Expression = {"Incomes"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"kyc"}} , @{Name = "TABLE_NAME"; Expression = {"kyc"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Ledgers"}} , @{Name = "TABLE_NAME"; Expression = {"Ledgers"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Lifemomentcategoryconfig"}} , @{Name = "TABLE_NAME"; Expression = {"Lifemomentcategoryconfig"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Lifemoments"}} , @{Name = "TABLE_NAME"; Expression = {"Lifemoments"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Lifemomentsconfigurations"}} , @{Name = "TABLE_NAME"; Expression = {"Lifemomentsconfigurations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Lifemomentsconfigurations_s"}} , @{Name = "TABLE_NAME"; Expression = {"Lifemomentsconfigurations_s"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"LifeMomentTypeConfig"}} , @{Name = "TABLE_NAME"; Expression = {"LifeMomentTypeConfig"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"LifeMomentTypeConfigs"}} , @{Name = "TABLE_NAME"; Expression = {"LifeMomentTypeConfigs"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"LoanApplication"}} , @{Name = "TABLE_NAME"; Expression = {"LoanApplication"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"LoanApplicationContact"}} , @{Name = "TABLE_NAME"; Expression = {"LoanApplicationContact"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"LoanApplicationContacts"}} , @{Name = "TABLE_NAME"; Expression = {"LoanApplicationContacts"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"LoanApplications"}} , @{Name = "TABLE_NAME"; Expression = {"LoanApplications"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OFAC"}} , @{Name = "TABLE_NAME"; Expression = {"OFAC"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PropertyHoldings"}} , @{Name = "TABLE_NAME"; Expression = {"PropertyHoldings"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RoleNew"}} , @{Name = "TABLE_NAME"; Expression = {"RoleNew"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Source"}} , @{Name = "TABLE_NAME"; Expression = {"Source"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"USHeaderMapReport"}} , @{Name = "TABLE_NAME"; Expression = {"USHeaderMapReport"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynapseLinkFSIDataHTAP"}} , @{Name = "TABLE_NAME"; Expression = {"SynapseLinkFSIDataHTAP"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SynapseLinkFSIData"}} , @{Name = "TABLE_NAME"; Expression = {"SynapseLinkFSIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInterestRevenue"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInterestRevenue"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiIncidentsSsDocument"}} , @{Name = "TABLE_NAME"; Expression = {"pbiIncidentsSsDocument"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiESG"}} , @{Name = "TABLE_NAME"; Expression = {"pbiESG"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiKPI"}} , @{Name = "TABLE_NAME"; Expression = {"pbiKPI"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiCustomerTransactionsCopy"}} , @{Name = "TABLE_NAME"; Expression = {"pbiCustomerTransactionsCopy"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)

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
    #Write-output "Data for $($dataTableLoad.TABLE_NAME) loaded."
}


##Search service 
Write-Host "-----------------Search service ---------------"
Add-Content log.txt "-----------------Search service ---------------"
RefreshTokens
# Create Search Service
#$sku = "Standard"
#New-AzSearchService -Name $searchName -ResourceGroupName $rgName -Sku $sku -Location $location

# Create search query key
Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
$queryKey = "QueryKey"
New-AzSearchQueryKey -Name $queryKey -ServiceName $searchName -ResourceGroupName $rgName

# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $searchName
$primaryAdminKey = $adminKeyPair.Primary

#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cog_marketdatacgsvc_name -g $rgName|ConvertFrom-json
$destinationKey=$key.key1

# Fetch connection string
$storageKey = (Get-AzStorageAccountKey -Name $storageAccountName -ResourceGroupName $rgName)[0].Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($storageAccountName);AccountKey=$($storageKey);EndpointSuffix=core.windows.net"

#resource id of cognitive_services_name
$resource=az resource show -g $rgName -n $cog_marketdatacgsvc_name --resource-type "Microsoft.CognitiveServices/accounts"|ConvertFrom-Json
$resourceId=$resource.id

# Create Index
Write-Host  "------Index----"
Get-ChildItem "artifacts/search" -Filter incident-index.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/indexes?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

# Create Datasource endpoint
Write-Host  "------Datasource----"
Get-ChildItem "artifacts/search" -Filter search_datasource.json |
        ForEach-Object {
            $datasourceDefinition = (Get-Content $_.FullName -Raw).replace("#STORAGE_CONNECTION#", $storageConnectionString)
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

             $url = "https://$searchName.search.windows.net/datasources?api-version=2020-06-30"
             $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $dataSourceDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

#Replace connection string in search_skillset.json
(Get-Content -path artifacts/search/search_skillset.json -Raw) | Foreach-Object { $_ `
				-replace '#RESOURCE_ID#', $resourceId`
				-replace '#STORAGEACCOUNTNAME#', $storageAccountName`
				-replace '#STORAGEKEY#', $storageKey`
				-replace '#COGNITIVE_API_KEY#', $destinationKey`
			} | Set-Content -Path artifacts/search/search_skillset.json

# Creat Skillset
Write-Host  "------Skillset----"
Get-ChildItem "artifacts/search" -Filter search_skillset.json |
        ForEach-Object {
            $skillsetDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/skillsets?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $skillsetDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

# Create Indexers
Write-Host  "------Indexers----"
Get-ChildItem "artifacts/search" -Filter search_indexer.json |
        ForEach-Object {
            $indexerDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/indexers?api-version=2020-06-30"
           $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexerDefinition | ConvertTo-Json
        }
	
Write-Host  "-----------------AML Workspace ---------------"
Add-Content log.txt "-----------AML Workspace -------------"
RefreshTokens

$forms_cogs_endpoint = "https://"+$forms_cogs_name+".cognitiveservices.azure.com"
$search_uri = "https://"+$searchName+".search.windows.net"

$filepath="./artifacts/amlnotebooks/GlobalVariables.py"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key).Replace("#SEARCH_API_KEY#", $searchKey).Replace("#SEARCH_URI#", $search_uri).Replace("#FORM_RECOGNIZER_ENDPOINT#", $forms_cogs_endpoint).Replace("#FORM_RECOGNIZER_API_KEY#", $forms_cogs_keys.Key1).Replace("#ACCOUNT_OPENING_FORM_RECOGNIZER_MODEL_ID#", $modelId).Replace("#INCIDENT_FORM_RECOGNIZER_MODEL_ID#", $modelId).Replace("#SUBSCRIPTION_ID#", $subscriptionId).Replace("#RESOURCE_GROUP_NAME#", $rgName).Replace("#WORKSPACE_NAME#", $amlworkspacename).Replace("#TRANSLATOR_SERVICE_NAME#", $cog_translator_name).Replace("#TRANSLATOR_SERVICE_KEY#", $cog_translator_key.Key1).Replace("#CPU_SHELL#",$cpuShell)
Set-Content -Path $filepath -Value $item

#AML Workspace
#create aml workspace
az extension add -n azure-cli-ml
az ml workspace create -w $amlworkspacename -g $rgName

#attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
az ml folder attach -w $amlworkspacename -g $rgName -e aml
start-sleep -s 10

#create and delete a compute instance to get the code folder created in default store
az ml computetarget create computeinstance -n $cpuShell -s "STANDARD_DS2_V2" -v

#get default data store
$defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
$defaultdatastoreaccname = $defaultdatastore.account_name

#get fileshare and code folder within that
$storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
$share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context 
$shareName = $share[0].Name
$notebooks=Get-ChildItem "./artifacts/amlnotebooks" | Select BaseName
foreach($notebook in $notebooks)
{
	if($notebook.BaseName -eq "GlobalVariables")
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".py"
		$path="/Users/"+$notebook.BaseName+".py"
	}
     elseif($notebook.BaseName -eq "retail_banking_customer_churn_for_model" -or $notebook.BaseName  -eq "retail_banking_customer_churn_data" -or $notebook.BaseName  -eq "prepared_customer_churn_data")
    {
        $source="./artifacts/amlnotebooks/"+$notebook.BaseName+".csv"
		$path="/Users/"+$notebook.BaseName+".csv"
	}
    elseif($notebook.BaseName -eq "202045000" -or $notebook.BaseName  -eq "202045001" -or $notebook.BaseName  -eq "202045002" -or $notebook.BaseName  -eq "202045003"  )
    {
        $source="./artifacts/amlnotebooks/"+$notebook.BaseName+".json"
		$path="/Users/"+$notebook.BaseName+".json"
	}
	else
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path="/Users/"+$notebook.BaseName+".ipynb"
	}

Write-Host " Uplaoding AML assets : $($notebook.BaseName)"
Set-AzStorageFileContent `
   -Context $storageAcct.Context `
   -ShareName $shareName `
   -Source $source `
   -Path $path
}

#create aks compute
#az ml computetarget create aks --name  "new-aks" --resource-group $rgName --workspace-name $amlWorkSpaceName
az ml computetarget delete -n $cpuShell -v

##Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "--------- PBI connections update---------"	

foreach($report in $reportList)
{
    if($report.name -eq "Fsi Demo Master Images" -or $report.name -eq "Realtime Operational Analytics Static" -or $report.name -eq "Realtime Twitter Analytics"  -or $report.name -eq "Chief Risk Officer Realtime" -or $report.name -eq "Chief Risk Officer After Dashboard Realtime"  -or $report.name -eq "FSI Realtime KPI" -or $report.name -eq "FSI CCO Realtime Before" -or $report.name -eq "Head of Financial Intelligence Realtime"  -or $report.name -eq "Head of Financial Intelligence After Dashboard Realtime" -or $report.name -eq "Global overview tiles" -or $report.name -eq "FSI-Chicklets"  -or $report.name -eq "FSITwitterreport" -or $report.name -eq "ESGDashboardV2_KPIandGraphs" -or $report.name -eq "FarmBeats Analytics" -or $report.name -eq "Master Images for FSI Dashboardpbix_v2")
    {
       continue;     
	}
	elseif($report.name -eq "ESG Metrics for Woodgrove" -or $report.name -eq  "FSI Incident Report" -or $report.name -eq "FSI HTAP" -or $report.name -eq "ESG Report Synapse Import Mode" -or $report.name -eq "Geospatial Fraud Detection Miami" -or $report.name -eq "Finance Report" -or $report.name -eq "globalmarkets" -or $report.name -eq "FSI CCO Dashboard"  -or $report.name -eq "FSI CEO Dashboard" -or $report.name -eq  "Company Insight KPIs" -or $report.name -eq "US Map with header" -or $report.name -eq "MSCI report" -or $report.name -eq "FSI Predictive Analytics" -or $report.name -eq "Head of Financial Intelligence" -or $report.name -eq "Group Chief Risk Officer")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}

	Write-Host "PBI connections updating for report : $($report.name)"	
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"} -ErrorAction SilentlyContinue;
		
    start-sleep -s 5
}

#databricks
Add-Content log.txt "------databricks------"
Write-Host "--------- Databricks---------"
$tenantId = $(az account show --query tenantId -o tsv)
$dbswsId = $(az resource show `
        --resource-type Microsoft.Databricks/workspaces `
        -g "$rgName" `
        -n "$databricks_workspace_name" `
        --query id -o tsv)

# Get a token for the global Databricks application.
# The resource ID is fixed and never changes.
$token_response = $(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json) | ConvertFrom-Json
$token = $token_response.accessToken

# Get a token for the Azure management API
$token_response = $(az account get-access-token --resource https://management.core.windows.net/ --output json) | ConvertFrom-Json
$azToken = $token_response.accessToken
$uri = "https://$($location).azuredatabricks.net/api/2.0/token/create"
$baseUrl = "https://$($location).azuredatabricks.net"

# You can also generate a PAT token. Note the quota limit of 600 tokens.
$body = '{"lifetime_seconds": 100000, "comment": "Ranatest" }';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")
$headers.Add("X-Databricks-Azure-SP-Management-Token", "$azToken")
$headers.Add("X-Databricks-Azure-Workspace-Resource-Id", "$dbswsId")
$pat_token = Invoke-RestMethod -Uri $uri -Method Post -Body $body -H $headers 
#Create a dir in dbfs & workspace to store the scipt files and init file
$requestHeaders = @{
    Authorization  = "Bearer" + " " + $pat_token.token_value
    "Content-Type" = "application/json"
}

$body = '{"path": "dbfs:/FileStore/geospatial_fraud_detection" }';
#get job list
$endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$body = '{"path": "dbfs:/FileStore/demo-fsi/geoscan/python" }';
#get job list
$endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$body = '{"path": "dbfs:/FileStore/demo-fsi/geoscan/synapse_migration" }';   
#get job list
$endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

 $body = '{"path": "dbfs:/FileStore/demo-fsi/geoscan/tables" }';   
#get job list
$endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

(Get-Content -path artifacts/databricks/03_esg_market.ipynb -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path artifacts/databricks/03_esg_market.ipynb

(Get-Content -path artifacts/databricks/01_esg.ipynb -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path artifacts/databricks/01_esg.ipynb

(Get-Content -path artifacts/databricks/Customer_Churn.ipynb -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path artifacts/databricks/Customer_Churn.ipynb

(Get-Content -path artifacts/databricks/02_esg_scoring.scala -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path artifacts/databricks/02_esg_scoring.scala

(Get-Content -path artifacts/databricks/Fraud_Migration.ipynb -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path artifacts/databricks/Fraud_Migration.ipynb

$files = Get-ChildItem -path "artifacts/databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
Set-Location ./artifacts/databricks
foreach ($name in $files.name) {
    if( $name -eq "miami.csv" )
    {
          $fileContent = get-content -raw $name
          $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
          $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
          $requestHeaders = @{
              Authorization = "Bearer" + " " + $pat_token.token_value
          }
          $body = '{"path": "dbfs:/FileStore/geospatial_fraud_detection/miami.csv","contents":"' + $fileContentEncoded + '" }';
          #get job list
          $endPoint = $baseURL +  "/api/2.0/dbfs/put"
          Invoke-RestMethod $endPoint `
              -ContentType 'application/json' `
              -Method Post `
              -Headers $requestHeaders `
              -Body $body
    } 
    elseif( $name -eq "02_esg_scoring.scala" )
    { 
          $fileContent = get-content -raw $name
          $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
          $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
          $requestHeaders = @{
              Authorization = "Bearer" + " " + $pat_token.token_value
	      			}
          $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "SCALA", "format": "SOURCE"}'
          
	      			$endPoint = $baseURL + "/api/2.0/workspace/import"
	      			Invoke-RestMethod $endPoint `
              -ContentType 'application/json' `
              -Method Post `
              -Headers $requestHeaders `
              -Body $body
    } 
    else
    {
          $fileContent = get-content -raw $name
          $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
          $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
          $requestHeaders = @{
              Authorization = "Bearer" + " " + $pat_token.token_value
	      			}
          $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
          
	      			$endPoint = $baseURL + "/api/2.0/workspace/import"
	      			Invoke-RestMethod $endPoint `
              -ContentType 'application/json' `
              -Method Post `
              -Headers $requestHeaders `
              -Body $body
    }
}
Set-Location ../../

#Web app
Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------Deploy web app ---------------"
RefreshTokens

$device = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iot_hub_name -DeviceId realtime-traffic-device 
$zips = @("app_fsidemo","realtime_kpi_simulator","azure-maps-app")
foreach($zip in $zips)
{
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

$spname="Fsi Demo $deploymentid"
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
				
(Get-Content -path app_fsidemo/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path app_fsidemo/appsettings.json

(Get-Content -path app_fsidemo/wwwroot/geospatial-azuremap.html -Raw) | Foreach-Object { $_ `
                -replace '#APP_MAPS_SERVICE_NAME#', $app_maps_service_name`
				-replace '#MAPS_KEY#', $accounts_map_key`			
        } | Set-Content -Path app_fsidemo/wwwroot/geospatial-azuremap.html

#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable
$ht.add("#STORAGE_ACCOUNT#", $dataLakeAccountName)
$ht.add("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$ht.add("#APP_NAME#", $fsi_poc_app_service_name)
$ht.add("#CHIEF_RISK_OFFICER_AFTER_DASHBOARD_REALTIME#", $($reportList | where {$_.Name -eq "Chief Risk Officer After Dashboard Realtime"}).ReportId)
$ht.add("#CHIEF_RISK_OFFICER_REALTIME#", $($reportList | where {$_.Name -eq "Chief Risk Officer Realtime"}).ReportId)
$ht.add("#ESG_METRICS_FOR_WOODGROVE#", $($reportList | where {$_.Name -eq "ESG Metrics for Woodgrove"}).ReportId)
$ht.add("#ESG_REPORT_SYNAPSE#", $($reportList | where {$_.Name -eq "ESG Report Synapse Import Mode"}).ReportId)
$ht.add("#FSI_CCO_REALTIME_BEFORE#", $($reportList | where {$_.Name -eq "FSI CCO Realtime Before"}).ReportId)
$ht.add("#FSI_HTAP#", $($reportList | where {$_.Name -eq "FSI HTAP"}).ReportId)
$ht.add("#FSI_INCIDENT_REPORT#", $($reportList | where {$_.Name -eq "FSI Incident Report"}).ReportId)
$ht.add("#FSI_PREDICTIVE_ANALYTICS#", $($reportList | where {$_.Name -eq "FSI Predictive Analytics"}).ReportId)
$ht.add("#FSI_REALTIME_KPI#", $($reportList | where {$_.Name -eq "FSI Realtime KPI"}).ReportId)
$ht.add("#GEOSPATIAL_FRAUD_DETECTION_MIAMI#", $($reportList | where {$_.Name -eq "Geospatial Fraud Detection Miami"}).ReportId)
$ht.add("#HEAD_OF_FINANCIAL_INTELLIGENCE_AFTER_DASHBOARD_REALTIME#", $($reportList | where {$_.Name -eq "Head of Financial Intelligence After Dashboard Realtime"}).ReportId)
$ht.add("#HEAD_OF_FINANCIAL_INTELLIGENCE_REALTIME#", $($reportList | where {$_.Name -eq "Head of Financial Intelligence Realtime"}).ReportId)
$ht.add("#MSCI_REPORT#", $($reportList | where {$_.Name -eq "MSCI report"}).ReportId)
$ht.add("#US_MAP_WITH_HEADER#", $($reportList | where {$_.Name -eq "US Map with header"}).ReportId)
$ht.add("#FSI_CEO_DASHBOARD#", $($reportList | where {$_.Name -eq "FSI CEO Dashboard"}).ReportId)
$ht.add("#FSI_TWITTER_REPORT#", $($reportList | where {$_.Name -eq "FSITwitterreport"}).ReportId)
$ht.add("#FINANCE_REPORT#", $($reportList | where {$_.Name -eq "Finance Report"}).ReportId)
$ht.add("#GLOBAL_OVERVIEW_TILES#", $($reportList | where {$_.Name -eq "Global overview tiles"}).ReportId)
$ht.add("#GLOBAL_MARKETS#", $($reportList | where {$_.Name -eq "globalmarkets"}).ReportId)
$ht.add("#MSCIBeforeReportId#", $($reportList | where {$_.Name -eq "MSCI Report"}).ReportId)
$ht.add("#MSCIAfterReportId#", $($reportList | where {$_.Name -eq "MSCI Report"}).ReportId)
$ht.add("#ESGReportId#", $($reportList | where {$_.Name -eq "ESG Report Synapse Import Mode"}).ReportId)
$ht.add("#fc_reportId#", $($reportList | where {$_.Name -eq ""}).ReportId)
$ht.add("#SPEECH_KEY#", $cog_speech_key.key1)
$ht.add("#SPEECH_REGION#", $location)
$ht.add("#FSI_CCO_DASHBOARD#", $($reportList | where {$_.Name -eq "FSI CCO Dashboard"}).ReportId)

$filePath = "./app_fsidemo/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./app_fsidemo/*" -DestinationPath "./app_fsidemo.zip"

az webapp stop --name $fsi_poc_app_service_name --resource-group $rgName

try{
az webapp deployment source config-zip --resource-group $rgName --name $fsi_poc_app_service_name --src "./app_fsidemo.zip"
}
catch
{
}

cd azure-maps-app
npm install
cd ..
Compress-Archive -Path "./azure-maps-app/*" -DestinationPath "./azure-maps-app.zip"
Start-Sleep -s 10
try{
az webapp deployment source config-zip --resource-group $rgName --name $app_maps_service_name --src "./azure-maps-app.zip"
}
catch
{
}

$config = az webapp config appsettings set -g $rgName -n $app_maps_service_name --settings DB_DATABASE=$mssql_database_name
$config = az webapp config appsettings set -g $rgName -n $app_maps_service_name --settings DB_PASSSWORD=$mssql_administrator_password
$config = az webapp config appsettings set -g $rgName -n $app_maps_service_name --settings DB_SERVER=$server
$config = az webapp config appsettings set -g $rgName -n $app_maps_service_name --settings DB_USERNAME=$mssql_administrator_login

$iot_device_connection= $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub_name -DeviceId realtime-traffic-device).ConnectionString

$filepath="./realtime_kpi_simulator/.env"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#PBI_STREAMING_URL_BEFOREANDAFTER_SCENARIO_GROUPCEO_REALTIME#", $before_and_after_scenario_group_ceo_url).Replace("#PBI_STREAMING_URL_BEFORE_SCENARIO_CCOREALTIME#", $before_scenario_cco_url).Replace("#PBI_STREAMING_URL_BEFORE_SCENARIO_FINANCIAL_HEADANDCHIEF_RISLREALTIME#", $before_scenario_financial_hcrr_url).Replace("#PBI_STREAMING_URL_AFTER_SCENARIO_FINANCIAL_HEADANDCHIEF_RISLREALTIME#", $after_scenario_financial_hcrr_url).Replace("#IOT_HUB_DEVICE_CS#", $iot_device_connection)
Set-Content -Path $filepath -Value $item 

# deploy the codes on app services  
Write-Information "Deploying web app"
cd realtime_kpi_simulator
az webapp up --resource-group $rgName --name $app_name_realtime_kpi_simulator
cd ..
Start-Sleep -s 10

$AfterScenarioFinancialHeadAndChiefRislRealtimeConfig   = '{\"main_data_frequency_seconds\":1,\"urlString\":\"'+$after_scenario_financial_hcrr_url+'\",\"data\":[{\"InvestigationResponseTime\":{\"minValue\":1,\"maxValue\":3}},{\"TargetInvestigationResponseTime\":{\"minValue\":7,\"maxValue\":7}},{\"PerfvsEfficiency\":{\"minValue\":54,\"maxValue\":60}},{\"TargetPerfvsEfficiency\":{\"minValue\":30,\"maxValue\":30}},{\"SanctionsAlertRate\":{\"minValue\":1.1,\"maxValue\":1.5}},{\"TargetSanctionsAlertRate\":{\"minValue\":1.3,\"maxValue\":1.3}},{\"OpenTransactionsAlertLevel1\":{\"minValue\":2144,\"maxValue\":2368}},{\"TargetOpenTransactionsAlertLevel1\":{\"minValue\":2256,\"maxValue\":2256}},{\"OpenTransactionsAlertLevel2\":{\"minValue\":17,\"maxValue\":19}},{\"TargetOpenTransactionsAlertLevel2\":{\"minValue\":18,\"maxValue\":18}},{\"AlertsClosedWithSLA\":{\"minValue\":96,\"maxValue\":97}},{\"TargetAlertsClosedWithSLA\":{\"minValue\":95,\"maxValue\":95}},{\"KYCAlertinSanctions\":{\"minValue\":1.2,\"maxValue\":1.9}},{\"TargetKYCAlertinSanctions\":{\"minValue\":1.82,\"maxValue\":1.82}},{\"KYCAlertinPEP\":{\"minValue\":3.1,\"maxValue\":3.9}},{\"TargetKYCAlertinPEP\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"KYCAlertinMedia\":{\"minValue\":3.1,\"maxValue\":3.9}},{\"TargetKYCAlertinMedia\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"Vulnerabilities\":{\"minValue\":213,\"maxValue\":319}},{\"TargetVulnerabilities\":{\"minValue\":325,\"maxValue\":325}},{\"InvestigationResponseTimeCyberSec\":{\"minValue\":1,\"maxValue\":3}},{\"TargetInvestigationResponseTimeCyberSec\":{\"minValue\":3,\"maxValue\":3}},{\"TerminatedEmployeesAccess\":{\"minValue\":1.1,\"maxValue\":2}},{\"TargetTerminatedEmployeesAccess\":{\"minValue\":1.5,\"maxValue\":1.5}},{\"UnauthorizedEmployees\":{\"minValue\":0,\"maxValue\":2}},{\"TargetUnauthorizedEmployees\":{\"minValue\":6,\"maxValue\":6}},{\"NoHardwareSecurity\":{\"minValue\":4,\"maxValue\":9}},{\"TargetNoHardwareSecurity\":{\"minValue\":0,\"maxValue\":0}},{\"CreditRiskExposure\":{\"minValue\":10,\"maxValue\":20}},{\"TargetCreditRiskExposure\":{\"minValue\":15,\"maxValue\":15}},{\"FinancialCrime\":{\"minValue\":0.5,\"maxValue\":3}},{\"TargetFinancialCrime\":{\"minValue\":2,\"maxValue\":2}},{\"TradingExposure\":{\"minValue\":1,\"maxValue\":3}},{\"TargetTradingExposure\":{\"minValue\":5.5,\"maxValue\":5.5}},{\"ESGAssets\":{\"minValue\":35,\"maxValue\":45}},{\"TargetESGAssets\":{\"minValue\":25,\"maxValue\":25}},{\"ClaimsProcessingCycleTime\":{\"minValue\":1,\"maxValue\":2}},{\"TargetClaimsProcessingCycleTime\":{\"minValue\":1,\"maxValue\":1}},{\"UnderwritingEfficiency\":{\"minValue\":50,\"maxValue\":57}},{\"TargetUnderwritingEfficiency\":{\"minValue\":55,\"maxValue\":55}},{\"OverallCreditRisk\":{\"minValue\":30,\"maxValue\":55}},{\"TargetOverallCreditRisk\":{\"minValue\":50,\"maxValue\":50}},{\"OverallOperationalRisk\":{\"minValue\":1,\"maxValue\":18}},{\"TargetOverallOperationalRisk\":{\"minValue\":10,\"maxValue\":10}}]}'
$config = az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings AfterScenarioFinancialHeadAndChiefRislRealtimeConfig=$AfterScenarioFinancialHeadAndChiefRislRealtimeConfig

$BeforeAndAfterScenarioGroupCEORealtimeConfigs   = '{\"main_data_frequency_seconds\":1,\"urlString\":\"'+$before_and_after_scenario_group_ceo_url+'\",\"data\":[{\"CSAT\":{\"minValue\":1,\"maxValue\":5}},{\"AverageAttrition\":{\"minValue\":11,\"maxValue\":15}},{\"ComplianceScore\":{\"minValue\":1,\"maxValue\":4}},{\"CustomerChurn\":{\"minValue\":18,\"maxValue\":23}},{\"CustomerChurnAfter\":{\"minValue\":9,\"maxValue\":15}},{\"EmployeeSatisfaction\":{\"minValue\":2.5,\"maxValue\":2.75}},{\"EmployeeSatisfactionAfter\":{\"minValue\":3.5,\"maxValue\":3.75}},{\"TargetCustomerChurn\":{\"minValue\":24,\"maxValue\":24}},{\"TargetCustomerChurnAfter\":{\"minValue\":10,\"maxValue\":10}},{\"TargetAverageAttrition\":{\"minValue\":14,\"maxValue\":14}},{\"TargetEmployeeSatisfaction\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"TargetEmployeeSatisfactionAfter\":{\"minValue\":3.75,\"maxValue\":3.75}},{\"TargetComplianceScore\":{\"minValue\":4,\"maxValue\":4}},{\"RelativePerformancetoS&P500\":{\"minValue\":-25,\"maxValue\":-5}},{\"RelativePerformancetoS&P500After\":{\"minValue\":1,\"maxValue\":8}},{\"TargetRelativePerformancetoS&P500\":{\"minValue\":-15,\"maxValue\":-15}},{\"TargetRelativePerformancetoS&P500After\":{\"minValue\":5,\"maxValue\":5}},{\"QuarterlyClaimsProcessingEfficiency\":{\"minValue\":-36,\"maxValue\":-20}},{\"QuarterlyClaimsProcessingEfficiencyAfter\":{\"minValue\":1,\"maxValue\":15}},{\"TargetQuarterlyClaimsProcessingEfficiency\":{\"minValue\":-28,\"maxValue\":-28}},{\"TargetQuarterlyClaimsProcessingEfficiencyAfter\":{\"minValue\":9,\"maxValue\":9}},{\"CSRRating\":{\"minValue\":3.6,\"maxValue\":4}},{\"CSRRatingAfter\":{\"minValue\":4.1,\"maxValue\":4.7}},{\"TargetCSRRating\":{\"minValue\":3.8,\"maxValue\":3.8}},{\"TargetCSRRatingAfter\":{\"minValue\":4.4,\"maxValue\":4.4}},{\"ChannelEngagementRiskofChurn\":{\"minValue\":40,\"maxValue\":45}},{\"ChannelEngagementRiskofChurnAfter\":{\"minValue\":30,\"maxValue\":34}},{\"TargetChannelEngagementRiskofChurn\":{\"minValue\":42,\"maxValue\":42}},{\"TargetChannelEngagementRiskofChurnAfter\":{\"minValue\":32,\"maxValue\":32}},{\"ProjectedAnnualGrowthMarketShare\":{\"minValue\":-19,\"maxValue\":-13}},{\"ProjectedAnnualGrowthMarketShareAfter\":{\"minValue\":7,\"maxValue\":12}},{\"TargetProjectedAnnualGrowthMarketShare\":{\"minValue\":-15,\"maxValue\":-15}},{\"TargetProjectedAnnualGrowthMarketShareAfter\":{\"minValue\":11,\"maxValue\":11}},{\"ProjectedAnnualGrowthEmployeeStrength\":{\"minValue\":-18,\"maxValue\":-11}},{\"ProjectedAnnualGrowthEmployeeStrengthAfter\":{\"minValue\":15,\"maxValue\":25}},{\"TargetProjectedAnnualGrowthEmployeeStrength\":{\"minValue\":-13,\"maxValue\":-13}},{\"TargetProjectedAnnualGrowthEmployeeStrengthAfter\":{\"minValue\":22,\"maxValue\":22}},{\"ActiveSensors\":{\"minValue\":43000,\"maxValue\":45000}},{\"TargetActiveSensors\":{\"minValue\":40000,\"maxValue\":40000}},{\"InvestmentBefore\":{\"minValue\":100,\"maxValue\":130}},{\"InvestmentAfter\":{\"minValue\":200,\"maxValue\":250}},{\"CreditCardTransactionVolume\":{\"minValue\":8,\"maxValue\":10,\"Behaviour\":\"increament\",\"SpikeValue\":0.0022}},{\"EmployeeOnboardCycle\":{\"minValue\":15,\"maxValue\":30}},{\"EmployeeOnboardCycleAfter\":{\"minValue\":1,\"maxValue\":7}},{\"TargetEmployeeOnboardCycle\":{\"minValue\":7,\"maxValue\":7}},{\"CreditCardTransactionAmount\":{\"minValue\":120,\"maxValue\":225,\"Behaviour\":\"increament\",\"SpikeValue\":0.1166}},{\"S&P500IndexValue\":{\"minValue\":3400,\"maxValue\":4250,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"randomMin\":-0.1,\"randomMax\":1.1,\"SpikeValue\":21.25,\"ReleaseValue\":42.5,\"relatableTo\":[{\"WoodgrovePortfolioIndexValue\":{\"minValue\":3280,\"maxValue\":3900,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"relationship\":\"SmallerNumber\",\"randomMin\":0.5,\"randomMax\":1,\"SpikeValue\":15.5,\"ReleaseValue\":31}}]}},{\"S&P500IndexValueMid\":{\"minValue\":3280,\"maxValue\":3900,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"randomMin\":-0.1,\"randomMax\":1.1,\"SpikeValue\":21.25,\"ReleaseValue\":42.5,\"relatableTo\":[{\"WoodgrovePortfolioIndexValueMid\":{\"minValue\":3350,\"maxValue\":3970,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"relationship\":\"BiggerNumber\",\"randomMin\":0.5,\"randomMax\":1,\"SpikeValue\":21.25,\"ReleaseValue\":42.5}}]}},{\"S&P500IndexValueAfter\":{\"minValue\":3280,\"maxValue\":3900,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"randomMin\":-0.1,\"randomMax\":1.1,\"SpikeValue\":15.5,\"ReleaseValue\":31,\"relatableTo\":[{\"WoodgrovePortfolioIndexValueAfter\":{\"minValue\":3400,\"maxValue\":4250,\"Behaviour\":\"increament-decreament\",\"Flag\":0,\"relationship\":\"BiggerNumber\",\"randomMin\":0.5,\"randomMax\":1,\"SpikeValue\":21.25,\"ReleaseValue\":42.5}}]}}]}'
$config = az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings BeforeAndAfterScenarioGroupCEORealtimeConfigs=$BeforeAndAfterScenarioGroupCEORealtimeConfigs

$BeforeScenarioCCORealtimeConfig   = '{\"main_data_frequency_seconds\":1,\"urlString\":\"'+$before_scenario_cco_url+'\",\"data\":[{\"NPS\":{\"minValue\":-20,\"maxValue\":-5}},{\"TargetNPS\":{\"minValue\":-10,\"maxValue\":-10}},{\"CustomerChurn\":{\"minValue\":35,\"maxValue\":45}},{\"TargetCustomerChurn\":{\"minValue\":30,\"maxValue\":30}},{\"AccountOpeningTime\":{\"minValue\":24,\"maxValue\":50}},{\"TargetAccountOpeningTime\":{\"minValue\":30,\"maxValue\":30}},{\"RequestsWithinSLA\":{\"minValue\":50,\"maxValue\":55}},{\"TargetRequestsWithinSLA\":{\"minValue\":52,\"maxValue\":52}},{\"SocialSentiment\":{\"minValue\":[\"Negative\",\"Neutral\"]}},{\"NPSAfter\":{\"minValue\":7,\"maxValue\":12}},{\"TargetNPSAfter\":{\"minValue\":10,\"maxValue\":10}},{\"CustomerChurnAfter\":{\"minValue\":15,\"maxValue\":20}},{\"TargetCustomerChurnAfter\":{\"minValue\":25,\"maxValue\":25}},{\"AccountOpeningTimeAfter\":{\"minValue\":8,\"maxValue\":12}},{\"TargetAccountOpeningTimeAfter\":{\"minValue\":10,\"maxValue\":10}},{\"RequestsWithinSLAAfter\":{\"minValue\":55,\"maxValue\":65}},{\"TargetRequestsWithinSLAAfter\":{\"minValue\":55,\"maxValue\":55}},{\"SocialSentimentAfter\":{\"minValue\":[\"Good\",\"Neutral\"]}}]}'
$config = az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings BeforeScenarioCCORealtimeConfig=$BeforeScenarioCCORealtimeConfig

$BeforeScenarioFinancialHeadAndChiefRislRealtimeConfig   = '"{\"main_data_frequency_seconds\":1,\"urlString\":\"'+$before_scenario_financial_hcrr_url+'\",\"data\":[{\"InvestigationResponseTime\":{\"minValue\":5,\"maxValue\":12}},{\"TargetInvestigationResponseTime\":{\"minValue\":7,\"maxValue\":7}},{\"PerfvsEfficiency\":{\"minValue\":28,\"maxValue\":32}},{\"TargetPerfvsEfficiency\":{\"minValue\":30,\"maxValue\":30}},{\"SanctionsAlertRate\":{\"minValue\":3.7,\"maxValue\":4.5}},{\"TargetSanctionsAlertRate\":{\"minValue\":1.3,\"maxValue\":1.3}},{\"OpenTransactionsAlertLevel1\":{\"minValue\":2368,\"maxValue\":2481}},{\"TargetOpenTransactionsAlertLevel1\":{\"minValue\":2256,\"maxValue\":2256}},{\"OpenTransactionsAlertLevel2\":{\"minValue\":20,\"maxValue\":24}},{\"TargetOpenTransactionsAlertLevel2\":{\"minValue\":18,\"maxValue\":18}},{\"AlertsClosedWithSLA\":{\"minValue\":85,\"maxValue\":94}},{\"TargetAlertsClosedWithSLA\":{\"minValue\":95,\"maxValue\":95}},{\"KYCAlertinSanctions\":{\"minValue\":3.2,\"maxValue\":3.7}},{\"TargetKYCAlertinSanctions\":{\"minValue\":1.82,\"maxValue\":1.82}},{\"KYCAlertinPEP\":{\"minValue\":3.1,\"maxValue\":3.9}},{\"TargetKYCAlertinPEP\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"KYCAlertinMedia\":{\"minValue\":3.1,\"maxValue\":3.9}},{\"TargetKYCAlertinMedia\":{\"minValue\":3.5,\"maxValue\":3.5}},{\"Vulnerabilities\":{\"minValue\":700,\"maxValue\":851}},{\"TargetVulnerabilities\":{\"minValue\":750,\"maxValue\":750}},{\"InvestigationResponseTimeCyberSec\":{\"minValue\":11,\"maxValue\":24}},{\"TargetInvestigationResponseTimeCyberSec\":{\"minValue\":3,\"maxValue\":3}},{\"TerminatedEmployeesAccess\":{\"minValue\":5,\"maxValue\":15}},{\"TargetTerminatedEmployeesAccess\":{\"minValue\":1.5,\"maxValue\":1.5}},{\"UnauthorizedEmployees\":{\"minValue\":5,\"maxValue\":15}},{\"TargetUnauthorizedEmployees\":{\"minValue\":6,\"maxValue\":6}},{\"NoHardwareSecurity\":{\"minValue\":30,\"maxValue\":45}},{\"TargetNoHardwareSecurity\":{\"minValue\":0,\"maxValue\":0}},{\"CreditRiskExposure\":{\"minValue\":35,\"maxValue\":75}},{\"TargetCreditRiskExposure\":{\"minValue\":55,\"maxValue\":55}},{\"FinancialCrime\":{\"minValue\":12,\"maxValue\":16}},{\"TargetFinancialCrime\":{\"minValue\":2,\"maxValue\":2}},{\"TradingExposure\":{\"minValue\":11,\"maxValue\":15}},{\"TargetTradingExposure\":{\"minValue\":5.5,\"maxValue\":5.5}},{\"ESGAssets\":{\"minValue\":12,\"maxValue\":15}},{\"TargetESGAssets\":{\"minValue\":25,\"maxValue\":25}},{\"ClaimsProcessingCycleTime\":{\"minValue\":3,\"maxValue\":7}},{\"TargetClaimsProcessingCycleTime\":{\"minValue\":1,\"maxValue\":1}},{\"UnderwritingEfficiency\":{\"minValue\":33,\"maxValue\":46}},{\"TargetUnderwritingEfficiency\":{\"minValue\":55,\"maxValue\":55}},{\"OverallCreditRisk\":{\"minValue\":60,\"maxValue\":75}},{\"TargetOverallCreditRisk\":{\"minValue\":50,\"maxValue\":50}},{\"OverallOperationalRisk\":{\"minValue\":40,\"maxValue\":65}},{\"TargetOverallOperationalRisk\":{\"minValue\":10,\"maxValue\":10}}]}'
$config = az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings BeforeScenarioFinancialHeadAndChiefRislRealtimeConfig=$BeforeScenarioFinancialHeadAndChiefRislRealtimeConfig

$IoTSimulatorConfigs = '"{\"main_data_frequency_seconds\":1,\"data\":[{\"before-foottraffic\":{\"minValue\":18,\"maxValue\":25}},{\"after-foottraffic\":{\"minValue\":35,\"maxValue\":45}}]}"'
$config = az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings IoTSimulatorConfigs=$IoTSimulatorConfigs

$IoTHubConfig = '"{\"frequency\":1,\"connection\":{\"provisioning_host\":\"global.azure-devices-provisioning.net\",\"id_scope\":\"0ne001BF93E\",\"registration_id\":\"7jqqgjhj0j\",\"symmetric_key\":\"ctSxPAs\\/r9f99k+NPsTADiEwmodz6lmBXJpagDXPE7o=\",\"IoTHubConnectionString\":\"'+$iot_device_connection+'\"}}"'
$config = az webapp config appsettings set -g $rgName -n $app_name_realtime_kpi_simulator --settings IoTHubConfig=$IoTHubConfig

az webapp start  --name $app_name_realtime_kpi_simulator --resource-group $rgName
az webapp start --name $fsi_poc_app_service_name --resource-group $rgName
az webapp start --name $app_maps_service_name --resource-group $rgName

foreach($zip in $zips)
{
	if($zip -eq "realtime_kpi_simulator")
	{
	continue
	}

    remove-item -path "./$($zip).zip" -recurse -force
}

#MSSQL
Add-Content log.txt "------deploy MSSQL------"
Write-Host  "-----------Uploading MSSQL Data ---------------"
$SQLScriptsPath="./artifacts/sqlscripts"
$ip = Invoke-WebRequest https://api.ipify.org/
az sql server firewall-rule create `
    --name externalip `
    --resource-group $rgName `
    --server $mssql_server_name `
    --start-ip-address $ip.Content `
    --end-ip-address $ip.Content

Write-Host  "-----------Creating MSSQL Schema -------"
Invoke-Sqlcmd -ServerInstance $server `
    -Username $mssql_administrator_login `
    -Password $mssql_administrator_password `
    -Database $mssql_database_name `
    -InputFile "$($SQLScriptsPath)/sql-geospatial-schema.sql"  

Write-Host  "-----------Uploading MSSQL Data -------"
Invoke-Sqlcmd -ServerInstance $server `
    -Username $mssql_administrator_login `
    -Password $mssql_administrator_password `
    -Database $mssql_database_name `
    -InputFile "$($SQLScriptsPath)/sql-geospatial-data.sql"
	
az sql server firewall-rule delete `
    --name externalip `
    --resource-group $rgName `
    --server $mssql_server_name
	
RefreshTokens
Add-Content log.txt "------asa powerbi connection-----"
Write-Host "----ASA Powerbi Connection-----"
#connecting asa and powerbi
$principal=az resource show -g $rgName -n $asa_name_fsi --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

#start ASA
Write-Host "----Starting ASA-----"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_fsi -OutputStartMode 'JobStartTime'

#COSMOS Section
Write-Host  "-----------------Uploading Cosmos Data --------------"
Add-Content log.txt "-----------------uploading Cosmos data--------------"
RefreshTokens
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmos_account_name
$databaseName = $cosmos_database_name
$cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $rgName
    $path="./artifacts/cosmos/"+$name.BaseName+".json"
    $document=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $document

    foreach($json in $document)
    {
        $key=$json.TransactionType
        $id = New-Guid
       if(![bool]($json.PSobject.Properties.name -match "id"))
       {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
       if(![bool]($json.PSobject.Properties.name -match "TransactionType"))
       {$json | Add-Member -MemberType NoteProperty -Name 'TransactionType' -Value $id}
        $body=ConvertTo-Json $json
        $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    }
} 

 Write-Host  "Click the following URL-  https://$($app_name_realtime_kpi_simulator).azurewebsites.net"
 Write-Host  "Click the following URL-  https://$($app_maps_service_name).azurewebsites.net"

Add-Content log.txt "-----------------Execution Complete---------------"
Write-Host  "-----------------Execution Complete----------------"
}
