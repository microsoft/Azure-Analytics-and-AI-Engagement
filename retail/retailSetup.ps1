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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$rglocation = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$thermostat_telemetry_Realtime_URL =  (Get-AzResourceGroup -Name $rgName).Tags["thermostat_telemetry_Realtime_URL"]
$occupancy_data_Realtime_URL =  (Get-AzResourceGroup -Name $rgName).Tags["occupancy_data_Realtime_URL"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$deploymentId = $init
$cpuShell = "cpuShell$random"
$synapseWorkspaceName = "synapseretail$init$random"
$sqlPoolName = "RetailDW"
$concatString = "$init$random"
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$cosmosdb_retail2_name = "cosmosdb-retail2-$random$init";
if($cosmosdb_retail2_name.length -gt 43)
{
$cosmosdb_retail2_name = $cosmosdb_retail2_name.substring(0,43)
}
$cosmos_database_name_retailinventorydb = "retailinventorydb";
$cosmos_database_name= "retail-foottraffic";
$sqlUser = "labsqladmin";
$concatString = "$random$init";
$forms_retail_name = "retail-form-recognizer-$suffix";
$bot_qnamaker_retail_name= "botmultilingual-$suffix";
$accounts_transqna_retail_name = "transqna-retail-$suffix";
$workflows_LogicApp_retail_name = "logicapp-retail-$suffix"
$accounts_qnamaker_name= "qnamaker-$suffix";
$search_srch_retail_name = "srch-retail-product-$suffix";
$search_retail_qna_name = "srch-retail-qna-$suffix";
$app_retail_qna_name = "retaildemo-qna-$suffix";
$app_retaildemo_name = "retaildemo-app-$suffix";
$iot_hub_name = "iothub-retail-$suffix";
$sites_app_multiling_retail_name = "multiling-retail-app-$suffix";
$asp_multiling_retail_name = "multiling-retail-asp-$suffix";
$sites_app_iotfoottraffic_sensor_name = "iot-foottraffic-sensor-retail-app-$suffix";
$sparkPoolName = "Retail"
$kustoPoolName = "retailkustopool$init"
$kustoDatabaseName = "RetailDB"
$storageAccountName = $dataLakeAccountName
$keyVaultName = "kv-$suffix";
$asa_name_retail = "retailasa-$suffix"
$amlworkspacename = "amlws-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
$forms_cogs_endpoint = "https://"+$rglocation+".api.cognitive.microsoft.com/"
$AADApp_Immnersive_DisplayName = "RetailImmersiveReader-$suffix"
$CurrentTime = Get-Date
$AADAppClientSecretExpiration = $CurrentTime.AddDays(365)
$AADAppClientSecret = "Smoothie@2021@2021"
$AADApp_Multiling_DisplayName = "RetailMultiling-$suffix"
$sites_retail_mediasearch_app_name = "mediasearch-retail-app-$suffix"
$sites_adx_thermostat_realtime_name = "app-realtime-kpi-retail-$suffix"
$sites_app_product_search = "app-product-search-ui-$suffix"
$functionapptranscript = "func-app-media-transcript-$suffix"
$functionapplivestreaming = "func-app-livestreaming-$suffix"
$func_product_search_name = "func-app-product-search-$suffix"
$connections_cosmosdb_name =  "conn-documentdb-$suffix"
$connections_azureblob_name = "conn-azureblob-$suffix"
$namespaces_adx_thermostat_occupancy_name = "adx-thermostat-occupancy-$suffix"
$iothub_foottraffic = "iothub-foottraffic-$suffix"
$media_search_app_service_name = "app-media-search-$suffix"
$vi_account_key = (Get-AzResourceGroup -Name $rgName).Tags["VideoIndexerApiKey"]
$vi_account_id = (Get-AzResourceGroup -Name $rgName).Tags["VideoIndexerAccountId"]
$vi_location = "trial"
$workflows_logic_video_indexer_trigger_name = "logic-app-video-trigger-$suffix"
$workflows_logic_storage_trigger_name = "logic-app-storage-trigger-$suffix"
$title = "Video Indexer"
$message = "Do you have unlimited video indexer account?"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
if($result -eq 0)
{
$vi_account_id = read-host "Enter the account id of your unlimited video indexer account";
$vi_account_key = read-host "Enter the account key of your unlimited video indexer account";
$vi_location = read-host "Enter the location/region of your Media Service.";
}
$vi_api_url = 'https://api.videoindexer.ai'
$location = (Get-AzResourceGroup -Name $rgName).Location
# $vi_account_url = "$vi_api_url/$location/Accounts/$vi_account_id"
$cog_speech_name = "retailspeechapp-$suffix"
$cog_speech_key = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $cog_speech_name
$incident_search_retail_name = "incident-srch-retail-$suffix";
$cog_retail_name = "cogretail-$suffix"
$accounts_purview_retail_name = "purviewretail$suffix"
$purviewCollectionName1 = "AzureDataLakeStorage"
$purviewCollectionName2 = "AzureSynapse"
$purviewCollectionName3 = "CosmosDB-Retail"
$purviewCollectionName4 = "PowerBI-Retail"

$functionapprecommender="func-app-media-recommendation-$suffix"
$functionappmodelbuilder="func-app-model-builder-$suffix"
$functionapprecommender_asp="func-asp-media-recommendation-$suffix"
$functionappmodelbuilder_asp="func-asp-model-builder-$suffix"

$cog_translator_key =  Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $accounts_transqna_retail_name
$translator_key=$cog_translator_key.Key1

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_retail_name

#Cosmos keys
$cosmos_account_key=az cosmosdb keys list -n $cosmosdb_retail2_name -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

Write-Host "Setting Key Vault Access Policy"
#Import-Module Az.KeyVault
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,get,list
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

$purview_id = (Get-AzADServicePrincipal -DisplayName $accounts_purview_retail_name).id
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $purview_id -PermissionsToSecrets set,get,list

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
# $principal=az resource show -g $rgName -n $asa_name_retail --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
# $principalId=$principal.identity.principalId
# Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

Add-Content log.txt "------Data Explorer Creation-----"
Write-Host "----Data Explorer Creation-----"
New-AzSynapseKustoPool -ResourceGroupName $rgName -WorkspaceName $synapseWorkspaceName -Name $kustoPoolName -Location $rglocation -SkuName "Compute optimized" -SkuSize Small

New-AzSynapseKustoPoolDatabase -ResourceGroupName $rgName -WorkspaceName $synapseWorkspaceName -KustoPoolName $kustoPoolName -DatabaseName $kustoDatabaseName -Kind "ReadWrite" -Location $rglocation

RefreshTokens
Write-Host "-----Enable Transparent Data Encryption----------"
$result = New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile "./artifacts/templates/transparentDataEncryption.json" -workspace_name_synapse $synapseWorkspaceName -sql_compute_name $sqlPoolName -ErrorAction SilentlyContinue
$result = az synapse spark pool update --name $sparkPoolName --workspace-name $synapseWorkspaceName --resource-group $rgName --library-requirements "./artifacts/templates/environment.yml"

RefreshTokens
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$StartTime = Get-Date
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "incidentpdftraining" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime

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
}else{
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

az webapp stop --name $functionapptranscript --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $functionapptranscript --src "./artifacts/binaries/func_savetranscript.zip"	
az webapp start --name $functionapptranscript --resource-group $rgName

#logic app template replacement
(Get-Content -path artifacts/templates/logic_app_video_trigger_def.json -Raw) | Foreach-Object { $_ `
                -replace '###Document_Connection_name###', $connections_cosmosdb_name`
				-replace '###video_indexer_api_key###', $vi_account_key`
				-replace '###video_indexer_account_id###', $vi_account_id`
				-replace '###subscriptions_id###', $subscriptionId`
				-replace '###rg_name###', $rgName`
				-replace '###function_name###', $functionapptranscript`
				-replace '###location###', $rglocation`
				-replace '###vi_location###', $vi_location`
				
        } | Set-Content -Path artifacts/templates/logic_app_video_trigger_def1.json
		
$video_logic_callbackurl = Get-AzLogicAppTriggerCallbackUrl -ResourceGroupName $rgName -Name $workflows_logic_video_indexer_trigger_name -TriggerName "manual"
$video_logic_callbackurl = $video_logic_callbackurl.value
#logic app template replacement
(Get-Content -path artifacts/templates/logic_app_storage_trigger_def.json -Raw) | Foreach-Object { $_ `
                -replace '###blob_connection_name###', $connections_azureblob_name`
				-replace '###video_indexer_api_key###', $vi_account_key`
				-replace '###video_indexer_account_id###', $vi_account_id`
				-replace '###subscriptions_id###', $subscriptionId`
				-replace '###rg_name###', $rgName`
				-replace '###call_back_url###', $video_logic_callbackurl`
				-replace '###location###', $rglocation`
				-replace '###vi_location###', $vi_location`		
        } | Set-Content -Path artifacts/templates/logic_app_storage_trigger_def1.json

RefreshTokens
#logic app definition update
az extension add -n logic
az logic workflow update --resource-group $rgName --name $workflows_logic_video_indexer_trigger_name --definition "./artifacts/templates/logic_app_video_trigger_def1.json"

az logic workflow update --resource-group $rgName --name $workflows_logic_storage_trigger_name --definition "./artifacts/templates/logic_app_storage_trigger_def1.json"
 
start-sleep -s 60

#Uploading to storage containers
Add-Content log.txt "-----------Uploading to storage containers-----------------"
Write-Host "----Uploading to Storage Containers-----"
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

RefreshTokens

$destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/customcsv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "retail20" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/retail20$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/retail20" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "adfstagedcopytempdata" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/adfstagedcopytempdata$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/adfstagedcopytempdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "adfstagedpolybasetempdata" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/adfstagedpolybasetempdata$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/adfstagedpolybasetempdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "magentocontosomergerdata" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/magentocontosomergerdata$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/magentocontosomergerdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "market-basket" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/market-basket$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/market-basket" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "rawdata-customerinsight" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/rawdata-customerinsight$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/rawdata-customerinsight" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "retail-customerreviewsdata" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/retail-customerreviewsdata$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/retail-customerreviewsdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "retail-notebook-data" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/retail-notebook-data$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/retail-notebook-data" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "spatialanalysis" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/spatialanalysis$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/spatialanalysis" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "spatialanalysisinput" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/spatialanalysisinput$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/spatialanalysisinput" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "spatialanalysisvideo" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/spatialanalysisvideo$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/spatialanalysisvideo" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "storevideo" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/storevideo$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/storevideo" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "thermostat" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/thermostat$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/thermostat" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "videoanalyzer" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/videoanalyzer$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/videoanalyzer" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "adx-historical" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/adx-historical$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/adx-historical" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "semanticsearch" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/semanticsearch$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/semanticsearch" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "video" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/video$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/video" $destinationUri --recursive

### Replacing Incident Search Files
# get search query key
Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
$incidentQueryKey = Get-AzSearchQueryKey -ResourceGroupName $rgName -ServiceName $incident_search_retail_name
$incidentQueryKey = $incidentQueryKey.Key

(Get-Content -path artifacts/storageassets/incident-search/AzSearch_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/storageassets/incident-search/AzSearch.html

(Get-Content -path artifacts/storageassets/incident-search/gistfile1_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/storageassets/incident-search/gistfile1.html

(Get-Content -path artifacts/storageassets/incident-search/search_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/storageassets/incident-search/search.html

(Get-Content -path artifacts/storageassets/incident-search/detail_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
} | Set-Content -Path artifacts/storageassets/incident-search/detail.html

#storage assests copy
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$containers=Get-ChildItem "./artifacts/storageassets" | Select BaseName

foreach($container in $containers)
{
    $destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
    if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
    $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
    & $azCopyCommand copy "./artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive
}

#########################

Add-Content log.txt "----Form Recognizer-----"
Write-Host "----Form Recognizer-----"
#form Recognizer
#Replace values in create_model.py
(Get-Content -path artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
                -replace '#LOCATION#', $rglocation`
				-replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
				-replace '#CONTAINER_NAME#', "incidentpdftraining"`
				-replace '#SAS_TOKEN#', $sasToken`
				-replace '#APIM_KEY#',  $forms_cogs_keys.Key1`
			} | Set-Content -Path artifacts/formrecognizer/create_model1.py
			
$modelUrl = python "./artifacts/formrecognizer/create_model1.py"
$modelId = $modelUrl.split("/")
$modelId = $modelId[7]

##############################

#Search service 
Write-Host "-----------------Search services---------------"
RefreshTokens

Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $search_srch_retail_name
$primaryAdminKey = $adminKeyPair.Primary

# Create Index
Write-Host  "------Index----"
try {
Get-ChildItem "./artifacts/search" -Filter fabrikam-fashion.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$($search_srch_retail_name).search.windows.net/indexes?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }
    } catch {
        Write-Host "Resource already Exists !"
}
Start-Sleep -s 10

$headers = @{
'api-key' = $primaryAdminKey
'Content-Type' = 'application/json' 
'Accept' = 'application/json' }
$url = "https://$search_srch_retail_name.search.windows.net/indexes/fabrikam-fashion/docs/index?api-version=2021-04-30-Preview"
$Data= Get-Content -Raw -Path ./artifacts/search/data.json
$body = $Data.Replace("#STORAGE_ACCOUNT_NAME#",$dataLakeAccountName)
Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body

#### Incident Search ####

# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $incident_search_retail_name
$primaryAdminKey = $adminKeyPair.Primary

#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cog_retail_name -g $rgName|ConvertFrom-json
$destinationKey=$key.key1

# Fetch connection string
$storageKey = (Get-AzStorageAccountKey -Name $storageAccountName -ResourceGroupName $rgName)[0].Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($storageAccountName);AccountKey=$($storageKey);EndpointSuffix=core.windows.net"

#resource id of cognitive_services_name
$resource=az resource show -g $rgName -n $cog_retail_name --resource-type "Microsoft.CognitiveServices/accounts"|ConvertFrom-Json
$resourceId=$resource.id

# Create Index
Write-Host  "------Index----"
Get-ChildItem "artifacts/search" -Filter incidentsearch-index.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$incident_search_retail_name.search.windows.net/indexes?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

#Replace connection string in retailcogsearchjsondata.json
(Get-Content -path artifacts/search/retailcogsearchjsondata.json -Raw) | Foreach-Object { $_ `
    -replace '#STORAGEACCOUNTNAME#', $storageAccountName`
    -replace '#STORAGEKEY#', $storageKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/search/retailcogsearchjsondata.json

# Create Datasource endpoint
Write-Host  "------Datasource----"
Get-ChildItem "artifacts/search" -Filter retailcogsearchjsondata.json |
        ForEach-Object {
            $datasourceDefinition = (Get-Content $_.FullName -Raw).replace("#STORAGE_CONNECTION#", $storageConnectionString)
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

             $url = "https://$incident_search_retail_name.search.windows.net/datasources?api-version=2020-06-30"
             $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $dataSourceDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

#Replace connection string in retailcog-skillset.json
(Get-Content -path artifacts/search/retailcog-skillset.json -Raw) | Foreach-Object { $_ `
				-replace '#RESOURCE_ID#', $resourceId`
				-replace '#STORAGEACCOUNTNAME#', $storageAccountName`
                -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
                -replace '#RESOURCE_GROUP#', $rgName`
				-replace '#STORAGEKEY#', $storageKey`
				-replace '#COGNITIVE_API_KEY#', $destinationKey`
                -replace '#COGNITIVE_RETAIL_NAME#', $cog_retail_name`
                -replace '#SUBSCRIPTION_ID#', $subscriptionId`
			} | Set-Content -Path artifacts/search/retailcog-skillset.json

# Create Skillset
Write-Host  "------Skillset----"
Get-ChildItem "artifacts/search" -Filter retailcog-skillset.json |
        ForEach-Object {
            $skillsetDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$incident_search_retail_name.search.windows.net/skillsets?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $skillsetDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

#Replace connection string in adlsgen2-indexer.json
(Get-Content -path artifacts/search/adlsgen2-indexer.json -Raw) | Foreach-Object { $_ `
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/search/adlsgen2-indexer.json

# Create Indexers
Write-Host  "------Indexers----"
Get-ChildItem "artifacts/search" -Filter adlsgen2-indexer.json |
        ForEach-Object {
            $indexerDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$incident_search_retail_name.search.windows.net/indexers?api-version=2020-06-30"
           $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexerDefinition | ConvertTo-Json
        }

##############################

#Azure Purview
Write-Host "-----------------Azure Purview---------------"
RefreshTokens

#create collections
$body = @{
    parentCollection = @{
      referenceName = $accounts_purview_retail_name
    }
  }
  
  $body = $body | ConvertTo-Json
  
  RefreshTokens
  $uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName1)?api-version=2019-11-01-preview"
  $result = Invoke-RestMethod -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  RefreshTokens
  $uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName2)?api-version=2019-11-01-preview"
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  RefreshTokens
  $uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName3)?api-version=2019-11-01-preview"
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  RefreshTokens
  $uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName4)?api-version=2019-11-01-preview"
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  #create sources
  $body = @{
          kind = "AdlsGen2"
          properties = @{
              endpoint = "https://$($storageAccountName).dfs.core.windows.net/"
        subscriptionId = $subscriptionId
        resourceGroup = $rgName
        location = $rglocation
        resourceName = $storageAccountName
        collection = @{
                type = "CollectionReference"
                referenceName = $purviewCollectionName1
              }
          }
      }
  
  $body = $body | ConvertTo-Json
  
  $uri = "https://$($accounts_purview_retail_name).purview.azure.com/scan/datasources/AzureDataLakeStorage?api-version=2018-12-01-preview"
  RefreshTokens
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  $body = @{
    kind = "AzureSynapseWorkspace"
    properties = @{
      dedicatedSqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
      serverlessSqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
      subscriptionId = $subscriptionId
      resourceGroup = $rgName
      location = $rglocation
      resourceName = $synapseWorkspaceName
      collection = @{
        type = "CollectionReference"
        referenceName = $purviewCollectionName2
      }
    }
  }
  
  $body = $body | ConvertTo-Json
  
  $uri = "https://$($accounts_purview_retail_name).purview.azure.com/scan/datasources/AzureSynapseAnalytics?api-version=2018-12-01-preview"
  RefreshTokens
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  $body = @{
    kind = "AzureCosmosDb"
    properties = @{
      accountUri = "https://$($cosmosdb_retail2_name).documents.azure.com:443/"
      subscriptionId = $subscriptionId
      resourceGroup = $rgName
      location = $rglocation
      resourceName = $cosmosdb_retail2_name
      collection = @{
        type = "CollectionReference"
        referenceName = $purviewCollectionName3
      }
    }
  }
  
  $body = $body | ConvertTo-Json
  
  $uri = "https://$($accounts_purview_retail_name).purview.azure.com/scan/datasources/CosmosDB?api-version=2018-12-01-preview"
  RefreshTokens
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
  
  $body = @{
    kind = "PowerBI"
    properties = @{
      tenant = $tenantId
      collection = @{
        type = "CollectionReference"
        referenceName = $purviewCollectionName4
      }
    }
  }
  
  $body = $body | ConvertTo-Json
  
  $uri = "https://$($accounts_purview_retail_name).purview.azure.com/scan/datasources/PowerBI?api-version=2018-12-01-preview"
  RefreshTokens
  $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"  

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

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sql_user_retail.sql"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery  = "CREATE DATABASE RetailSqlOnDemand"
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
    if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "storedprocedures" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sql_user_retail")
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
    $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmosdb_retail2_name)
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

#uploading Sql Scripts
Add-Content log.txt "-----------uploading KQL Scripts-----------------"
Write-Host "----KQL Scripts------"
RefreshTokens
$scripts=Get-ChildItem "./artifacts/kqlscripts" | Select BaseName

foreach ($name in $scripts) 
{
    $ScriptFileName="./artifacts/kqlscripts/"+$name.BaseName+".kql"
    Write-Host "Uploading Kql Script : $($name.BaseName)"
    New-AzSynapseKqlScript -WorkspaceName $synapseWorkspaceName -DefinitionFile $ScriptFileName
}


Add-Content log.txt "------linked Services------"
Write-Host "----linked Services------"
#Creating linked services
RefreshTokens
$templatepath="./artifacts/linkedservices/"

##SynapseDev linked services
Write-Host "Creating linked Service: SynapseDev"
$filepath=$templatepath+"SynapseDev.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SynapseDev?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##synretailprod-WorkspaceDefaultSqlServer linked services
Write-Host "Creating linked Service: synretailprod-WorkspaceDefaultSqlServer"
$filepath=$templatepath+"synretailprod-WorkspaceDefaultSqlServer.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synretailprod-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##PowerBIWorkspace linked services
Write-Host "Creating linked Service: PowerBIWorkspace"
$filepath=$templatepath+"PowerBIWorkspace.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/PowerBIWorkspace?api-version=2019-06-01-preview"
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

##blob linked services
Write-Host "Creating linked Service: synretailprod-WorkspaceDefaultStorage"
$filepath=$templatepath+"synretailprod-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synretailprod-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
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

##Sale_DataLakeStorage linked services
Write-Host "Creating linked Service: Sale_DataLakeStorage"
$filepath=$templatepath+"Sale_DataLakeStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Sale_DataLakeStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##RetailProd linked services
Write-Host "Creating linked Service: RetailProd"
$filepath=$templatepath+"RetailProd.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/RetailProd?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##OracleDB linked services
Write-Host "Creating linked Service: OracleDB"
$filepath=$templatepath+"OracleDB.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/OracleDB?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##cosmosdbretail2prod linked services
Write-Host "Creating linked Service: cosmosdbretail2prod"
$filepath=$templatepath+"cosmosdbretail2prod.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmosdb_retail2_name).Replace("#COSMOS_DATABASE#", $cosmos_database_name).Replace("COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/cosmosdbretail2prod?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##cosmosdbretail2 linked services for inventory db
Write-Host "Creating linked Service: cosmosdbretail2"
$filepath=$templatepath+"cosmosdbretail2.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmosdb_retail2_name).Replace("#COSMOS_DATABASE#", $cosmos_database_name_retailinventorydb).Replace("COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/cosmosdbretail2?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##CDPProd linked services
Write-Host "Creating linked Service: CDPProd"
$filepath=$templatepath+"CDPProd.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/CDPProd?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##AzureMLService1 linked services
Write-Host "Creating linked Service: AzureMLService1"
$filepath=$templatepath+"AzureMLService1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#SUBSCRIPTION_ID#", $subscriptionId).Replace("#RESOURCE_GROUP_NAME#", $rgName).Replace("#ML_WORKSPACE_NAME#", $amlworkspacename)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureMLService1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##AzureDataExplorer1 linked services
Write-Host "Creating linked Service: AzureDataExplorer1"
$filepath=$templatepath+"AzureDataExplorer1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#SUBSCRIPTION_ID#", $subscriptionId).Replace("#RESOURCE_GROUP_NAME#", $rgName).Replace("#ML_WORKSPACE_NAME#", $amlworkspacename)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDataExplorer1?api-version=2019-06-01-preview"
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
		"#COSMOS_LINKED_SERVICE#" = $cosmosdb_retail2_name
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

#uploading powerbi reports
RefreshTokens

Add-Content log.txt "------powerbi reports upload------"
Write-Host "------------Powerbi Reports Upload ------------"
#Connect-PowerBIServiceAccount
$spname="Retail Demo $deploymentId"

$app = az ad app create --display-name $spname | ConvertFrom-Json
$appId = $app.appId

$mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$clientsecpwd = $mainAppCredential.password

az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "id" -o tsv
start-sleep -s 30

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

$credential = New-Object PSCredential($appId, (ConvertTo-SecureString $clientsecpwd -AsPlainText -Force))

   # Connect to Power BI using the service principal
    Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenantId

    $PowerBIFiles = Get-ChildItem "./artifacts/reports" -Recurse -Filter *.pbix
    $reportList = @()

    foreach ($Pbix in $PowerBIFiles) {
    Write-Output "Uploading report: $($Pbix.FullName)"
  
    $report = New-PowerBIReport -Path $Pbix.FullName -WorkspaceId $wsId

    if ($report -ne $null) {
        Write-Output "Report uploaded successfully: $($report.Name)"

        $temp = [PSCustomObject]@{
            FileName        = $Pbix.FullName
            Name            = $Pbix.BaseName  # Using BaseName to get the file name without the extension
            PowerBIDataSetId = $null
            ReportId        = $report.Id
            SourceServer    = $null
            SourceDatabase  = $null
        }

        # Get dataset
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets"
        $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" }

        foreach ($res in $dataSets.value) {
            if ($res.name -eq $temp.Name) {
                $temp.PowerBIDataSetId = $res.id
                break  # Exit the loop once a match is found
            }
        }

        $reportList += $temp
    } else {
        Write-Output "Failed to upload report: $($Pbix.BaseName)"
    }
    }

Start-Sleep -s 30

Write-Host  "-----------------AML Workspace ---------------"
Add-Content log.txt "-----------AML Workspace -------------"
RefreshTokens

(Get-Content -path ./artifacts/amlnotebooks/Config.py -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName`
    -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key`
    -replace '#FORM_RECOGNIZER_ENDPOINT#', $forms_cogs_endpoint`
    -replace '#FORM_RECOGNIZER_API_KEY#', $forms_cogs_keys.Key1`
    -replace '#FORM_RECOGNIZER_MODEL_ID#', $modelId`
    -replace '#SUBSCRIPTION_ID#', $subscriptionId`
    -replace '#RESOURCE_GROUP#', $rgName`
    -replace '#WORKSPACE_NAME#', $amlworkspacename`
    -replace '#COMPUTE_NAME#', $cpuShell`
    -replace '#TRANSLATION_API_KEY#', $translator_key`
    -replace '#LOCATION#', $rglocation`
} | Set-Content -Path ./artifacts/amlnotebooks/GlobalVariables.py
    
#create aml workspace
az extension add -n azure-cli-ml
az ml workspace create -n $amlworkspacename -g $rgName

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
    elseif($notebook.BaseName -eq "prepared_customer_churn_data" -or $notebook.BaseName  -eq "data" -or $notebook.BaseName  -eq "retail_customer_churn_data"   -or $notebook.BaseName  -eq "retail_sales_dataset" -or $notebook.BaseName  -eq "retail_sales_datasetv2" -or $notebook.BaseName  -eq "Channel_attribution" -or $notebook.BaseName  -eq "OnlineRetailData" -or $notebook.BaseName  -eq "wait_time_forecasted" -or $notebook.BaseName  -eq "Markov - Output - Conversion values")
    {
        $source="./artifacts/amlnotebooks/"+$notebook.BaseName+".csv"
		$path=$notebook.BaseName+".csv"
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

#delete aks compute
az ml computetarget delete -n $cpuShell -v

##Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "--------- PBI connections update---------"	

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$sasTokenAcc = New-AzureStorageAccountSASToken -Context $dataLakeContext -Service Blob -ResourceType Service -Permission rwdl

foreach ($report in $reportList) {
    $datasetId = $report.PowerBIDataSetId
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets/$datasetId/Default.TakeOver"

    try {
        $response = Invoke-RestMethod -Uri $url -Method POST -Headers @{ Authorization = "Bearer $powerbitoken" }
        Write-Host "TakeOver action completed successfully for dataset ID: $datasetId"
    }
    catch {
        Write-Host "Error occurred while performing TakeOver action for dataset ID: $datasetId - $_"
    }
    }

foreach($report in $reportList)
{
    if($report.name -eq "Dashboard-Images" -or $report.name -eq "ADX dashboard 8AM" -or $report.name -eq "CEO Dec" -or $report.name -eq "CEO May" -or $report.name -eq "CEO Nov" -or $report.name -eq "CEO Oct" -or $report.name -eq "CEO Sep" -or $report.name -eq "Datbase template PBI" -or $report.name -eq "VP Dashboard" -or $report.name -eq "Twitter Sentiment Analytics")
    {
        continue;
    }
	    elseif($report.name -eq "ADX Thermostat and Occupancy")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"KustoServer`",
									`"newValue`": `"https://$($kustoPoolName).$($synapseWorkspaceName).kusto.azuresynapse.net`"
								},
								{
									`"name`": `"KustoDB`",
									`"newValue`": `"$($kustoDatabaseName)`"
								}
								
								]
								}"	
	}
    elseif($report.name -eq "Acquisition Impact Report")
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
								},
								{
									`"name`": `"Source_LakeDB`",
									`"newValue`": `"$($synapseWorkspaceName)`"
								},
								{
									`"name`": `"LakeDB`",
									`"newValue`": `"WWImportersConstosoRetailLakeDB`"
								}
								]
								}"	
	}
	elseif($report.name -eq "Revenue and Profiability" -or $report.name -eq "Finance Report")
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
    elseif($report.name -eq "CCO Report" )
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server1`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database1`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
    elseif($report.name -eq "CDP Vision Report" -or $report.name -eq "US Map with header" -or $report.name -eq "ESG Report Final" -or $report.name -eq  "globalmarkets" -or $report.name -eq "Location Analytics" -or $report.name -eq "World Map" -or $report.name -eq "Campaign Analytics" -or $report.name -eq "Retail Predictive Analytics")
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
	elseif($report.name -eq "Retail Group CEO KPI")
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
								},
								{
									`"name`": `"RetailServer`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								]
								}"	
	}
    elseif($report.name -eq "Retail HTAP")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"CosmosLink`",
									`"newValue`": `"https://$($cosmosdb_retail2_name).documents.azure.com:443/`"
                                    
								},
								{
									`"name`": `"CosmosDb`",
									`"newValue`": `"$($cosmos_database_name_retailinventorydb)`"
								}
								]
								}"	
	}
	 elseif($report.name -eq "Customer Segmentation")
	 {	 $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								}
								]
								}"	
	 }
	  elseif($report.name -eq "Retail Dynamic Data Masking (Azure Synapse)")
	 {	 $body = "{
			`"updateDetails`": [
								{
									`"name`": `"ServerNew`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								}
								]
								}"	
	 }
    elseif($report.name -eq  "Product Recommendation" -or $report.name -eq "Campaign Analytics Deep Dive")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"ServerName`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
	elseif($report.name -eq "Retail Column Level Security (Azure Synapse)" -or $report.name -eq "Retail Row Level Security (Azure Synapse)")
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
	elseif($report.name -eq "Global Occupational Safety Report")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"KnowledgeStoreStorageAccount`",
									`"newValue`": `"$($dataLakeAccountName)`"
								},
								{
									`"name`": `"StorageAccountSasUri`",
									`"newValue`": `"$($sasTokenAcc)`"
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

$app = az ad app create --display-name $sites_app_multiling_retail_name | ConvertFrom-Json
$appId = $app.appId

$appCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$appPassword = $appCredential.password

az deployment group create --resource-group $rgName --template-file "./artifacts/qnamaker/bot-multiling-template.json" --parameters appId=$appId appSecret=$appPassword botId=$bot_qnamaker_retail_name newWebAppName=$sites_app_multiling_retail_name newAppServicePlanName=$asp_multiling_retail_name appServicePlanLocation=$rglocation

az webapp deployment source config-zip --resource-group $rgName --name $sites_app_multiling_retail_name --src "./artifacts/qnamaker/chatbot.zip"
az webapp start --name $sites_app_multiling_retail_name --resource-group $rgName 

#################

#function apps
Add-Content log.txt "-----Unzipping function and webapps-------"
Write-Host  "--------------Unzipping function and webapps---------------"
RefreshTokens

$zips = @("retaildemo-app", "app-iotfoottraffic-sensor", "app-adx-thermostat-realtime", "app_media_search", "func-product-search", "app-product-search", "model_builder", "recommender")
foreach($zip in $zips)
{
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

az webapp stop --name $functionapplivestreaming --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $functionapplivestreaming --src "./artifacts/binaries/func-retail-livestreaming.zip"	
az webapp start --name $functionapplivestreaming --resource-group $rgName

#Web app
Add-Content log.txt "------deploy poc web app------"
Write-Host  "-----------------Deploy web app ---------------"
RefreshTokens

$device = Add-AzIotHubDevice -ResourceGroupName $rgName -IotHubName $iothub_foottraffic -DeviceId retail-foottraffic-device

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

(Get-Content -path retaildemo-app/appsettings.json -Raw) | Foreach-Object { $_ `
                -replace '#WORKSPACE_ID#', $wsId`
				-replace '#APP_ID#', $appId`
				-replace '#APP_SECRET#', $clientsecpwd`
				-replace '#TENANT_ID#', $tenantId`				
        } | Set-Content -Path retaildemo-app/appsettings.json

$filepath="./retaildemo-app/wwwroot/config-poc.js"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName).Replace("#SERVER_NAME#", $app_retaildemo_name).Replace("#SEARCH_APP_NAME#", $media_search_app_service_name).Replace("#SPEECH_KEY#", $cog_speech_key.key1).Replace("#LOCATION#", $rglocation)
Set-Content -Path $filepath -Value $item

