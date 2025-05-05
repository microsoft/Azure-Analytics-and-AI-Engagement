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

$starttime=get-date

$response = az ad signed-in-user show | ConvertFrom-Json
$date = get-date
$demoType = "FSI2.0"
$body = '{"demoType":"#demoType#","userPrincipalName":"#userPrincipalName#","displayName":"#displayName#","companyName":"#companyName#","mail":"#mail#","date":"#date#"}'
$body = $body.Replace("#userPrincipalName#", $response.userPrincipalName)
$body = $body.Replace("#displayName#", $response.displayName)
$body = $body.Replace("#companyName#", $response.companyName)
$body = $body.Replace("#mail#", $response.mail)
$body = $body.Replace("#date#", $date)
$body = $body.Replace("#demoType#", $demoType)

$uri = "https://registerddibuser.azurewebsites.net/api/registeruser?code=pTrmFDqp25iVSxrJ/ykJ5l0xeTOg5nxio9MjZedaXwiEH8oh3NeqMg=="
$result = Invoke-RestMethod  -Uri $uri -Method POST -Body $body -Headers @{} -ContentType "application/json"

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
$rgName = "rg-fsi-2.0-$suffix"
$Region = read-host "Enter the region for deployment"
$wsIdContosoSales =  Read-Host "Enter your 'Woodgrove' PowerBI workspace Id "
$subscriptionId = (Get-AzContext).Subscription.Id
$dataLakeAccountName = "stfsi2$suffix"
$tenantId = (Get-AzContext).Tenant.Id
$mssql_server_name = "mssql$suffix"
$mssql_database_name = "SalesDb"
$mssql_administrator_login = "labsqladmin"
$cosmosdb_account = "cosmosdb$suffix"
$sites_fsi2webapp = "app-fsi2webapp-$suffix"
$serverfarm_fsi2webapp = "asp-fsi2webapp-$suffix"
$accounts_cog_fsi2_name = "accounts-cog-fsi2-$suffix"
# $databricks_workspace_name = "adb-fabric-$suffix"
# $databricks_managed_resource_group_name = "rg-managed-adb-$suffix"
# $userAssignedIdentities_ami_databricks_build = "ami-databricks-$suffix"
# $dbdataLakeAccountName = "stfsi2adb$suffix"
# $databricksconnector = "access-adb-connector-$suffix"
# $keyVaultName = "kv-adb-$suffix"
# $containerName = "containerdatabricksmetastore"
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

$lakehouseBronze =  "FSI_lakehouse_Bronze_$suffix"
$lakehouseSilver =  "FSI_lakehouse_Silver_$suffix"
$lakehouseSales = "Sales_Lakehouse"


Add-Content log.txt "------FABRIC assets deployment STARTS HERE------"
Write-Host "------------FABRIC assets deployment STARTS HERE------------"

Add-Content log.txt "------Creating Lakehouses in '$contosoSalesWsName' workspace------"
Write-Host "------Creating Lakehouses in '$contosoSalesWsName' workspace------"
$lakehouseNames = @($lakehouseBronze, $lakehouseSilver, $lakehouseSales)
# Set the token and request headers
$pat_token = $fabric
    $requestHeaders = @{
        Authorization  = "Bearer" + " " + $pat_token
        "Content-Type" = "application/json"
    }

