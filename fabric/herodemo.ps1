
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "I accept the license agreement."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "I do not accept and wish to stop execution."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$title = "Agreement"
$message = "By typing [Y], I hereby confirm that I have read the license ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/license.md ) and disclaimers ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/README.md ) and hereby accept the terms of the license and agree that the terms and conditions set forth therein govern my use of the code made available hereunder. (Type [Y] for Yes or [N] for No and press enter)"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
if ($result -eq 1) {
write-host "Thank you. Please ensure you delete the resources created with template to avoid further cost implications."
}
else 
{
function RefreshTokens()
{
#Copy external blob content
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

Write-Host "------------Prerequisites------------"
Write-Host "-An Azure Account with the ability to create Fabric Workspace."
Write-Host "-A Power BI with Fabric License to host Power BI reports."
Write-Host "-Make sure the user deploying the script has atleast a 'Contributor' level of access on the 'Subscription' on which it is being deployed."
Write-Host "-Make sure your Power BI administrator can provide service principal access on your Power BI tenant."
Write-Host "-Make sure to register the following resource providers with your Azure Subscription:"
Write-Host "-Microsoft.Fabric"
Write-Host "-Microsoft.EventHub"
Write-Host "-Microsoft.SQLSever"
Write-Host "-Microsoft.StorageAccount"
Write-Host "-Microsoft.AppService"
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
# #download azcopy command
# if ([System.Environment]::OSVersion.Platform -eq "Unix") {
# $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-linux"

# if (!$azCopyLink) {
# $azCopyLink = "https://azcopyvnext.azureedge.net/release20200709/azcopy_linux_amd64_10.5.0.tar.gz"
# }

# Invoke-WebRequest $azCopyLink -OutFile "azCopy.tar.gz"
# tar -xf "azCopy.tar.gz"
# $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy).Directory.FullName

# if ($azCopyCommand.count -gt 1) {
# $azCopyCommand = $azCopyCommand[0];
# }

# cd $azCopyCommand
# chmod +x azcopy
# cd ..
# $azCopyCommand += "\azcopy"
# } else {
# $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

# if (!$azCopyLink) {
# $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
# }

# Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
# Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
# $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName

# if ($azCopyCommand.count -gt 1) {
# $azCopyCommand = $azCopyCommand[0];
# }

# $azCopyCommand += "\azcopy"
# }


# $tenantId = (Get-AzContext).Tenant.Id
# azcopy login --tenant-id $tenantId

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
$rgName = "rg-herodemos-dpoc-$suffix"
# Deployment Region
$Region = Read-Host "Enter the region for deployment"

# Context info (optional if not used in template)
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId       = (Get-AzContext).Tenant.Id
$purviewaccountName = "purviewaccount-$suffix"
# Core resources
$storage_account_name = "storage$suffix"
$mssql_server_name    = "mssql$suffix"
$mssql_database_name  = "sql-azurehero-demo"
$mssql_administrator_login = "labsqladmin"

# Cosmos DB
$cosmosMongoAccountName = "cosmos-mongo-herodemo-$suffix"
$cosmosdb_account       = "cosmosdb-herodemo-$suffix"

# App Service + Server Farm
$serverfarm_asp_fabric_name = "asp-fabric-$suffix"
$app_fabric_name            = "app-fabric-$suffix"

# Databricks
$databricks_workspace_name               = "adb-fabric-$suffix"
$databricks_managed_resource_group_name  = "rg-managed-adb-$suffix"
$userAssignedIdentities_ami_databricks_build = "ami-databricks-$suffix"
$databricksconnector = "access-adb-connector-$suffix"


# Data Lake
$datalake_account_name = "stherodemoadb$suffix"

# Key Vault
$vaults_kv_databricks_prod_name = "kv-adb-$suffix"
$containerName = "containerdatabricksmetastore"

# SQL Admin password (validated with complexity rules)
$sql_administrator_login_password = ""
$complexPassword = 0
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



$wsIdZava =  Read-Host "Enter your 'Zava' PowerBI workspace Id "

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdZava";
$ZavaWsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$ZavaWsName = $ZavaWsName.name


$lakehouseBronze =  "lakehouseBronze_$suffix"
$lakehouseSilver =  "lakehouseSilver_$suffix"
$lakehouseGold =  "lakehouseGold_$suffix"
$lakehouseai =  "lakehouseAI_$suffix"
Add-Content log.txt "------FABRIC assets deployment STARTS HERE------"
Write-Host "------------FABRIC assets deployment STARTS HERE------------"

Add-Content log.txt "------Creating Lakehouses in '$ZavaWsName' workspace------"
Write-Host "------Creating Lakehouses in '$ZavaWsName' workspace------"
$lakehouseNames = @($lakehouseBronze, $lakehouseSilver, $lakehouseGold)
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

$createUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/items"
    
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
Add-Content log.txt "------Creation of Lakehouses in '$ZavaWsName' workspace COMPLETED------"
Write-Host "-----Creation of Lakehouses in '$ZavaWsName' workspace COMPLETED------"

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/lakehouses"
$Lakehouse = Invoke-RestMethod $endPoint `
-Method GET `
-Headers $requestHeaders

$LakehouseBronzeid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseBronze" }).id

$LakehouseSilverid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseSilver" }).id

$LakehouseGoldid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseGold" }).id

Write-Output "Bronze Lakehouse ID: $LakehouseBronzeid"

Write-Output "Silver Lakehouse ID: $LakehouseSilverid"

Write-Output "Gold Lakehouse ID: $LakehouseGoldid"

RefreshTokens

$url = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/lakehouses/$LakehouseSilverid";
$LakehouseSilverdetails = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $fabric" };

$SilverServerName = $LakehouseSilverdetails.properties.sqlEndpointProperties.connectionString

Add-Content log.txt "------Uploading assets to Lakehouses------"
Write-Host "------------Uploading assets to Lakehouses------------"



$spname = "Azure Hero Demo $suffix"

$app = az ad app create --display-name $spname | ConvertFrom-Json
$appId = $app.appId

$mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$clientsecpwdapp = $mainAppCredential.password

az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "id" -o tsv
start-sleep -s 15

$tenantId = az account show --query tenantId -o tsv
Write-Host "Tenant ID: $tenantId"

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
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdZava/users";
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

pip install --user --upgrade pip setuptools
pip install --user packaging  # Packaging is required by ansible-core
pip install --user cryptography
pip install --user ms-fabric-cli


fab config set encryption_fallback_enabled true
fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$salesworkspacePath = "$ZavaWsName.Workspace"

# 3. Pass it to `fab cd`

fab mkdir "$salesworkspacePath/$lakehouseai.Lakehouse"

Write-Host "-----------Creation of Eventstream Started------------"

$eventStreamName = "ThermostatEventStream_$suffix"
$eventStreamPath = "$salesworkspacePath/$eventStreamName.eventstream"

fab mkdir $eventStreamPath

$eventStreamName1 = "Eventstream_foottraffic_$suffix"
$eventStreamPath1 = "$salesworkspacePath/$eventStreamName1.eventstream"

fab mkdir $eventStreamPath1

$eventStreamName2 = "Eventstream_Inventory_$suffix"
$eventStreamPath2 = "$salesworkspacePath/$eventStreamName2.eventstream"

fab mkdir $eventStreamPath2

Write-Host "-----------Creation of Eventstream COMPLETED------------"

Write-Host "------Creating Eventhouse------"
$KQLDB = "Zava-Eventhouse"
fab mkdir $salesworkspacePath/$KQLDB.eventhouse

Write-Host "------Creating Eventhouse completed------"

Write-Host "------Creating Queryset------"
$Queryset = "thermostat"

fab mkdir $salesworkspacePath/$Queryset.KQLQueryset

Write-Host "------Creating Queryset completed------"


Write-Host "------Creating SQLdatabase------"
$SQLDB = "SQL_DB"
fab mkdir $salesworkspacePath/$SQLDB.sqldatabase

Write-Host "-----------Creation of Warehouse------------"

$warehousename = "DataWarehouse_$suffix"
fab mkdir $salesworkspacePath/$warehousename.warehouse

Write-Host "-----------Creation of Warehouse COMPLETED------------"

Write-Host "------Creating Schema in lakehouse bronze completed------"



RefreshTokens
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/lakehouses"
$Lakehouse = Invoke-RestMethod $endPoint `
-Method GET `
-Headers $requestHeaders

$LakehouseAIid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseai" }).id

## notebooks
Add-Content log.txt "-----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses-----"
Write-Host "----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses----"



(Get-Content -path "artifacts/fabricnotebooks/03 Silver to Gold layer Medallion Architecture.ipynb" -Raw) | Foreach-Object { $_ `
-replace '#LAKEHOUSE_GOLD#', $lakehouseGold `
} | Set-Content -Path "artifacts/fabricnotebooks/03 Silver to Gold layer Medallion Architecture.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/Segment customer and Incorporate discount.ipynb" -Raw) | Foreach-Object { $_ `
-replace '#Lakehouse_Silver#', $lakehouseSilver `
} | Set-Content -Path "artifacts/fabricnotebooks/Segment customer and Incorporate discount.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/01 Marketing Data to Lakehouse (Bronze) - Code-First Experience.ipynb" -Raw) | Foreach-Object { $_ `
-replace '#wsId#', $wsIdZava `
-replace '#Lakehouse_Bronze#', $lakehouseBronze `
} | Set-Content -Path "artifacts/fabricnotebooks/01 Marketing Data to Lakehouse (Bronze) - Code-First Experience.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/Segment customer and Incorporate discount.ipynb" -Raw) | Foreach-Object { $_ `
-replace '#Lakehouse_Silver#', $lakehouseSilver `
-replace '#$wsId#', $wsIdZava `
-replace '#Lakehouse_Bronze#', $lakehouseBronze `
} | Set-Content -Path "artifacts/fabricnotebooks/02 Bronze to Silver layer Medallion Architecture.ipynb"


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
if ($name -eq "FootTraffic_RealtimeData.ipynb" -or
$name -eq "01 Data Wrangler Notebook.ipynb" -or
$name -eq "03 Silver to Gold layer Medallion Architecture.ipynb") {

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

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/items/"

$Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

Write-Host "Notebook uploaded: $name"
} elseif ($name -eq "Generate realtime thermostat data.ipynb" -or
$name -eq "real-time paint accessory inventory data.ipynb" -or 
$name -eq "CreateSchema.ipynb") {

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

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/items/"
$Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

Write-Host "Notebook uploaded: $name"
} elseif ($name -eq "01 Copilot Notebook for Data Science.ipynb" -or
$name -eq "02 Churn Prediction using MLFlow.ipynb" -or 
$name -eq "Segment customer and Incorporate discount.ipynb") {

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

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/items/"
$Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

Write-Host "Notebook uploaded: $name"
}
elseif ($name -eq "01 Marketing Data to Lakehouse (Bronze) - Code-First Experience.ipynb" -or
$name -eq "02 Bronze to Silver layer Medallion Architecture.ipynb" ) {

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

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/items/"
$Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

Write-Host "Notebook uploaded: $name"
}

}
Add-Content log.txt "-----Uploading Notebooks COMPLETED-----"
Write-Host "-----Uploading Notebooks COMPLETED-----"

cd..
cd..

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath1 = "$salesworkspacePath/CreateSchema.ipynb.Notebook"

# Build the JSON input string
$jsonInput1 = @{
known_lakehouses = @(@{ id = $LakehouseBronzeid })
default_lakehouse = $LakehouseBronzeid
default_lakehouse_name = $lakehouseBronze
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath1" -q lakehouse -i $jsonInput1 -f

fab job run "$salesworkspacePath/CreateSchema.ipynb.Notebook"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath2 = "$salesworkspacePath/01 Copilot Notebook for Data Science.ipynb.Notebook"

# Build the JSON input string
$jsonInput2 = @{
known_lakehouses = @(@{ id = $LakehouseAIid })
default_lakehouse = $LakehouseAIid
default_lakehouse_name = $lakehouseai
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath2" -q lakehouse -i $jsonInput2 -f

$notebookPath01 = "$salesworkspacePath/01 Marketing Data to Lakehouse (Bronze) - Code-First Experience.ipynb.Notebook"

# Build the JSON input string
$jsonInput01 = @{
known_lakehouses = @(@{ id = $LakehouseBronzeid })
default_lakehouse = $LakehouseBronzeid
default_lakehouse_name = $lakehouseBronze
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath01" -q lakehouse -i $jsonInput01 -f

$notebookPath02 = "$salesworkspacePath/02 Bronze to Silver layer Medallion Architecture.ipynb.Notebook"

# Build the JSON input string
$jsonInput02 = @{
known_lakehouses = @(@{ id = $LakehouseBronzeid })
default_lakehouse = $LakehouseBronzeid
default_lakehouse_name = $lakehouseBronze
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath02" -q lakehouse -i $jsonInput02 -f

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath3 = "$salesworkspacePath/02 Churn Prediction using MLFlow.ipynb.Notebook"

# Build the JSON input string
$jsonInput3 = @{
known_lakehouses = @(@{ id = $LakehouseSilverid })
default_lakehouse = $LakehouseSilverid
default_lakehouse_name = $lakehouseSilver
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath3" -q lakehouse -i $jsonInput3 -f

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath4 = "$salesworkspacePath/Segment customer and Incorporate discount.ipynb.Notebook"

# Build the JSON input string
$jsonInput4 = @{
known_lakehouses = @(@{ id = $LakehouseSilverid })
default_lakehouse = $LakehouseSilverid
default_lakehouse_name = $lakehouseSilver
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath4" -q lakehouse -i $jsonInput4 -f

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath5 = "$salesworkspacePath/01 Data Wrangler Notebook.ipynb.Notebook"

# Build the JSON input string
$jsonInput5 = @{
known_lakehouses = @(@{ id = $LakehouseBronzeid })
default_lakehouse = $LakehouseBronzeid
default_lakehouse_name = $lakehouseBronze
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath5" -q lakehouse -i $jsonInput5 -f


fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath6 = "$salesworkspacePath/Generate realtime thermostat data.ipynb.Notebook"

# Build the JSON input string
$jsonInput6 = @{
known_lakehouses = @(@{ id = $LakehouseBronzeid })
default_lakehouse = $LakehouseBronzeid
default_lakehouse_name = $lakehouseBronze
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath6" -q lakehouse -i $jsonInput6 -f


fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath7 = "$salesworkspacePath/real-time paint accessory inventory data.ipynb.Notebook"

# Build the JSON input string
$jsonInput7 = @{
known_lakehouses = @(@{ id = $LakehouseBronzeid })
default_lakehouse = $LakehouseBronzeid
default_lakehouse_name = $lakehouseBronze
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath7" -q lakehouse -i $jsonInput7 -f


fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath8 = "$salesworkspacePath/FootTraffic_RealtimeData.ipynb.Notebook"

# Build the JSON input string
$jsonInput8 = @{
known_lakehouses = @(@{ id = $LakehouseBronzeid })
default_lakehouse = $LakehouseBronzeid
default_lakehouse_name = $lakehouseBronze
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath8" -q lakehouse -i $jsonInput8 -f




Add-Content log.txt "------Uploading assets to Lakehouses------"
Write-Host "------------Uploading assets to Lakehouses------------"
$tenantId = (Get-AzContext).Tenant.Id
azcopy login --tenant-id $tenantId

azcopy copy "https://stherodemodpoc.blob.core.windows.net/lakehousebronzefiles/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseBronze.Lakehouse/Files/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stherodemodpoc.blob.core.windows.net/lakehousebronzetables/aws/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseBronze.Lakehouse/Tables/AWS" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stherodemodpoc.blob.core.windows.net/lakehousebronzetables/sqldb/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseBronze.Lakehouse/Tables/sqldb" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stherodemodpoc.blob.core.windows.net/lakehousebronzetables/cosmosDb/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseBronze.Lakehouse/Tables/cosmosDb" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stherodemodpoc.blob.core.windows.net/lakehousebronzetables/azuresql/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseBronze.Lakehouse/Tables/azuresql" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stherodemodpoc.blob.core.windows.net/lakehousebronzetables/copilotnotebook/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseai.Lakehouse/Tables/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stherodemodpoc.blob.core.windows.net/lakehousebronzetables/dbo/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseBronze.Lakehouse/Tables/dbo" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;


azcopy copy "https://stherodemodpoc.blob.core.windows.net/silverlakehousetables/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseSilver.Lakehouse/Tables/dbo" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stherodemodpoc.blob.core.windows.net/lakehousegoldtables/*" "https://onelake.blob.fabric.microsoft.com/$ZavaWsName/$lakehouseGold.Lakehouse/Tables/dbo" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;


Add-Content log.txt "------Uploading assets to Lakehouses COMPLETED------"
Write-Host "------------Uploading assets to Lakehouses COMPLETED------------"

Add-Content log.txt "------Creating Shortcuts in Lakehouse Gold------"
write-Host "------------Creating Shortcuts in Lakehouse Gold------------"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

fab job run "$salesworkspacePath/Segment customer and Incorporate discount.ipynb.Notebook"

# Internal shortcut in Azure Herodemos:

# Define lakehouse paths
$goldLakehouse = "$salesworkspacePath/$lakehouseGold.Lakehouse/Tables"
$silverLakehouse = "$salesworkspacePath/$lakehouseSilver.Lakehouse/Tables"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

# Tables to shortcut
$tables = @(
"dimension_date",
"dimension_product",
"dimension_customer"
)

# Create internal shortcuts

foreach ($table in $tables) {
Write-Host "Creating Shortcut for $table"

$shortcutPath = "$goldLakehouse/dbo/$table.Shortcut"
$targetPath = "$silverLakehouse/dbo/$table"

fab ln $shortcutPath --type oneLake --target $targetPath
Write-Host "✅ Shortcut created: $table"
} 

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath2 = "$salesworkspacePath/03 Silver to Gold layer Medallion Architecture.ipynb.Notebook"

# Build the JSON input string
$jsonInput2 = @{
known_lakehouses = @(@{ id = $LakehouseGoldId })
default_lakehouse = $LakehouseGoldId
default_lakehouse_name = $lakehouseGold
default_lakehouse_workspace_id = $wsIdZava
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath2" -q lakehouse -i $jsonInput2 -f

fab job run "$salesworkspacePath/03 Silver to Gold layer Medallion Architecture.ipynb.Notebook"

Add-Content log.txt "------Creating Shortcuts in Lakehouse Gold COMPLETED------"

write-Host "------Creating Shortcuts in Lakehouse Gold COMPLETED------"

Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
Write-Host "Resource group $rgName creation COMPLETE"

Write-Host "Deploying resources in $rgName..."

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-TemplateFile "mainTemplate.json" `
-Mode Complete `
-location $Region `
-purviewAccountName $purviewaccountName `
-cosmosdb_account $cosmosdb_account `
-cosmosMongoAccountName $cosmosMongoAccountName `
-storage_account_name $storage_account_name `
-mssql_server_name $mssql_server_name `
-mssql_database_name $mssql_database_name `
-mssql_administrator_login $mssql_administrator_login `
-sql_administrator_login_password $sql_administrator_login_password `
-databricks_workspace_name $databricks_workspace_name `
-databricks_managed_resource_group_name $databricks_managed_resource_group_name `
-userAssignedIdentities_ami_databricks_build $userAssignedIdentities_ami_databricks_build `
-datalake_account_name $datalake_account_name `
-vaults_kv_databricks_prod_name $vaults_kv_databricks_prod_name `
-serverfarm_asp_fabric_name $serverfarm_asp_fabric_name `
-app_fabric_name $app_fabric_name `
-Force


Write-Host "Resource creation in $rgName resource group COMPLETE"

Add-Content log.txt "------Copying assets to the Storage Account------"
Write-Host "------------Copying assets to the Storage Account------------"

## storage AZ Copy
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storage_account_name)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_account_key

$destinationSasKey = New-AzStorageContainerSASToken -Container "aws-operations-data" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/aws-operations-data$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stherodemodpoc.blob.core.windows.net/aws-operations-data/" $destinationUri --recursive

Write-Host "aws-operations-data copied"

$destinationSasKey = New-AzStorageContainerSASToken -Container "sales-transaction-data" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/sales-transaction-data$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stherodemodpoc.blob.core.windows.net/sales-transaction/" $destinationUri --recursive

Write-Host "sales-transaction-data copied"

$destinationSasKey = New-AzStorageContainerSASToken -Container "databricks" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/databricks$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stherodemodpoc.blob.core.windows.net/databricks/" $destinationUri --recursive

Write-Host "databricks copied"

$destinationSasKey = New-AzStorageContainerSASToken -Container "datawarehouse" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/datawarehouse$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stherodemodpoc.blob.core.windows.net/datawarehouse/" $destinationUri --recursive

Write-Host "datawarehouse-data copied"

$destinationSasKey = New-AzStorageContainerSASToken -Container "herodemos" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/herodemos$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stherodemodpoc.blob.core.windows.net/herodemos/" $destinationUri --recursive

Write-Host "herodemos copied"

$destinationSasKey = New-AzStorageContainerSASToken -Container "cog-search-product-images" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/cog-search-product-images$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stherodemodpoc.blob.core.windows.net/cog-search-product-images/" $destinationUri --recursive

Write-Host "cog-search-product-images-data copied"

Add-Content log.txt "------Copying assets to the Storage Account COMPLETED------"
Write-Host "------------Copying assets to the Storage Account COMPLETED------------"

##Assigning SP as Storage Blob Data Contributor
Add-Content log.txt "------Assigning SP as Storage Blob Data Contributor------"

az role assignment create --assignee $appId --role "Storage Blob Data Contributor" --scope "/subscriptions/$subscriptionId/resourceGroups/$rgname"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

# Creating ADLSGen2 shortcuts
$connectionName = ".connections/salestransaction$suffix.Connection"
$serverUrl = "https://$storage_account_name.dfs.core.windows.net"
$path = "sales-transaction-data"

# Build param string
$params = @(
    "connectionDetails.type=AzureDataLakeStorage",
    "connectionDetails.parameters.server=$serverUrl",
    "connectionDetails.parameters.path=$path",
    "credentialDetails.type=ServicePrincipal",
    "credentialDetails.servicePrincipalClientId=$appId",
    "credentialDetails.servicePrincipalSecret=$clientsecpwdapp",
    "credentialDetails.tenantId=$tenantId",
    "privacyLevel=Organizational"
) -join ","

# Final command
fab create $connectionName -P $params

$connectionId = (fab ls .connections -l | Where-Object { $_ -match "salestransaction$suffix.Connection" } | ForEach-Object { ($_ -split '\s+')[1] })
$BronzeLakehousepath = "$salesworkspacePath/$lakehouseBronze.Lakehouse/Files"
$shortcutPath = "$BronzeLakehousepath/sales-transaction.shortcut"
$jsonInput = @{
    location = "https://$storage_account_name.dfs.core.windows.net/"
    subpath = "sales-transaction-data"
    connectionId = $connectionId
} | ConvertTo-Json -Compress

fab ln $shortcutPath --type adlsGen2 -i $jsonInput

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$connectionName2 = ".connections/aws$suffix.Connection"
$serverUrl = "https://$storage_account_name.dfs.core.windows.net"
$path2 = "aws-operations-data"

# Build param string
$params2 = @(
    "connectionDetails.type=AzureDataLakeStorage",
    "connectionDetails.parameters.server=$serverUrl",
    "connectionDetails.parameters.path=$path2",
    "credentialDetails.type=ServicePrincipal",
    "credentialDetails.servicePrincipalClientId=$appId",
    "credentialDetails.servicePrincipalSecret=$clientsecpwdapp",
    "credentialDetails.tenantId=$tenantId",
    "privacyLevel=Organizational"
) -join ","

# Final command
fab create $connectionName2 -P $params2

$connectionId2 = (fab ls .connections -l | Where-Object { $_ -match "aws$suffix.Connection" } | ForEach-Object { ($_ -split '\s+')[1] })
$BronzeLakehousepath = "$salesworkspacePath/$lakehouseBronze.Lakehouse/Files"
$shortcutPath2 = "$BronzeLakehousepath/aws-operations-data.shortcut"
$jsonInput2 = @{
    location = "https://$storage_account_name.dfs.core.windows.net/"
    subpath = "aws-operations-data"
    connectionId = $connectionId2
} | ConvertTo-Json -Compress

fab ln $shortcutPath2 --type adlsGen2 -i $jsonInput2


### SQL
Add-Content log.txt "------Copying assets to the Azure SQL Server------"
Write-Host "------------Copying assets to the Azure SQL Server------------"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/azureherodemoSqlDbScript.sql"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_database_name -Username $mssql_administrator_login -Password $sql_administrator_login_password
Add-Content log.txt $result
Add-Content log.txt "------Copying assets to the Azure SQL Server COMPLETED------"
Write-Host "------------Copying assets to the Azure SQL Server COMPLETED------------"

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
$assignment1 = az role assignment create --role "Key Vault Reader" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName/providers/Microsoft.KeyVault/vaults/$vaults_kv_databricks_prod_name
$assignment2 = az role assignment create --role "Storage Blob Data Contributor" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName/providers/Microsoft.Storage/storageAccounts/$datalake_account_name
$asssignment3 = az role assignment create --role "Contributor" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName
$asssignment4 = az keyvault set-policy --name $vaults_kv_databricks_prod_name --upn $signedinusername --secret-permissions set list get

$roleassigments = If ($assignment1, $assignment2, $assignment3, $asssignment4 -ne $null) { "Role assignment COMPLETE..." } Else { "Role assignment Failed" }
write-host $roleassigments

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $datalake_account_name)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $datalake_account_name -StorageAccountKey $storage_account_key

$filesystemName = "containerdatabricksmetastore"
$dirname = "metastore_root/"
$directory = New-AzDataLakeGen2Item -Context $dataLakeContext -FileSystem $filesystemName -Path $dirname -Directory

$dir = if ($directory -ne $null) { "created container named containerdatabricksmetastore" } Else { "failed to create container containerdatabricksmetastore" }
write-host $dir 

$connectionString = (Get-AzStorageAccount -ResourceGroupName $rgName -Name $datalake_account_name).Context.ConnectionString

## Create Directory in ADLS Gen2
az storage fs directory create -n metastore_root/catalog -f "containerdatabricksmetastore" --connection-string $connectionstring
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
# $token_response = $(az account get-access-token --resource https://management.core.windows.net/ --output json) | ConvertFrom-Json
# $azToken = $token_response.accessToken

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
$secret = az keyvault secret set --name "databricks-token" --value $pat_token --vault-name $vaults_kv_databricks_prod_name

# creating personal compute

$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}

# to create a new cluster
Write-Host "Creating CLUSTERS in Azure Databricks..."


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
"storage_root": "abfss://'+ $containerName + '@' + $datalake_account_name + '.dfs.core.windows.net/metastore_root",
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
"url": "abfss://'+ $containerName + '@' + $datalake_account_name + '.dfs.core.windows.net/metastore_root",
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

Write-Host "Creating Azure SQL Connection in workspace..."

$workspaceBaseUrl = "https://$workspaceUrl"

$connectionName = "azuresql_conn"
$sqlServer = "$mssql_server_name.database.windows.net"
$sqlUser = "$mssql_administrator_login"
$sqlPassword = "$sql_administrator_login_password"

$body = '{
"name": "' + $connectionName + '",
"connection_type": "SQLSERVER",
"options": {
    "host": "' + $sqlServer + '",
    "port": "1433",
    "trustServerCertificate": "false",
    "user": "' + $sqlUser + '",
    "password": "' + $sqlPassword + '",
    "applicationIntent": "ReadWrite"
}
}'

$endPoint = $workspaceBaseUrl + "/api/2.1/unity-catalog/connections"

$newConnection = Invoke-RestMethod $endPoint `
-Method Post `
-Headers $requestHeaders `
-Body $body `
-ContentType "application/json"

if ($newConnection.connection_id -ne $Null) {
Write-Host "✅ Workspace-level Azure SQL connection created successfully."
} else {
Write-Host "❌ Failed to create workspace-level connection."
}

##  Creting Unity catalog using External COnnection


$catalogName = "sql_catalog"                                  # Desired Catalog Name
$externalConnectionName = "azuresql_conn"           # Name of the existing external connection
$comment = "Catalog created using external connection"
$databaseName = "$mssql_database_name"

# ==============================
# API Endpoint
# ==============================
$uri = "$baseURL/api/2.1/unity-catalog/catalogs"

$body = @{
    name = $catalogName
    connection_name = $externalConnectionName
    comment = $comment
    options = @{
        database = $databaseName
    }
} | ConvertTo-Json -Depth 3



$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $requestHeaders -Body $body

# Output result
$response

## creating Unity Catalog
Write-Host "Creating Unity Catalog..."

$body = 
'{
"name": "herodemo_unity_catalog",
"comment": "none",
"properties": {},
"storage_root": "abfss://'+ $containerName + '@' + $datalake_account_name + '.dfs.core.windows.net/metastore_root/catalog"
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
"name": "herodemo",
"catalog_name": "herodemo_unity_catalog",
"comment": "schema",
"properties": {
},
"storage_root": "abfss://'+ $containerName + '@' + $datalake_account_name + '.dfs.core.windows.net/metastore_root/herodemoschema"
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
RefreshTokens
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}
$maxRetries = 3
$retryIntervalSeconds = 2

for ($i = 0; $i -lt $maxRetries; $i++) {

$body = '{
"catalog_name": "herodemo_unity_catalog",
"schema_name": "herodemo",
"name": "documents_store",
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

$endPoint = $baseURL + "/api/2.0/fs/directories/Volumes/herodemo_unity_catalog/herodemo/documents_store/PDFs"
$volume = Invoke-RestMethod $endPoint `
-Method PUT `
-Headers $requestHeaders 

$endPoint = $baseURL + "/api/2.0/fs/directories/Volumes/herodemo_unity_catalog/herodemo/documents_store/MktData"
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
}
Set-Location ../../



## fecthing Volume id 

$endPoint = $baseURL + "/api/2.1/unity-catalog/volumes/herodemo_unity_catalog.herodemo.documents_store"
$volume = Invoke-RestMethod $endPoint `
-Method GET `
-Headers $requestHeaders 

$volumestatus = if ($volume -ne $null) { "Volume have been created successfully" }Else { "Failed to create volume" }
$volumeid = $volume.volume_id
write-host $volumestatus


Write-Host "Uploading PDFs to volume... "

$destinationSasKey = New-AzStorageContainerSASToken -Container "containerdatabricksmetastore" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey" }

$destinationUri1 = "https://$($datalake_account_name).blob.core.windows.net/containerdatabricksmetastore/metastore_root/herodemoschema/__unitystorage/schemas/$($schema)/volumes/$($volumeid)/PDFs$($destinationSasKey)"
$volupload1 = azcopy copy "https://stherodemodpoc.blob.core.windows.net/databricks/pdfs/*" $destinationUri1 --recursive
# $volupload1 = azcopy copy "https://stherodemodpoc.blob.core.windows.net/databricks/pdfs/*" $destinationUri1 --recursive

$destinationUri2 = "https://$($datalake_account_name).blob.core.windows.net/containerdatabricksmetastore/metastore_root/herodemoschema/__unitystorage/schemas/$($schema)/volumes/$($volumeid)/MktData$($destinationSasKey)"
$volupload2 = azcopy copy "https://stherodemodpoc.blob.core.windows.net/databricks/mkdata/*" $destinationUri2 --recursive

$volupload2 = if ($LASTEXITCODE -eq 0) {
"CSVs upload to volume COMPLETE...."
}
else {
"Upload failed with exit code $LASTEXITCODE. Output: $volupload2"
}
write-host $volupload2
### creating DTL Pipeline

$pipelineBody = @{
    name          = "DTL Pipeline"
    pipeline_type = "WORKSPACE"
    catalog       = "herodemo_unity_catalog"
    schema        = "herodemo"
    continuous    = $false
    development   = $true
    photon        = $false
    edition       = "ADVANCED"
    channel       = "CURRENT"
    clusters      = @(
        @{
            label    = "default"
            autoscale = @{
                min_workers = 1
                max_workers = 5
                mode        = "ENHANCED"
            }
        }
    )
    libraries = @(
        @{
            notebook = @{
                path = "/Shared/Analytics with ADB/01 DLT Notebook"
            }
        }
    )
}

# Convert to JSON
$bodyJson = $pipelineBody | ConvertTo-Json -Depth 10 -Compress

# API endpoint
$createPipelineUrl = "$baseurl/api/2.0/pipelines"

Write-Host "🚀 Creating Databricks Pipeline..."

$response = Invoke-RestMethod -Uri $createPipelineUrl `
                            -Method Post `
                            -Headers $requestHeaders `
                            -Body $bodyJson

if ($response.pipeline_id) {
    Write-Host "✅ Pipeline created successfully. Pipeline ID:" $response.pipeline_id
} else {
    Write-Host "❌ Failed to create pipeline. Response:" ($response | ConvertTo-Json -Depth 5)
}

$pipelineId = $($response.pipeline_id)
$startPipelineUrl = "$baseURL/api/2.0/pipelines/$pipelineId/updates"

# Body (empty or with options)
$bodyJson = @{
    full_refresh = $true   # set to $false if you don’t want full refresh
} | ConvertTo-Json -Compress

Write-Host "🚀 Starting Databricks DLT Pipeline..."

$response = Invoke-RestMethod -Uri $startPipelineUrl `
                            -Method Post `
                            -Headers $requestHeaders `
                            -Body $bodyJson

if ($response.update_id) {
    Write-Host "✅ Pipeline started successfully. Update ID:" $response.update_id
} else {
    Write-Host "❌ Failed to start pipeline. Response:" ($response | ConvertTo-Json -Depth 5)
}


####



#Adding tags
$tags = @{
"wsIdZava" = $wsIdZava
}
Set-AzResourceGroup -ResourceGroupName $rgName -Tag $tags

#### webapp

    $BlobBaseUrl = "https://$($storage_account_name).blob.core.windows.net/herodemos/"
    $IconBlobBaseUrl = "https://$($storage_account_name).blob.core.windows.net/herodemos/"
    $PersonaBlobURL = "https://$($storage_account_name).blob.core.windows.net/herodemos/"

expand-archive -path "./artifacts/binaries/herodemosdpocbuild.zip" -destinationpath "./herodemosdpocbuild" -force

$filepath = "./herodemosdpocbuild/wwwroot/environment.js"
$itemTemplate = Get-Content -Path $filepath


$item = $itemTemplate.Replace("#stherodemodpoc#", $storage_account_name).Replace("#IconBlobBaseUrl#", $IconBlobBaseUrl).Replace("#personaUrl#", $PersonaBlobURL).Replace("#BackendURL#", $app_fabric_name)
Set-Content -Path $filepath -Value $item

Compress-Archive -Path "./herodemosdpocbuild/*" -DestinationPath "./herodemosdpoc.zip" -Update



$TOKEN_1 = az account get-access-token --query accessToken | tr -d '"'

$deployment = curl -X POST -H "Authorization: Bearer $TOKEN_1" -T "./herodemosdpoc.zip" "https://$app_fabric_name.scm.azurewebsites.net/api/publish?type=zip"

az webapp start --name $app_fabric_name --resource-group $rgName


####Cosmos Mongo DB


$toolsUrl = "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-100.9.4.tgz"
$toolsFile = "mongodb-database-tools.tgz"
$filePath = "./artifacts/cosmosMongo/products.json"
$dbName = "herodemo_db"
$collectionName = "products"
$connectionString = $(az cosmosdb keys list `
--name $cosmosMongoAccountName `
--resource-group $rgName `
--type connection-strings `
--query "connectionStrings[0].connectionString" `
-o tsv)
if ($connectionString -match "mongodb://(.*?):(.*?)@") {
$username = $matches[1]
$password = $matches[2]
}
(Get-Content -path artifacts/cosmosMongo/products.json -Raw) | Foreach-Object { $_ `
-replace '#STORAGE_ACCOUNT#', $dataLakeAccountName `
} | Set-Content -Path artifacts/cosmosMongo/products.json