#bot qna maker
$bot_detail = az bot webchat show --name $bot_qnamaker_retail_name --resource-group $rgName --with-secrets true | ConvertFrom-Json
$bot_key = $bot_detail.properties.properties.sites[0].key

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
$reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$reportList = $reportList.Value
$sites_app_product_search_url = "https://$($sites_app_product_search).azurewebsites.net"
#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable   
# $ht.add("#Bing_Map_Key#", "AhBNZSn-fKVSNUE5xYFbW_qajVAZwWYc8OoSHlH8nmchGuDI6ykzYjrtbwuNSrR8")
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
$ht.add("#PRODUCT_AI_SEARCH_APP_URL#", $sites_app_product_search_url)

$filePath = "./retaildemo-app/wwwroot/config-poc.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./retaildemo-app/*" -DestinationPath "./retaildemo-app.zip"
Compress-Archive -Path "./app_media_search/*" -DestinationPath "./app_media_search.zip"

az webapp stop --name $app_retaildemo_name --resource-group $rgName
az webapp stop --name $media_search_app_service_name --resource-group $rgName
try{
az webapp deployment source config-zip --resource-group $rgName --name $app_retaildemo_name --src "./retaildemo-app.zip"
}
catch
{
}
try{
az webapp deployment source config-zip --resource-group $rgName --name $media_search_app_service_name --src "./app_media_search.zip"
}
catch
{
}