# Iterate through each Lakehouse name and create it
foreach ($lakehouseName in $lakehouseNames) {
# Create the body for the Lakehouse creation
    $body = @{
        displayName = $lakehouseName
        type        = "Lakehouse"
    } | ConvertTo-Json

# Set the API endpoint
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/items/"

# Invoke the REST method to create a new Lakehouse
try {
        $Lakehouse = Invoke-RestMethod $endPoint `
            -Method POST `
            -Headers $requestHeaders `
            -Body $body

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

Write-Output "Bronze Lakehouse ID: $LakehouseBronzeid"

Write-Output "Silver Lakehouse ID: $LakehouseSilverid"

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

Add-Content log.txt "------KQL Queryset------"
Write-Host "------Creating KQL Queryset"
        $KQLQs = "Query Foot-traffic Data in Near Real-Time using KQL"
        $body1 = @{
                displayName = $KQLQs 
            } | ConvertTo-Json
            
    try{
        $endPoint1 = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/kqlQuerysets"
        $KQLDBAPI = Invoke-RestMethod -Method Post -Uri $endPoint1 -Headers $requestHeaders -Body $body1
                Write-Host "KQL Queryset '$KQLQs' created successfully."
        }catch{
            Write-Host "Error creating KQL Queryset '$KQLQs'"
        }
Start-Sleep -s 10 
Write-Host "-----------Creation of KQL Queryset COMPLETED------------"




Add-Content log.txt "------Uploading assets to Lakehouses------"
Write-Host "------------Uploading assets to Lakehouses------------"
$tenantId = (Get-AzContext).Tenant.Id
azcopy login --tenant-id $tenantId

azcopy copy "https://stfsi2dpoc.blob.core.windows.net/bronzelakehousefiles/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseBronze.Lakehouse/Files/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stfsi2dpoc.blob.core.windows.net/silverlakehousefiles/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseSilver.Lakehouse/Files/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stfsi2dpoc.blob.core.windows.net/silverlakehousetables/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseSilver.Lakehouse/Tables/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;

Add-Content log.txt "------Uploading assets to Lakehouses COMPLETED------"
Write-Host "------------Uploading assets to Lakehouses COMPLETED------------"


## notebooks
Add-Content log.txt "-----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses-----"
Write-Host "----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses----"

(Get-Content -path "artifacts/fabricnotebooks/00 Copilot Notebook in Data Science & Data Engineering.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#LAKEHOUSE_SILVER#', $lakehouseSilver `
} | Set-Content -Path "artifacts/fabricnotebooks/00 Copilot Notebook in Data Science & Data Engineering.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/01 Raw Data to Lakehouse (Bronze) Code First Experience.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#SALES_WORKSPACE_NAME#', $wsIdContosoSales `
    -replace '#LAKEHOUSE_BRONZE#', $LakehouseBronzeid `

} | Set-Content -Path "artifacts/fabricnotebooks/01 Raw Data to Lakehouse (Bronze) Code First Experience.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/02 Bronze to Silver Layer Medallion Architecture.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#LAKEHOUSE_SILVER#', $lakehouseSilver `
    -replace '#LAKEHOUSE_BRONZE#', $LakehouseBronzeid `
    -replace '#SALES_WORKSPACE_NAME#', $wsIdContosoSales `
    -replace '#Lakehouse_SilverID#', $LakehouseSilverid `
    
} | Set-Content -Path "artifacts/fabricnotebooks/02 Bronze to Silver Layer Medallion Architecture.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/03. Churn Prediction for Retail Banking Scenario.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#LAKEHOUSE_SILVER#', $LakehouseSilverid `
    -replace '#LAKEHOUSE_GOLD#', $lakehouseGold `
    -replace '#SALES_WORKSPACE_NAME#', $contosoSalesWsName `
} | Set-Content -Path "artifacts/fabricnotebooks/03. Churn Prediction for Retail Banking Scenario.ipynb"


