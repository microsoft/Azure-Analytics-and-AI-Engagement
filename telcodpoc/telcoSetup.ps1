$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "I accept the license agreement."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "I do not accept and wish to stop execution."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$title = "Agreement"
$message = "By typing [Y], I hereby confirm that I have read the license ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/license.md ) and disclaimers ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/README.md ) and hereby accept the terms of the license and agree that the terms and conditions set forth therein govern my use of the code made available hereunder. (Type [Y] for Yes or [N] for No and press enter)"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)

if ($result -eq 1) {
    Write-Host "Thank you. Please ensure you delete the resources created with template to avoid further cost implications."
} else {
    function RefreshTokens() {
        # Copy external blob content
        $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
        $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
        $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
        $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
        $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
        $global:fabric = ((az account get-access-token --resource https://api.fabric.microsoft.com) | ConvertFrom-Json).accessToken
    }

    function Check-HttpRedirect($uri) {
        $httpReq = [system.net.HttpWebRequest]::Create($uri)
        $httpReq.Accept = "text/html, application/xhtml+xml, */*"
        $httpReq.method = "GET"
        $httpReq.AllowAutoRedirect = $false;

        # use them all...
        # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls;

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
            } catch {
            }

            return $null;
        } catch {
            $res2 = $_.Exception.InnerException.Response;
            $global:httpCode = $_.Exception.InnerException.HResult;
            $global:httperror = $_.exception.message;

            try {
                $global:location = $res2.Headers["Location"].ToString();
                return $global:location;
            } catch {
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


    
}


Write-Host "------------Prerequisites------------"
Write-Host "-An Azure Account with the ability to create Fabric Workspace."
Write-Host "-A Power BI with Fabric License to host Power BI reports."
Write-Host "-Make sure the user deploying the script has atleast a 'Contributor' level of access on the 'Subscription' on which it is being deployed."
Write-Host "-Make sure your Power BI administrator can provide service principal access on your Power BI tenant."
Write-Host "-Make sure to register the following resource providers with your Azure Subscription:"
Write-Host "-Microsoft.Fabric"
Write-Host "-Microsoft.SQLSever"
Write-Host "-Microsoft.StorageAccount"

Write-Host "-Make sure you use the same valid credentials to log into Azure and Power BI."

Write-Host "    -----------------   "
Write-Host "    -----------------   "
Write-Host "If you fulfill the above requirements please proceed otherwise press 'Ctrl+C' to end script execution."
Write-Host "    -----------------   "
Write-Host "    -----------------   "

Start-Sleep -s 30

az login

$subscriptionId = (az account show --query 'id' -o tsv)
 
#for powershell...
Connect-AzAccount -DeviceCode -SubscriptionId $subscriptionId

$starttime = get-date
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


$tenantId = (Get-AzContext).Tenant.Id
& $azCopyCommand login --tenant-id $tenantId

Start-Transcript -Path ./log.txt
$subscriptionId = (Get-AzContext).Subscription.Id
$signedinusername = az ad signed-in-user show | ConvertFrom-Json
$signedinusername = $signedinusername.userPrincipalName

# Check if the user has Owner role on the subscription
Add-Content log.txt "Check if the user has Owner role on the subscription..."
Write-Host "Check if the user has Owner role on the subscription..."

$roleAssignments = az role assignment list --assignee $signedinusername --subscription $subscriptionId | ConvertFrom-Json
$hasOwnerRole = $roleAssignments | Where-Object { $_.roleDefinitionName -eq "Owner" }

if ($null -ne $hasOwnerRole) {
    Write-Host "User has Owner permission on the subscription. Proceeding..." -ForegroundColor Green
} else {
    Write-Host "User does not have Owner permission on the subscription. Deployment will fail. Would you still like to continue? (Yes/No)" -ForegroundColor Red

    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "Yes") {
        Write-Host "Proceeding with deployment..."
    } else {
        Write-Host "Aborting deployment."
        exit
    }
}



[string]$suffix =  -join ((48..57) + (97..122) | Get-Random -Count 7 | % {[char]$_})
$rgName = "rg-telco-$suffix"
$Region = read-host "Enter the region for deployment"
$wsIdContosoSales =  Read-Host "Enter your 'Telco-demo' PowerBI workspace Id "
$subscriptionId = (Get-AzContext).Subscription.Id
$dataLakeAccountName = "sttelco$suffix"
$tenantId = (Get-AzContext).Tenant.Id
$sites_telcowebapp = "app-telcowebapp-$suffix"
$serverfarm_telcowebapp = "asp-telcowebapp-$suffix"
$accounts_cog_telco_name = "accounts-cog-telco-$suffix"
$mssql_server_name = "mssql$suffix"
$mssql_database_name = "CustomerDB"
$mssql_administrator_login = "labsqladmin"
$complexPassword = 0
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
            Write-Output "$sql_administrator_login_password does not meet the compexity requirements."
        }
    }

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales";
$contosoSalesWsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$contosoSalesWsName = $contosoSalesWsName.name

