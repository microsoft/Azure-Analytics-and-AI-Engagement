function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

function Check-HttpRedirect($uri) {
    $httpReq = [system.net.HttpWebRequest]::Create($uri)
    $httpReq.Accept = "text/html, application/xhtml+xml, */*"
    $httpReq.method = "GET"   
    $httpReq.AllowAutoRedirect = $false;

    #use them all...
    #[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls;

    $global:httpCode = -1;

    $response = "";            

    try {
        $res = $httpReq.GetResponse();

        $statusCode = $res.StatusCode.ToString();
        $global:httpCode = [int]$res.StatusCode;
        $cookieC = $res.Cookies;
        $resHeaders = $res.Headers;  
        $global:rescontentLength = $res.ContentLength;
        $global:location = $null;
                            
        try {
            $global:location = $res.Headers["Location"].ToString();
            return $global:location;
        }
        catch {
        }

        return $null;

    }
    catch {
        $res2 = $_.Exception.InnerException.Response;
        $global:httpCode = $_.Exception.InnerException.HResult;
        $global:httperror = $_.exception.message;

        try {
            $global:location = $res2.Headers["Location"].ToString();
            return $global:location;
        }
        catch {
        }
    } 

    return $null;
}

az login

#for powershell...
Connect-AzAccount -DeviceCode

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
if ($subs.GetType().IsArray -and $subs.length -gt 1) {
    $subOptions = [System.Collections.ArrayList]::new()
    for ($subIdx = 0; $subIdx -lt $subs.length; $subIdx++) {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    $title = 'Subscription selection'
    $question = 'Are you sure you want to select this subscription for this lab?'
    $choices = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
    else {
        $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
        $selectedSubName = $subs[$selectedSubIdx]
        Write-Host "Selecting the subscription : $selectedSubName "
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
}

$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
$concatString = "$init$random"

$dataLakeAccountName = "sthealthcare2$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value


#download azcopy command
    if ([System.Environment]::OSVersion.Platform -eq "Unix") {
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-linux"

        if (!$azCopyLink) {
            $azCopyLink = "https://azcopyvnext.azureedge.net/release20200709/azcopy_linux_amd64_10.5.0.tar.gz"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.tar.gz"
        tar -xf "azCopy.tar.gz"
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy).Directory.FullName

        if ($azCopyCommand.count -gt 1) {
            $azCopyCommand = $azCopyCommand[0];
        }

        cd $azCopyCommand
        chmod +x azcopy
        cd ..
        $azCopyCommand += "\azcopy"
    } else {
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

        if (!$azCopyLink) {
            $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
        Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName

        if ($azCopyCommand.count -gt 1) {
            $azCopyCommand = $azCopyCommand[0];
        }

        $azCopyCommand += "\azcopy"
    }

    #Uploading to storage containers
    Add-Content log.txt "-----------Uploading to storage containers-----------------"
    Write-Host "----Uploading to Storage Containers-----"

    $dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

    RefreshTokens

    $destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/customcsv" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "data-source" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/data-source$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/data-source" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "delta-files" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/delta-files$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/delta-files" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "fhirdata" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/fhirdata$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/fhirdata" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "formrecogoutput" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/formrecogoutput$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/formrecogoutput" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "hospitalincidentkdm" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/hospitalincidentkdm$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/hospitalincidentkdm" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "hospitalincidentsearch-skillset-image-projection" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/hospitalincidentsearch-skillset-image-projection$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/hospitalincidentsearch-skillset-image-projection" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "patientintakeform" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/patientintakeform$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/patientintakeform" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "predictiveanalytics" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/predictiveanalytics$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/predictiveanalytics" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "twitter" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/twitter$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/twitter" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/webappassets" $destinationUri --recursive
  
    $destinationSasKey = New-AzStorageContainerSASToken -Container "healthcare-reports" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/healthcare-reports$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/healthcare-reports" $destinationUri --recursive
  
    $destinationSasKey = New-AzStorageContainerSASToken -Container "consolidated-report" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/consolidated-report$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/consolidated-report" $destinationUri --recursive
  
    $destinationSasKey = New-AzStorageContainerSASToken -Container "sthealthcare2" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/sthealthcare2$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/sthealthcare2" $destinationUri --recursive