Add-Content log.txt "-----Fabric Notebook Configuration COMPLETED-----"
Write-Host "----Fabric Notebook Configuration COMPLETED----"


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
if ($name -eq "00 Copilot Notebook in Data Science & Data Engineering.ipynb" -or
        $name -eq "01 Raw Data to Lakehouse (Bronze) Code First Experience.ipynb" -or
        $name -eq "02 Bronze to Silver Layer Medallion Architecture.ipynb" -or
        $name -eq "03. Churn Prediction for Retail Banking Scenario.ipynb") 
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
-sites_fsi2webapp $sites_fsi2webapp `
-serverfarm_fsi2webapp $serverfarm_fsi2webapp `
-storage_account_name $dataLakeAccountName `
-mssql_server_name $mssql_server_name `
-mssql_database_name $mssql_database_name `
-mssql_administrator_login $mssql_administrator_login `
-sql_administrator_login_password $sql_administrator_login_password `
-cosmosdb_fsi2_name $cosmosdb_account `
-accounts_cog_fsi2_name $accounts_cog_fsi2_name `
-Force
# -databricks_workspace_name $databricks_workspace_name `
# -databricks_managed_resource_group_name $databricks_managed_resource_group_name `
# -userAssignedIdentities_ami_databricks_build $userAssignedIdentities_ami_databricks_build `
# -datalake_account_name $dbdataLakeAccountName `
# -vaults_kv_databricks_prod_name $keyVaultName `

    
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




RefreshTokens
Add-Content log.txt "------Uploading PowerBI Reports------"
Write-Host "------------Uploading PowerBI Reports------------"
$spname = "FSI 2.0 $suffix"
 
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
$Lakehouseid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseSilver" }).id


Write-Output "Lakehouse ID: $LakehouseId"

$url = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/lakehouses/$lakehouseid";
$Lakehousedetails = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $fabric" };