$lakehouse =  "Lakehouse_$suffix"
$lakehouseBronze =  "Lakehouse_Bronze_$suffix"
$lakehouseSilver =  "Lakehouse_Silver_$suffix"
$lakehouseGold =  "Lakehouse_Gold_$suffix"


Add-Content log.txt "------FABRIC assets deployment STARTS HERE------"
Write-Host "------------FABRIC assets deployment STARTS HERE------------"

Add-Content log.txt "------Creating Lakehouses in '$contosoSalesWsName' workspace------"
Write-Host "------Creating Lakehouses in '$contosoSalesWsName' workspace------"
$lakehouseNames = @($lakehouse, $lakehouseBronze, $lakehouseSilver, $lakehouseGold)
# Set the token and request headers
$pat_token = $fabric
    $requestHeaders = @{
        Authorization  = "Bearer" + " " + $pat_token
        "Content-Type" = "application/json"
    }

    $headers = @{

        Authorization = "Bearer $global:fabric"

    }


# Iterate through each Lakehouse name and create it
foreach ($lakehouseName in $lakehouseNames) {
# Create the body for the Lakehouse creation
$requestBody = @{
    
    type            = "Lakehouse"

    displayName     = "$lakehouseName"

    description     = "Lakehouse created with schemas enabled"

    creationPayload = @{

        enableSchemas = $true

    }

} | ConvertTo-Json -Depth 3

$createUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/items"
     
# Make the POST request to create the Lakehouse

# Invoke the REST method to create a new Lakehouse
try {
    $lakehouseName = Invoke-RestMethod -Method Post -Uri $createUri -Headers $headers -Body $requestBody -ContentType "application/json"

        Write-Host "Lakehouse '$lakehouseName' created successfully."
    } catch {
        Write-Host "Error creating Lakehouse '$lakehouseName': $_"
        if ($_.Exception.Response -ne $null) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $reader.ReadToEnd()
        }
    }
}
Add-Content log.txt "------Creation of Lakehouses in '$contosoSalesWsName' workspace COMPLETED------"
Write-Host "-----Creation of Lakehouses in '$contosoSalesWsName' workspace COMPLETED------"

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/lakehouses"
    $Lakehouse = Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders

$LakehouseBronzeid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseBronze" }).id

$LakehouseSilverid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseSilver" }).id

$LakehouseGoldid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseGold" }).id

Write-Output "Bronze Lakehouse ID: $LakehouseBronzeid"

Write-Output "Silver Lakehouse ID: $LakehouseSilverid"

Write-Output "Silver Lakehouse ID: $LakehouseGoldid"


Add-Content log.txt "------Uploading assets to Lakehouses------"
Write-Host "------------Uploading assets to Lakehouses------------"


