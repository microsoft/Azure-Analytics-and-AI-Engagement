
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
Write-Host "-Make sure your Power BI administrator can provide service principal access on your Power BI tenant."
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

[string]$suffix =  -join ((48..57) + (97..122) | Get-Random -Count 7 | % {[char]$_})
$rgName = "rg-unifydataplatform-$suffix"
$Region = read-host "Enter the region for deployment"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$wsIdUnify_Dataplatform_2 =  Read-Host "Enter your 'Unify_Dataplatform_2' PowerBI workspace Id "
$storage_account_name = "storage$suffix"
$cosmosdb_account       = "cosmosdb-$suffix"


Write-Host "Deploying Resources on Microsoft Azure Started ..."
Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
Write-Host "Resource group $rgName creation COMPLETE"
    
Write-Host "Creating resources in $rgName..."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile "mainTemplate.json" `
    -Mode Complete `
    -location $Region `
    -storage_account_name $storage_account_name `
    -cosmosdb_account $cosmosdb_account `
    -Force
    
$templatedeployment = Get-AzResourceGroupDeployment -Name "mainTemplate" -ResourceGroupName $rgName
$deploymentStatus = $templatedeployment.ProvisioningState
Write-Host "Deployment in $rgName : $deploymentStatus"

Add-Content log.txt "------Copying assets to the Storage Account------"
Write-Host "------------Copying assets to the Storage Account------------"



## storage AZ Copy
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storage_account_name)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_account_key

$destinationSasKey = New-AzStorageContainerSASToken -Container "operations-data-s3" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/operations-data-s3$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stunifydpoc.blob.core.windows.net/operations-data-s3/" $destinationUri --recursive

Write-Host "operations-data-s3 copied"

$destinationSasKey = New-AzStorageContainerSASToken -Container "sales-transaction-data-adlsgen2" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/sales-transaction-data$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stunifydpoc.blob.core.windows.net/sales-transaction-data-adlsgen2/" $destinationUri --recursive

Write-Host "sales-transaction-data copied"

# $destinationSasKey = New-AzStorageContainerSASToken -Container "snowflake-iceberg" -Context $dataLakeContext -Permission rwdl
# if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
# $destinationUri = "https://$($storage_account_name).blob.core.windows.net/snowflake-iceberg$($destinationSasKey)"
# $azCopy_Data_container = azcopy copy "https://stunifydpoc.blob.core.windows.net/lakehousebronzefiles/Snowflake_iceberg/" $destinationUri --recursive

# Write-Host " Snowflake_iceberg copied"

$destinationSasKey = New-AzStorageContainerSASToken -Container "datawarehouse" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/datawarehouse$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://stunifydpoc.blob.core.windows.net/datawarehouse/" $destinationUri --recursive

Write-Host "datawarehouse-data copied"



### Fabric starts here

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdUnify_Dataplatform_2";
$Unify_Dataplatform_2WsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$Unify_Dataplatform_2WsName = $Unify_Dataplatform_2WsName.name


$lakehouseBronze =  "lakehouseBronze_$suffix"
$lakehouseSilver =  "lakehouseSilver_$suffix"
$lakehouseGold =  "lakehouseGold_$suffix"
$AILakehouse =  "lakehouseAI_$suffix"
Add-Content log.txt "------FABRIC assets deployment STARTS HERE------"
Write-Host "------------FABRIC assets deployment STARTS HERE------------"

Add-Content log.txt "------Creating Lakehouses in '$Unify_Dataplatform_2WsName' workspace------"
Write-Host "------Creating Lakehouses in '$Unify_Dataplatform_2WsName' workspace------"
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

$createUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/items"
    
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
Add-Content log.txt "------Creation of Lakehouses in '$Unify_Dataplatform_2WsName' workspace COMPLETED------"
Write-Host "-----Creation of Lakehouses in '$Unify_Dataplatform_2WsName' workspace COMPLETED------"
Write-Host "-----Creating of AILakehouses in '$Unify_Dataplatform_2WsName' workspace STARTED------"

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/lakehouses"
$Lakehouse = Invoke-RestMethod $endPoint `
-Method GET `
-Headers $requestHeaders

$LakehouseBronzeid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseBronze" }).id

$LakehouseSilverid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseSilver" }).id

$LakehouseGoldid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$lakehouseGold" }).id


Write-Output "Bronze Lakehouse ID: $LakehouseBronzeid"

Write-Output "Silver Lakehouse ID: $LakehouseSilverid"
Write-Output "Gold Lakehouse ID: $LakehouseGoldid"


$url = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/lakehouses/$LakehouseSilverid";
$LakehouseSilverdetails = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $fabric" };

$SilverServerName = $LakehouseSilverdetails.properties.sqlEndpointProperties.connectionString

RefreshTokens

$url = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/lakehouses/$LakehouseSilverid";
$LakehouseSilverdetails = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $fabric" };

$SilverServerName = $LakehouseSilverdetails.properties.sqlEndpointProperties.connectionString

Add-Content log.txt "------Uploading assets to Lakehouses------"
Write-Host "------------Uploading assets to Lakehouses------------"

RefreshTokens
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}
$requestBody2 = @{
    displayName = "Unify_Dataplatform_DTB"
    description = "Digital Twin Builder for Smart Factory operations"
} | ConvertTo-Json -Depth 3

$createUri2 = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/digitaltwinbuilders"

$response = Invoke-RestMethod `
    -Method Post `
    -Uri $createUri2 `
    -Headers $requestHeaders `
    -Body $requestBody2 `
    -ContentType "application/json"