Add-Content log.txt "-----python function apps zip deploy-------"
Write-Host "----python function apps zip deploy------"

cd recommender
az webapp up --resource-group $rgName --name $functionapprecommender --plan $functionapprecommender_asp --location $rglocation --sku "B1"
cd ..
Start-Sleep -s 30
az functionapp deployment source config-zip --resource-group $rgName --name $functionapprecommender --src "./artifacts/binaries/recommender.zip" --build-remote true
Start-Sleep -s 30
az webapp start  --name $functionapprecommender --resource-group $rgName

cd model_builder
az webapp up --resource-group $rgName --name $functionappmodelbuilder --plan $functionappmodelbuilder_asp --location $rglocation --sku "B1"
cd ..
Start-Sleep -s 30
az functionapp deployment source config-zip --resource-group $rgName --name $functionappmodelbuilder --src "./artifacts/binaries/model_builder.zip" --build-remote true
Start-Sleep -s 30
$vi_indexer_url = "https://api.videoindexer.ai/"+$vi_location+"/Accounts/"+$vi_account_id+"/Videos/{}/Index?reTranslate=False&includeStreamingUrls=True"
Update-AzFunctionAppSetting -Name $functionappmodelbuilder -ResourceGroupName $rgName -AppSetting @{"VIDEO_INDEXER_URL" = "$($vi_indexer_url)"}
az webapp start  --name $functionappmodelbuilder --resource-group $rgName