Write-Host "Downloading MongoDB tools from $toolsUrl"




# Download MongoDB tools
Invoke-WebRequest -Uri $toolsUrl -OutFile $toolsFile

# Extract
tar -xvzf $toolsFile 
& (Join-Path (Join-Path ((Get-ChildItem -Directory | Where-Object { $_.Name -like "mongodb-database-tools-*" } | Select-Object -First 1).FullName) "bin") "mongoimport") `
--uri $connectionString `
--db $dbName `
--collection $collectionName `
--file $filePath `
--jsonArray `
--numInsertionWorkers 1 `
--batchSize 1 `
--tlsInsecure

# Variables
$displayName   = "mongocosmosConnection-$suffix"
$server        = "mongodb://$cosmosMongoAccountName.mongo.cosmos.azure.com:10255/"
$serverVersion = "Above 3.2"

# Build request body
$body = @{
connectivityType = "ShareableCloud"
displayName      = $displayName
connectionDetails = @{
type           = "AzureCosmosDBForMongoDB"
creationMethod = "AzureCosmosDBForMongoDB.Database"
parameters     = @(
@{ name = "server";        dataType = "Text"; value = $server },
@{ name = "serverVersion"; dataType = "Text"; value = $serverVersion }
)
}
privacyLevel = "None"
credentialDetails = @{
connectionEncryption = "Encrypted"
credentials = @{
credentialType = "Basic"
username       = $username
password       = $password
}
}
}

