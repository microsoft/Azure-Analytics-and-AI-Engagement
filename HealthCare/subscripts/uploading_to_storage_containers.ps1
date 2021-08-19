function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))

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
$containers=Get-ChildItem "./artifacts/storageassets" | Select BaseName

foreach($container in $containers)
{
    $destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
    $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
    & $azCopyCommand copy "./artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive
}

RefreshTokens
 
$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/webappassets/$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/webappassets" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/customcsv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "predictiveanalytics" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/predictiveanalytics$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/predictiveanalytics" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "marketingdata" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/marketingdata$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/marketingdata" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "saphana-finance-data" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/saphana-finance-data$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/saphana-finance-data" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "healthcare-assets" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/healthcare-assets$($destinationSasKey)"
& $azCopyCommand copy "https://pocaccelerator.blob.core.windows.net/healthcare-vm-assets" $destinationUri --recursive