# IOT FootTraffic
$device_conn_string= $(Get-AzIotHubDeviceConnectionString -ResourceGroupName $rgName -IotHubName $iothub_foottraffic -DeviceId retail-foottraffic-device).ConnectionString
$shared_access_key = $device_conn_string.Split(";")[2]
$device_primary_key= $shared_access_key.Substring($shared_access_key.IndexOf("=")+1)

$iot_hub_config = '"{\"frequency\":1,\"connection\":{\"provisioning_host\":\"global.azure-devices-provisioning.net\",\"symmetric_key\":\"' + $device_primary_key + '\",\"IoTHubConnectionString\":\"' + $device_conn_string + '\"}}"'

(Get-Content -path app-iotfoottraffic-sensor/.env -Raw) | Foreach-Object { $_ `
     -replace '#DEVICE_PRIMARY_KEY#', $device_primary_key`
     -replace '#DEVICE_CONN_STRING#', $device_conn_string`
 } | Set-Content -Path app-iotfoottraffic-sensor/.env

Write-Information "Deploying IOT FootTraffic Retail App"
cd app-iotfoottraffic-sensor
az webapp up --resource-group $rgName --name $sites_app_iotfoottraffic_sensor_name
cd ..
Start-Sleep -s 10

$config = az webapp config appsettings set -g $rgName -n $sites_app_iotfoottraffic_sensor_name --settings IoTHubConfig=$iot_hub_config

# ADX Thermostat Realtime
$occupancy_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name occupancy --name occupancy | ConvertFrom-Json
$occupancy_endpoint = $occupancy_endpoint.primaryConnectionString
$thermostat_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name thermostat --name thermostat | ConvertFrom-Json
$thermostat_endpoint = $thermostat_endpoint.primaryConnectionString

(Get-Content -path adx-config-appsetting.json -Raw) | Foreach-Object { $_ `
    -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_THERMOSTAT_ENDPOINT#', $thermostat_endpoint`
    -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_OCCUPANCY_ENDPOINT#', $occupancy_endpoint`
   -replace '#THERMOSTATTELEMETRY_URL#', $thermostat_telemetry_Realtime_URL`
   -replace '#OCCUPANCYDATA_URL#', $occupancy_data_Realtime_URL`
} | Set-Content -Path adx-config-appsetting-with-replacement.json