# Convert body to JSON
$jsonBody = $body | ConvertTo-Json -Depth 10 -Compress
RefreshTokens

# Call Fabric API
$response1 = Invoke-RestMethod -Method Post `
-Uri "https://api.fabric.microsoft.com/v1/connections" `
-Headers @{ Authorization = "Bearer $fabric"; "Content-Type" = "application/json" } `
-Body $jsonBody

$mongoconnectionid = $response1.id

$requestHeaders = @{
Authorization  = "Bearer " + $fabric
"Content-Type" = "application/json"
"Scope"        = "Notebook.ReadWrite.All"
}



## Replace values in pipeline.json
(Get-Content -path "artifacts/pipelines/Copy_Data_From_Mongo_DB_for_Cosmos_DB.json" -Raw) | Foreach-Object { $_ `
-replace '#mongoconnectionid#', $mongoconnectionid `
-replace '#Lakehouse_Silver#', $lakehouseSilver `
-replace '#wsid#', $wsIdZava `
-replace '#lakehouse_silverid#', $LakehouseSilverid `
} | Set-Content -Path "artifacts/pipelines/Copy_Data_From_Mongo_DB_for_Cosmos_DB.json"

$files = Get-ChildItem -Path "./artifacts/pipelines" -File -Recurse
Set-Location ./artifacts/pipelines
RefreshTokens
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
"Scope"        = "DataPipeline.ReadWrite.All"
}


