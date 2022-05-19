
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
$location = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"       
$concatString = "$init$random"
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

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
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/customcsv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "retail20" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/retail20$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/retail20" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "adfstagedcopytempdata" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/adfstagedcopytempdata$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/adfstagedcopytempdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "adfstagedpolybasetempdata" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/adfstagedpolybasetempdata$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/adfstagedpolybasetempdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "magentocontosomergerdata" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/magentocontosomergerdata$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/magentocontosomergerdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "market-basket" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/market-basket$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/market-basket" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "rawdata-customerinsight" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/rawdata-customerinsight$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/rawdata-customerinsight" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "retail-customerreviewsdata" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/retail-customerreviewsdata$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/retail-customerreviewsdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "retail-notebook-data" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/retail-notebook-data$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/retail-notebook-data" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "spatialanalysis" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/spatialanalysis$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/spatialanalysis" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "spatialanalysisinput" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/spatialanalysisinput$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/spatialanalysisinput" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "spatialanalysisvideo" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/spatialanalysisvideo$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/spatialanalysisvideo" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "storevideo" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/storevideo$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/storevideo" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "thermostat" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/thermostat$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/thermostat" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "videoanalyzer" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/videoanalyzer$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/videoanalyzer" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "adx-historical" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/adx-historical$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/adx-historical" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "semanticsearch" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/semanticsearch$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/semanticsearch" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "video" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/video$($destinationSasKey)"
& $azCopyCommand copy "https://retail2poc.blob.core.windows.net/video" $destinationUri --recursive

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
