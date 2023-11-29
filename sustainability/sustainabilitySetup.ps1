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
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
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

#getting user details

$response=az ad signed-in-user show | ConvertFrom-Json
$date=get-date
$demoType="Sustainability"
$body= '{"demoType":"#demoType#","userPrincipalName":"#userPrincipalName#","displayName":"#displayName#","companyName":"#companyName#","mail":"#mail#","date":"#date#"}'
$body = $body.Replace("#userPrincipalName#", $response.userPrincipalName)
$body = $body.Replace("#displayName#", $response.displayName)
$body = $body.Replace("#companyName#", $response.companyName)
$body = $body.Replace("#mail#", $response.mail)
$body = $body.Replace("#date#", $date)
$body = $body.Replace("#demoType#", $demoType)

$uri ="https://registerddibuser.azurewebsites.net/api/registeruser?code=pTrmFDqp25iVSxrJ/ykJ5l0xeTOg5nxio9MjZedaXwiEH8oh3NeqMg=="
$result = Invoke-RestMethod  -Uri $uri -Method POST -Body $body -Headers @{} -ContentType "application/json"

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$starttime=get-date
$rglocation = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$Realtime_Air_Quality_API =  (Get-AzResourceGroup -Name $rgName).Tags["Realtime_Air_Quality_API"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$deploymentId = $init
$synapseWorkspaceName = "synapsesustain$init$random"
$sqlPoolName = "SustainabilityDW"
$concatString = "$init$random"
$dataLakeAccountName = "stsustain$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$cosmosdb_sustainability_name = "cosmosdb-sustain-$random$init";
if($cosmosdb_sustainability_name.length -gt 43)
{
$cosmosdb_sustainability_name = $cosmosdb_sustainability_name.substring(0,43)
}
$cosmos_database_name_sustain = "sustainbusridershipdb";
$sqlUser = "labsqladmin";
$concatString = "$random$init";
$app_sustainabilitydemo_name = "sustainabilitydemo-app-$suffix";
$sites_iotsustainability_name = "app-iot-sustainability-$suffix";
$sites_airquality_name = "app-airquality-sustainability-$suffix";
$sparkPoolName = "Sustainability"
$storageAccountName = $dataLakeAccountName
$keyVaultName = "kv-$suffix";
$asa_name_sustainability = "sustainabilityasa-$suffix"
$amlworkspacename = "amlws-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
$iot_hub_sustainability = "iothub-sustainability-$suffix"

#Cosmos keys
$cosmos_account_key=az cosmosdb keys list -n $cosmosdb_sustainability_name -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

Write-Host "Setting Key Vault Access Policy"
#Import-Module Az.KeyVault
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,get,list
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

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

###################################################################
New-Item log.txt

# Install-Module -Name MicrosoftPowerBIMgmt -Force
# $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","I have enough permissions for PowerBI login."
# $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","I will run PowerBI setup seperately."
# $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
# $title = "PowerBI login"
# $message = " (Type [Y] for Yes or [N] for No and press enter)"
# $result = $host.ui.PromptForChoice($title, $message, $options, 1)
# if($result -eq 0)
# {
#  Login-PowerBI 
# }
	
# RefreshTokens
# Add-Content log.txt "------asa powerbi connection-----"
# Write-Host "----ASA Powerbi Connection-----"
# #connecting asa and powerbi
# $principal=az resource show -g $rgName -n $asa_name_sustainability --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
# $principalId=$principal.identity.principalId
# Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

RefreshTokens
Write-Host "-----Enable Transparent Data Encryption----------"
$result = New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile "./artifacts/templates/transparentDataEncryption.json" -workspace_name_synapse $synapseWorkspaceName -sql_compute_name $sqlPoolName -ErrorAction SilentlyContinue
$result = az synapse spark pool update --name $sparkPoolName --workspace-name $synapseWorkspaceName --resource-group $rgName --library-requirements "./artifacts/templates/requirements.txt"

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
} else {
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
$destinationSasKey = "?$destinationSasKey"
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
& $azCopyCommand copy "https://sustainabilitypoc.blob.core.windows.net/customcsv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
$destinationSasKey = "?$destinationSasKey"
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/webappassets$($destinationSasKey)"
& $azCopyCommand copy "https://sustainabilitypoc.blob.core.windows.net/webappassets" $destinationUri --recursive

#storage assests copy
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$containers=Get-ChildItem "./artifacts/storageassets" | Select BaseName

foreach($container in $containers)
{
    $destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
    $destinationSasKey = "?$destinationSasKey"
    $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
    & $azCopyCommand copy "./artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive
}

##############################

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

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/storedprocedures.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
(Get-Content -path "$($SQLScriptsPath)/sqluser.sql" -Raw) | Foreach-Object { $_ `
                -replace '#SQL_PASSWORD#', $sqlPassword`		
        } | Set-Content -Path "$($SQLScriptsPath)/sqluser.sql"		
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sql_user_sustainability.sql"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery  = "CREATE DATABASE SustainabilityOnDemand"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"

try{
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
} catch {
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
}
Add-Content log.txt $result	
 
#uploading Sql Scripts
Add-Content log.txt "-----------uploading Sql Scripts-----------------"
Write-Host "----Sql Scripts------"
RefreshTokens
$scripts=Get-ChildItem "./artifacts/sqlscripts" | Select BaseName
$TemplatesPath="./artifacts/templates";	

foreach ($name in $scripts) 
{
    if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "storedprocedures" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sql_user_sustainability")
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
    $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmosdb_sustainability_name)
    $query = $query.Replace("#COSMOSDB_ACCOUNT_KEY#", $cosmos_account_key)
    $query = $query.Replace("#LOCATION#", $rglocation)
    $query = $query.Replace("#SQL_PASSWORD#", $sqlPassword)
    
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
$templatepath="./artifacts/linkedservices/"

# AutoResolveIntegrationRuntime
$FilePathRT="./artifacts/linkedservices/AutoResolveIntegrationRuntime.json" 
$itemRT = Get-Content -Path $FilePathRT
$uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
Add-Content log.txt $result

# IntegrationRuntime
$FilePathRT="./artifacts/linkedservices/IntegrationRuntime.json" 
$itemRT = Get-Content -Path $FilePathRT
$uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/IntegrationRuntime?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
Add-Content log.txt $result

##LsSustainSQLOnDemand
Write-Host "Creating linked Service: LsSustainSQLOnDemand"
$filepath=$templatepath+"LsSustainSQLOnDemand.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/LsSustainSQLOnDemand?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##AzureSynapseAnalytics1
Write-Host "Creating linked Service: AzureSynapseAnalytics1"
$filepath=$templatepath+"AzureSynapseAnalytics1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureSynapseAnalytics1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##cosmos linked service
Write-Host "Creating linked Service: cosmosdbsustainabilityprod"
$filepath=$templatepath+"cosmosdbsustainabilityprod.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmosdb_sustainability_name).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/cosmosdbsustainabilityprod?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# Oracle linked services
Write-Host "Creating linked Service: Oracle"
$filepath=$templatepath+"Oracle.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Oracle?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# retailsynapse
Write-Host "Creating linked Service: retailsynapse"
$filepath=$templatepath+"retailsynapse.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/retailsynapse?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##SapHana linked services
Write-Host "Creating linked Service: SapHana1"
$filepath=$templatepath+"SapHana1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# SustainSyn1
Write-Host "Creating linked Service: SustainSyn1"
$filepath=$templatepath+"SustainSyn1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SustainSyn1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##SynSustainabilityDW
Write-Host "Creating linked Service: SynSustainabilityDW"
$filepath=$templatepath+"SynSustainabilityDW.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SynSustainabilityDW?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# synsustainabilityprod-WorkspaceDefaultSqlServer
Write-Host "Creating linked Service: synsustainabilityprod-WorkspaceDefaultSqlServer"
$filepath=$templatepath+"synsustainabilityprod-WorkspaceDefaultSqlServer.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synsustainabilityprod-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# synsustainabilityprod-WorkspaceDefaultStorage
Write-Host "Creating linked Service: synsustainabilityprod-WorkspaceDefaultStorage"
$filepath=$templatepath+"synsustainabilityprod-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synsustainabilityprod-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# Teradata linked services
Write-Host "Creating linked Service: Teradata"
$filepath=$templatepath+"Teradata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
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
    $item = $itemTemplate
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
        "#COSMOS_LINKED_SERVICE#" = $cosmosdb_sustainability_name
        "#STORAGE_ACCOUNT_NAME#" = $dataLakeAccountName
        "#LOCATION#"=$rglocation
        "#AML_WORKSPACE_NAME#"=$amlWorkSpaceName
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
    $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
    Start-Sleep -Seconds 10
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    Add-Content log.txt $result 
}

