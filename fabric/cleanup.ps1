function RefreshTokens()
{
    $global:fabric = ((az account get-access-token --resource https://api.fabric.microsoft.com) | ConvertFrom-Json).accessToken
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

function ReplaceTokensInFile($ht, $filePath) {
    $template = Get-Content -Raw -Path $filePath
    
    foreach ($paramName in $ht.Keys) {
        $template = $template.Replace($paramName, $ht[$paramName])
    }

    return $template;
}

az login

$starttime=get-date

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
if($subs.GetType().IsArray -and $subs.length -gt 1)
{
$subOptions = [System.Collections.ArrayList]::new()
    for($subIdx=0; $subIdx -lt $subs.length; $subIdx++)
    {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the Azure Subscription used for lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
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
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the Azure Subscription used for lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
    }
}

$rgName = Read-Host "Enter your resource group name"
$wsIdContosoSales = (az group show --name $rgName --query 'tags.wsIdContosoSale' --output tsv)
$wsIdContosoFinance = (az group show --name $rgName --query 'tags.wsIdContosoFinance' --output tsv)

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales";
$contosoSalesWsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$contosoSalesWsName = $contosoSalesWsName.name
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoFinance"
$contosoFinanceWsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$contosoFinanceWsName = $contosoFinanceWsName.name

RefreshTokens
$pat_token = $fabric
    $requestHeaders = @{
        Authorization  = "Bearer" + " " + $pat_token
        "Content-Type" = "application/json"
         "Scope" = "Workspace.ReadWrite.All"
    }

Write-Host "Deleting '$contosoSalesWsName' Workspace"
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales"
    $salesws = Invoke-RestMethod $endPoint `
        -Method DELETE `
        -Headers $requestHeaders 
Write-Host "'$contosoSalesWsName' Workspace DELETED"

Write-Host "Deleting '$contosoFinanceWsName' Workspace"
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoFinance"
    $financews = Invoke-RestMethod $endPoint `
        -Method DELETE `
        -Headers $requestHeaders 
Write-Host "'$contosoFinanceWsName' Workspace DELETED"

Write-Host "Deleting '$rgName' resource group"
az group delete --name $rgName -y 
Write-Host "'$rgName' resource group DELETED"

Write-Host "----CLEAN-UP OPERATION DONE----"



