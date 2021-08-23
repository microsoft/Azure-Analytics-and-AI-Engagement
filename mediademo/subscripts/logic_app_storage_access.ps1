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
$vi_account_id = (Get-AzResourceGroup -Name $rgName).Tags["VideoIndexerAccountId"]
$vi_account_key = (Get-AzResourceGroup -Name $rgName).Tags["VideoIndexerApiKey"]
$subscriptionId = (Get-AzContext).Subscription.Id
$suffix = "$random-$init"
$concatString = "$init$random"
$location = (Get-AzResourceGroup -Name $rgName).Location
$vi_location = "trial"
$workflows_logic_video_indexer_trigger_name = "logic-app-video-trigger-$suffix"
$workflows_logic_storage_trigger_name = "logic-app-storage-trigger-$suffix"
$functionapptranscript = "func-app-media-transcript-$suffix"
$connections_cosmosdb_name =  "conn-documentdb-$suffix"
$connections_azureblob_name = "conn-azureblob-$suffix"

if($concatString.length -gt 16)
{
$dataLakeAccountName = "stmedia"+($concatString.substring(0,17))
}
else
{
	$dataLakeAccountName = "stmedia"+ $concatString
}

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
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

az webapp stop --name $functionapptranscript --resource-group $rgName
az webapp deployment source config-zip --resource-group $rgName --name $functionapptranscript --src "../artifacts/binaries/func_savetranscript.zip"	
az webapp start --name $functionapptranscript --resource-group $rgName

#logic app template replacement
(Get-Content -path artifacts/templates/logic_app_video_trigger_def.json -Raw) | Foreach-Object { $_ `
                -replace '###Document_Connection_name###', $connections_cosmosdb_name`
				-replace '###video_indexer_api_key###', $vi_account_key`
				-replace '###video_indexer_account_id###', $vi_account_id`
				-replace '###subscriptions_id###', $subscriptionId`
				-replace '###rg_name###', $rgName`
				-replace '###function_name###', $functionapptranscript`
				-replace '###location###', $location`
				-replace '###vi_location###', $vi_location`
				
        } | Set-Content -Path artifacts/templates/logic_app_video_trigger_def.json
		
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
				-replace '###location###', $location`
				-replace '###vi_location###', $vi_location`		
        } | Set-Content -Path artifacts/templates/logic_app_storage_trigger_def.json

RefreshTokens
#logic app definition update
az extension add -n logic
 az logic workflow update --resource-group $rgName --name $workflows_logic_video_indexer_trigger_name --definition "../artifacts/templates/logic_app_video_trigger_def.json"
 
  az logic workflow update --resource-group $rgName --name $workflows_logic_storage_trigger_name --definition "../artifacts/templates/logic_app_storage_trigger_def.json"
 
 start-sleep -s 60
 
#storage assests copy
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$containers=Get-ChildItem "../artifacts/storageassets" | Select BaseName

foreach($container in $containers)
{
    $destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
    $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
    & $azCopyCommand copy "../artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive
}