$ServerName = $Lakehousedetails.properties.sqlEndpointProperties.connectionString
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
    if ($report.Name -ne "09 FSI HTAP" -and $report.Name -ne "08 FSI Twitter Report")
    {

    $body = "{
        `"updateDetails`": [
            {
                `"name`": `"Server`",
                `"newValue`": `"$($ServerName)`"
            },
            {
                `"name`": `"Database`",
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

    if ($report.Name -eq "08 FSI Twitter Report") {
       
    $body = "{
        `"updateDetails`": [
            {
                `"name`": `"ServerName`",
                `"newValue`": `"$($KQLDBID)`"
            },
            {
                `"name`": `"DBName`",
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

    if ($report.Name -eq "09 FSI HTAP") {
       
        $body = "{
            `"updateDetails`": [
            {
                `"name`": `"Server`",
                `"newValue`": `"$($ServerName)`"
            },
            {
                `"name`": `"Database`",
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
}

Write-Host "------------Updating PowerBI Reports COMPLETED------------"

Add-Content log.txt "------FABRIC assets deployment DONE------"
Write-Host "------------FABRIC assets deployment DONE------------"

Add-Content log.txt "------AZURE assets deployment STARTS HERE------"
## storage az copy
Write-Host "Copying files to Storage Container"
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$destinationSasKey = New-AzStorageContainerSASToken -Container "adls-core-banking-system-data" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/adls-core-banking-system-data$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://stfsi2dpoc.blob.core.windows.net/adls-core-banking-system-data/" $destinationUri --recursive
    
$destinationSasKey = New-AzStorageContainerSASToken -Container "videoassets" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/videoassets$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://stfsi2dpoc.blob.core.windows.net/videoassets/" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "campaign-generation-watermark-images" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/campaign-generation-watermark-images$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://stfsi2dpoc.blob.core.windows.net/campaign-generation-watermark-images/" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "kqldbdata" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/kqldbdata$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://stfsi2dpoc.blob.core.windows.net/kqldbdata/" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://stfsi2dpoc.blob.core.windows.net/webappassets/" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "news-and-sentiment" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/news-and-sentiment$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://stfsi2dpoc.blob.core.windows.net/news-and-sentiment/" $destinationUri --recursive



Add-Content log.txt "------unzipping poc web app------"
    Write-Host  "--------------Unzipping web app---------------"

expand-archive -path "./artifacts/binaries/fsi2dpocbuild.zip" -destinationpath "./fsi2dpocbuild" -force

    #Web app
    Add-Content log.txt "------deploy poc web app------"
    Write-Host  "-----------------Deploy web app---------------"
    RefreshTokens
    $BlobBaseUrl = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets/fsi/"
    $IconBlobBaseUrl = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets/left-nav-icons/"
    $PersonaBlobURL = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets/personas/"

    $cognitiveEndpoint = az cognitiveservices account show -n $accounts_cog_fsi2_name -g $rgName | jq -r .properties.endpoint

    #retirieving cognitive service key
    $cognitivePrimaryKey = az cognitiveservices account keys list -n $accounts_cog_fsi2_name -g $rgName | jq -r .key1
(Get-Content -path ./fsi2dpocbuild/appsettings.json -Raw) | Foreach-Object { $_ `
            -replace '#WORKSPACE_ID#', $wsIdContosoSales`
            -replace '#APP_ID#', $appId`
            -replace '#APP_SECRET#', $clientsecpwdapp`
            -replace '#TENANT_ID#', $tenantId`
            -replace '#REGION#', $Region`
            -replace '#COGNITIVE_SERVICE_ENDPOINT#', $cognitiveEndpoint`
            -replace '#COGNITIVE_KEY#', $cognitivePrimaryKey`
            -replace '#SITES_FSI2WEBAPP#', $sites_fsi2webapp`

    } | Set-Content -Path ./fsi2dpocbuild/appsettings.json



    # $WorldMapReportID = ($reportList | where { $_.name -eq "01 World Map" }).id

    $filepath = "./fsi2dpocbuild/wwwroot/environment-dpoc.js"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WorkspaceID#", $wsIdContosoSales).Replace("#BlobURL#", $BlobBaseUrl).Replace("#IconURL#", $IconBlobBaseUrl).Replace("#PersonaURL#", $PersonaBlobURL).Replace("#BackendURL#", $sites_fsi2webapp)
    Set-Content -Path $filepath -Value $item

    RefreshTokens
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales/reports";
    $reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
    $reportList = $reportList.Value

    #update all th report ids in the poc web app...
    $ht = new-object system.collections.hashtable  
  
    $ht.add("#WorldMapReportID#", $($reportList | where { $_.name -eq "01 World Map" }).id)

    $ht.add("#CEODashBoardJanBeforeReportID#", $($reportList | where { $_.name -eq "CEO Dashboard New FSI Jan" }).id)

    $ht.add("#CCODashboardReportID#", $($reportList | where { $_.name -eq "14 FSI CCO Dashboard" }).id)

    $ht.add("#ESGDashboardReportID#", $($reportList | where { $_.name -eq "16 ESGDashboardV2_KPIandGraphs" }).id)

    $ht.add("#ESGTalkReportId#", $($reportList | where { $_.name -eq "02 ESG Report" }).id)

    $ht.add("#MSCIReportID#", $($reportList | where { $_.name -eq "03 MSCI report" }).id)

    $ht.add("#MSCIReportAfterID#", $($reportList | where { $_.name -eq "03 MSCI report" }).id)

    $ht.add("#CEODashBoardJuneBeforeReportID#", $($reportList | where { $_.name -eq "CEO Dashboard New FSI June" }).id)

    $ht.add("#CFODashBoardReportID#", $($reportList | where { $_.name -eq "22 Finance Report KPI CFO Dashboard" }).id)

    $ht.add("#RevenueProfitReportID#", $($reportList | where { $_.name -eq "07 Finance Report" }).id)

    $ht.add("#CEODashBoardSeptBeforeReportID#", $($reportList | where { $_.name -eq "CEO Dashboard New FSI Sep" }).id)

    $ht.add("#SenitmentReportID#", $($reportList | where { $_.name -eq "08 FSI Twitter Report" }).id)
    

    $ht.add("#HofiDashBoardBeforeReportID#", $($reportList | where { $_.name -eq "18 FSI Head of Financial Intelligence" }).id)

    $ht.add("#HofiDashBoardAfterReportID#", $($reportList | where { $_.name -eq "18 FSI Head of Financial Intelligence" }).id)

    $ht.add("#InitialInvestmentReportID#", $($reportList | where { $_.name -eq "Wealth Advisor Report_New" }).id)

    $ht.add("#ModifiedInitialInvestmentReportID#", $($reportList | where { $_.name -eq "Wealth Advisor Report_New" }).id)
    $ht.add("#WealthAdviserReport#", $($reportList | where { $_.name -eq "Post Meeting Report" }).id)

    $ht.add("#CallCenterBeforeSummaryReport#", $($reportList | where { $_.name -eq "Call Center Report Before OpenAI" }).id)

    $ht.add("#CallCenterBeforeScriptReport#", $($reportList | where { $_.name -eq "Call Center Report Before OpenAI" }).id)

    $ht.add("#CallCenterAfterSummaryReport#", $($reportList | where { $_.name -eq "Call Center Report After OpenAI" }).id)

    $ht.add("#CallCenterAfterScriptReport#", $($reportList | where { $_.name -eq "Call Center Report After OpenAI" }).id)

    $ht.add("#CEODashBoardDecBeforeReportID#", $($reportList | where { $_.name -eq "CEO Dashboard New FSI Dec" }).id)

    $ht.add("#HtapWithAzureCosmosReportID#", $($reportList | where { $_.name -eq "09 FSI HTAP" }).id)

    $ht.add("#HtapReportID#", $($reportList | where { $_.name -eq "09 FSI HTAP" }).id)

    $filePath = "./fsi2dpocbuild/wwwroot/environment-dpoc.js";
    Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

    Compress-Archive -Path "./fsi2dpocbuild/*" -DestinationPath "./fsi2dpocbuild.zip" -Update

  
    $TOKEN_1 = az account get-access-token --query accessToken | tr -d '"'

    $deployment = curl -X POST -H "Authorization: Bearer $TOKEN_1" -T "./fsi2dpocbuild.zip" "https://$sites_fsi2webapp.scm.azurewebsites.net/api/publish?type=zip"
    
    az webapp start --name $sites_fsi2webapp --resource-group $rgName

## mssql
Write-Host "---------Loading files to MS SQL DB--------"
Add-Content log.txt "-----Loading files to MS SQL DB-----"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/FSI2SqlDbScript.sql"
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
    displayName      = "Mirroredsqlconnection-$suffix"
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
                database = "SalesDb"
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
    "displayName" : "SQL-DB-GeospatialData",
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

Connect-AzureAD

$app = Get-AzureADServicePrincipal -Filter "DisplayName eq '$mssql_server_name'"
 
 
$body = @{
    principal = @{
      id = "$($app.ObjectId)"
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

Write-Host  "-----------------Uploading Cosmos Data Started--------------"
#uploading Cosmos data
Add-Content log.txt "-----------------uploading Cosmos data--------------"

(Get-Content -path artifacts/cosmos/kyc.json -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName `
} | Set-Content -Path artifacts/cosmos/kyc.json


RefreshTokens
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmos_appcosmos_name
$cosmosDatabaseName = "fsi-marketdata"

# Retrieve JSON files
$cosmos = Get-ChildItem "./artifacts/cosmos" | Where-Object { $_.Extension -eq ".json" } | Select BaseName 

# Process each JSON file
foreach ($name in $cosmos) {
    $collection = $name.BaseName 
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosdb_account -Database $cosmosDatabaseName -ResourceGroup $rgName
    $path = "./artifacts/cosmos/" + $name.BaseName + ".json"
    $document = Get-Content -Raw -Path $path
    $document = ConvertFrom-Json $document

    foreach ($json in $document) {
        $key = $json.id
        $body = ConvertTo-Json $json
        $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId "KYC" -DocumentBody $body -PartitionKey $key -ErrorAction SilentlyContinue
    }
} 

Write-Host  "-----------------Uploaded Data to Cosmos DB--------------"


Write-Host  "-----------------Execution Complete----------------"