# $createUri3 = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/mirroredDatabases"
# $requestBody3 = @{
#     displayName = "MirroredDatabase_historical_sales_data"
#     description = "MirroredDatabase_historical_sales_data"
# } | ConvertTo-Json -Depth 3
# $response = Invoke-RestMethod `
#     -Method Post `
#     -Uri $createUri3 `
#     -Headers $requestHeaders `
#     -Body $requestBody3 `
#     -ContentType "application/json"

$spname = "unify data Demo $suffix"

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
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdUnify_Dataplatform_2/users";
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

$spObjectId = az ad sp show --id $appId --query id -o tsv
az role assignment create --assignee-object-id $spObjectId --role "Azure AI User" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rgName"


$credential = New-Object PSCredential($appId, (ConvertTo-SecureString $clientsecpwdapp -AsPlainText -Force))

# Connect to Power BI using the service principal
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenantId

pip install --user --upgrade pip setuptools
pip install --user packaging  # Packaging is required by ansible-core
pip install --user cryptography
pip install --user ms-fabric-cli


fab config set encryption_fallback_enabled true

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$salesworkspacePath = "$Unify_Dataplatform_2WsName.Workspace"

fab mkdir "$salesworkspacePath/$AILakehouse.Lakehouse"

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/lakehouses"
$Lakehouse = Invoke-RestMethod $endPoint `
-Method GET `
-Headers $requestHeaders

$AILakehouseid = ($Lakehouse.value | Where-Object { $_.displayName -eq "$AILakehouse" }).id

Write-Host "-----------Creation of Eventstream Started------------"

$eventStreamName = "Thermostat_Eventstream_$suffix"
$eventStreamPath = "$salesworkspacePath/$eventStreamName.eventstream"

fab mkdir $eventStreamPath

$eventStreamName1 = "Ingest_Store_Level_Foot_Traffic_Data_$suffix"
$eventStreamPath1 = "$salesworkspacePath/$eventStreamName1.eventstream"

fab mkdir $eventStreamPath1

$eventStreamName2 = "PaintInventory_Eventstream_$suffix"
$eventStreamPath2 = "$salesworkspacePath/$eventStreamName2.eventstream"

fab mkdir $eventStreamPath2

$eventStreamName = "Ingest_Aisle_Level_Foot_Traffic_Data_$suffix"
$eventStreamPath = "$salesworkspacePath/$eventStreamName.eventstream"

fab mkdir $eventStreamPath

$eventStreamName = "Ingest_Products_Inventory_Data_$suffix"
$eventStreamPath = "$salesworkspacePath/$eventStreamName.eventstream"

fab mkdir $eventStreamPath

Write-Host "-----------Creation of Eventstream COMPLETED------------"