$config = az webapp config appsettings set -g $rgName -n $sites_adx_thermostat_realtime_name --settings @adx-config-appsetting-with-replacement.json

Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_adx_thermostat_realtime_name -ArchivePath ./artifacts/binaries/app-adx-thermostat-realtime.zip -Force

# Write-Information "Deploying ADX Thermostat Realtime App"
# cd app-adx-thermostat-realtime
# az webapp up --resource-group $rgName --name $sites_adx_thermostat_realtime_name
# cd ..
# Start-Sleep -s 10

$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $search_srch_retail_name
$primaryAdminKey = $adminKeyPair.Primary

# Product Seach Function App adn WebApp deployment
Write-Information "Deploying Product Seach Function App"
try{
az functionapp create --resource-group $rgName --consumption-plan-location $rglocation --runtime node --runtime-version 16 --functions-version 4 --name $func_product_search_name --storage-account $dataLakeAccountName
}
catch
{
az functionapp create --resource-group $rgName --consumption-plan-location $rglocation --runtime node --runtime-version 16 --functions-version 4 --name $func_product_search_name --storage-account $dataLakeAccountName
}
Start-Sleep -s 30

$config = az webapp config appsettings set -g $rgName -n $func_product_search_name --settings SearchApiKey=$primaryAdminKey
$config = az webapp config appsettings set -g $rgName -n $func_product_search_name --settings SearchFacets="category1, category2, category3"
$config = az webapp config appsettings set -g $rgName -n $func_product_search_name --settings SearchIndexName="fabrikam-fashion"
$config = az webapp config appsettings set -g $rgName -n $func_product_search_name --settings SearchServiceName=$search_srch_retail_name