Add-Content log.txt "------Creating Eventhouse------"
Write-Host "------Creating Eventhouse------"
        $KQLDB = "Eventhouse-Real-Time-Data"
        $body = @{
                displayName = $KQLDB 
            } | ConvertTo-Json
            
    try{
        $endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/eventhouses"
        $KQLDBAPI = Invoke-RestMethod -Method Post -Uri $endPoint -Headers $requestHeaders -Body $body
                Write-Host "Eventhouse '$KQLDB' created successfully."
        }catch{
            Write-Host "Error creating Eventhouse '$KQLDB'"
        }
Start-Sleep -s 10 
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/kqlDatabases"
    $KQLdetails = Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders


$KQLDBID = $KQLdetails.value.properties.queryServiceUri

Write-Host "$KQLDBID"

Write-Host "-----------Creation of Eventhouse COMPLETED------------"

$tenantId = (Get-AzContext).Tenant.Id
azcopy login --tenant-id $tenantId

azcopy copy "https://sttelcodpoc.blob.core.windows.net/telco-silver-tables/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseSilver.Lakehouse/Tables/dbo/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://sttelcodpoc.blob.core.windows.net/telco-finance-tables/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseBronze.Lakehouse/Tables/dbo/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://sttelcodpoc.blob.core.windows.net/dataflowgen2/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseBronze.Lakehouse/Files/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://sttelcodpoc.blob.core.windows.net/data/operation_datastore_S3/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseBronze.Lakehouse/Files/operation_datastore_S3/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://sttelcodpoc.blob.core.windows.net/data/finance_datastore_gcp/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseBronze.Lakehouse/Files/finance_datastore_gcp/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;

Add-Content log.txt "------Uploading assets to Lakehouses COMPLETED------"
Write-Host "------------Uploading assets to Lakehouses COMPLETED------------"

## notebooks
Add-Content log.txt "-----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses-----"
Write-Host "----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses----"

(Get-Content -path "artifacts/fabricnotebooks/00 Create_Table_Structure_Bronze.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#Lakehouse_Bronze_ID#', $LakehouseBronzeid `
    -replace '#wsid#', $wsIdContosoSales `
} | Set-Content -Path "artifacts/fabricnotebooks/00 Create_Table_Structure_Bronze.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/01 Load_Data_Bronze.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#Lakehouse_Silver_ID#', $LakehouseSilverid `
    -replace '#Lakehouse_Bronze_ID#', $LakehouseBronzeid `
    -replace '#wsid#', $wsIdContosoSales `
} | Set-Content -Path "artifacts/fabricnotebooks/01 Load_Data_Bronze.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/02 Load_Data_Silver_Layer.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#Lakehouse_Silver_ID#', $LakehouseSilverid `
    -replace '#Lakehouse_Bronze_ID#', $LakehouseBronzeid `
    -replace '#wsid#', $wsIdContosoSales `
} | Set-Content -Path "artifacts/fabricnotebooks/02 Load_Data_Silver_Layer.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/03 Load_Data_Gold_Layer.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#Lakehouse_SilverID#', $LakehouseSilver `
    -replace '#Lakehouse_Silver#', $LakehouseSilver `
    -replace '#Lakehouse_Gold#', $lakehouseGold `
    -replace '#Lakehouse_Bronze#', $lakehouseBronze `

} | Set-Content -Path "artifacts/fabricnotebooks/03 Load_Data_Gold_Layer.ipynb"


Add-Content log.txt "-----Fabric Notebook Configuration COMPLETED-----"
Write-Host "----Fabric Notebook Configuration COMPLETED----"



Add-Content log.txt "-----Uploading Notebooks-----"
Write-Host "-----Uploading Notebooks-----"
RefreshTokens
$requestHeaders = @{
        Authorization  = "Bearer " + $fabric
        "Content-Type" = "application/json"
        "Scope"        = "Notebook.ReadWrite.All"
}

$files = Get-ChildItem -Path "./artifacts/fabricnotebooks" -File -Recurse
Set-Location ./artifacts/fabricnotebooks

foreach ($name in $files.name) {
if ($name -eq "00 Create_Table_Structure_Bronze.ipynb" -or
        $name -eq "01 Load_Data_Bronze.ipynb" -or
        $name -eq "02 Load_Data_Silver_Layer.ipynb" -or
        $name -eq "03 Load_Data_Gold_Layer.ipynb") 
{
        
    $fileContent = Get-Content -Raw $name
    $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
    $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

    $body = '{
                "displayName": "' + $name + '",
                "type": "Notebook",
                "definition": {
                    "format": "ipynb",
                    "parts": [
                        {
                            "path": "artifact.content.ipynb",
                            "payload": "' + $fileContentEncoded + '",
                            "payloadType": "InlineBase64"
                        }
                    ]
                }
            }'

    $endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/items/"
    $Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

    Write-Host "Notebook uploaded: $name"
} 
  
}
Add-Content log.txt "-----Uploading Notebooks COMPLETED-----"
Write-Host "-----Uploading Notebooks COMPLETED-----"

cd..
cd..



Write-Host "Deploying Resources on Microsoft Azure Started ..."
Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
Write-Host "Resource group $rgName creation COMPLETE"
    
Write-Host "Creating resources in $rgName..."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-TemplateFile "mainTemplate.json" `
-Mode Complete `
-location $Region `
-storage_account_name $dataLakeAccountName `
-mssql_server_name $mssql_server_name `
-mssql_database_name $mssql_database_name `
-mssql_administrator_login $mssql_administrator_login `
-sql_administrator_login_password $sql_administrator_login_password `
-accounts_cog_telco_name $accounts_cog_telco_name `
-sites_telcowebapp $sites_telcowebapp `
-serverfarm_telcowebapp $serverfarm_telcowebapp `
-Force


    
$templatedeployment = Get-AzResourceGroupDeployment -Name "mainTemplate" -ResourceGroupName $rgName
$deploymentStatus = $templatedeployment.ProvisioningState
Write-Host "Deployment in $rgName : $deploymentStatus"

