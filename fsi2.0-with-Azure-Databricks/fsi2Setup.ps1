$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "I accept the license agreement."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "I do not accept and wish to stop execution."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$title = "Agreement"
$message = "By typing [Y], I hereby confirm that I have read the license ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/license.md ) and disclaimers ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/README.md ) and hereby accept the terms of the license and agree that the terms and conditions set forth therein govern my use of the code made available hereunder. (Type [Y] for Yes or [N] for No and press enter)"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)

if ($result -eq 1) {
    Write-Host "Thank you. Please ensure you delete the resources created with template to avoid further cost implications."
}
else {
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
}
else {
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
}
else {
    Write-Host "User does not have Owner permission on the subscription. Deployment will fail. Would you still like to continue? (Yes/No)" -ForegroundColor Red

    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "Yes") {
        Write-Host "Proceeding with deployment..."
    }
    else {
        Write-Host "Aborting deployment."
        exit
    }
}



[string]$suffix = -join ((48..57) + (97..122) | Get-Random -Count 7 | % { [char]$_ })
$rgName = "rg-fsi-2.0-$suffix"
$Region = read-host "Enter the region for deployment"
$wsIdContosoSales = Read-Host "Enter your 'Woodgrove' PowerBI workspace Id "
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
$databricks_workspace_name = "adb-fabric-$suffix"
$databricks_managed_resource_group_name = "rg-managed-adb-$suffix"
$userAssignedIdentities_ami_databricks_build = "ami-databricks-$suffix"
$dbdataLakeAccountName = "stfsi2adb$suffix"
$databricksconnector = "access-adb-connector-$suffix"
$keyVaultName = "kv-adb-$suffix"
$containerName = "containerdatabricksmetastore"
$complexPassword = 0
$sql_administrator_login_password = ""
while ($complexPassword -ne 1) {
    $sql_administrator_login_password = Read-Host "Enter a password to use for the $mssql_administrator_login login.
        `The password must meet complexity requirements:
        ` - Minimum 8 characters. 
        ` - At least one upper case English letter [A-Z]
        ` - At least one lower case English letter [a-z]
        ` - At least one digit [0-9]
        ` - At least one special character (!,@,#,%,^,&,$)
        ` "

    if (($sql_administrator_login_password -cmatch '[a-z]') -and ($sql_administrator_login_password -cmatch '[A-Z]') -and ($sql_administrator_login_password -match '\d') -and ($sql_administrator_login_password.length -ge 8) -and ($sql_administrator_login_password -match '!|@|#|%|^|&|$')) {
        $complexPassword = 1
        Write-Output "Password $sql_administrator_login_password accepted. Make sure you remember this!"
    }
    else {
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
    -storage_account_name $dataLakeAccountName `
    -sites_fsi2webapp $sites_fsi2webapp `
    -serverfarm_fsi2webapp $serverfarm_fsi2webapp `
    -mssql_server_name $mssql_server_name `
    -mssql_database_name $mssql_database_name `
    -mssql_administrator_login $mssql_administrator_login `
    -sql_administrator_login_password $sql_administrator_login_password `
    -cosmosdb_fsi2_name $cosmosdb_account `
    -databricks_workspace_name $databricks_workspace_name `
    -databricks_managed_resource_group_name $databricks_managed_resource_group_name `
    -userAssignedIdentities_ami_databricks_build $userAssignedIdentities_ami_databricks_build `
    -datalake_account_name $dbdataLakeAccountName `
    -vaults_kv_databricks_prod_name $keyVaultName `
    -accounts_cog_fsi2_name $accounts_cog_fsi2_name `
    -Force
    
$templatedeployment = Get-AzResourceGroupDeployment -Name "mainTemplate" -ResourceGroupName $rgName
$deploymentStatus = $templatedeployment.ProvisioningState
Write-Host "Deployment in $rgName : $deploymentStatus"


if ($deploymentStatus -eq "Succeeded") {
    Write-Host "Template deployment succeeded. Have you provided yourself as account administrator on Databricks? (Yes/No)"

    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "Yes") {
        Write-Host "Proceeding with further resource creation..."
    }
    else {
        Write-Host "Further resource creation in Databricks will fail, proceeding with further deployment..."
    }
}
else {
    Write-Host "Template deployment failed or is not complete. Aborting further actions,please redeploy the template. "
    exit
}

##Azre Databricks 

##creating databricks connector

Write-Host "Creating Access Connector for Azure Databricks in $rgName"

New-AzDatabricksAccessConnector -Name $databricksconnector `
    -ResourceGroupName $rgName `
    -Location $Region `
    -SubscriptionId $subscriptionId `
    -IdentityType UserAssigned `
    -UserAssignedIdentity @{"/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentities_ami_databricks_build" = @{} }

$datbricksconnectorstatus = Get-AzDatabricksAccessConnector -Name $databricksconnector -ResourceGroupName $rgName
$datbricksconnectorstatus = $datbricksconnectorstatus.ProvisioningState
Write-Host "Creation of Access Connector for Azure Databricks : $datbricksconnectorstatus"


            
##Role assingment for managed identity##
Write-Host "Assigning required roles to managed identity..."
$userassignedidentityid = (Get-AzUserAssignedIdentity -Name "ami-databricks-$suffix" -ResourceGroupName $rgName).clientid
$assignment1 = az role assignment create --role "Key Vault Reader" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName/providers/Microsoft.KeyVault/vaults/$keyVaultName
$assignment2 = az role assignment create --role "Storage Blob Data Contributor" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dbdataLakeAccountName
$asssignment3 = az role assignment create --role "Contributor" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName
$asssignment4 = az keyvault set-policy --name $keyVaultName --upn $signedinusername --secret-permissions set list get

$roleassigments = If ($assignment1, $assignment2, $assignment3, $asssignment4 -ne $null) { "Role assignment COMPLETE..." } Else { "Role assignment Failed" }
write-host $roleassigments

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dbdataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dbdataLakeAccountName -StorageAccountKey $storage_account_key

$filesystemName = "containerdatabricksmetastore"
$dirname = "metastore_root/"
$directory = New-AzDataLakeGen2Item -Context $dataLakeContext -FileSystem $filesystemName -Path $dirname -Directory

$dir = if ($directory -ne $null) { "created container named containerdatabricksmetastore" } Else { "failed to create container containerdatabricksmetastore" }
write-host $dir 

$connectionString = (Get-AzStorageAccount -ResourceGroupName $rgName -Name $dbdataLakeAccountName).Context.ConnectionString

## Create Directory in ADLS Gen2
az storage fs directory create -n metastore_root -f "containerdatabricksmetastore" --connection-string $connectionstring
Write-Host "-----Deploying Resources on Microsoft Azure COMPLETE-----"

Write-Host "---------AZURE DATABRICKS---------"
Write-Host "---Deploying Resources on Azure Databricks..."
$dbswsId = $(az resource show `
        --resource-type Microsoft.Databricks/workspaces `
        -g "$rgName" `
        -n "$databricks_workspace_name" `
        --query id -o tsv)

$dbsId = $(az resource show `
        --resource-type Microsoft.Databricks/workspaces `
        -g "$rgName" `
        -n "$databricks_workspace_name" `
        --query properties.workspaceId -o tsv)

$workspaceUrl = $(az resource show `
        --resource-type Microsoft.Databricks/workspaces `
        -g "$rgName" `
        -n "$databricks_workspace_name" `
        --query properties.workspaceUrl -o tsv)

# Get a token for the global Databricks application.
# The resource ID is fixed and never changes.
$token_response = $(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json) | ConvertFrom-Json
$token = $token_response.accessToken

# Get a token for the Azure management API
$token_response = $(az account get-access-token --resource https://management.core.windows.net/ --output json) | ConvertFrom-Json
$azToken = $token_response.accessToken

$uri = "https://$($workspaceUrl)/api/2.0/token/create"
$baseUrl = 'https://' + $workspaceUrl
# You can also generate a PAT token. Note the quota limit of 600 tokens.
$body = '{"lifetime_seconds": 1000000, "comment": "catalog" }';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")
$headers.Add("X-Databricks-Azure-SP-Management-Token", "$azToken")
$headers.Add("X-Databricks-Azure-Workspace-Resource-Id", "$dbswsId")
$pat_token = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Header $headers 
$pat_token = $pat_token.token_value

$pattokenvalidation = if ($pat_token -ne $null) { "Pat token created" }Else { "Failed to create pat token" }
write-host $pattokenvalidation

# adding PAT token as secret in keyvualt
$secret = az keyvault secret set --name "databricks-token" --value $pat_token --vault-name $keyVaultName

# creating personal compute

$requestHeaders = @{
    Authorization  = "Bearer" + " " + $pat_token
    "Content-Type" = "application/json"
}

# to create a new cluster
Write-Host "Creating CLUSTERS in Azure Databricks..."

# $body = '{
#     "cluster_name": "PersonalCluster",
#     "spark_version": "13.3.x-scala2.12",
#     "spark_conf": {
#         "spark.master": "local[*, 4]",
#         "spark.databricks.cluster.profile": "singleNode"
#     },
#     "azure_attributes": {
#         "first_on_demand": 1,
#         "availability": "ON_DEMAND_AZURE",
#         "spot_bid_max_price": -1
#     },
#     "node_type_id": "Standard_DS3_v2",
#     "driver_node_type_id": "Standard_DS3_v2",
#     "custom_tags": {
#         "ResourceClass": "SingleNode"
#     },
#     "autotermination_minutes": 45,
#     "enable_elastic_disk": true,
#     "data_security_mode": "SINGLE_USER",
#     "runtime_engine": "STANDARD",
#     "num_workers": 0
# }'

# $endPoint = $baseURL + "/api/2.0/clusters/create"
# $clusterId_1 = Invoke-RestMethod $endPoint `
#     -Method Post `
#     -Headers $requestHeaders `
#     -Body $body

# $clusterstatus = if ($clusterId_1.cluster_id -ne $Null) { "cluster has been created successfully." } else { "cluster creation failed." }
# write-host $clusterstatus
# $clusterId_1 = $clusterId_1.cluster_id

Write-Host "Creating ML CLUSTER in Azure Databricks..."

$body = '{
    "cluster_name": "ML Cluster",
    "spark_version": "15.4.x-cpu-ml-scala2.12",
    "azure_attributes": {
        "first_on_demand": 1,
        "availability": "ON_DEMAND_AZURE",
        "spot_bid_max_price": -1
    },
    "node_type_id": "Standard_DS3_v2",
    "autotermination_minutes": 45,
    "data_security_mode": "SINGLE_USER",
    "runtime_engine": "STANDARD",
    "autoscale": {
        "min_workers": 2,
        "max_workers": 8
    }
}'

$endPoint = $baseURL + "/api/2.0/clusters/create"
$MLcluster = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$MLclusterstatus = if ($MLcluster.cluster_id -ne $Null) { "ML cluster has been created successfully." } else { "ML cluster creation failed." }
write-host $MLclusterstatus
$MLcluster = $MLcluster.cluster_id

Write-Host "----Cluster creation COMPLETE----"

## creating Metastore
Write-Host "----Creating Metastore----"

$requestHeaders = @{
    Authorization  = "Bearer" + " " + $pat_token
    "Content-Type" = "application/json"
}

$body = '{
  "name": "metastore-'+ $Region + '",
  "storage_root": "abfss://'+ $containerName + '@' + $dbdataLakeAccountName + '.dfs.core.windows.net/metastore_root",
  "region": "' + $Region + '"
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/metastores"
$metastore = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Start-Sleep -Seconds 5
$metastorestatus = if ($metastore.metastore_id -ne $Null) { "Metastore has been created successfully." } else { "Metastore creation failed." }
Write-host $metastorestatus
$metastoreid = $metastore.metastore_id


## Assigning metastore to workspace 
Write-Host "Assigning Metastore to your Azure Databricks workspace..."

$body = '{
  "metastore_id": "' + $metastoreid + '"
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/workspaces/$dbsId/metastore"
$metastorews = Invoke-RestMethod $endPoint `
    -Method PUT `
    -Headers $requestHeaders `
    -Body $body

## fecthing workspace assignment
$endPoint = $baseURL + "/api/2.1/unity-catalog/current-metastore-assignment"
$metastorewsassignment = Invoke-RestMethod $endPoint `
    -Method GET `
    -Headers $requestHeaders
        
$metastorewsassignmentstatus = if ($metastorewsassignment.metastore_id -ne $Null) { "Metastore has been assigned to your Azure Databricks workspace." } else { " Failed to assign Metastore Azure Databricks workspace." }
write-host $metastorewsassignmentstatus

## Get SQL warehouse
$endPoint = $baseURL + "/api/2.0/sql/warehouses"
$warehouse = Invoke-RestMethod $endPoint `
    -Method GET `
    -Headers $requestHeaders 

$warehouse = $warehouse.warehouses.id

## Start a warehouse
Write-Host "Starting SQL Warehouse, it may take a while..."

$endPoint = $baseURL + "/api/2.0/sql/warehouses/$warehouse/start"
$warehouse = Invoke-RestMethod $endPoint `
    -Method POST `
    -Headers $requestHeaders 

Start-Sleep -Seconds 400
## Fecthing Warehouse State
$endPoint = $baseURL + "/api/2.0/sql/warehouses"
$warehouse = Invoke-RestMethod $endPoint `
    -Method GET `
    -Headers $requestHeaders 

$warehousestate = $warehouse.warehouses.state

$warehousestatus = if ($warehousestate -eq "RUNNING") { "Warehouse Started." } else { "Warehouse is $warehousestate" }
write-host $warehousestatus

##Creating Storage Credentials 
Write-Host "Creating Storage Credentials..."

$body = '{
  "name": "storagecred",
  "comment": "none",
  "read_only": false,
  "azure_managed_identity": {
    "access_connector_id": "/subscriptions/' + $subscriptionId + '/resourceGroups/' + $rgName + '/providers/Microsoft.Databricks/accessConnectors/' + $databricksconnector + '",
    "managed_identity_id": "/subscriptions/' + $subscriptionId + '/resourcegroups/' + $rgName + '/providers/Microsoft.ManagedIdentity/userAssignedIdentities/' + $userAssignedIdentities_ami_databricks_build + '"
  },
  "skip_validation": false
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/storage-credentials"
$storagecred = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Start-Sleep -Seconds 5
$storagecredstatus = if ($storagecred.id -ne $Null) { "Storage credentials has been created successfully." } else { "Failed to create Storage Credentials." }
write-host $storagecredstatus

##Creating External location 
Write-Host "Creating External Location..."

$body = 
'{
  "name": "externalbuild",
  "url": "abfss://'+ $containerName + '@' + $dbdataLakeAccountName + '.dfs.core.windows.net/metastore_root",
  "credential_name": "storagecred",
  "read_only": false,
  "comment": "string",
  "skip_validation": true
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/external-locations"
$extlocation = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Start-Sleep -Seconds 5
$extlocationstatus = if ($extlocation.id -ne $Null) { "External location has been created successfully." } else { "Failed to create External location." }
write-host $extlocationstatus

## creating Unity Catalog
Write-Host "Creating Unity Catalog..."

$body = 
'{
  "name": "cronos_unity_catalog",
  "comment": "none",
  "properties": {},
  "storage_root": "abfss://'+ $containerName + '@' + $dbdataLakeAccountName + '.dfs.core.windows.net/metastore_root/catalog"
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/catalogs"
$catalog = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Start-Sleep -Seconds 5
$catalogstatus = if ($catalog.id -ne $Null) { "Unity Catalog has been created successfully." } else { "Failed to create Unity Catalog." }
write-host $catalogstatus

##Creating Schema
Write-Host "Creating Schema..."

$body = 
'{
  "name": "cdata",
  "catalog_name": "cronos_unity_catalog",
  "comment": "schema",
  "properties": {
  },
  "storage_root": "abfss://'+ $containerName + '@' + $dbdataLakeAccountName + '.dfs.core.windows.net/metastore_root/cdataschema"
}'


$endPoint = $baseURL + "/api/2.1/unity-catalog/schemas"
$schema = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Start-Sleep -Seconds 5
$schemastatus = if ($schema.schema_id -ne $Null) { "Schema has been created successfully." } else { "Failed to create Schema." }
write-host $schemastatus
$schema = $schema.schema_id

# create Volume
Write-Host "Creating Volume..."

$maxRetries = 3
$retryIntervalSeconds = 2

for ($i = 0; $i -lt $maxRetries; $i++) {
    
    $body = '{
  "catalog_name": "cronos_unity_catalog",
  "schema_name": "cdata",
  "name": "banking_unity_catalog",
  "volume_type": "MANAGED"
}'

    $endPoint = $baseURL + "/api/2.1/unity-catalog/volumes"
    $volume = Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body
    
    if ($volume.volume_id -ne $Null) {
        Write-Host "Volume has been created successfully."
        break  # Exit the loop if Volume is created.
    }
    else {
        Write-Host "creating Volume is in progress. Retrying in $retryIntervalSeconds seconds..."
        Start-Sleep -Seconds $retryIntervalSeconds
    }
}

if ($i -eq $maxRetries) {
    Write-Host "Max retries reached. Failed to create Volume."
}

# create Directory 
Write-Host "Creating Directories in Volume..."


# ## datastore dir
# $endPoint = $baseURL + "/api/2.0/fs/directories/Volumes/cronos_unity_catalog/cdata/banking_unity_catalog/datastore"
# $volume = Invoke-RestMethod $endPoint `
#     -Method PUT `
#     -Headers $requestHeaders 

$endPoint = $baseURL + "/api/2.0/fs/directories/Volumes/cronos_unity_catalog/cdata/banking_unity_catalog/PDFs"
$volume = Invoke-RestMethod $endPoint `
    -Method PUT `
    -Headers $requestHeaders 

Write-Host "Directories creation in Volume. COMPLETE.."

# create diretory in Shared folder
Write-Host "Creating directory in Shared folder..."


##Analytics with ADB

$body = '{
  "path": "/Workspace/Shared/Analytics with ADB"
}'

$endPoint = $baseURL + "/api/2.0/workspace/mkdirs"
$volume = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Write-Host "Directory created successfully in shared folder."
Start-Sleep -Seconds 5

$body = '{
    "path": "/Workspace/Shared/Retrieval Augmented Generation (RAG) - Version-2"
  }'
  