Write-Host "------Creating Eventhouse------"
$KQLDB = "Eventhouse"
fab mkdir $salesworkspacePath/$KQLDB.eventhouse

Write-Host "------Creating Eventhouse completed------"

Write-Host "------Creating Queryset------"
$Queryset = "Eventhouse_queryset"

fab mkdir $salesworkspacePath/$Queryset.KQLQueryset

Write-Host "------Creating Queryset completed------"

Write-Host "-----------Creation of Warehouse------------"

$warehousename = "RetailDW001"
fab mkdir $salesworkspacePath/$warehousename.warehouse

Write-Host "-----------Creation of Warehouse COMPLETED------------"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

fab mkdir "$salesworkspacePath/SQL_DB.sqldatabase" 

RefreshTokens
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/sqldatabases"
$Fabricsql = Invoke-RestMethod $endPoint `
-Method GET `
-Headers $requestHeaders

$fabricsqlid = ($Fabricsql.value | Where-Object { $_.displayName -eq "SQL_DB" }).id


## notebooks
Add-Content log.txt "-----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses-----"
Write-Host "----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses----"




Add-Content log.txt "-----Uploading Notebooks-----"
Write-Host "-----Uploading Notebooks-----"
RefreshTokens
$requestHeaders = @{
Authorization  = "Bearer " + $fabric
"Content-Type" = "application/json"
"Scope"        = "Notebook.ReadWrite.All"
}




(Get-Content -path "artifacts/fabricnotebooks/2-Customer 360 Insights – Segmentation.ipynb" -Raw) | Foreach-Object { $_ `
-replace '#AILakehouse#', $AILakehouse `
} | Set-Content -Path "artifacts/fabricnotebooks/2-Customer 360 Insights – Segmentation.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/1-ML Solution-Financial Forecasting-AutoML.ipynb" -Raw) | Foreach-Object { $_ `
-replace '#AILakehouseid#', $AILakehouseid `
-replace '#wsid#', $wsIdUnify_Dataplatform_2 `
} | Set-Content -Path "artifacts/fabricnotebooks/1-ML Solution-Financial Forecasting-AutoML.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/Campaign Optimization.ipynb" -Raw) | Foreach-Object { $_ `
-replace '#AILakehouse#', $AILakehouse `
-replace '#wsname#', $Unify_Dataplatform_2WsName `
-replace '#wsid#', $wsIdUnify_Dataplatform_2 `
-replace '#Lakehousegolddid#', $LakehouseGoldid `
} | Set-Content -Path "artifacts/fabricnotebooks/Campaign Optimization.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/GenerateFactSalesData.ipynb" -Raw) | Foreach-Object { $_ `
-replace '#LakehouseSilver#', $LakehouseSilver `
} | Set-Content -Path "artifacts/fabricnotebooks/GenerateFactSalesData.ipynb"


$files = Get-ChildItem -Path "./artifacts/fabricnotebooks" -File -Recurse
Set-Location ./artifacts/fabricnotebooks