# Set the file name
$name = "Copy_Data_From_Mongo_DB_for_Cosmos_DB.json"

if ($name -eq "Copy_Data_From_Mongo_DB_for_Cosmos_DB.json") {

# Read the JSON content of the pipeline file
$fileContent = Get-Content -Raw $name
$fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

# Construct request body for Pipeline
$body = '{
"displayName": "Copy_Data_From_Mongo_DB_for_Cosmos_DB",
"definition": {
    "parts": [
        {
            "path": "Copy_Data_From_Mongo_DB_for_Cosmos_DB.json",
            "payload": "' + $fileContentEncoded + '",
            "payloadType": "InlineBase64"
        }
    ]
}
}'

# POST to Fabric API
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/dataPipelines"
$pipelineResult = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

Write-Host "Pipeline uploaded: $name"
}

Write-Host " ---------Data Pipelines setup complete------------"

cd..
cd..

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

fab job run "$salesworkspacePath/Copy_Data_From_Mongo_DB_for_Cosmos_DB.DataPipeline"



### Reports
RefreshTokens
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}

$headers = @{

Authorization = "Bearer $global:fabric"

}
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/warehouses"
$response = Invoke-RestMethod $endPoint `
    -Method GET `
    -Headers $requestHeaders

$warehouse = $response.value | Where-Object { $_.displayName -eq $warehousename }