$endPoint = $baseURL + "/api/2.0/workspace/mkdirs"
$volume = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body
  
Write-Host "RAG Directory created successfully in shared folder."
Start-Sleep -Seconds 5
  
(Get-Content -path "artifacts/databricks/01 DLT Notebook.ipynb" -Raw) | Foreach-Object { $_ `
        -replace '#STORAGEACCOUNT#', $dbdataLakeAccountName `
        -replace '#storage_account_key#', $storage_account_key `
} | Set-Content -Path "artifacts/databricks/01 DLT Notebook.ipynb"


#uploading Notebooks
Write-Host "Uploading Notebooks in shared folder..."
$files = Get-ChildItem -path "artifacts/databricks"  -File -Recurse  #all files uploaded in one folder change config paths in python jobs
Set-Location "./artifacts/databricks"
foreach ($file in $files) {
    if ($file.Name -eq "01 DLT Notebook.ipynb") {
        $fileContent = Get-Content -Raw $file.FullName
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

        # Extract the name without extension
        $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $body = '{"content": "' + $fileContentEncoded + '",  "path": "/Workspace/Shared/Analytics with ADB/' + $nameWithoutExtension + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
        #get job list
        $endPoint = $baseURL + "/api/2.0/workspace/import"
        $result = Invoke-RestMethod $endPoint `
            -ContentType 'application/json' `
            -Method Post `
            -Headers $requestHeaders `
            -Body $body
    }
    if ($file.Name -eq "00-init.ipynb" -or
        $file.Name -eq "1. Create a delta table from UC volume with Autoloader.ipynb" -or
        $file.Name -eq "2. Ingesting and preparing PDF for LLM and Self Managed Vector Search Embeddings.ipynb") {
        $fileContent = Get-Content -Raw $file.FullName
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

        # Extract the name without extension
        $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $body = '{"content": "' + $fileContentEncoded + '",  "path": "/Workspace/Shared/Retrieval Augmented Generation (RAG) - Version-2/' + $nameWithoutExtension + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
        #get job list
        $endPoint = $baseURL + "/api/2.0/workspace/import"
        $result = Invoke-RestMethod $endPoint `
            -ContentType 'application/json' `
            -Method Post `
            -Headers $requestHeaders `
            -Body $body
    }

    if ($file.Name -eq "3. Register and Deploy RAG model as Endpoint.ipynb") {
        $fileContent = Get-Content -Raw $file.FullName
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

        # Extract the name without extension
        $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $body = '{"content": "' + $fileContentEncoded + '",  "path": "/Workspace/Shared/Retrieval Augmented Generation (RAG) - Version-2/' + $nameWithoutExtension + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
        #get job list
        $endPoint = $baseURL + "/api/2.0/workspace/import"
        $result = Invoke-RestMethod $endPoint `
            -ContentType 'application/json' `
            -Method Post `
            -Headers $requestHeaders `
            -Body $body
    }
}
Set-Location ../../



## fecthing Volume id 

$endPoint = $baseURL + "/api/2.1/unity-catalog/volumes/cronos_unity_catalog.cdata.banking_unity_catalog"
$volume = Invoke-RestMethod $endPoint `
    -Method GET `
    -Headers $requestHeaders 

$volumestatus = if ($volume -ne $null) { "Volume have been created successfully" }Else { "Failed to create volume" }
$volumeid = $volume.volume_id
write-host $volumestatus



# # Uploading CSV to Volume

# Write-Host "Uploading CSVs to volume... "

# $destinationSasKey = New-AzStorageContainerSASToken -Container "containerdatabricksmetastore" -Context $dataLakeContext -Permission rwdl
# if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey" }
# $destinationUri = "https://$($dbdataLakeAccountName).blob.core.windows.net/containerdatabricksmetastore/metastore_root/cdataschema/__unitystorage/schemas/$($schema)/volumes/$($volumeid)/datastore$($destinationSasKey)"
# $volupload2 = & $azCopyCommand copy "https://stfsi2dpoc.blob.core.windows.net/datastore/*" $destinationUri --recursive

# $volupload2 = if ($LASTEXITCODE -eq 0) {
#     "CSVs upload to volume COMPLETE...."
# }
# else {
#     "Upload failed with exit code $LASTEXITCODE. Output: $volupload2"
# }
# write-host $volupload2

# Uploading PDs to Volume

Write-Host "Uploading PDFs to volume... "

$destinationSasKey = New-AzStorageContainerSASToken -Container "containerdatabricksmetastore" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey" }
$destinationUri1 = "https://$($dbdataLakeAccountName).blob.core.windows.net/containerdatabricksmetastore/metastore_root/cdataschema/__unitystorage/schemas/$($schema)/volumes/$($volumeid)/PDFs$($destinationSasKey)"
$volupload2 = & $azCopyCommand copy "https://stfsi2dpoc.blob.core.windows.net/pdfs/*" $destinationUri1 --recursive

$volupload2 = if ($LASTEXITCODE -eq 0) {
    "CSVs upload to volume COMPLETE...."
}
else {
    "Upload failed with exit code $LASTEXITCODE. Output: $volupload2"
}
write-host $volupload2

#Creating Jobs to run Notebooks
Write-Host "Creating Jobs to run Notebooks..."

$body = '{
  "name": "init notebook run",
  "email_notifications": {
    "no_alert_for_skipped_runs": false
  },
  "webhook_notifications": {},
  "timeout_seconds": 0,
  "max_concurrent_runs": 1,
  "tasks": [
    {
      "task_key": "first_notebook_run",
      "run_if": "ALL_SUCCESS",
      "notebook_task": {
        "notebook_path": "/Shared/Retrieval Augmented Generation (RAG) - Version-2/00-init",
        "source": "WORKSPACE"
      },
      "existing_cluster_id": "'+ $MLcluster + '",
      "timeout_seconds": 0,
      "email_notifications": {}
    }
  ]
}'

$endPoint = $baseURL + "/api/2.1/jobs/create"
$job1 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$job1status = if ($Null -ne $job1.job_id) { "Created a job for init Notebook." } else { "Failed to create a job for init Notebook." }
write-host $job1status
$job1id = $job1.job_id



$body = '{
  "name": "first notebook run",
  "email_notifications": {
    "no_alert_for_skipped_runs": false
  },
  "webhook_notifications": {},
  "timeout_seconds": 0,
  "max_concurrent_runs": 1,
  "tasks": [
    {
      "task_key": "first_notebook_run",
      "run_if": "ALL_SUCCESS",
      "notebook_task": {
        "notebook_path": "/Shared/Retrieval Augmented Generation (RAG) - Version-2/1. Create a delta table from UC volume with Autoloader",
        "source": "WORKSPACE"
      },
      "existing_cluster_id": "'+ $MLcluster + '",
      "timeout_seconds": 0,
      "email_notifications": {}
    }
  ]
}'

$endPoint = $baseURL + "/api/2.1/jobs/create"
$job2 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$job2status = if ($Null -ne $job2.job_id) { "Created a job for first Notebook." } else { "Failed to create a job for first Notebook." }
write-host $job2status
$job2id = $job2.job_id


#Create a job for second notebook
Write-Host "Creating job for second Notebook..."

$body = '{
  "name": "second notebook run",
  "email_notifications": {
    "no_alert_for_skipped_runs": false
  },
  "webhook_notifications": {},
  "timeout_seconds": 0,
  "max_concurrent_runs": 1,
  "tasks": [
    {
      "task_key": "second_notebook_run",
      "run_if": "ALL_SUCCESS",
      "notebook_task": {
        "notebook_path": "/Shared/Retrieval Augmented Generation (RAG) - Version-2/2. Ingesting and preparing PDF for LLM and Self Managed Vector Search Embeddings",
        "source": "WORKSPACE"
      },
      "existing_cluster_id": "'+ $MLcluster + '",
      "timeout_seconds": 0,
      "email_notifications": {}
    }
  ]
}'

$endPoint = $baseURL + "/api/2.1/jobs/create"
$job3 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$job3status = if ($job3.job_id -ne $null) { "Created a job for second Notebook." } else { "Failed to create a job for second Notebook." }
write-host $job3status
$job3id = $job3.job_id

#Create a job for Third notebook
Write-Host "Creating job for Third Notebook..."

$body = '{
  "name": "third notebook run",
  "email_notifications": {
    "no_alert_for_skipped_runs": false
  },
  "webhook_notifications": {},
  "timeout_seconds": 0,
  "max_concurrent_runs": 1,
  "tasks": [
    {
      "task_key": "third_notebook_run",
      "run_if": "ALL_SUCCESS",
      "notebook_task": {
        "notebook_path": "/Shared/Retrieval Augmented Generation (RAG) - Version-2/3. Register and Deploy RAG model as Endpoint",
        "source": "WORKSPACE"
      },
      "existing_cluster_id": "'+ $MLcluster + '",
      "timeout_seconds": 0,
      "email_notifications": {}
    }
  ]
}'

$endPoint = $baseURL + "/api/2.1/jobs/create"
$job4 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$job4status = if ($job4.job_id -ne $null) { "Created a job for Third Notebook." } else { "Failed to create a job for Third Notebook." }
write-host $job4status
$job4id = $job4.job_id


#Running jobs
#Running job1 
Write-Host "Running job1"

$body = '{"job_id": "' + $job1id + '"}'

$endPoint = $baseURL + "/api/2.1/jobs/run-now"
$run2 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Write-Host "Please wait while the job is ready..."
Start-Sleep -Seconds 40

#Running job2 
Write-Host "Running job2"

$body = '{"job_id": "' + $job2id + '"}'

$endPoint = $baseURL + "/api/2.1/jobs/run-now"
$run2 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Write-Host "Please wait while the job is ready..."
Start-Sleep -Seconds 100


#Running job3
Write-Host "Running job3"


$body = '{"job_id": "' + $job3id + '"}'

$endPoint = $baseURL + "/api/2.1/jobs/run-now"
$run2 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Write-Host "Please wait while the job is ready..."
Start-Sleep -Seconds 300
# $maxRetries = 3
# $retryIntervalSeconds = 300
# $clusterState = $null
# $run1 = $null

# # Loop to retrieve cluster state and check if it's "RUNNING"
# for ($i = 0; $i -lt $maxRetries; $i++) {
#     $body = '{"cluster_id": "' + $clusterId_1 + '"}'
#     $endPoint = $baseURL + "/api/2.0/clusters/get"
#     $clusterResponse = Invoke-RestMethod $endPoint `
#         -Method Post `
#         -Headers $requestHeaders `
#         -Body $body
    
#     $clusterState = $clusterResponse.state
    
#     if ($clusterState -eq "RUNNING") {
#         Write-Host "Cluster is running. Proceeding with job execution."
#         $jobBody = '{"job_id": "' + $job3id + '"}'
#         $jobEndPoint = $baseURL + "/api/2.1/jobs/run-now"
#         $run1 = Invoke-RestMethod $jobEndPoint `
#             -Method Post `
#             -Headers $requestHeaders `
#             -Body $jobBody
#         break  # Exit the loop if cluster is running
#     }
#     else {
#         Write-Host "Cluster is provisioning. Retrying in $retryIntervalSeconds seconds..."
#         Start-Sleep -Seconds $retryIntervalSeconds
#     }
# }

# if ($i -eq $maxRetries) {
#     Write-Host "Max retries reached. Cluster is still not running."
# }
# else {
#     Start-Sleep -Seconds 300
    
#     # Stop job3
#     Write-Host "Stopping job3"

#     if ($run1 -ne $null) {
#         $body = '{"run_id": "' + $run1.run_id + '"}'
#         $endPoint = $baseURL + "/api/2.1/jobs/runs/cancel"
#         $run1 = Invoke-RestMethod $endPoint `
#             -Method Post `
#             -Headers $requestHeaders `
#             -Body $body
#         Write-Host "Job3 stopped successfully."
#     }
#     else {
#         Write-Host "Error: Failed to stop job3, please stop the job manually."
#     }
# }

## Creating Endpoint
Write-Host "creating Endpoint..."
$body = '{
  "name": "vector_search_endpoint",
  "endpoint_type": "STANDARD"
}'