#creating Triggers
Add-Content log.txt "------triggers------"
Write-Host "-------Triggers-----------"
RefreshTokens
$triggers=Get-ChildItem "./artifacts/trigger" | Select BaseName
foreach($name in $triggers)
{
    $FilePath="./artifacts/trigger/"+$name.BaseName+".json"
    Write-Host "Creating trigger : $($name.BaseName)"

    $item = Get-Content -Path $FilePath
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/triggers/$($name.BaseName)?api-version=2020-12-01"
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

##Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "--------- PBI connections update---------"	

foreach($report in $reportList)
{
    if($report.name -eq "Master Images")
    {
        continue;
    }
    elseif($report.name -eq "Budget dashboard" -or $report.name -eq "Fleet Manager Dashboard" -or $report.name -eq "Mayor Dashboard" -or $report.name -eq  "Power Management" -or $report.name -eq "Realtime Air Quality Report Static" -or $report.name -eq "Transportation Head Dashboard" -or $report.name -eq "Twitter Report Static" -or $report.name -eq "Transport Deep Dive")
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
    elseif($report.name -eq "Sustainability Column Level Security (Azure Synapse)" -or $report.name -eq "Sustainability Row Level Security (Azure Synapse)")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"servername`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
    elseif($report.name -eq "Sustainability Dynamic Data Masking (Azure Synapse)")
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"ServerNew`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                                
                            },
                            {
                                `"name`": `"Pool`",
                                `"newValue`": `"$($sqlPoolName)`"
                            }
                            ]
                            }"	
	}
    elseif($report.name -eq "Demand and Bus Frequency")
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server`",
                                `"newValue`": `"https://$($cosmosdb_sustainability_name).documents.azure.com:443/`"
                                
                            },
                            {
                                `"name`": `"Database`",
                                `"newValue`": `"$($cosmos_database_name_sustain)`"
                            }
                            ]
                            }"	
	}
    elseif($report.name -eq "NYC_AQI" -or $report.name -eq "Billion Rows Demo" )
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Connection_String`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                                
                            },
                            {
                                `"name`": `"Database_Name`",
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