if ($deploymentStatus -eq "Succeeded") {
    Write-Host "Template deployment succeeded. "
    Write-Host "Proceeding with further resource creation..."    
    } 
    else 
    {
    Write-Host "Template deployment failed or is not complete. Aborting further actions,please redeploy the template. "
    exit
}


Write-Host "-----Deploying Resources on Microsoft Azure COMPLETE-----"

## storage az copy
Write-Host "Copying files to Storage Container"
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$destinationSasKey = New-AzStorageContainerSASToken -Container "data" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/data$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://sttelcodpoc.blob.core.windows.net/telco-dpoc/" $destinationUri --recursive
    

$destinationSasKey = New-AzStorageContainerSASToken -Container "kqldbdata" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/kqldbdata$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://sttelcodpoc.blob.core.windows.net/kqldbdata/" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://sttelcodpoc.blob.core.windows.net/webappassets/" $destinationUri --recursive

RefreshTokens
Add-Content log.txt "------Uploading PowerBI Reports------"
Write-Host "------------Uploading PowerBI Reports------------"
$spname = "TELCO $suffix"
 
$app = az ad app create --display-name $spname | ConvertFrom-Json
$appId = $app.appId
 
$mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$clientsecpwdapp = $mainAppCredential.password
 
az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "id" -o tsv
start-sleep -s 15
 