$endPoint = $baseURL + "/api/2.0/vector-search/endpoints"
$endpoint_vector = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$endpoint_vector = if ($endpoint_vector -ne $null) { "Endpoint have been created successfully." } else { "Failed to create an Endpoint for vector index." }
Write-Host $endpoint_vector

write-host "creating Keyvault backed secret scope..."

pip install databricks-cli --user

# Set environment variables for Databricks CLI
$databricksHost = 'https://' + $workspaceUrl 

# Run Azure CLI command to get AAD token
$tokenResponse = az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken -o json | ConvertFrom-Json

# Extract the access token
$aadToken = $tokenResponse

# Set the AAD token as an environment variable
$env:DATABRICKS_AAD_TOKEN = $aadToken

databricks configure --aad-token --host $databricksHost 

# Define Key Vault details
$keyVaultResourceId = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
$keyVaultDnsName = "https://$keyVaultName.vault.azure.net/"

# Define the scope name
$scopeName = "databricksscope"

# Run the Databricks CLI command to create the Key Vault-backed secret scope
$createScopeCommand = @"
databricks secrets create-scope --scope $scopeName --scope-backend-type AZURE_KEYVAULT --resource-id $keyVaultResourceId --dns-name $keyVaultDnsName
"@
Invoke-Expression $createScopeCommand

