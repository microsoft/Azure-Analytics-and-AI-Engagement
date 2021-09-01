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

function Refresh-Token {
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TokenType
    )

    if(Test-Path C:\LabFiles\AzureCreds.ps1){
        if ($TokenType -eq "Synapse") {
            $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                -Method POST -Body $global:ropcBodySynapse -ContentType "application/x-www-form-urlencoded"
            $global:synapseToken = $result.access_token
        } elseif ($TokenType -eq "SynapseSQL") {
            $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                -Method POST -Body $global:ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
            $global:synapseSQLToken = $result.access_token
        } elseif ($TokenType -eq "Management") {
            $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                -Method POST -Body $global:ropcBodyManagement -ContentType "application/x-www-form-urlencoded"
            $global:managementToken = $result.access_token
        } elseif ($TokenType -eq "PowerBI") {
            $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                -Method POST -Body $global:ropcBodyPowerBI -ContentType "application/x-www-form-urlencoded"
            $global:powerbitoken = $result.access_token
        }
        else {
            throw "The token type $($TokenType) is not supported."
        }
    } else {
        switch($TokenType) {
            "Synapse" {
                $tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
                $global:synapseToken = $tokenValue; 
                break;
            }
            "SynapseSQL" {
                $tokenValue = ((az account get-access-token --resource https://sql.azuresynapse.net) | ConvertFrom-Json).accessToken
                $global:synapseSQLToken = $tokenValue; 
                break;
            }
            "Management" {
                $tokenValue = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
                $global:managementToken = $tokenValue; 
                break;
            }
            "PowerBI" {
                $tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
                $global:powerbitoken = $tokenValue; 
                break;
            }
            default {throw "The token type $($TokenType) is not supported.";}
        }
    }
}

function Ensure-ValidTokens {
	
    for ($i = 0; $i -lt $tokenTimes.Count; $i++) {
        Ensure-ValidToken $($tokenTimes.Keys)[$i]
    }
}


function Ensure-ValidToken {
    param(
        [parameter(Mandatory=$true)]
        [String]
        $TokenName
    )

    $refTime = Get-Date

    if (($refTime - $tokenTimes[$TokenName]).TotalMinutes -gt 30) {
        Write-Host "Refreshing $($TokenName) token."
        Refresh-Token $TokenName
        $tokenTimes[$TokenName] = $refTime
    }
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
        if($subs.GetType().IsArray -and $subs.length -gt 1){
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

$resourceGroups = az group list --query '[].name' -o tsv 

if($resourceGroups.GetType().IsArray -and $resourceGroups.length -gt 1){
    $rgOptions = [System.Collections.ArrayList]::new()
    for($rgIdx=0; $rgIdx -lt $resourceGroups.length; $rgIdx++){
        $optionName = $resourceGroups[$rgIdx]
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($optionName)", "Selects the $($resourceGroups[$rgIdx]) resource group."   
        $rgOptions.Add($opt)
    }
    $selectedRgIdx = $host.ui.PromptForChoice('Enter the desired Resource Group for this lab','Copy and paste the name of the resource group to make your choice.', $rgOptions.ToArray(),0)
    $resourceGroupName = $resourceGroups[$selectedRgIdx]
    Write-Host "Selecting the $resourceGroupName resource group"
}
else{
$resourceGroupName=$resourceGroups
Write-Host "Selecting the $resourceGroupName resource group"
}

$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$dataLakeAccountName = "asaexpdatalake$($uniqueId)"
$publicDataUrl = "https://retailpocstorage.blob.core.windows.net/"
$dataLakeStorageBlobUrl = "https://"+ $dataLakeAccountName + ".blob.core.windows.net/"

Ensure-ValidTokens

$dataLakeStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $dataLakeStorageAccountKey

$storageContainers = @{
        twitterData = "twitterdata"
        financeDb = "financedb"
        salesData = "salesdata"
        customerInsights = "customer-insights"
        sapHana = "saphana"
        campaignData = "campaigndata"
        iotContainer = "iotcontainer"
        recommendations = "recommendations"
        customCsv = "customcsv"
        machineLearning = "machine-learning"
}

foreach ($storageContainer in $storageContainers.Keys) {        
        Write-Host "Creating container: $($storageContainers[$storageContainer])"
        if(Get-AzStorageContainer -Name $storageContainers[$storageContainer] -Context $dataLakeContext -ErrorAction SilentlyContinue)  {  
                Write-Host "$($storageContainers[$storageContainer]) container already exists."  
        }else{  
                Write-Host "$($storageContainers[$storageContainer]) container created."   
                New-AzStorageContainer -Name $storageContainers[$storageContainer] -Permission Container -Context $dataLakeContext  
        }
}          

$StartTime = Get-Date
$EndTime = $startTime.AddDays(365)  
$destinationSasKey = New-AzStorageContainerSASToken -Container "twitterdata" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime

$azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

if (!$azCopyLink)
{
    $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
}

Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
$azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName
$Env:Path += ";"+ $azCopyCommand

$AnonContext = New-AzStorageContext -StorageAccountName "retailpocstorage" -Anonymous
$singleFiles = Get-AzStorageBlob -Container "cdp" -Blob twitter* -Context $AnonContext | Where-Object Length -GT 0 | select-object @{Name = "SourcePath"; Expression = {"cdp/"+$_.Name}} , @{Name = "TargetPath"; Expression = {$_.Name}}

foreach ($singleFile in $singleFiles) {
        Write-Host $singleFile
        $source = $publicDataUrl + $singleFile.SourcePath
        $destination = $dataLakeStorageBlobUrl + 'twitterdata/' +$singleFile.TargetPath + $destinationSasKey
        Write-Host "Copying file $($source) to $($destination)"
        azcopy copy $source $destination
}


$destinationSasKey = New-AzStorageContainerSASToken -Container "machine-learning" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/machine-learning$($destinationSasKey)"
azcopy copy "https://retailpocstorage.blob.core.windows.net/machine-learning" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
azcopy copy "https://retailpocstorage.blob.core.windows.net/customcsv" $destinationUri --recursive
