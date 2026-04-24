
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
$rgName = "rg-telconoa-$suffix"
$Region = read-host "Enter the region for deployment."
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$location_1 = read-host "Enter the region for AI Foundary deployment with the necessary resources available, preferably "eastus2" "
$wsIdtelconoa =  Read-Host "Enter your 'Telco_NOA' PowerBI workspace Id "
$openAIResource = "openAIResource$suffix"
$workspaces_prj_name = "proj-telconoa-$suffix"
$aiServicesName = "prj-telconoa-$suffix-resource"
$aiHubName = "hub-$suffix"
$storage_account_name = "storage$suffix"
$cosmosdb_account       = "cosmosdb-$suffix"
$appServicePlanName = "asp-telconoa-$suffix"
$search_service = "srch-$suffix"
$func_scrm = "funcapp$suffix"
$serverfarm_asp_func_app_name = "asp$suffix"
$funstorageAccountName = "stfunc$suffix"
$func_scrm1 = "funcappworkflow$suffix"
$serverfarm_asp_func_app_name1 = "aspworkflow$suffix"
$funstorageAccountName1 = "stfuncworkflow$suffix"
$app_fabric_name = "app-telconoa-$suffix"
$accounts_cog_telconoa_name = "accounts-cog-telconoa-$suffix"

# $storage_account_AIstudio = "staistudio$suffix"


Write-Host "Deploying Resources on Microsoft Azure Started ..."
Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
Write-Host "Resource group $rgName creation COMPLETE"
    
Write-Host "Creating resources in $rgName..."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile "maintemplate.json" `
    -Mode Complete `
    -location $Region `
    -storage_account_name $storage_account_name `
    -cosmosdb_account $cosmosdb_account `
    -app_fabric_name $app_fabric_name `
    -appServicePlanName $appServicePlanName `
    -search_service $search_service `
    -func_scrm $func_scrm `
    -serverfarm_asp_func_app_name $serverfarm_asp_func_app_name `
    -funstorageAccountName $funstorageAccountName `
    -func_scrm1 $func_scrm1 `
    -serverfarm_asp_func_app_name1 $serverfarm_asp_func_app_name1 `
    -funstorageAccountName1 $funstorageAccountName1 `
    -accounts_cog_telconoa_name $accounts_cog_telconoa_name `
    -Force
    
$templatedeployment = Get-AzResourceGroupDeployment -Name "mainTemplate" -ResourceGroupName $rgName
$deploymentStatus = $templatedeployment.ProvisioningState
Write-Host "Deployment in $rgName : $deploymentStatus"

Add-Content log.txt "------Copying assets to the Storage Account------"
Write-Host "------------Copying assets to the Storage Account------------"



## storage AZ Copy
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storage_account_name)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_account_key

$destinationSasKey1 = New-AzStorageContainerSASToken -Container "network-security" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey1.StartsWith('?')) { $destinationSasKey1 = "?$destinationSasKey1"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/network-security$($destinationSasKey1)"
$azCopy_Data_container = azcopy copy "https://sttelconoadpoc.blob.core.windows.net/network-security/" $destinationUri --recursive

Write-Host "network-security copied"

$destinationSasKey2 = New-AzStorageContainerSASToken `
    -Container "sop-knowledge-articles" `
    -Context $dataLakeContext `
    -Permission rwdl

if (-not $destinationSasKey2.StartsWith('?')) {
    $destinationSasKey2 = "?$destinationSasKey2"
}

$destinationUri = "https://$($storage_account_name).blob.core.windows.net/sop-knowledge-articles$($destinationSasKey2)"

