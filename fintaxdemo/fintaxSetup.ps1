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
$deploymentId = $init
$cpuShell = "cpuShell$random"
$synapseWorkspaceName = "synapsefintax$init$random"
$sqlPoolName = "FinTaxDW"
$concatString = "$init$random"
$dataLakeAccountName = "stfintax$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

$sqlUser = "labsqladmin"
$concatString = "$random$init"
$forms_fintax_name = "fintax-form-recognizer-$suffix";
$bot_qnamaker_fintax_name= "botmultilingual-$suffix";
$accounts_transqna_fintax_name = "transqna-fintax-$suffix";
$workflows_LogicApp_fintax_name = "logicapp-fintax-$suffix"
$accounts_immersive_reader_fintax_name = "immersive-reader-fintax-$suffix";
$accounts_qnamaker_name= "qnamaker-$suffix";
$search_srch_fintax_name = "srch-fintax-$suffix";
$app_immersive_reader_fintax_name = "immersive-reader-fintax-app-$suffix";
$app_fintax_qna_name = "fintaxdemo-qna-$suffix";
$app_fintaxdemo_name = "fintaxdemo-app-$suffix";
$iot_hub_name = "iothub-fintax-$suffix";
$sites_app_multiling_fintax_name = "multiling-fintax-app-$suffix";
$asp_multiling_fintax_name = "multiling-fintax-asp-$suffix";
$sites_app_taxcollection_realtime_name = "taxcollectionrealtime-fintax-app-$suffix";
$sites_app_vat_custsat_eventhub_name = "vat-custsat-eventhub-fintax-app-$suffix";
$sites_app_iotfoottraffic_sensor_name = "iot-foottraffic-sensor-fintax-app-$suffix";
$sparkPoolName = "Fintax"
$storageAccountName = $dataLakeAccountName
$keyVaultName = "kv-$suffix";
$asa_name_fintax = "fintaxasa-$suffix"
$amlworkspacename = "amlws-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
$forms_cogs_endpoint = "https://"+$forms_fintax_name+".cognitiveservices.azure.com"
$AADApp_Immnersive_DisplayName = "FintaxImmersiveReader-$suffix"
$CurrentTime = Get-Date
$AADAppClientSecretExpiration = $CurrentTime.AddDays(365)
$AADAppClientSecret = "Smoothie@2021@2021"
$AADApp_Multiling_DisplayName = "FintaxMultiling-$suffix"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_fintax_name
$searchKey = $(az search admin-key show --resource-group $rgName --service-name $search_srch_fintax_name | ConvertFrom-Json).primarykey;
$cog_translator_key =  Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $accounts_transqna_fintax_name

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

Install-Module -Name MicrosoftPowerBIMgmt -Force
Login-PowerBI
	
RefreshTokens
Add-Content log.txt "------asa powerbi connection-----"
Write-Host "----ASA Powerbi Connection-----"
#connecting asa and powerbi
$principal=az resource show -g $rgName -n $asa_name_fintax --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

RefreshTokens
Write-Host "-----Enable Transparent Data Encryption----------"
$result = New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile "./artifacts/templates/transparentDataEncryption.json" -workspace_name_synapse $synapseWorkspaceName -sql_compute_name $sqlPoolName -ErrorAction SilentlyContinue
$result = az synapse spark pool update --name $sparkPoolName --workspace-name $synapseWorkspaceName --resource-group $rgName --library-requirements "./artifacts/templates/requirements.txt"

RefreshTokens
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$StartTime = Get-Date
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "training-data-output" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime

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
& $azCopyCommand copy "https://fintaxpoc.blob.core.windows.net/customcsv" $destinationUri --recursive

 $destinationSasKey = New-AzStorageContainerSASToken -Container "fintaxdemo" -Context $dataLakeContext -Permission rwdl
 $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/fintaxdemo$($destinationSasKey)"
 & $azCopyCommand copy "https://fintaxpoc.blob.core.windows.net/fintaxdemo" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "fraud-detection-sample-nyrealestate" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/fraud-detection-sample-nyrealestate$($destinationSasKey)"
& $azCopyCommand copy "https://fintaxpoc.blob.core.windows.net/fraud-detection-sample-nyrealestate" $destinationUri --recursive



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

#########################

Add-Content log.txt "----Form Recognizer-----"
Write-Host "----Form Recognizer-----"
#form Recognizer
#Replace values in create_model.py
(Get-Content -path artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
                -replace '#LOCATION#', $location`
				-replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
				-replace '#CONTAINER_NAME#', "training-data-output"`
				-replace '#SAS_TOKEN#', $sasToken`
				-replace '#APIM_KEY#',  $forms_cogs_keys.Key1`
			} | Set-Content -Path artifacts/formrecognizer/create_model1.py
			