az functionapp cors add -g $rgName -n $func_product_search_name  --allowed-origins "*"

az webapp stop --name $func_product_search_name --resource-group $rgName 
az functionapp deployment source config-zip -g $rgName -n $func_product_search_name --src "./artifacts/binaries/product-search-func-app.zip"
az webapp start --name $func_product_search_name --resource-group $rgName 

(Get-Content -path app-product-search/config-prod.js -Raw) | Foreach-Object { $_ `
    -replace '#FUNCTION_PRODUCT_SEARCH#', $func_product_search_name`
    -replace '#BOT_NAME#', $bot_qnamaker_retail_name`
    -replace '#BOT_KEY#', $bot_key`
} | Set-Content -Path app-product-search/config-prod.js

Write-Information "Deploying Product Seach Web App"
cd app-product-search
az webapp up --resource-group $rgName --name $sites_app_product_search --html;
cd ..
Start-Sleep -s 10

RefreshTokens

az webapp restart --name $functionapplivestreaming --resource-group $rgName 
az webapp start --name $func_product_search_name --resource-group $rgName 
az webapp start  --name $app_retaildemo_name --resource-group $rgName
az webapp start --name $media_search_app_service_name --resource-group $rgName
az webapp start  --name $sites_app_iotfoottraffic_sensor_name --resource-group $rgName
az webapp start --name $sites_adx_thermostat_realtime_name --resource-group $rgName
az webapp start --name $sites_app_product_search --resource-group $rgName