azcopy copy `
    "https://sttelconoadpoc.blob.core.windows.net/sop-knowledge-articles/*" `
    $destinationUri `
    --recursive

Write-Host "sop-knowledge-articles copied"


$destinationSasKey = New-AzStorageContainerSASToken -Container "telemetry" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/telemetry$($destinationSasKey)"
$azCopy_Data_container = azcopy copy "https://sttelconoadpoc.blob.core.windows.net/telemetry/" $destinationUri --recursive

Write-Host " telemetry copied"

$destinationSasKey3 = New-AzStorageContainerSASToken -Container "troubleshooting-guides" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey3.StartsWith('?')) { $destinationSasKey3 = "?$destinationSasKey3"}
$destinationUri = "https://$($storage_account_name).blob.core.windows.net/troubleshooting-guides$($destinationSasKey3)"
$azCopy_Data_container = azcopy copy "https://sttelconoadpoc.blob.core.windows.net/troubleshooting-guides/" $destinationUri --recursive

Write-Host "troubleshooting-guides-data copied"


$destinationSasKey4 = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey4.StartsWith('?')) { $destinationSasKey4 = "?$destinationSasKey4" }

$destinationUri = "https://$($storage_account_name).blob.core.windows.net/webappassets$($destinationSasKey4)"
$azCopy_Data_container = azcopy copy "https://sttelconoadpoc.blob.core.windows.net/webappassests/" $destinationUri --recursive

Write-Host "webappassets copied"


### Fabric starts here

RefreshTokens

$pat_token = $fabric

$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
}

$headers = @{
Authorization = "Bearer $global:fabric"
}

RefreshTokens

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdtelconoa";
$Telco_NOA_WsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$Telco_NOA_WsName = $Telco_NOA_WsName.name

# Create Service Principal for Power BI Fabric
Write-Host "------Creating Service Principal for Power BI Fabric------"

$spname = "telco noa demo $suffix"

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
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdtelconoa/users";
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

 
$PowerBIFiles = Get-ChildItem "./artifacts/reports" -Recurse -Filter *.pbix
$reportList = @()
 
foreach ($Pbix in $PowerBIFiles) {
Write-Output "Uploading report: $($Pbix.BaseName +'.pbix')"
 
$report = New-PowerBIReport -Path $Pbix.FullName -WorkspaceId $wsIdtelconoa -ConflictAction CreateOrOverwrite
 
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
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdtelconoa/datasets"
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


# TakingOver Datasets.
foreach ($report in $reportList) {
    $datasetId = $report.PowerBIDataSetId
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdtelconoa/datasets/$datasetId/Default.TakeOver"

    try {
        $response = Invoke-RestMethod -Uri $url -Method POST -Headers @{ Authorization = "Bearer $powerbitoken" }
        Write-Host "TakeOver action completed successfully for dataset ID: $datasetId"
    }
    catch {
        Write-Host "Error occurred while performing TakeOver action for dataset ID: $datasetId - $_"
    }
    }


pip install --user --upgrade pip setuptools
pip install --user packaging  # Packaging is required by ansible-core
pip install --user cryptography
pip install --user ms-fabric-cli


fab config set encryption_fallback_enabled true

fab auth login --username $appId --password $clientsecpwdapp --tenant $tenantId

$salesworkspacePath = "$Telco_NOA_WsName.Workspace"


Write-Host "------Creating Eventhouse------"

$KQLDB = "TelemetryTelcoNetworking"

fab mkdir $salesworkspacePath/$KQLDB.eventhouse

Write-Host "------Creating Eventhouse completed------"

Write-Host "------Creating Queryset------"
$Queryset = "TelemetryTelcoNetowking_queryset"

fab mkdir $salesworkspacePath/$Queryset.KQLQueryset

Write-Host "------Creating Queryset completed------"

### Azure cosmos DB


RefreshTokens
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
# --------------------------------------------
# Variables
# --------------------------------------------
$cosmosDatabaseName = "TelcoNOADB"
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
Write-Host "------------Deployment Completed Successfully------------"

#Search service 
Write-Host "-----------------Search service ---------------"
Add-Content log.txt "-----------------Search service ---------------"
RefreshTokens
Install-Module -Name Az.Search -f
# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $search_service
$primaryAdminKey = $adminKeyPair.Primary

#retirieving cosmos DB key
$cosmos_account_key = az cosmosdb keys list -n $cosmosdb_account -g $rgName | ConvertFrom-Json
$cosmos_account_key = $cosmos_account_key.primarymasterkey

$cosmosendpoint = "https://$cosmosdb_account.documents.azure.com:443/"

$cosmosconnectionstring = "AccountEndpoint=$cosmosendpoint;AccountKey=$cosmos_account_key;"
# Create Datasource endpoint1
Write-Host "Creating Data source in Azure search service..."
Get-ChildItem "artifacts/search" -Filter cosmosdb-noa-datasource.json |
        ForEach-Object {
            $datasourceDefinition = (Get-Content $_.FullName -Raw).replace("#SEARCHSERVICE#", $search_service).Replace("#COSMOSDBSTRING#", $cosmosconnectionstring)
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

             $url = "https://$search_service.search.windows.net/datasources?api-version=2023-11-01"
             Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $dataSourceDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

# Get OpenAI Key
$openAIPrimaryKey = az cognitiveservices account keys list -n $openAIResource -g $rgName | jq -r .key1

Write-Host "Creating Index in Azure search service..."
Get-ChildItem "artifacts/search" -Filter index-historical-tickets.json |
        ForEach-Object {
            $indexDefinition = (Get-Content $_.FullName -Raw).replace("#openairesource#", $openAIResource).replace("#openairesourcekey#", $openAIPrimaryKey)
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }
            $url = "https://$search_service.search.windows.net/indexes?api-version=2024-07-01"
            # $url = "https://$search_service.search.windows.net/indexes?api-version=2023-11-01-preview"
            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }
Start-Sleep -s 10



# Create Indexer1
Get-ChildItem "artifacts/search" -Filter indexer-historical-tickets.json |
    ForEach-Object {
        $indexerDefinition = (Get-Content $_.FullName -Raw).Replace("#SEARCHSERVICE#", $search_service)
        $headers = @{
            'api-key' = $primaryAdminKey
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }

        $url = "https://$search_service.search.windows.net/indexers?api-version=2023-11-01"
        Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexerDefinition | ConvertTo-Json
    }
Start-Sleep -s 10

# Write-Host "Fecthing Keys and Endpoints"
# $openAIModel1 = az cognitiveservices account deployment create -g $rgName -n $openAIResource --deployment-name "gpt-4o" --model-name "gpt-4o" --model-version "2024-11-20" --model-format OpenAI --sku-capacity 10 --sku-name "Standard" 
# $openAIModel2 = az cognitiveservices account deployment create -g $rgName -n $openAIResource --deployment-name "text-embedding-ada-002" --model-name "text-embedding-ada-002" --model-version "2" --model-format OpenAI --sku-capacity 10 --sku-name "Standard" 

$aifoundary = az cognitiveservices account create --name $aiServicesName --resource-group $rgName --kind AIServices --sku S0 --location $location_1 --allow-project-management
$aifoundarydomain = az cognitiveservices account update --name $aiServicesName --resource-group $rgName --custom-domain $aiServicesName
$aifoundaryproject = az cognitiveservices account project create --name $aiServicesName --resource-group $rgName --project-name $workspaces_prj_name --location $location_1
$aifoundarymodel =az cognitiveservices account deployment create --name $aiServicesName --resource-group $rgName --deployment-name gpt-4o --model-name gpt-4o --model-version 2024-05-13 --model-format OpenAI --sku-capacity 10

# Get AI Services Keys and Endpoints
$PROJECT_ENDPOINT = "https://$($aiServicesName).services.ai.azure.com/api/projects/$($workspaces_prj_name)"
$ENDPOINT_URL = "https://$($aiServicesName).openai.azure.com/openai/v1/"
$principalId = az functionapp identity show --name $func_scrm1 --resource-group $rgName --query principalId -o tsv

az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --role "Cognitive Services OpenAI User" --scope /subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$aiServicesName
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --role "Azure AI User" --scope /subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$aiServicesName




$configPI = az functionapp config appsettings set --name $func_scrm --resource-group $rgName --settings COSMOS_ENDPOINT=$cosmosendpoint
$configPI = az functionapp config appsettings set --name $func_scrm --resource-group $rgName --settings COSMOS_KEY=$cosmos_account_key
$configPI = az functionapp config appsettings set --name $func_scrm --resource-group $rgName --settings DATABASE_NAME="TelcoNOADB"
$configPI = az functionapp config appsettings set --name $func_scrm --resource-group $rgName --settings CONTAINER_NAME="trouble-tickets"


Write-Host "Uploading function app build, it may take upto 5 min..."

for ($i=1; $i -le 5; $i++) {
    try {
        Publish-AzWebApp -ResourceGroupName $rgName -Name $func_scrm `
            -ArchivePath "./artifacts/binaries/func-mcp-tmf-dpoc.zip" `
            -Force -Verbose -ErrorAction Stop
        Write-Host "Deployment succeeded on attempt $i"
        break
    } catch {
        Write-Warning "Attempt $i failed: $($_.Exception.Message)"
        Start-Sleep -Seconds 10
    }
}

$configPI = az functionapp config appsettings set --name $func_scrm1 --resource-group $rgName --settings PROJECT_ENDPOINT=$PROJECT_ENDPOINT
$configPI = az functionapp config appsettings set --name $func_scrm1 --resource-group $rgName --settings ENDPOINT_URL=$ENDPOINT_URL
$configPI = az functionapp config appsettings set --name $func_scrm1 --resource-group $rgName --settings DEPLOYMENT_NAME="gpt-4o"

for ($i=1; $i -le 5; $i++) {
    try {
        Publish-AzWebApp -ResourceGroupName $rgName -Name $func_scrm1 `
            -ArchivePath "./artifacts/binaries/func-telco-workflow-dpoc.zip" `
            -Force -Verbose -ErrorAction Stop
        Write-Host "Deployment succeeded on attempt $i"
        break
    } catch {
        Write-Warning "Attempt $i failed: $($_.Exception.Message)"
        Start-Sleep -Seconds 10
    }
}

Write-Host "-----------------Function app build deployment compeleted ---------------"
Add-Content log.txt "-----------------Function app build deployment compeleted  ---------------"



#webapp
Write-Host "Uploading webapp build..."

expand-archive -path "./artifacts/binaries/build.zip" -destinationpath "./build" -force

    $cognitiveEndpoint = az cognitiveservices account show -n $accounts_cog_telconoa_name -g $rgName | jq -r .properties.endpoint
 
    #retirieving cognitive service key
    $cognitivePrimaryKey = az cognitiveservices account keys list -n $accounts_cog_telconoa_name -g $rgName | jq -r .key1
(Get-Content -path ./build/appsettings.json -Raw) | Foreach-Object { $_ `
            -replace '#WORKSPACE_ID#', $wsIdtelconoa`
            -replace '#APP_ID#', $appId`
            -replace '#APP_SECRET#', $clientsecpwdapp`
            -replace '#TENANT_ID#', $tenantId`
            -replace '#REGION#', $Region`
            -replace '#COGNITIVE_SERVICE_ENDPOINT#', $cognitiveEndpoint`
            -replace '#COGNITIVE_KEY#', $cognitivePrimaryKey`
            -replace '#SITES_FSI2WEBAPP#', $app_fabric_name`
 
    } | Set-Content -Path ./build/appsettings.json