$modelUrl = python "./artifacts/formrecognizer/create_model1.py"
$modelId = $modelUrl.split("/")
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

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sql_user_fintax.sql"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

 $sqlQuery="GRANT SELECT ON [Fact-Invoices] TO  TaxAuditor, TaxAuditSupervisor, TaxAuditorSurDatum, TaxAuditorStatiso;"
 $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword

 $sqlQuery="GRANT SELECT ON [FactInvoices] TO  TaxAuditor, TaxAuditSupervisor, TaxAuditorSurDatum, TaxAuditorStatiso;"
 $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword

 $sqlQuery="GRANT SELECT ON [FactInvoicesData] TO AntiCorruptionUnitHead;"
 $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword

$sqlQuery  = "CREATE DATABASE FintaxSqlOnDemand"
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
    if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "storedprocedures" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sql_user_fintax")
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
    #$query = $query.Replace("#COSMOS_ACCOUNT#", $db_graph_fintax_name)
   # $query = $query.Replace("#COSMOS_KEY#", $cosmos_account_key)

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

$templatepath="./artifacts/linkedservices/"

##AzureSynapseAnalytics1 linked services
Write-Host "Creating linked Service: AzureSynapseAnalytics1"
$filepath=$templatepath+"AzureSynapseAnalytics1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureSynapseAnalytics1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##MarketingCampaignData linked services
Write-Host "Creating linked Service: MarketingCampaignData"
$filepath=$templatepath+"MarketingCampaignData.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/MarketingCampaignData?api-version=2019-06-01-preview"
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

