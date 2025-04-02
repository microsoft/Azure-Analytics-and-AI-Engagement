## Task 5.1

```
 /* Create View that will be used in the SQL GraphQL Endpoint */
CREATE VIEW dbo.vProductsbySuppliers AS
SELECT COUNT(a.ProductID) AS ProductCount
, a.SupplierLocationID
, b.CompanyName
FROM dbo.Warehouse AS a
INNER JOIN dbo.Suppliers AS b ON a.SupplierID = b.SupplierID
GROUP BY a.SupplierLocationID, b.CompanyName;
GO
```

```
query { vProductsbySuppliers(filter: { SupplierLocationID: { eq: 7 } }) { items { CompanyName SupplierLocationID ProductCount } } }

```

## PowerShell script

```
function RefreshTokens() {
    #Copy external blob content
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

$endpoint =  Read-Host "Enter your GraphQL ednpoint"

az login

winget install --exact --id Microsoft.AzureCLI --version 2.67.0 --force 

& $azCopyCommand copy "https://stfabcon.blob.core.windows.net/dotnet/Program.cs.txt" "./" --recursive
& $azCopyCommand copy "https://stfabcon.blob.core.windows.net/dotnet/contoso.png" "./" --recursive

(Get-Content -path Program.cs.txt -Raw) | Foreach-Object { $_ `
            -replace '#ReplaceWithYourGraphQLEndpointAddress#', $endpoint`
    } | Set-Content -Path Program.cs.txt


dotnet new webapp -n GraphQLWebApp
cd GraphQLWebApp
dotnet add package Azure.Identity
dotnet add package GraphQL
dotnet add package GraphQL.Client
dotnet add package GraphQL.Client.Serializer.Newtonsoft

Get-Content -Path "../Program.cs.txt" -Raw | Set-Content -Path "./Program.cs"
cp "./contoso.png" ".\wwwroot\contoso.png"
dotnet run

```