$personaUrl = "https://$storage_account_name.blob.core.windows.net/webappassets"
$IconBlobBaseUrl = "https://$storage_account_name.blob.core.windows.net/webappassets"

$filepath = "./build/wwwroot/environment-dpoc.js"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WorkspaceID#", $wsIdtelconoa).Replace("#StorageName#", $storage_account_name).Replace("#TelcoFunctionApp#", $func_scrm1).Replace("#BackendURL#", $app_fabric_name).Replace("#personaUrl#", $personaUrl).Replace("#IconBlobBaseUrl#", $IconBlobBaseUrl)
    Set-Content -Path $filepath -Value $item

    RefreshTokens
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdtelconoa/reports";
    $reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
    $reportList = $reportList.Value

    #update all th report ids in the poc web app...
    $ht = new-object system.collections.hashtable  
  
    $ht.add("#ReportID#", $($reportList | where { $_.name -eq "CEO Dashboard" }).id)

    $filePath = "./build/wwwroot/environment-dpoc.js";

    Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

compress-archive -path "./build/*" "./build.zip"

Publish-AzWebApp -ResourceGroupName $rgName -Name $app_fabric_name -ArchivePath "./build.zip" -Force -Verbose

Write-Host "----------------- webapp build deployment compeleted ---------------"

$endtime=get-date
$executiontime=$endtime-$starttime
Write-Host "Execution Time - "$executiontime.TotalMinutes

}

