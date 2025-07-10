function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:fabric = ((az account get-access-token --resource https://api.fabric.microsoft.com) | ConvertFrom-Json).accessToken
}

function Check-HttpRedirect($uri) {
    $httpReq = [system.net.HttpWebRequest]::Create($uri)
    $httpReq.Accept = "text/html, application/xhtml+xml, */*"
    $httpReq.method = "GET"   
    $httpReq.AllowAutoRedirect = $false;

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

$subscriptionId = (az account show --query id --output tsv)
    
Connect-AzAccount -UseDeviceAuthentication -Subscription $subscriptionId 

#az copy

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

Start-Transcript -Path ./log.txt 

[string]$suffix = -join ((48..57) + (97..122) | Get-Random -Count 7 | % { [char]$_ })
$rgName = "rg-fabcon-$suffix"
$FabconVM = "FabconVM$suffix"
$Region = read-host "Enter the region for deployment"
$openAI_location = read-host "Enter the region for OpenAI GPT-4 and text-embedding-ada-002"
$tenantId = (Get-AzContext).Tenant.Id
$subscriptionId = (Get-AzContext).Subscription.Id
$adminUsername = "azureuser"
$adminPassword=""
    while ($complexPassword -ne 1)
    {
        $adminPassword = Read-Host "Enter a password for the virtual machine.
        `The password must meet complexity requirements:
        ` - Minimum 8 characters. 
        ` - At least one upper case English letter [A-Z]
        ` - At least one lower case English letter [a-z]
        ` - At least one digit [0-9]
        ` - At least one special character (!,@,#,%,^,&,$)
        ` "

        if(($adminPassword -cmatch '[a-z]') -and ($adminPassword -cmatch '[A-Z]') -and ($adminPassword -match '\d') -and ($adminPassword.length -ge 8) -and ($adminPassword -match '!|@|#|%|^|&|$'))
        {
            $complexPassword = 1
        Write-Output "Password $adminPassword accepted. Make sure you remember this!"
        }
        else
        {
            Write-Output "$adminPassword does not meet the complexity requirements."
        }
    }
$adminPassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$dataLakeAccountName = "stfabcon$suffix"
$mssql_server_name = "mssql$suffix"
$mssql_database_name = "SalesDb"
$mssql_administrator_login = "labsqladmin"
$sql_administrator_login_password=""
    while ($complexPassword -ne 1)
    {
        $sql_administrator_login_password = Read-Host "Enter a password to use for the $mssql_administrator_login login.
        `The password must meet complexity requirements:
        ` - Minimum 8 characters. 
        ` - At least one upper case English letter [A-Z]
        ` - At least one lower case English letter [a-z]
        ` - At least one digit [0-9]
        ` - At least one special character (!,@,#,%,^,&,$)
        ` "

        if(($sql_administrator_login_password -cmatch '[a-z]') -and ($sql_administrator_login_password -cmatch '[A-Z]') -and ($sql_administrator_login_password -match '\d') -and ($sql_administrator_login_password.length -ge 8) -and ($sql_administrator_login_password -match '!|@|#|%|^|&|$'))
        {
            $complexPassword = 1
        Write-Output "Password $sql_administrator_login_password accepted. Make sure you remember this!"
        }
        else
        {
            Write-Output "$sql_administrator_login_password does not meet the complexity requirements."
        }
    }
$azure_open_ai = "OpenAI$suffix"
$networkInterfaceName = "NIC$suffix"
$publicIpAddressName = "pip$suffix"
$virtualNetworkName = "vnet$suffix"
$networkSecurityGroupname = "nsg-$suffix"


Write-Host "Deploying Resources on Microsoft Azure Started ..."
Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
Write-Host "Resource group $rgName creation COMPLETE"

Write-Host "Creating resources in $rgName..."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-TemplateFile "labMainTemplate.json" `
-Mode Complete `
-location $Region `
-adminUsername $adminUsername `
-adminPassword $adminPassword `
-storage_account_name $dataLakeAccountName `
-mssql_server_name $mssql_server_name `
-mssql_database_name $mssql_database_name `
-mssql_administrator_login $mssql_administrator_login `
-sql_administrator_login_password $sql_administrator_login_password `
-azure_open_ai $azure_open_ai `
-openAI_location $openAI_location `
-networkInterfaceName $networkInterfaceName `
-virtualMachineName $FabconVM `
-publicIpAddressName $publicIpAddressName `
-virtualNetworkName $virtualNetworkName `
-networkSecurityGroupname $networkSecurityGroupname `
-Force

$templatedeployment = Get-AzResourceGroupDeployment -Name "labMainTemplate" -ResourceGroupName $rgName
$deploymentStatus = $templatedeployment.ProvisioningState
Write-Host "Deployment in $rgName : $deploymentStatus"


## storage az copy
Write-Host "Copying files to Storage Container"

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$destinationSasKey = New-AzStorageContainerSASToken -Container "data" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/data$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://stignite24.blob.core.windows.net/data/sales_data.csv" $destinationUri --recursive

Write-Host "Copying files to Storage Container Complete"

##Azure OpenAI
Write-Host "---------Deploying OpenAI models--------"

$openAIModel1 = az cognitiveservices account deployment create -g $rgName -n $azure_open_ai --deployment-name "gpt-4" --model-name "gpt-4" --model-version "0613" --model-format OpenAI --sku-capacity 50 --sku-name "Standard" 
$openAIModel3 = az cognitiveservices account deployment create -g $rgName -n $azure_open_ai --deployment-name "text-embedding-ada-002" --model-name "text-embedding-ada-002" --model-version "2" --model-format OpenAI --sku-capacity 50 --sku-name "Standard"

## mssql
Write-Host "---------Loading files to MS SQL DB--------"
Add-Content log.txt "-----Loading files to MS SQL DB-----"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/salesSqlDbScript.sql"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_database_name -Username $mssql_administrator_login -Password $sql_administrator_login_password
Write-Host "---------Loading files to MS SQL DB COMPLETE--------"
Add-Content log.txt "-----Loading files to MS SQL DB COMPLETE-----"