##SapHana linked services
Write-Host "Creating linked Service: SapHana"
$filepath=$templatepath+"SapHana.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##SQLServer linked services
Write-Host "Creating linked Service: synfintaxprod-WorkspaceDefaultSqlServer"
$filepath=$templatepath+"synfintaxprod-WorkspaceDefaultSqlServer.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synfintaxprod-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##blob linked services
Write-Host "Creating linked Service: synfintaxprod-WorkspaceDefaultStorage"
$filepath=$templatepath+"synfintaxprod-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synfintaxprod-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
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
$FilePathRT="./artifacts/linkedservices/AutoResolveIntegrationRuntime.json" 
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
		"#COSMOS_LINKED_SERVICE#" = $db_graph_fintax_name
		"#STORAGE_ACCOUNT_NAME#" = $dataLakeAccountName
		"#LOCATION#"=$location
		"#ML_WORKSPACE_NAME#"=$amlWorkSpaceName
        # "#SEARCH_KEY#" = $searchKey
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

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"All_Data"}} , @{Name = "TABLE_NAME"; Expression = {"All_Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Color"}} , @{Name = "TABLE_NAME"; Expression = {"Color"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Corruption_Data"}} , @{Name = "TABLE_NAME"; Expression = {"Corruption_Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact-dailytaxdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact-dailytaxdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactInvoicedetailsfinal"}} , @{Name = "TABLE_NAME"; Expression = {"FactInvoicedetailsfinal"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactInvoicedetailsfinals"}} , @{Name = "TABLE_NAME"; Expression = {"FactInvoicedetailsfinals"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactInvoicedetailsIDpTA"}} , @{Name = "TABLE_NAME"; Expression = {"FactInvoicedetailsIDpTA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactInvoices"}} , @{Name = "TABLE_NAME"; Expression = {"FactInvoices"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact-Invoices"}} , @{Name = "TABLE_NAME"; Expression = {"Fact-Invoices"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactInvoicesData"}} , @{Name = "TABLE_NAME"; Expression = {"FactInvoicesData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"fact-pbiMonthlyTaxDetails"}} , @{Name = "TABLE_NAME"; Expression = {"fact-pbiMonthlyTaxDetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact-Taxpayersatisfactiondetail"}} , @{Name = "TABLE_NAME"; Expression = {"Fact-Taxpayersatisfactiondetail"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fintaxtransaction"}} , @{Name = "TABLE_NAME"; Expression = {"Fintaxtransaction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Industry"}} , @{Name = "TABLE_NAME"; Expression = {"Industry"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"iot-foottraffic-data"}} , @{Name = "TABLE_NAME"; Expression = {"iot-foottraffic-data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Location"}} , @{Name = "TABLE_NAME"; Expression = {"Location"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiTaxCustSatMonthly"}} , @{Name = "TABLE_NAME"; Expression = {"pbiTaxCustSatMonthly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiTaxDetailMonthly"}} , @{Name = "TABLE_NAME"; Expression = {"pbiTaxDetailMonthly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Source"}} , @{Name = "TABLE_NAME"; Expression = {"Source"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"StagingFintaxtransaction"}} , @{Name = "TABLE_NAME"; Expression = {"StagingFintaxtransaction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TaxpayerSatisfactionMetrics"}} , @{Name = "TABLE_NAME"; Expression = {"TaxpayerSatisfactionMetrics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"temp"}} , @{Name = "TABLE_NAME"; Expression = {"temp"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TRF-Social-Data"}} , @{Name = "TABLE_NAME"; Expression = {"TRF-Social-Data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VAT_Daily"}} , @{Name = "TABLE_NAME"; Expression = {"VAT_Daily"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
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
    #Write-output "Data for $($dataTableLoad.TABLE_NAME) loaded."
}

Write-Host  "-----------------AML Workspace ---------------"
Add-Content log.txt "-----------AML Workspace -------------"
RefreshTokens

$filepath="./artifacts/amlnotebooks/Config.py"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key).Replace("#FORM_RECOGNIZER_ENDPOINT#", $forms_cogs_endpoint).Replace("#FORM_RECOGNIZER_API_KEY#", $forms_cogs_keys.Key1).Replace("#FORM_RECOGNIZER_MODEL_ID#", $modelId)
$filepath="./artifacts/amlnotebooks/GlobalVariables.py"
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
		$path=$notebook.BaseName+".py"
	}
    elseif ($notebook.BaseName -eq "anomaly_model") {
        $source="./artifacts/amlnotebooks/"+$notebook.BaseName+".sav"
		$path=$notebook.BaseName+".sav"
    }
    elseif($notebook.BaseName -eq "Config")
	{
     continue;
	}
	else
	{
		$source="./artifacts/amlnotebooks/"+$notebook.BaseName+".ipynb"
		$path=$notebook.BaseName+".ipynb"
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
    if($report.name -eq "Tax Collection Realtime" -or $report.name -eq "TRF-Chicklets")
    {
       continue;     
	}
	elseif($report.name -eq "Anti Corruption Report" -or $report.name -eq  "Fraud Investigator Report" -or $report.name -eq "Tax Compliance Comissioner Report")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server_Name`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"DB_Name`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
    elseif($report.name -eq "Amazon MAP" -or $report.name -eq  "Tax Collections Commissioner" -or $report.name -eq "Taxpayer Client Services Report")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Connection_string`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database_name`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
    elseif($report.name -eq "FinTax Column Level Security (Azure Synapse)" -or $report.name -eq  "FinTax Dynamic Data Masking (Azure Synapse)" -or $report.name -eq "FinTax Row Level Security (Azure Synapse)")
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
    elseif($report.name -eq "vat auditor report")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Connection_string_demo`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database_name_demo`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
    elseif($report.name -eq "Report Tax Finance")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"ServerName`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"DB_Name`",
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

#########################

Add-Content log.txt "----Bot and multilingual App-----"
Write-Host "----Bot and multilingual App----"

$app = az ad app create --display-name $sites_app_multiling_fintax_name --password "Smoothie@2021@2021" --available-to-other-tenants | ConvertFrom-Json
$appId = $app.appId

az deployment group create --resource-group $rgName --template-file "./artifacts/qnamaker/bot-multiling-template.json" --parameters appId=$appId appSecret=$AADAppClientSecret botId=$bot_qnamaker_fintax_name newWebAppName=$sites_app_multiling_fintax_name newAppServicePlanName=$asp_multiling_fintax_name appServicePlanLocation=$location

az webapp deployment source config-zip --resource-group $rgName --name $sites_app_multiling_fintax_name --src "./artifacts/qnamaker/chatbot.zip"

#################

#Web app
Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------Deploy web app ---------------"
RefreshTokens

$device = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iot_hub_name -DeviceId trf-foottraffic-device

$zips = @("immersive-reader-app", "fintaxdemo-app", "app-iotfoottraffic-sensor", "app-taxcollection-realtime", "app-vat-custsat-eventhub")
foreach($zip in $zips)
{
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

$spname="FinTax Demo $deploymentId"
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
				
(Get-Content -path fintaxdemo-app/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path fintaxdemo-app/appsettings.json

$filepath="./fintaxdemo-app/wwwroot/config.js"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName).Replace("#SERVER_NAME#", $app_fintaxdemo_name).Replace("#APP_NAME#", $app_fintaxdemo_name)
Set-Content -Path $filepath -Value $item 

#bot qna maker
$bot_detail = az bot webchat show --name $bot_qnamaker_fintax_name --resource-group $rgName --with-secrets true | ConvertFrom-Json
$bot_key = $bot_detail.properties.properties.sites[0].key

#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable   
#TODO need to check which url to use here
# $ht.add("#Blob_Base_Url#", "https://fsicdn.azureedge.net/webappassets/")
$ht.add("#Bing_Map_Key#", "AhBNZSn-fKVSNUE5xYFbW_qajVAZwWYc8OoSHlH8nmchGuDI6ykzYjrtbwuNSrR8")
$ht.add("#IMMERSIVE_READER_FINTAX_NAME#", $app_immersive_reader_fintax_name)
$ht.add("#BOT_QNAMAKER_FINTAX_NAME#", $bot_qnamaker_fintax_name)
$ht.add("#BOT_KEY#", $bot_key)
$ht.add("#AMAZON_MAP#", $($reportList | where {$_.Name -eq "Amazon MAP"}).ReportId)
$ht.add("#ANTI_CORRUPTION_REPORT#", $($reportList | where {$_.Name -eq "Anti Corruption Report"}).ReportId)
#.add("#FINTAX_COLUMN_LEVEL_SECURITY_SYNAPSE#", $($reportList | where {$_.Name -eq "FinTax Column Level Security (Azure Synapse)"}).ReportId)
#$ht.add("#FINTAX_DYNAMIC_DATA_MASKING_SYNAPSE#", $($reportList | where {$_.Name -eq "FinTax Dynamic Data Masking (Azure Synapse)"}).ReportId)
#$ht.add("#FINTAX_ROW_LEVEL_SECURITY_SYNAPSE#", $($reportList | where {$_.Name -eq "FinTax Row Level Security (Azure Synapse)"}).ReportId)
$ht.add("#FRAUD_INVESTIGATOR_REPORT#", $($reportList | where {$_.Name -eq "Fraud Investigator Report"}).ReportId)
$ht.add("#REPORT_TAX_FINANCE#", $($reportList | where {$_.Name -eq "Report Tax Finance"}).ReportId)
#$ht.add("#TAX_COLLECTIONS_COMMISSIONER#", $($reportList | where {$_.Name -eq "Tax Collections Commissioner"}).ReportId)
$ht.add("#TAX_COMPLIANCE_COMISSIONER_REPORT#", $($reportList | where {$_.Name -eq "Tax Compliance Comissioner Report"}).ReportId)
#$ht.add("#TAXPAYER_CLIENT_SERVICES_REPORT#", $($reportList | where {$_.Name -eq "Taxpayer Client Services Report"}).ReportId)
#$ht.add("#TRF_CHICKLETS#", $($reportList | where {$_.Name -eq "TRF-Chicklets"}).ReportId)
$ht.add("#VAT_AUDITOR_REPORT#", $($reportList | where {$_.Name -eq "vat auditor report"}).ReportId)

#$ht.add("#SPEECH_REGION#", $location)

$filePath = "./fintaxdemo-app/wwwroot/config.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./fintaxdemo-app/*" -DestinationPath "./fintaxdemo-app.zip"

az webapp stop --name $app_fintaxdemo_name --resource-group $rgName

try{
az webapp deployment source config-zip --resource-group $rgName --name $app_fintaxdemo_name --src "./fintaxdemo-app.zip"
}
catch
{
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

az webapp start  --name $app_fintaxdemo_name --resource-group $rgName
az webapp start --name $app_immersive_reader_fintax_name --resource-group $rgName
az webapp start --name $sites_app_multiling_fintax_name --resource-group $rgName
az webapp start  --name $sites_app_iotfoottraffic_sensor_name --resource-group $rgName
az webapp start --name $sites_app_taxcollection_realtime_name --resource-group $rgName
az webapp start --name $sites_app_vat_custsat_eventhub_name --resource-group $rgName

foreach($zip in $zips)
{
    if ($zip -eq  "immersive-reader-app"  -or $zip -eq  "fintaxdemo-app" ) 
    {
        remove-item -path "./$($zip).zip" -recurse -force
    }
    if ($zip -eq "fintaxdemo-app" ) 
    {
        continue;
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

Add-Content log.txt "-----------------Execution Complete---------------"
Write-Host  "-----------------Execution Complete----------------"