#https://docs.microsoft.com/en-us/power-bi/developer/embedded/embed-service-principal
#Allow service principals to user PowerBI APIS must be enabled - https://app.powerbi.com/admin-portal/tenantSettings?language=en-U
#add PowerBI App to workspace as an admin to group
RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups";
$result = Invoke-WebRequest -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization = "Bearer $powerbitoken" } -ea SilentlyContinue;
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
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales/users";
$post = "{
    `"identifier`":`"$($sp)`",
    `"groupUserAccessRight`":`"Admin`",
    `"principalType`":`"App`"
    }";
 
$result = Invoke-RestMethod -Uri $url -Method POST -body $post -ContentType "application/json" -Headers @{ Authorization = "Bearer $powerbitoken" } -ea SilentlyContinue;
 
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
 
$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization = "Bearer $graphtoken" } -ea SilentlyContinue;
 
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
 
$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization = "Bearer $graphtoken" } -ea SilentlyContinue;
 
$credential = New-Object PSCredential($appId, (ConvertTo-SecureString $clientsecpwdapp -AsPlainText -Force))
 
    # Connect to Power BI using the service principal
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenantId
 
$PowerBIFiles = Get-ChildItem "./artifacts/reports" -Recurse -Filter *.pbix
$reportList = @()
 
foreach ($Pbix in $PowerBIFiles) {
Write-Output "Uploading report: $($Pbix.BaseName +'.pbix')"
 
$report = New-PowerBIReport -Path $Pbix.FullName -WorkspaceId $wsIdContosoSales -ConflictAction CreateOrOverwrite
 
if ($report -ne $null) {
        Write-Output "Report uploaded successfully: $($report.Name +'.pbix')"
 
        $temp = [PSCustomObject]@{
            FileName        = $Pbix.FullName
            Name            = $Pbix.BaseName  # Using BaseName to get the file name without the extension
            PowerBIDataSetId = $null
            ReportId        = $report.Id
            SourceServer    = $null
            SourceDatabase  = $null
        }
 
        # Get dataset
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales/datasets"
$dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" }
 
foreach ($res in $dataSets.value) {
    if ($res.name -eq $temp.Name) {
                $temp.PowerBIDataSetId = $res.id
                break  # Exit the loop once a match is found
            }
        }
 
        $reportList += $temp
    } else {
        Write-Output "Failed to upload report: $($report.Name +'.pbix')"
        }
}
Add-Content log.txt "------Uploading PowerBI Reports COMPLETED------"
Write-Host "------------Uploading PowerBI Reports COMPLETED------------"
 
Start-Sleep -s 10

## Get Lakehouse details
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/lakehouses"
    $Lakehouse = Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders


# Get the ID of the  lakehouse 
# $LakehouseId = $Lakehouse.value[0].id  # or use a filter:
$LakehouseSilverId = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseSilver" }).id
$LakehouseGoldId = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseBronze" }).id
$LakehouseBronzeId = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseGold" }).id

Write-Output "Lakehouse ID: $LakehouseSilverId"
Write-Output "Lakehouse ID: $LakehouseGoldId"
Write-Output "Lakehouse ID: $LakehouseBronzeId"

$url = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/lakehouses/$lakehouseSilverId";
$LakehouseSilverdetails = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $fabric" };

$SilverServerName = $LakehouseSilverdetails.properties.sqlEndpointProperties.connectionString

$url = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/lakehouses/$lakehouseGoldId";
$LakehouseGolddetails = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $fabric" };

$GoldServerName = $LakehouseGolddetails.properties.sqlEndpointProperties.connectionString

$url = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/lakehouses/$lakehouseBronzeId";
$LakehouseBronzedetails = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $fabric" };

$BronzeServerName = $LakehouseBronzedetails.properties.sqlEndpointProperties.connectionString

    # TakingOver Datasets.
    foreach ($report in $reportList) {
        $datasetId = $report.PowerBIDataSetId
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales/datasets/$datasetId/Default.TakeOver"
    
        try {
            $response = Invoke-RestMethod -Uri $url -Method POST -Headers @{ Authorization = "Bearer $powerbitoken" }
            Write-Host "TakeOver action completed successfully for dataset ID: $datasetId"
        }
        catch {
            Write-Host "Error occurred while performing TakeOver action for dataset ID: $datasetId - $_"
        }
        }


    foreach ($report in $reportList) {
    if ($report.Name -eq "Finance Report")
    {

    $body = "{
        `"updateDetails`": [
            {
                `"name`": `"Server_Name`",
                `"newValue`": `"$($BronzeServerName)`"
            },
            {
                `"name`": `"DB_Name`",
                `"newValue`": `"$($lakehouseBronze)`"
            }
        ]
    }"

    Write-Host "PBI connections updating for report : $($report.name)"	

    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdContosoSales)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"

    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
        Authorization = "Bearer $powerbitoken"
    } -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 5
    }

    if ($report.Name -eq "Call Center Report Before OpenAI Fluent" -or $report.Name -eq "Call Center Report After OpenAI Fluent" -or $report.Name -eq "Sales Report") {
    
        $body = "{
        `"updateDetails`": [
            {
                `"name`": `"Server_Name`",
                `"newValue`": `"$($GoldServerName)`"
            },
            {
                `"name`": `"DB_Name`",
                `"newValue`": `"$($lakehouseGold)`"
            }
        ]
    }"


    Write-Host "PBI connections updating for report : $($report.name)"	

    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdContosoSales)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"

    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
        Authorization = "Bearer $powerbitoken"
    } -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 5
    }

    if ($report.Name -eq "World Map" -or $report.Name -eq "Operations Report" -or $report.Name -eq "Network Report") {
       
        $body = "{
            `"updateDetails`": [
            {
                `"name`": `"Server_Name`",
                `"newValue`": `"$($SilverServerName)`"
            },
            {
                `"name`": `"DB_Name`",
                `"newValue`": `"$($lakehouseSilver)`"
            }
            ]
        }"
    
        Write-Host "PBI connections updating for report : $($report.name)"	
    
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdContosoSales)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
    
        $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
            Authorization = "Bearer $powerbitoken"
        } -ErrorAction SilentlyContinue
    
        Start-Sleep -Seconds 5
        }

    if ($report.Name -eq "Telco CEO Before Dashboard") {
    
    $body = "{
        `"updateDetails`": [
        {
            `"name`": `"Server_Name`",
            `"newValue`": `"$($SilverServerName)`"
        },
        {
            `"name`": `"DB_Name`",
            `"newValue`": `"$($lakehouseSilver)`"
        },

        {
            `"name`": `"KQLCluster`",
            `"newValue`": `"$($KQLDBID)`"
        },
        {
            `"name`": `"KQLEventHouse`",
            `"newValue`": `"$($KQLDB)`"
        }

        ]
    }"

    Write-Host "PBI connections updating for report : $($report.name)"	

    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdContosoSales)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"

    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
        Authorization = "Bearer $powerbitoken"
    } -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 5
    }
}