foreach($zip in $zips)
{
    if ($zip -eq  "immersive-reader-app"  -or $zip -eq  "retaildemo-app" ) 
    {
        remove-item -path "./$($zip).zip" -recurse -force
    }
    if ($zip -eq "retaildemo-app" ) 
    {
        continue;
    }
    remove-item -path "./$($zip)" -recurse -force
}

#start ASA
Write-Host "----Starting ASA-----"
Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_retail -OutputStartMode 'JobStartTime'

#####################################################
Write-Host "------COSMOS data Upload -------------"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmosdb_retail2_name
$cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    if($name.BaseName -eq "inventorydb")
	{
     $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmos_database_name_retailinventorydb -ResourceGroup $rgName
	}
	else 
	{
	$cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmos_database_name -ResourceGroup $rgName
	}
    $path="./artifacts/cosmos/"+$name.BaseName+".json"
    $documents=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $documents

    foreach($json in $document)
    {
        if($name.Basename -eq "retaildb") {
            $partitionKey = "beforefoottraffic" + $((Get-Date -Format MM-dd-yyyy).ToString())
            if(![bool]($json.PSobject.Properties.name -match "beforefoottraffic"))
            {$json | Add-Member -MemberType NoteProperty -Name 'beforefoottraffic' -Value $partitionKey }
            $key=$json.beforefoottraffic
        }
        elseif ($name.Basename -eq "retailcosmos") {
            $key = $json.TransactionType
        }
        elseif ($name.Basename -eq "inventorydb") {
            $key = $json.InventoryType
        }
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
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"AggregatedSales_SAPHANA"}} , @{Name = "TABLE_NAME"; Expression = {"AggregatedSales_SAPHANA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics_New"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalyticLatest"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalyticLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaigns"}} , @{Name = "TABLE_NAME"; Expression = {"Campaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ConflictofInterest"}} , @{Name = "TABLE_NAME"; Expression = {"ConflictofInterest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Country"}} , @{Name = "TABLE_NAME"; Expression = {"Country"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerInfo"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerSalesHana"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerSalesHana"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerVisitF"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerVisitF"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"customerVisitsInPersonByLocation"}} , @{Name = "TABLE_NAME"; Expression = {"customerVisitsInPersonByLocation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DailyStockData"}} , @{Name = "TABLE_NAME"; Expression = {"DailyStockData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Dim_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Dim_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DimData"}} , @{Name = "TABLE_NAME"; Expression = {"DimData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"EmailAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"EmailAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Engagement_ActualVsForecast"}} , @{Name = "TABLE_NAME"; Expression = {"Engagement_ActualVsForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ESGOrganisation"}} , @{Name = "TABLE_NAME"; Expression = {"ESGOrganisation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinalRevenue"}} , @{Name = "TABLE_NAME"; Expression = {"FinalRevenue"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinanceSales"}} , @{Name = "TABLE_NAME"; Expression = {"FinanceSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FPA"}} , @{Name = "TABLE_NAME"; Expression = {"FPA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HeaderWIP"}} , @{Name = "TABLE_NAME"; Expression = {"HeaderWIP"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Location_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Location_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Address"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Address"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_CustomerGender"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_CustomerGender"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Order"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Order"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_OrderLineStatus_New"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_OrderLineStatus_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Product_New"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Product_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"MillennialCustomers"}} , @{Name = "TABLE_NAME"; Expression = {"MillennialCustomers"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"NewsAndSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"NewsAndSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OperatingExpenses"}} , @{Name = "TABLE_NAME"; Expression = {"OperatingExpenses"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBalanceSheet"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBalanceSheet"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBankCustomerRanking"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBankCustomerRanking"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBedOccupancyForecasted"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBedOccupancyForecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiCustomer"}} , @{Name = "TABLE_NAME"; Expression = {"pbiCustomer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiESG"}} , @{Name = "TABLE_NAME"; Expression = {"pbiESG"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
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
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitution"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitutionUnit"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitutionUnit"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiKPI"}} , @{Name = "TABLE_NAME"; Expression = {"pbiKPI"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiRegion"}} , @{Name = "TABLE_NAME"; Expression = {"pbiRegion"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiWaitTimeForecast"}} , @{Name = "TABLE_NAME"; Expression = {"PbiWaitTimeForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pred_anomaly"}} , @{Name = "TABLE_NAME"; Expression = {"pred_anomaly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductLink2"}} , @{Name = "TABLE_NAME"; Expression = {"ProductLink2"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductRecommendations"}} , @{Name = "TABLE_NAME"; Expression = {"ProductRecommendations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Products"}} , @{Name = "TABLE_NAME"; Expression = {"Products"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RevenueVsMarketingCost"}} , @{Name = "TABLE_NAME"; Expression = {"RevenueVsMarketingCost"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Role"}} , @{Name = "TABLE_NAME"; Expression = {"Role"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMaster"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMaster"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMasters"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMasters"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMasterUpdated"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMasterUpdated"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesVsExpense"}} , @{Name = "TABLE_NAME"; Expression = {"SalesVsExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SiteSecurity"}} , @{Name = "TABLE_NAME"; Expression = {"SiteSecurity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SortedCampaigns"}} , @{Name = "TABLE_NAME"; Expression = {"SortedCampaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Travel_Entertainment"}} , @{Name = "TABLE_NAME"; Expression = {"Travel_Entertainment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterRawData"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterRawData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VTBByChannel"}} , @{Name = "TABLE_NAME"; Expression = {"VTBByChannel"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"vwPbiESGSlicerOrganizations"}} , @{Name = "TABLE_NAME"; Expression = {"vwPbiESGSlicerOrganizations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WWIBrands"}} , @{Name = "TABLE_NAME"; Expression = {"WWIBrands"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WWIProducts"}} , @{Name = "TABLE_NAME"; Expression = {"WWIProducts"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Automotive"}} , @{Name = "TABLE_NAME"; Expression = {"Automotive"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalyticLatestBKP"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalyticLatestBKP"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CohortAnalysis"}} , @{Name = "TABLE_NAME"; Expression = {"CohortAnalysis"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"customer_segment_rfm"}} , @{Name = "TABLE_NAME"; Expression = {"customer_segment_rfm"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"iot-foottraffic-data"}} , @{Name = "TABLE_NAME"; Expression = {"iot-foottraffic-data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"KS_CustomerInfo"}} , @{Name = "TABLE_NAME"; Expression = {"KS_CustomerInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OccupancyDate_0001"}} , @{Name = "TABLE_NAME"; Expression = {"OccupancyDate_0001"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OccupancyDateNews"}} , @{Name = "TABLE_NAME"; Expression = {"OccupancyDateNews"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"occupancyHistoricalData"}} , @{Name = "TABLE_NAME"; Expression = {"occupancyHistoricalData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"occupancyHistoricalData2021"}} , @{Name = "TABLE_NAME"; Expression = {"occupancyHistoricalData2021"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OnlineRetailData"}} , @{Name = "TABLE_NAME"; Expression = {"OnlineRetailData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBankGlobalRanking"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBankGlobalRanking"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiReadmissionPrediction"}} , @{Name = "TABLE_NAME"; Expression = {"PbiReadmissionPrediction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiRetailPrediction"}} , @{Name = "TABLE_NAME"; Expression = {"PbiRetailPrediction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RealTimeTwitterData"}} , @{Name = "TABLE_NAME"; Expression = {"RealTimeTwitterData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Sales"}} , @{Name = "TABLE_NAME"; Expression = {"Sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Salestransaction"}} , @{Name = "TABLE_NAME"; Expression = {"Salestransaction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"testtable"}} , @{Name = "TABLE_NAME"; Expression = {"testtable"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"thermostatHistoricalData"}} , @{Name = "TABLE_NAME"; Expression = {"thermostatHistoricalData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"thermostatHistoricalData2021"}} , @{Name = "TABLE_NAME"; Expression = {"thermostatHistoricalData2021"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Wait_Time_Forecasted"}} , @{Name = "TABLE_NAME"; Expression = {"Wait_Time_Forecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
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

Add-Content log.txt "-----------------Execution Complete---------------"
Write-Host  "-----------------Execution Complete----------------"
}