if ($warehouse) {
Write-Host "Warehouse Name : $($warehouse.displayName)"
Write-Host "Warehouse ID   : $($warehouse.id)"
} else {
Write-Host "Warehouse '$warehousename' not found in workspace $workspaceId"
}

$Warehouseid = $warehouse.id

$uriDetails = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/warehouses/$Warehouseid"

$uriConnStr = "$uriDetails/connectionString"
$connResponse = Invoke-RestMethod -Method Get -Uri $uriConnStr -Headers $headers

$Warehouseconnectionstring = $connResponse.connectionString
Write-Host $Warehouseconnectionstring

$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/warehouses/$Warehouseid/connectionString"

$response2 = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

# === Output ===

Write-Host $response2.connectionString

## updating data to Data warehouse

##Creating ADLSGen2 shortcuts

$connectionName2 = ".connections/datawarehouse_$suffix.Connection"
$serverUrl = "https://$storage_account_name.dfs.core.windows.net"
$path = "datawarehouse"

# Fetch the storage account key dynamically
$storageAccountKey = (az storage account keys list `
    --resource-group $rgName `
    --account-name $storage_account_name `
    --query "[0].value" -o tsv)

# Build param string for Key auth
$params3 = @(
    "connectionDetails.type=AzureDataLakeStorage",
    "connectionDetails.parameters.server=$serverUrl",
    "connectionDetails.parameters.path=$path",
    "credentialDetails.type=Key",
    "credentialDetails.key=$storageAccountKey",
    "privacyLevel=None"
) -join ","

# Create the connection
fab create $connectionName2 -P $params3



$datawarehouseadlgen2connectionId = (fab ls .connections -l | Where-Object { $_ -match "datawarehouse_$suffix.Connection" } | ForEach-Object { ($_ -split '\s+')[1] })


## Replace values in pipeline.json
(Get-Content -path "artifacts/pipelines/IngestDatawarehousedatapipeline.DataPipeline/pipeline-content.json" -Raw) | Foreach-Object { $_ `
-replace '#adlsgen2connectionid#', $datawarehouseadlgen2connectionId `
-replace '#warehouseName#', $warehousename `
-replace '#wsid#', $wsIdZava `
-replace '#warehouseid#', $Warehouseid `
-replace '#connectionstring#', $Warehouseconnectionstring
} | Set-Content -Path "artifacts/pipelines/IngestDatawarehousedatapipeline.DataPipeline/pipeline-content.json"