Write-Host "------------Updating PowerBI Reports COMPLETED------------"


Add-Content log.txt "------unzipping poc web app------"
    Write-Host  "--------------Unzipping web app---------------"

expand-archive -path "./artifacts/binaries/telcodpocbuild.zip" -destinationpath "./telcodpocbuild" -force
    #Web app
    Add-Content log.txt "------deploy poc web app------"
    Write-Host  "-----------------Deploy web app---------------"
    RefreshTokens
    $BlobBaseUrl = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets/"
    $IconBlobBaseUrl = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets/"
    $PersonaBlobURL = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets/"

    $cognitiveEndpoint = az cognitiveservices account show -n $accounts_cog_telco_name -g $rgName | jq -r .properties.endpoint

    #retirieving cognitive service key
    $cognitivePrimaryKey = az cognitiveservices account keys list -n $accounts_cog_telco_name -g $rgName | jq -r .key1
(Get-Content -path ./telcodpocbuild/appsettings.json -Raw) | Foreach-Object { $_ `
            -replace '#WORKSPACE_ID#', $wsIdContosoSales`
            -replace '#APP_ID#', $appId`
            -replace '#APP_SECRET#', $clientsecpwdapp`
            -replace '#TENANT_ID#', $tenantId`
            -replace '#REGION#', $Region`
            -replace '#COGNITIVE_SERVICE_ENDPOINT#', $cognitiveEndpoint`
            -replace '#COGNITIVE_KEY#', $cognitivePrimaryKey`
            -replace '#SITES_TELCOWEBAPP#', $sites_telcowebapp`

    } | Set-Content -Path ./telcodpocbuild/appsettings.json



    # $WorldMapReportID = ($reportList | where { $_.name -eq "01 World Map" }).id

    $filepath = "./telcodpocbuild/wwwroot/environment.js"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WorkspaceID#", $wsIdContosoSales).Replace("#IconBlobBaseUrl#", $IconBlobBaseUrl).Replace("#personaUrl#", $PersonaBlobURL).Replace("#BackendURL#", $sites_telcowebapp)
    Set-Content -Path $filepath -Value $item

    RefreshTokens
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales/reports";
    $reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
    $reportList = $reportList.Value

    #update all th report ids in the poc web app...
    $ht = new-object system.collections.hashtable  
  
    $ht.add("#contactCenterAfterReportID#", $($reportList | where { $_.name -eq "Call Center Report After OpenAI Fluent" }).id)

    $ht.add("#contactCenterBeforeReportID#", $($reportList | where { $_.name -eq "Call Center Report Before OpenAI Fluent" }).id)

    $ht.add("#financeReportReportID#", $($reportList | where { $_.name -eq "Finance Report" }).id)

    $ht.add("#networkReportReportID#", $($reportList | where { $_.name -eq "Network Report" }).id)

    $ht.add("#operationsReportReportID#", $($reportList | where { $_.name -eq "Operations Report" }).id)

    $ht.add("#campaignAnalyticsReportReportID#", $($reportList | where { $_.name -eq "Sales Report" }).id)

    $ht.add("#ceoDashboardBeforeReportID#", $($reportList | where { $_.name -eq "Telco CEO Before Dashboard" }).id)

    $ht.add("#executiveDashboardAfterReportID#", $($reportList | where { $_.name -eq "Telco CEO Before Dashboard" }).id)

    $ht.add("#worldMapReportID#", $($reportList | where { $_.name -eq "World Map" }).id)

    

    $filePath = "./telcodpocbuild/wwwroot/environment.js";
    Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

    Compress-Archive -Path "./telcodpocbuild/*" -DestinationPath "./telcodpocbuild.zip" -Update

  
    $TOKEN_1 = az account get-access-token --query accessToken | tr -d '"'

    $deployment = curl -X POST -H "Authorization: Bearer $TOKEN_1" -T "./telcodpocbuild.zip" "https://$sites_telcowebapp.scm.azurewebsites.net/api/publish?type=zip"
    
    az webapp start --name $sites_telcowebapp --resource-group $rgName


## mssql
Write-Host "---------Loading files to MS SQL DB--------"
Add-Content log.txt "-----Loading files to MS SQL DB-----"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/telcoscriptsql.sql"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_database_name -Username $mssql_administrator_login -Password $sql_administrator_login_password
Write-Host "---------Loading files to MS SQL DB COMPLETE--------"
Add-Content log.txt "-----Loading files to MS SQL DB COMPLETE-----"

Write-Host "---------Enabling system asigned identity on SQL server--------"
Set-AzSqlServer -ResourceGroupName $rgName -ServerName $mssql_server_name -AssignIdentity
Write-Host "---------Enabled system asigned identity on SQL server--------"
 
Write-Host "---creating MirrorSQL Connection, MirrorSQLDB"
# Parameters for the API request
$uri = "https://api.fabric.microsoft.com/v1/connections"
$headers = @{
    Authorization = "Bearer $fabric"
    "Content-Type"  = "application/json"
}
$body = @{
    connectivityType = "ShareableCloud"
    displayName      = "TelcoMirroredsqlconnection-$suffix"
    connectionDetails = @{
        type           = "SQL"
        creationMethod = "SQL"
        parameters     = @(
            @{
                dataType = "Text"
                name     = "server"
                value    = "$($mssql_server_name).database.windows.net"
            },
            @{
                dataType = "Text"
                name     = "database"
                value    = "$mssql_database_name"
            }
        )
    }
    privacyLevel     = "Organizational"
    credentialDetails = @{
        singleSignOnType   = "None"
        connectionEncryption = "NotEncrypted"
        skipTestConnection = $false
        credentials = @{
            credentialType = "Basic"
            username       = "$mssql_administrator_login"
            password       = "$sql_administrator_login_password" # Replace with your actual password
        }
    }
}
# Convert the body to JSON
$bodyJson = $body | ConvertTo-Json -Depth 10
# Make the POST request
$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $bodyJson
$connection = $response.id                                            
Write-Output "Connection ID: $connection"




$payloadjson = @{
    properties = @{
        source = @{
            type = "AzureSqlDatabase"
            typeProperties = @{
                connection = $connection
                database = "CustomerDB"
                landingZone = @{
                    type = "MountedRelationalDatabase"
                }
            }
        }
        target = @{
            type = "MountedRelationalDatabase"
            typeProperties = @{
                defaultSchema = "dbo"
                format = "Delta"
            }
        }
    }
}

# Convert the PowerShell object to a JSON string 
$jsonString = $payloadjson | ConvertTo-Json -Depth 10 
# Convert the JSON string to a byte array 
$bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonString) 
# Convert the byte array to a Base64 string 
$base64Payload = [Convert]::ToBase64String($bytes) 

$body = '{
    "displayName" : "Mirrored_TelcoCustomer_DB",
    "description": "A mirrored database description",
    "definition": {
      "parts": [
        {
          "path": "mirrored.json",
          "payload": "$base64Payload",
          "payloadType": "InlineBase64"
        }
      ]
    }
  }'
  
  # Convert the JSON string to a PowerShell object
  $jsonObject = $body | ConvertFrom-Json
  
  # Update the payload value in the object
  $jsonObject.definition.parts[0].payload = $base64Payload
  
  # Convert the PowerShell object back to a JSON string
  $updatedbody = $jsonObject | ConvertTo-Json -Depth 10
  
  # Output the JSON string
  Write-Output $updatedbody
# Define the URI for the API request
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/mirroredDatabases"
# Define the headers
$headers = @{
    Authorization = "Bearer $fabric"
    "Content-Type" = "application/json"
}
# Make the POST request to create the mirrored database
$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $updatedbody
# Retrieve and display the Mirrored Database ID
$mirroredDatabaseId = $response.id
Write-Output "Mirrored Database ID: $mirroredDatabaseId"
start-sleep -s 30
#get mirroring status
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/mirroredDatabases/$mirroredDatabaseId/getMirroringStatus"
$headers = @{
    Authorization = "Bearer $fabric"
    "Content-Type" = "application/json"
}
    $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers
 Write-Output "$response"

start-sleep -s 30

#start Mirrorring
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/mirroredDatabases/$mirroredDatabaseId/startMirroring"
$headers = @{
    Authorization = "Bearer $fabric"
    "Content-Type" = "application/json"
}
$response1 = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers

Write-Host "Mirroring started: $($response1.status)"

# Get SP ID using Azure CLI (avoiding Microsoft.Graph)
$appJson = az ad sp list --display-name "$mssql_server_name" --query '[0]' --output json
$app = $appJson | ConvertFrom-Json
if (-not $app) {
    Write-Error "Service principal '$mssql_server_name' not found."
    
}
$principalId = $app.id



# # Connect-AzureAD

# # $app = Get-AzureADServicePrincipal -Filter "DisplayName eq '$mssql_server_name'"
 
 
$body = @{
    principal = @{
      id = "$principalId"
      type = "ServicePrincipal"
    }
    role = "Member"
  } | ConvertTo-Json
 
  # Now you can use $body in your PowerShell script where needed
  Write-Output $body
  $uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/roleAssignments"
 
# Define the headers
$headers = @{
    Authorization = "Bearer $fabric"
    "Content-Type" = "application/json"
}
 
# Make the REST API call
$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
 
# Output the response
$response  
 
 
Write-Host " ---------Mirrored SQLDB creation completed------------"