$Secscope = if ($createScopeCommand -ne $null) { "Secret scope have been created successfully." } else { "Failed to create secret scope." }
Write-Host $Secscope


## creating Vector index
Write-Host "Creating vector index..."

$body = '{
  "name": "cronos_unity_catalog.cdata.vector_search_index",
  "endpoint_name": "vector_search_endpoint",
  "primary_key": "id",
  "index_type": "DELTA_SYNC",
  "delta_sync_index_spec": {
    "source_table": "cronos_unity_catalog.cdata.documents_embedding",
    "pipeline_type": "TRIGGERED",
    "embedding_source_columns": [
      {
        "name": "content",
        "embedding_model_endpoint_name": "databricks-bge-large-en"
      }
    ]
  }
}'


$endPoint = $baseURL + "/api/2.0/vector-search/indexes"
$Vectorindex = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$Vectorindex = if ($Vectorindex -ne $null) { "Vector Index have been created successfully." } else { "Failed to create vector index." }

Write-Host $Vectorindex

Start-Sleep -Seconds 1200
#Running job4 
Write-Host "Running job4"

$body = '{"job_id": "' + $job4id + '"}'

$endPoint = $baseURL + "/api/2.1/jobs/run-now"
$run2 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

Write-Host "Please wait while the job is ready..."


###Azure Databricks End here##




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

$appJson = az ad sp list --display-name "$mssql_server_name" --query '[0]' --output json
$app = $appJson | ConvertFrom-Json
if (-not $app) {
    Write-Error "Service principal '$mssql_server_name' not found."
    
}
$principalId = $app.id
 
$body = @{
    principal = @{
        id   = "$principalId"
        type = "ServicePrincipal"
    }
    role      = "Member"
} | ConvertTo-Json

 
# Now you can use $body in your PowerShell script where needed
Write-Output $body
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/roleAssignments"
 
# Define the headers
$headers = @{
    Authorization  = "Bearer $fabric"
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