foreach ($name in $files.name) {
if ($name -eq "Simulate Aisle-Level Foot Traffic Data.ipynb" -or
$name -eq "Generate realtime thermostat data.ipynb" -or
$name -eq "real-time paint accessory inventory data.ipynb") {

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

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/items/"

$Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

Write-Host "Notebook uploaded: $name"
}
elseif ($name -eq "CreateSchema.ipynb" -or $name -eq "2-Customer 360 Insights – Segmentation.ipynb" -or $name -eq "1-ML Solution-Financial Forecasting-AutoML.ipynb") {

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

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/items/"
$Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

Write-Host "Notebook uploaded: $name"
} 
elseif ($name -eq "Materialized lake view.ipynb" -or $name -eq "CreateSchema-Gold.ipynb" -or $name -eq "GenerateFactSalesData.ipynb") {

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

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/items/"
$Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

Write-Host "Notebook uploaded: $name"
}
elseif ($name -eq "Campaign Optimization.ipynb") {

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

$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/items/"
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
known_lakehouses = @(@{ id = $LakehouseSilverid })
default_lakehouse = $LakehouseSilverid
default_lakehouse_name = $lakehouseSilver
default_lakehouse_workspace_id = $wsIdUnify_Dataplatform_2
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath1" -q lakehouse -i $jsonInput1 -f

fab job run "$salesworkspacePath/CreateSchema.ipynb.Notebook"

# $notebook = "$salesworkspacePath/CreateSchema.ipynb.Notebook"
# $maxRetries = 3
# $retryCount = 0

# do {
#     Write-Host "Running Fabric job for $notebook (Attempt: $($retryCount + 1))"
#     $output = fab job run $notebook 2>&1
#     Write-Host $output

#     if ($output -match "JobFailed") {
#         Write-Host "Job failed. Retrying..."
#         Start-Sleep -Seconds 10
#         $retryCount++
#     }
#     else {
#         Write-Host "Job succeeded!"
#         break
#     }

# } while ($retryCount -lt $maxRetries)

# if ($retryCount -eq $maxRetries) {
#     Write-Host "Job failed after $maxRetries attempts. Check job logs for details."
# }


fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath4 = "$salesworkspacePath/CreateSchema-Gold.ipynb.Notebook"

# Build the JSON input string
$jsonInput4 = @{
known_lakehouses = @(@{ id = $LakehouseGoldid })
default_lakehouse = $LakehouseGoldid
default_lakehouse_name = $lakehouseGold
default_lakehouse_workspace_id = $wsIdUnify_Dataplatform_2
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath4" -q lakehouse -i $jsonInput4 -f

fab job run "$salesworkspacePath/CreateSchema-Gold.ipynb.Notebook"

Add-Content log.txt "------Uploading assets to Lakehouses------"
Write-Host "------------Uploading assets to Lakehouses------------"
RefreshTokens

$requestHeaders = @{
    Authorization  = "Bearer" + " " + $fabric
    "Content-Type" = "application/json"
}
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/eventhouses"

# Get Eventhouse details
# Make GET request to list all Eventhouses
try {
    $response = Invoke-RestMethod -Method Get -Uri $endpoint -Headers $requestHeaders

    # Filter by display name
    $eventhouse = $response.value | Where-Object { $_.displayName -eq $KQLDB }

    if ($eventhouse) {
        $eventhouseId = $eventhouse.id
        $queryUri = $eventhouse.properties.queryServiceUri
        $ingestUri = $eventhouse.properties.ingestionServiceUri

        Write-Host "✅ Eventhouse found:"
        Write-Host "Display Name: $eventhouseName"
        Write-Host "Eventhouse ID: $eventhouseId"
        Write-Host "Query URI: $queryUri"
        Write-Host "Ingestion URI: $ingestUri"
    }
    else {
        Write-Host "❌ Eventhouse '$eventhouseName' not found in workspace $workspaceId"
    }
}
catch {
    Write-Host "❌ Error retrieving Eventhouse list from workspace $workspaceId"
}


# Extract and display the query URI
# $eventhouseUri = $eventhouseDetails.queryUri
# Write-Host "Eventhouse URI: $eventhouseUri"


$tenantId = (Get-AzContext).Tenant.Id
azcopy login --tenant-id $tenantId

azcopy copy "https://stunifydpoc.blob.core.windows.net/lakehousebronzetables/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseBronze.Lakehouse/Tables/dbo" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/lakehousebronzefiles/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseBronze.Lakehouse/Files" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousetables/snowflake/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Tables/Snowflake" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousetables/cosmosDB/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Tables/cosmosDB" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousetables/Oracle/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Tables/Oracle" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousetables/Dataverse/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Tables/Dataverse" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousetables/RetailDW001/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Tables/RetailDW001" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousetables/AWS/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Tables/AWS" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousetables/iot/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Tables/iot" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousetables/dbo/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Tables/dbo" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/silverlakehousefiles/SAP" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseSilver.Lakehouse/Files" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/ailakehousetables/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$AILakehouse.Lakehouse/Tables" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/ailakehousefiles/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$AILakehouse.Lakehouse/Files" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;

azcopy copy "https://stunifydpoc.blob.core.windows.net/lakehousegoldtables/dbo/customer_campaign_scores" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseGold.Lakehouse/Tables/dbo" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/lakehousegoldtables/snowflake/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseGold.Lakehouse/Tables/Snowflake" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://stunifydpoc.blob.core.windows.net/lakehousegoldtables/aws/*" "https://onelake.blob.fabric.microsoft.com/$Unify_Dataplatform_2WsName/$lakehouseGold.Lakehouse/Tables/AWS" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;

Add-Content log.txt "------Uploading assets to Lakehouses COMPLETED------"
Write-Host "------------Uploading assets to Lakehouses COMPLETED------------"

##Assigning SP as Storage Blob Data Contributor
Add-Content log.txt "------Assigning SP as Storage Blob Data Contributor------"

az role assignment create --assignee $appId --role "Storage Blob Data Contributor" --scope "/subscriptions/$subscriptionId/resourceGroups/$rgname"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

# Creating ADLSGen2 shortcuts
$connectionName = ".connections/salestransaction$suffix.Connection"
$serverUrl = "https://$storage_account_name.dfs.core.windows.net"
$path = "sales-transaction-data-adlsgen2"

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
$shortcutPath = "$BronzeLakehousepath/sales-transaction-data-adlsgen2.shortcut"
$jsonInput = @{
    location = "https://$storage_account_name.dfs.core.windows.net/"
    subpath = "sales-transaction-data-adlsgen2"
    connectionId = $connectionId
} | ConvertTo-Json -Compress

fab ln $shortcutPath --type adlsGen2 -i $jsonInput

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$connectionName2 = ".connections/aws$suffix.Connection"
$serverUrl = "https://$storage_account_name.dfs.core.windows.net"
$path2 = "operations-data-s3"

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
$shortcutPath2 = "$BronzeLakehousepath/operations-data-s3.shortcut"
$jsonInput2 = @{
    location = "https://$storage_account_name.dfs.core.windows.net/"
    subpath = "operations-data-s3"
    connectionId = $connectionId2
} | ConvertTo-Json -Compress

fab ln $shortcutPath2 --type adlsGen2 -i $jsonInput2


fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath2 = "$salesworkspacePath/2-Customer 360 Insights – Segmentation.ipynb.Notebook"

# Build the JSON input string
$jsonInput2 = @{
known_lakehouses = @(@{ id = $AILakehouseid })
default_lakehouse = $AILakehouseid
default_lakehouse_name = $AILakehouse
default_lakehouse_workspace_id = $wsIdUnify_Dataplatform_2
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath2" -q lakehouse -i $jsonInput2 -f

fab job run "$salesworkspacePath/2-Customer 360 Insights – Segmentation.ipynb.Notebook"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath3 = "$salesworkspacePath/1-ML Solution-Financial Forecasting-AutoML.ipynb.Notebook"

# Build the JSON input string
$jsonInput3 = @{
known_lakehouses = @(@{ id = $AILakehouseid })
default_lakehouse = $AILakehouseid
default_lakehouse_name = $AILakehouse
default_lakehouse_workspace_id = $wsIdUnify_Dataplatform_2
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath3" -q lakehouse -i $jsonInput3 -f

fab job run "$salesworkspacePath/1-ML Solution-Financial Forecasting-AutoML.ipynb.Notebook"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath7 = "$salesworkspacePath/Campaign Optimization.ipynb.Notebook"

# Build the JSON input string
$jsonInput7 = @{
known_lakehouses = @(@{ id = $AILakehouseid })
default_lakehouse = $AILakehouseid
default_lakehouse_name = $AILakehouse
default_lakehouse_workspace_id = $wsIdUnify_Dataplatform_2
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath7" -q lakehouse -i $jsonInput7 -f

fab job run "$salesworkspacePath/Campaign Optimization.ipynb.Notebook"


fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$notebookPath5 = "$salesworkspacePath/GenerateFactSalesData.ipynb.Notebook"

# Build the JSON input string
$jsonInput5 = @{
known_lakehouses = @(@{ id = $LakehouseSilverid })
default_lakehouse = $LakehouseSilverid
default_lakehouse_name = $lakehouseSilver
default_lakehouse_workspace_id = $wsIdUnify_Dataplatform_2
} | ConvertTo-Json -Compress

# Run the fab set command
fab set "$notebookPath5" -q lakehouse -i $jsonInput5 -f

fab job run "$salesworkspacePath/GenerateFactSalesData.ipynb.Notebook"

RefreshTokens
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}

$headers = @{

Authorization = "Bearer $global:fabric"

}
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/warehouses"
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

$uriDetails = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/warehouses/$Warehouseid"

$uriConnStr = "$uriDetails/connectionString"
$connResponse = Invoke-RestMethod -Method Get -Uri $uriConnStr -Headers $headers

$Warehouseconnectionstring = $connResponse.connectionString
Write-Host $Warehouseconnectionstring

$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdUnify_Dataplatform_2/warehouses/$Warehouseid/connectionString"

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
-replace '#wsid#', $wsIdUnify_Dataplatform_2 `
-replace '#warehouseid#', $Warehouseid `
-replace '#connectionstring#', $Warehouseconnectionstring
} | Set-Content -Path "artifacts/pipelines/IngestDatawarehousedatapipeline.DataPipeline/pipeline-content.json"

$files = Get-ChildItem -Path "./artifacts/pipelines" -File -Recurse
Set-Location ./artifacts/pipelines
fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId
fab import $salesworkspacePath/"Ingest Datawarehouse data using pipeline.Datapipeline" -i "./IngestDatawarehousedatapipeline.DataPipeline"

cd..
cd..

(Get-Content -path "artifacts/pipelines/CopydatafromLakehousetofabricsql.DataPipeline/pipeline-content.json" -Raw) | Foreach-Object { $_ `
-replace '#lakehouseBronze#', $lakehouseBronze `
-replace '#lakehouseBronzeid#', $LakehouseBronzeid `
-replace '#wsid#', $wsIdUnify_Dataplatform_2 `
-replace '#fabricsqlid#', $fabricsqlid `
} | Set-Content -Path "artifacts/pipelines/CopydatafromLakehousetofabricsql.DataPipeline/pipeline-content.json"

$files = Get-ChildItem -Path "./artifacts/pipelines" -File -Recurse
Set-Location ./artifacts/pipelines
fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId
fab import $salesworkspacePath/"CopydatafromLakehousetofabricsql.DataPipeline" -i "./CopydatafromLakehousetofabricsql.DataPipeline"

Write-Host " ---------Data Pipelines setup complete------------"

cd..
cd..


fab job run "$salesworkspacePath/Ingest Datawarehouse data using pipeline.Datapipeline"


### datawarehouse data ingestion completed

### Internal Shottcuts Creation

$AILakehouse =  "lakehouseAI_$suffix"
$salesworkspacePath = "$Unify_Dataplatform_2WsName.Workspace"
$silverLakehousepath = "$salesworkspacePath/$lakehouseSilver.Lakehouse/Tables"
$ailakehousepath = "$salesworkspacePath/$AILakehouse.Lakehouse/Tables"

Write-Host "Creating Shortcut for clickstream_data"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$shortcutPath2 = "$aiLakehousepath/clickstream_data.Shortcut"
$targetPath2 = "$silverLakehousepath/cosmosDB/clickstream_data"

fab ln $shortcutPath2 --type oneLake --target $targetPath2
Write-Host "✅ Shortcut created: clickstream_data"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

Write-Host "Creating Shortcut for productsinventory"

$shortcutPath3 = "$aiLakehousepath/productsinventory.Shortcut"
$targetPath3 = "$silverLakehousepath/iot/productsinventory"

fab ln $shortcutPath3 --type oneLake --target $targetPath3
Write-Host "✅ Shortcut created: productsinventory"

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

Write-Host "Creating Shortcut for DIM_CUSTOMERDATA"

$shortcutPath4 = "$aiLakehousepath/DIM_CUSTOMERDATA.Shortcut"
$targetPath4 = "$silverLakehousepath/Oracle/DIM_CUSTOMERDATA"

fab ln $shortcutPath4 --type oneLake --target $targetPath4
Write-Host "✅ Shortcut created: DIM_CUSTOMERDATA"
fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$shortcutPath6 = "$aiLakehousepath/cust_segment.Shortcut"
$targetPath6 = "$silverLakehousepath/Oracle/cust_segment"

fab ln $shortcutPath6 --type oneLake --target $targetPath6


fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId


Write-Host "Creating Shortcut for df_orders"
$shortcutPath5 = "$aiLakehousepath/df_orders.Shortcut"
$targetPath5 = "$silverLakehousepath/Snowflake/df_orders"

fab ln $shortcutPath5 --type oneLake --target $targetPath5
Write-Host "✅ Shortcut created: df_orders"


fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId


Write-Host "Creating Shortcut for $dim_product"

$shortcutPath = "$aiLakehousepath/dim_product.Shortcut"
$targetPath = "$silverLakehousepath/AWS/dim_product"

fab ln $shortcutPath --type oneLake --target $targetPath
Write-Host "✅ Shortcut created: $table"


### Uploading PowerBI reports

$credential = New-Object PSCredential($appId, (ConvertTo-SecureString $clientsecpwdapp -AsPlainText -Force))

# Connect to Power BI using the service principal
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenantId

$PowerBIFiles = Get-ChildItem "./artifacts/reports" -Recurse -Filter *.pbix
$reportList = @()

foreach ($Pbix in $PowerBIFiles) {
Write-Output "Uploading report: $($Pbix.BaseName +'.pbix')"

$report = New-PowerBIReport -Path $Pbix.FullName -WorkspaceId $wsIdUnify_Dataplatform_2 -ConflictAction CreateOrOverwrite

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
RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdUnify_Dataplatform_2/datasets"
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
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdUnify_Dataplatform_2/datasets/$datasetId/Default.TakeOver"

try {
    $response = Invoke-RestMethod -Uri $url -Method POST -Headers @{ Authorization = "Bearer $powerbitoken" }
    Write-Host "TakeOver action completed successfully for dataset ID: $datasetId"
}
catch {
    Write-Host "Error occurred while performing TakeOver action for dataset ID: $datasetId - $_"
}
}


foreach ($report in $reportList) {
if ($report.Name -eq "Inventory on Hand(RetailIQ)") 
{
$body = "{
`"updateDetails`": [
    {
        `"name`": `"Server Name`",
        `"newValue`": `"$($queryUri)`"
    },
    {
        `"name`": `"DBName`",
        `"newValue`": `"$($KQLDB)`"
    }
]
}"

Write-Host "PBI connections updating for report : $($report.name)"	

$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdUnify_Dataplatform_2)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"

$pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
Authorization = "Bearer $powerbitoken"
} -ErrorAction SilentlyContinue

Start-Sleep -Seconds 5
}
elseif ($report.Name -eq "CEO Report") 
{
$body = "{
`"updateDetails`": [
    {
        `"name`": `"ServerName`",
        `"newValue`": `"$($SilverServerName)`"
    },
    {
        `"name`": `"DBName`",
        `"newValue`": `"$($lakehouseSilver)`"
    }
]
}"