#################

#Web app
Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------Deploy web app ---------------"

$zips = @("app-sustainabilitydemo", "app-airqualitydata", "app-iot-sustainability")
foreach($zip in $zips)
{
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

RefreshTokens

$device = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iot_hub_sustainability -DeviceId iot-sustainability-device

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
$ht.add("#Twitter_Report#", $($reportList | where {$_.name -eq "Twitter Report Static"}).id)
# $ht.add("#World_Map#", $($reportList | where {$_.name -eq "Realtime Air Quality Report Static"}).id)

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

# IOT Sustainability
$device_conn_string= $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iot_hub_sustainability -DeviceId iot-sustainability-device).ConnectionString
$shared_access_key = $device_conn_string.Split(";")[2]
$device_primary_key= $shared_access_key.Substring($shared_access_key.IndexOf("=")+1)

$iot_hub_config = '"{\"frequency\":1,\"connection\":{\"provisioning_host\":\"global.azure-devices-provisioning.net\",\"symmetric_key\":\"' + $device_primary_key + '\",\"IoTHubConnectionString\":\"' + $device_conn_string + '\"}}"'

(Get-Content -path app-iot-sustainability/prod.env -Raw) | Foreach-Object { $_ `
     -replace '#DEVICE_PRIMARY_KEY#', $device_primary_key`
     -replace '#DEVICE_CONN_STRING#', $device_conn_string`
 } | Set-Content -Path app-iot-sustainability/prod.env

Write-Information "Deploying IOT Sustainability App"
cd app-iot-sustainability
az webapp up --resource-group $rgName --name $sites_iotsustainability_name
cd ..
Start-Sleep -s 10

$config = az webapp config appsettings set -g $rgName -n $sites_iotsustainability_name --settings IoTHubConfig=$iot_hub_config

# App Airqualitydata
$chicago_AQIReports_Config = '"{\"main_data_frequency_seconds\":1,\"urlStringPowerBI\":\"' + $Realtime_Air_Quality_API + '\",\"diff_After_Mid_AQI\":20.0,\"diff_After_Mid_PM1\":7.0,\"diff_After_Mid_PM10\":7.0,\"diff_After_Mid_PM25\":7.0,\"diff_After_Before_AQI\":35.0,\"diff_After_Before_PM10\":10.0,\"diff_After_Before_PM1\":10.0,\"diff_After_Before_PM25\":10.0,\"mean_AQI_Target\":40.0,\"mean_PM1_Target\":5.0,\"mean_PM10_Target\":5.0,\"mean_PM25_Target\":5.0,\"data\":[{\"mean_AQI\":{\"minValue\":10.0,\"maxValue\":25.0}},{\"mean_PM1\":{\"minValue\":1.0,\"maxValue\":5.0}},{\"mean_PM25\":{\"minValue\":1.0,\"maxValue\":5.0}},{\"mean_PM10\":{\"minValue\":1.0,\"maxValue\":5.0}}]}"'

(Get-Content -path app-airqualitydata/prod.env -Raw) | Foreach-Object { $_ `
    -replace '#AIR_QUALITY_STREAMING_URL#', $Realtime_Air_Quality_API`
} | Set-Content -Path app-airqualitydata/prod.env

Write-Information "Deploying Airqualitydata App"
cd app-airqualitydata
az webapp up --resource-group $rgName --name $sites_airquality_name
cd ..
Start-Sleep -s 10

$config = az webapp config appsettings set -g $rgName -n $sites_airquality_name --settings ChicagoAQIReportsConfig=$chicago_AQIReports_Config

RefreshTokens

az webapp start  --name $app_sustainabilitydemo_name --resource-group $rgName
az webapp start  --name $sites_iotsustainability_name --resource-group $rgName
az webapp start --name $sites_airquality_name --resource-group $rgName

foreach($zip in $zips)
{
    if ($zip -eq  "app-sustainabilitydemo" ) 
    {
        remove-item -path "./$($zip).zip" -recurse -force
    }
    if ($zip -eq "app-sustainabilitydemo" ) 
    {
        continue;
    }
    remove-item -path "./$($zip)" -recurse -force
}

#start ASA
Write-Host "----Starting ASA-----"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_sustainability -OutputStartMode 'JobStartTime'

#####################################################
Write-Host "------COSMOS data Upload -------------"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmosdb_sustainability_name
$cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmos_database_name_sustain -ResourceGroup $rgName
	$path="./artifacts/cosmos/"+$name.BaseName+".json"
    $documents=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $documents

    foreach($json in $document)
    {
        $key = $json.id
        $body=ConvertTo-Json $json
        $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    }
} 

#################################

Add-Content log.txt "------uploading sql data------"
Write-Host  "-------------Uploading Sql Data ---------------"
RefreshTokens
#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"AvgDailyRidership"}} , @{Name = "TABLE_NAME"; Expression = {"AvgDailyRidership"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleServicingTrend_old"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleServicingTrend_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Facility-FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"Facility-FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Airquality"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Airquality"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Airqualitydetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Airqualitydetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_ArticlePublished"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_ArticlePublished"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Citizensentimentdetail"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Citizensentimentdetail"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Citizensentimentsummmary"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Citizensentimentsummmary"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Eneryconsumptionsdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Eneryconsumptionsdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_FacilityManagementdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_FacilityManagementdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Fleetmaintenancecost"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Fleetmaintenancecost"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Fleetmanagementdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Fleetmanagementdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_TransportMaintenanceCost"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_TransportMaintenanceCost"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleBreakdown"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleBreakdown"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleManufacturingData"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleManufacturingData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_vehiclesdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_vehiclesdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleServicingTrend"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleServicingTrend"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleServicingTrend_old"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleServicingTrend_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"KPIsValuesFleetManager"}} , @{Name = "TABLE_NAME"; Expression = {"KPIsValuesFleetManager"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"KPIsValuesFleetManager_old"}} , @{Name = "TABLE_NAME"; Expression = {"KPIsValuesFleetManager_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PowerManagement"}} , @{Name = "TABLE_NAME"; Expression = {"PowerManagement"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleBreakDown"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleBreakDown"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleDetails"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleDetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleServiceLog"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleServiceLog"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleServiceLog_old"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleServiceLog_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"aqi_test_df"}} , @{Name = "TABLE_NAME"; Expression = {"aqi_test_df"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TweeterSentiments"}} , @{Name = "TABLE_NAME"; Expression = {"TweeterSentiments"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RealtimeAIRQualityAPI"}} , @{Name = "TABLE_NAME"; Expression = {"RealtimeAIRQualityAPI"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TweeterUserInfo"}} , @{Name = "TABLE_NAME"; Expression = {"TweeterUserInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"twitterRawData"}} , @{Name = "TABLE_NAME"; Expression = {"twitterRawData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Vehicle_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Vehicle_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleBreakDown_old"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleBreakDown_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleDetails_old"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleDetails_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fleet-FactExpense"}} , @{Name = "TABLE_NAME"; Expression = {"Fleet-FactExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FacilityInfo"}} , @{Name = "TABLE_NAME"; Expression = {"FacilityInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)

$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
foreach ($dataTableLoad in $dataTableList) {
    Write-output "Loading data for $($dataTableLoad.TABLE_NAME)"
    $sqlQuery = Get-Content -Raw -Path "./artifacts/templates/load_csv.sql"
    $sqlQuery = $sqlQuery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
    $Parameters =@{
            CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
            TABLE_NAME = $dataTableLoad.TABLE_NAME
            DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
     }
    foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
    Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
}

$endtime=get-date
$executiontime=$endtime-$starttime
Write-Host "Execution Time - "$executiontime.TotalMinutes
Add-Content log.txt "-----------------Execution Complete---------------"
Write-Host  "-----------------Execution Complete----------------"
}