$files = Get-ChildItem -Path "./artifacts/pipelines" -File -Recurse
Set-Location ./artifacts/pipelines
fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId
fab import $salesworkspacePath/"Ingest Datawarehouse data using pipeline.Datapipeline" -i "./IngestDatawarehousedatapipeline.DataPipeline"

# RefreshTokens
# $pat_token = $fabric
# $requestHeaders = @{
# Authorization  = "Bearer" + " " + $pat_token
# "Content-Type" = "application/json"
# }


# # Set the file name
# $name = "Ingest_Datawarehouse_data.json"

# if ($name -eq "Ingest_Datawarehouse_data.json") {

# # Read the JSON content of the pipeline file
# $fileContent = Get-Content -Raw $name
# $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
# $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

# # Construct request body for Pipeline
# $datawarehousebody = '{
# "displayName": "Ingest Datawarehouse data using pipeline1",
# "definition": {
#     "parts": [
#         {
#             "path": "Ingest_Datawarehouse_data.json",
#             "payload": "' + $fileContentEncoded + '",
#             "payloadType": "InlineBase64"
#         }
#     ]
# }
# }'

# # POST to Fabric API
# $endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/dataPipelines"
# $pipelineResult = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $datawarehousebody

# Write-Host "Pipeline uploaded: $name"
# }