Write-Host "PBI connections updating for report : $($report.name)"	

$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdUnify_Dataplatform_2)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"

$pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
Authorization = "Bearer $powerbitoken"
} -ErrorAction SilentlyContinue

Start-Sleep -Seconds 5
}
elseif ($report.Name -eq "Object Level Security in Warehouse" -or $report.Name -eq "Dynamic Data Masking in Warehouse" -or $report.Name -eq "Row-Level Security in Warehouse" -or $report.Name -eq "Column Level Security in Warehouse") 
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

$url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsIdUnify_Dataplatform_2)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"

$pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{
Authorization = "Bearer $powerbitoken"
} -ErrorAction SilentlyContinue

Start-Sleep -Seconds 5
}
}

### Azure cosmos DB

# az cosmosdb sql container create --account-name $cosmosdb_account --database-name "Inventory_Customersentiment" --name "Inventory_Customersentiment" --partition-key-path "/id" --resource-group $rgName --throughput "400"

RefreshTokens
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
# --------------------------------------------
# Variables
# --------------------------------------------
$cosmosDatabaseName = "Inventory_Customersentiment"
$cosmosFiles = Get-ChildItem "./artifacts/cosmos/" -Filter *.json
$partitionKeyPath = "/id"  # Update if your data uses a different partition key property

