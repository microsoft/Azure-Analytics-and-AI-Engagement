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
$concatString = "$init$random"
$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))
$location = (Get-AzResourceGroup -Name $rgName).Location
$storageAccountName = $dataLakeAccountName
$suffix = "$random-$init"
$forms_cogs_name = "forms-$suffix";
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_cogs_name

#Form Recognizer
Add-Content log.txt "-----------------Form Recognizer---------------"
Write-Host "-----Form Recognizer-----"
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$StartTime = Get-Date
$EndTime = $startTime.AddDays(6)
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
Write-Host "----Uploading to storage containers-----"
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

RefreshTokens
 
$destinationSasKey = New-AzStorageContainerSASToken -Container "mfgdemodata" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/mfgdemodata/$($destinationSasKey)"
& $azCopyCommand copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/publicassets/telemetryp.csv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "anomalydetection" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/anomalydetection$($destinationSasKey)"
& $azCopyCommand copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/anomalydetection" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "ppecompliancedetection" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/ppecompliancedetection$($destinationSasKey)"
& $azCopyCommand copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/ppecompliancedetection" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "qualitycontrol" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/qualitycontrol$($destinationSasKey)"
& $azCopyCommand copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/qualitycontrol" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "azureml-mfg" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/azureml-mfg$($destinationSasKey)"
& $azCopyCommand copy "https://dreamdemostrggen2r16gxwb.blob.core.windows.net/azureml-mfg" $destinationUri --recursive

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
        Write-Host "Copying directory $($source) to $($destination)"
        & $azCopyCommand copy $source $destination --recursive=true
}

#Replace values in create_model.py
(Get-Content -path artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
				-replace '#LOCATION#', $location`
				-replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
				-replace '#CONTAINER_NAME#', "form-datasets"`
				-replace '#SAS_TOKEN#', $sasToken`
				-replace '#APIM_KEY#',  $forms_cogs_keys.Key1`
			} | Set-Content -Path artifacts/formrecognizer/create_model.py