Write-Host " ---------Data Pipelines setup complete------------"

cd..
cd..


fab job run "$salesworkspacePath/Ingest Datawarehouse data using pipeline.Datapipeline"

### Uploading PowerBI reports

$credential = New-Object PSCredential($appId, (ConvertTo-SecureString $clientsecpwdapp -AsPlainText -Force))

# Connect to Power BI using the service principal
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenantId

$PowerBIFiles = Get-ChildItem "./artifacts/reports" -Recurse -Filter *.pbix
$reportList = @()

foreach ($Pbix in $PowerBIFiles) {
Write-Output "Uploading report: $($Pbix.BaseName +'.pbix')"

$report = New-PowerBIReport -Path $Pbix.FullName -WorkspaceId $wsIdZava -ConflictAction CreateOrOverwrite

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
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdZava/datasets"
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
foreach ($report in $reportList) {
$datasetId = $report.PowerBIDataSetId
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdZava/datasets/$datasetId/Default.TakeOver"

try {
    $response = Invoke-RestMethod -Uri $url -Method POST -Headers @{ Authorization = "Bearer $powerbitoken" }
    Write-Host "TakeOver action completed successfully for dataset ID: $datasetId"
}
catch {
    Write-Host "Error occurred while performing TakeOver action for dataset ID: $datasetId - $_"
}
}


foreach ($report in $reportList) {
if ($report.Name -eq "Column Level Security in Warehouse" -or $report.Name -eq "Object Level Security in Warehouse" -or $report.Name -eq "Row-Level Security in Warehouse" -or $report.Name -eq "Dynamic Data Masking in Warehouse") 
{
$body = "{
`"updateDetails`": [
    {
        `"name`": `"Server`",
        `"newValue`": `"$($Warehouseconnectionstring)`"
    },
    {
        `"name`": `"Warehouse`",
        `"newValue`": `"$($warehousename)`"
    }
]
}"

Write-Host "PBI connections updating for report : $($report.name)"	

$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdZava)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"

$pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
Authorization = "Bearer $powerbitoken"
} -ErrorAction SilentlyContinue

Start-Sleep -Seconds 5
}
if ($report.Name -eq "Sales_Report") 
{
$body = "{
`"updateDetails`": [
    {
        `"name`": `"Server`",
        `"newValue`": `"$($SilverServerName)`"
    },
    {
        `"name`": `"Database`",
        `"newValue`": `"$($lakehouseSilver)`"
    }
]
}"

Write-Host "PBI connections updating for report : $($report.name)"	

$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdZava)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"

$pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
Authorization = "Bearer $powerbitoken"
} -ErrorAction SilentlyContinue

Start-Sleep -Seconds 5
}
}




### Azure cosmos DB

az cosmosdb sql container create --account-name $cosmosdb_account --database-name "CustomerSentiment" --name "SentimentData" --partition-key-path "/id" --resource-group $rgName --throughput "400"

RefreshTokens
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDatabaseName = "CustomerSentiment"
$cosmos = Get-ChildItem "./artifacts/cosmos/" | Select BaseName 

foreach ($name in $cosmos) {
$collection = $name.BaseName 
$cosmosDbContext = New-CosmosDbContext -Account $cosmosdb_account -Database $cosmosDatabaseName -ResourceGroup $rgName
$path = "./artifacts/cosmos/" + $name.BaseName + ".json"
$document = Get-Content -Raw -Path $path
$document = ConvertFrom-Json $document

foreach ($json in $document) {
    $key = $json.id
    $body = ConvertTo-Json $json
    $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId "SentimentData" -DocumentBody $body -PartitionKey $key -ErrorAction SilentlyContinue
}
} 
$key = (Get-AzCosmosDBAccountKey -ResourceGroupName $rgName -Name $cosmosdb_account).PrimaryMasterKey
Write-Output "Cosmos Primary Key: $key"

$cosmos_key       = "$key"   
RefreshTokens
$fabric = az account get-access-token `
--resource "https://api.fabric.microsoft.com" `
--query accessToken -o tsv

$uri = "https://api.fabric.microsoft.com/v1/connections"
$headers = @{
Authorization = "Bearer $fabric"
"Content-Type" = "application/json"
}

# e.g. mycosmosdbkey



# Define the payload in PowerShell
$payload = @{
connectivityType = "ShareableCloud"
displayName      = "cosmosdb-$suffix"
connectionDetails = @{
type          = "CosmosDB"
creationMethod = "CosmosDB.Contents"
parameters    = @(
@{
name     = "host"
dataType = "Text"
value    = "https://$cosmosdb_account.documents.azure.com:443/"
},
@{
name     = "NUMBER_OF_RETRIES"
dataType = "Text"
value    = "1"
}
)
}
privacyLevel = "None"
credentialDetails = @{
supportsSkipTestConnection = $false
credentials = @{
credentialType = "Key"
key            = "$cosmos_key"   # <-- Insert Cosmos DB primary key here
}
}
}

# Convert to JSON
$bodyJson = $payload | ConvertTo-Json -Depth 10 -Compress
Write-Output $bodyJson

# Example POST call
$uri = "https://api.fabric.microsoft.com/v1/connections"
$headers = @{
Authorization = "Bearer $fabric"   # assumes you already have $fabricToken
"Content-Type" = "application/json"
}
$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $bodyJson
$azurecosmosdbconnectionid = $response.id
Write-Output "Connection ID: $azurecosmosdbconnectionid"



# $payloadjson = @{
# properties = @{
# source = @{
# type = "CosmosDb"
# typeProperties = @{
# connection = $azurecosmosdbconnectionid
# database = "$cosmosDatabaseName"
# }
# }
# target = @{
# type = "MountedRelationalDatabase"
# typeProperties = @{
# defaultSchema = "dbo"
# format = "Delta"
# }
# }
# }
# }

# # Convert the PowerShell object to a JSON string 
# $jsonString = $payloadjson | ConvertTo-Json -Depth 10 
# # Convert the JSON string to a byte array 
# $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonString) 
# # Convert the byte array to a Base64 string 
# $base64Payload = [Convert]::ToBase64String($bytes) 

# $body = '{
# "displayName" : "AzurecosmosDB-sentimentData",
# "description": "A mirrored database description",
# "definition": {
# "parts": [
# {
# "path": "mirrored.json",
# "payload": "$base64Payload",
# "payloadType": "InlineBase64"
# }
# ]
# }
# }'