# Create Cosmos DB context (only once)
$cosmosDbContext = New-CosmosDbContext `
    -Account $cosmosdb_account `
    -Database $cosmosDatabaseName `
    -ResourceGroup $rgName

# --------------------------------------------
# Loop through each JSON file
# --------------------------------------------
foreach ($file in $cosmosFiles) {
    $containerName = $file.BaseName
    Write-Host "----------------------------------------"
    Write-Host "Processing file: $($file.Name)"
    Write-Host "Container name: $containerName"
    Write-Host "----------------------------------------"

    # Step 1: Check if container exists
    $existingContainer = Get-CosmosDbCollection -Context $cosmosDbContext -Id $containerName -ErrorAction SilentlyContinue

    if (-not $existingContainer) {
        Write-Host "Creating new container '$containerName' ..."
        New-CosmosDbCollection -Context $cosmosDbContext `
            -Id $containerName `
            -PartitionKey "/id" `
            -OfferThroughput 400 | Out-Null

    } else {
        Write-Host "Container '$containerName' already exists. Skipping creation."
    }

    # Step 2: Read and upload JSON documents
    $jsonPath = $file.FullName
    $documents = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json

    Write-Host "Uploading documents from $($file.Name) ..."

    foreach ($doc in $documents) {
        $docBody = $doc | ConvertTo-Json -Depth 10
        $partitionKeyValue = $doc.id

        try {
            New-CosmosDbDocument -Context $cosmosDbContext `
                -CollectionId $containerName `
                -DocumentBody $docBody `
                -PartitionKey $partitionKeyValue `
                -ErrorAction Stop | Out-Null

            Write-Host "✅ Inserted document with id: $partitionKeyValue"
        }
        catch {
            Write-Warning "⚠️ Failed to insert document with id: $partitionKeyValue"
        }
    }

    Write-Host "✅ Completed upload for container: $containerName"
}

# --------------------------------------------
# Additional container: func-supplychain-risk-mitigation
# --------------------------------------------
$additionalContainerName = "func-supplychain-risk-mitigation"
$productCatalogPath = "./artifacts/cosmos/ProductsCatalog.json"

Write-Host "`n----------------------------------------"
Write-Host "Processing additional container: $additionalContainerName"
Write-Host "JSON file: productcatalog.json"
Write-Host "----------------------------------------"

# Check if the container exists
$existingAdditionalContainer = Get-CosmosDbCollection -Context $cosmosDbContext -Id $additionalContainerName -ErrorAction SilentlyContinue

if (-not $existingAdditionalContainer) {
    Write-Host "Creating new container '$additionalContainerName' ..."
    New-CosmosDbCollection -Context $cosmosDbContext `
        -Id $additionalContainerName `
        -PartitionKey "/id" `
        -OfferThroughput 400 | Out-Null
} else {
    Write-Host "Container '$additionalContainerName' already exists. Skipping creation."
}

# Upload documents from productcatalog.json
if (Test-Path $productCatalogPath) {
    $productDocuments = Get-Content -Raw -Path $productCatalogPath | ConvertFrom-Json
    Write-Host "Uploading documents from productcatalog.json ..."

    foreach ($doc in $productDocuments) {
        $docBody = $doc | ConvertTo-Json -Depth 10
        $partitionKeyValue = $doc.id

        try {
            New-CosmosDbDocument -Context $cosmosDbContext `
                -CollectionId $additionalContainerName `
                -DocumentBody $docBody `
                -PartitionKey $partitionKeyValue `
                -ErrorAction Stop | Out-Null

            Write-Host "✅ Inserted document with id: $partitionKeyValue"
        }
        catch {
            Write-Warning "⚠️ Failed to insert document with id: $partitionKeyValue"
        }
    }

    Write-Host "✅ Completed upload for container: $additionalContainerName"
} else {
    Write-Warning "⚠️ File not found: $productCatalogPath"
}

Write-Host "`n🎉 All containers processed successfully!"

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


$endtime=get-date
$executiontime=$endtime-$starttime
Write-Host "Execution Time - "$executiontime.TotalMinutes

Write-Host "List of resources deployed in $rgName resource group"
$deployed_resources = Get-AzResource -resourcegroup $rgName
$deployed_resources = $deployed_resources | Select-Object Name, Type | Format-Table -AutoSize
Write-Output $deployed_resources


}