# # Convert the JSON string to a PowerShell object
# $jsonObject = $body | ConvertFrom-Json

# # Update the payload value in the object
# $jsonObject.definition.parts[0].payload = $base64Payload

# # Convert the PowerShell object back to a JSON string
# $updatedbody = $jsonObject | ConvertTo-Json -Depth 10

# # Output the JSON string
# Write-Output $updatedbody
# # Define the URI for the API request
# $uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/mirroredDatabases"
# # Define the headers
# $headers = @{
# Authorization = "Bearer $fabric"
# "Content-Type" = "application/json"
# }
# # Make the POST request to create the mirrored database
# $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $updatedbody
# # Retrieve and display the Mirrored Database ID
# $mirroredDatabaseId = $response.id
# Write-Output "Mirrored Database ID: $mirroredDatabaseId"
# start-sleep -s 30
# #get mirroring status
# $uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/mirroredDatabases/$mirroredDatabaseId/getMirroringStatus"
# $headers = @{
# Authorization = "Bearer $fabric"
# "Content-Type" = "application/json"
# }
# $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers
# Write-Output "$response"

# start-sleep -s 30

# #start Mirrorring
# $uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/mirroredDatabases/$mirroredDatabaseId/startMirroring"
# $headers = @{
# Authorization = "Bearer $fabric"
# "Content-Type" = "application/json"
# }
# $response1 = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers

# $appJson = az ad sp list --display-name "$cosmosdb_account" --query '[0]' --output json
# $app = $appJson | ConvertFrom-Json
# if (-not $app) {
# Write-Error "Service principal '$cosmosdb_account' not found."

# }
# $principalId = $app.id

# $body = @{
# principal = @{
# id   = "$principalId"
# type = "ServicePrincipal"
# }
# role      = "Member"
# } | ConvertTo-Json


# # Now you can use $body in your PowerShell script where needed
# Write-Output $body
# $uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/roleAssignments"

# # Define the headers
# $headers = @{
# Authorization  = "Bearer $fabric"
# "Content-Type" = "application/json"
# }

# # Make the REST API call
# $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body

# # Output the response
# $response



## mssql


RefreshTokens   

$uri = "https://api.fabric.microsoft.com/v1/connections"
$headers = @{
Authorization = "Bearer $fabric"
"Content-Type"  = "application/json"
}
$body = @{
connectivityType = "ShareableCloud"
displayName      = "azuresqlconnection_$suffix"
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
connectionEncryption = "Encrypted"
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
$sqldbconnectionidid = $response.id                                            
Write-Output "Connection ID: $sqldbconnectionidid"

# fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

# $connectionName = ".connections/azuresql$suffix.Connection"
# $server = "$mssql_server_name.database.windows.net"
# $database = $mssql_database_name

# # Build param string
# $params = @(
#     "connectionDetails.type=SQL",
#     "connectionDetails.parameters.server=$server",
#     "connectionDetails.parameters.database=$database",
#     "credentialDetails.type=Basic",
#     "credentialDetails.userName=$mssql_administrator_login",
#     "credentialDetails.password=$sql_administrator_login_password",
#     "privacyLevel=Organizational"
# ) -join ","

# # Final command
# fab create $connectionName -P $params

# $sqldbconnectionidid = (fab ls .connections -l | Where-Object { $_ -match "azuresql$suffix.Connection" } | ForEach-Object { ($_ -split '\s+')[1] })
RefreshTokens
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/sqldatabases"
$Fabricsql = Invoke-RestMethod $endPoint -Method GET -Headers $requestHeaders 

$fabricsqlid = ($Fabricsql.value | Where-Object { $_.displayName -eq "$SQLDB" }).id 


(Get-Content -path "artifacts/pipelines/IngestAzureSQLInFabricSQL.DataPipeline/pipeline-content.json" -Raw) | Foreach-Object { $_ `
-replace '#salessqldbconnectionid#', $sqldbconnectionidid `
-replace '#fabricsqldatabaseid#', $fabricsqlid `
-replace '#fabricsqldbconnectionid#', $SQLDB `
-replace '#wsid#', $wsIdZava `
} | Set-Content -Path "artifacts/pipelines/IngestAzureSQLInFabricSQL.DataPipeline/pipeline-content.json"

$files = Get-ChildItem -Path "./artifacts/pipelines/IngestAzureSQLInFabricSQL.DataPipeline" -File -Recurse
Set-Location ./artifacts/pipelines/IngestAzureSQLInFabricSQL.DataPipeline

# fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId
# fab import $salesworkspacePath/"Ingest AzureSQLDB data using pipeline1.Datapipeline" -i "./IngestAzureSQLInFabricSQL.DataPipeline"

RefreshTokens
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
"Scope"        = "DataPipeline.ReadWrite.All"
}


# # Set the file name
$name = "pipeline-content.json"

if ($name -eq "pipeline-content.json") {

# Read the JSON content of the pipeline file
$fileContent = Get-Content -Raw $name
$fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

# Construct request body for Pipeline
$Azuresqldbbody = '{
"displayName": "Ingest AzureSQLDB data using pipeline",
"definition": {
    "parts": [
        {
            "path": "pipeline-content-new.json",
            "payload": "' + $fileContentEncoded + '",
            "payloadType": "InlineBase64"
        }
    ]
}
}'

# POST to Fabric API
$endPoint1 = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/dataPipelines"
# Create the pipeline
$pipelineResult = Invoke-RestMethod $endPoint1 -Method POST -Headers $requestHeaders -Body $Azuresqldbbody
}
# # Pipeline creation request accepted
# Write-Host "Pipeline creation request accepted. Checking status..."

# # Poll for pipeline availability
# $pipelineName = "Ingest AzureSQLDB data using pipeline"
# $statusEndpoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdZava/dataPipelines"

# $maxRetries = 10
# $delaySeconds = 30
# $found = $false


# for ($i = 1; $i -le $maxRetries; $i++) {
#     Start-Sleep -Seconds $delaySeconds

#     $pipelines = Invoke-RestMethod $statusEndpoint -Headers $requestHeaders -Method GET
#     $pipeline = $pipelines.value | Where-Object { $_.displayName -eq $pipelineName }

#     if ($null -ne $pipeline) {
#         Write-Host "✅ Pipeline is now available: $($pipeline.id)"
#         $found = $true
#         break
#     } else {
#         Write-Host "Attempt $i : Pipeline not ready yet, retrying in $delaySeconds seconds..."
#     }
# }

# if (-not $found) {
#     Write-Host "❌ Pipeline was not available after $($maxRetries * $delaySeconds) seconds."
# }

# }


# $connectionName = ".connections/fabricsql$suffix.Connection"


# # Build param string
# $params = @(
#     "connectionDetails.type=FabricSQLdatabse",
#     "credentialDetails.type=ServicePrincipal",
#     "credentialDetails.TenantID=$tenantId",
#     "credentialDetails.ServiceprincipalID=$appId",
#     "credentialDetails.Serviceprincipalkey=$clientsecpwdapp",
#     "privacyLevel=None"
# ) -join ","

# # Final command
# fab create $connectionName -P $params

# Write-Host " ---------Data Pipelines setup complete------------"

cd..
cd..
cd..

# fab job run "$salesworkspacePath/Ingest AzureSQLDB data using pipeline2.Datapipeline"

Write-Host " -----------Execution Complete--------------"

}


