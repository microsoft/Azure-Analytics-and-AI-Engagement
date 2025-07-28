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


## Checking Requirements
Add-Content log.txt "----------------Checking pre-requisites------------------"
Write-host "----------------Checking pre-requisites------------------"
Write-Host "Registering resource providers..."
# List of resource providers to check and register if not registered
$resourceProviders = @(
    "Microsoft.Databricks",
    "Microsoft.Fabric",
    "Microsoft.App",
    "Microsoft.Web",
    "Microsoft.CognitiveServices",
    "Microsoft.EventHub",
    "Microsoft.SQL",
    "Microsoft.Storage",
    "Microsoft.Compute"
)

# Loop through each resource provider
foreach ($provider in $resourceProviders) {
    # Get the registration state of the resource provider
    $providerState = (Get-AzResourceProvider -ProviderNamespace $provider).RegistrationState

    # Check if the resource provider is not registered
    if ($providerState -ne "Registered") {
        Write-Host "Registering resource provider: $provider" -ForegroundColor Yellow
        # Register the resource provider
        Register-AzResourceProvider -ProviderNamespace $provider
    } else {
        Write-Host "Resource provider $provider is already registered" -ForegroundColor Green
    }
}


[string]$suffix = -join ((48..57) + (97..122) | Get-Random -Count 7 | % { [char]$_ })
$rgName = "rg-fabric-adb-$suffix"
$Region = read-host "Enter the region for deployment"
$tenantId = (Get-AzContext).Tenant.Id
$databricks_workspace_name = "adb-fabric-$suffix"
$databricks_managed_resource_group_name = "rg-managed-adb-$suffix"
$userAssignedIdentities_ami_databricks_build = "ami-databricks-$suffix"
$dataLakeAccountName = "stfabricadb$suffix"
$databricksconnector = "access-adb-connector-$suffix"
$keyVaultName = "kv-adb-$suffix"
$containerName = "containerdatabricksmetastore"
$namespaces_adx_thermostat_occupancy_name = "evh-thermostat-$suffix"
$sites_adx_thermostat_realtime_name = "app-realtime-simulator-$suffix"
$serverfarm_adx_thermostat_realtime_name = "asp-realtime-simulator-$suffix"
$tenantId = (Get-AzContext).Tenant.Id
$mssql_server_name = "mssql$suffix"
$mssql_database_name = "SalesDb"
$mssql_administrator_login = "labsqladmin"
$sql_administrator_login_password = "Smoothie@2024"
$wsIdContosoSales =  Read-Host "Enter your PowerBI workspace Id "
$openAIResource = "openAIResource$suffix"
$useOpenAI = Read-Host "Do you want to use the Azure OpenAI endpoint for text embeddings? (yes/no)"
if ($useOpenAI -eq "yes"){$OpenAIregion = Read-Host "Enter the region for OpenAI resource"} else {$OpenAIregion = ""}

Write-Host "----FABRIC----"
Add-Content log.txt "Deploying resources on Microsoft Fabric Started..."
Write-Host "Deploying resources on Microsoft Fabric Started..."
RefreshTokens

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales";
$contosoSalesWsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$contosoSalesWsName = $contosoSalesWsName.name

$lakehouseBronze =  "lakehouse$suffix"

Write-Host "------------FABRIC assets deployment STARTS HERE------------"

Write-Host "------Creating Lakehouses in '$contosoSalesWsName' workspace------"
$lakehouseNames = @($lakehouseBronze)
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

Add-Content log.txt "-----Creation of Lakehouses in '$contosoSalesWsName' workspace COMPLETED------"
Write-Host "-----Creation of Lakehouses in '$contosoSalesWsName' workspace COMPLETED------"

RefreshTokens

Add-Content log.txt "------Creating Eventhouse------"
Write-Host "------Creating Eventhouse------"
    $KQLDB = "Contoso-Eventhouse"
    $body = @{
            displayName = $KQLDB 
        } | ConvertTo-Json
        
    try{
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/eventhouses"
$KQLDBAPI = Invoke-RestMethod $endPoint `
            -Method POST `
            -Headers $requestHeaders `
            -Body $body
            Write-Host "Eventhouse '$KQLDB' created successfully."
    }catch{
        Write-Host "Error creating Eventhouse '$KQLDB'"
    }
Start-Sleep -s 10 
Write-Host "-----------Creation of Eventhouse COMPLETED------------"


Write-Host "------------Uploading assets to Lakehouses------------"


& $azCopyCommand copy "https://stmsftbuild2024.blob.core.windows.net/copilotdata/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseBronze.Lakehouse/Tables/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
& $azCopyCommand copy "https://stmsftbuild2024.blob.core.windows.net/rawdata/*" "https://onelake.blob.fabric.microsoft.com/$contosoSalesWsName/$lakehouseBronze.Lakehouse/Files/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;

Write-Host "------------Uploading assets to Lakehouses COMPLETED------------"

Write-Host "Deploying Resources on Microsoft Azure Started ..."
Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
Write-Host "Resource group $rgName creation COMPLETE"

Write-Host "Creating resources in $rgName..."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-TemplateFile "mainTemplate.json" `
-Mode Complete `
-location $Region `
-databricks_workspace_name $databricks_workspace_name `
-databricks_managed_resource_group_name $databricks_managed_resource_group_name `
-userAssignedIdentities_ami_databricks_build $userAssignedIdentities_ami_databricks_build `
-storage_account_name $dataLakeAccountName `
-vaults_kv_databricks_prod_name $keyVaultName `
-sites_adx_thermostat_realtime_name $sites_adx_thermostat_realtime_name `
-serverfarm_adx_thermostat_realtime_name $serverfarm_adx_thermostat_realtime_name `
-namespaces_adx_thermostat_occupancy_name $namespaces_adx_thermostat_occupancy_name `
-mssql_server_name $mssql_server_name `
-mssql_database_name $mssql_database_name `
-mssql_administrator_login $mssql_administrator_login `
-sql_administrator_login_password $sql_administrator_login_password `
-Force

$templatedeployment = Get-AzResourceGroupDeployment -Name "mainTemplate" -ResourceGroupName $rgName
$deploymentStatus = $templatedeployment.ProvisioningState
Write-Host "Deployment in $rgName : $deploymentStatus"

if ($deploymentStatus -eq "Succeeded") {
    Write-Host "Template deployment succeeded. Have you provided yourself as account administrator on Databricks? (Yes/No)"

    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "Yes") {
        Write-Host "Proceeding with further resource creation..."
    } else {
        Write-Host "Further resource creation in Databricks will fail, proceeding with further deployment..."
    }
} else {
    Write-Host "Template deployment failed or is not complete. Aborting further actions,please redeploy the template. "
    exit
}

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


## storage az copy
Write-Host "Copying files to Storage Container"

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$destinationSasKey = New-AzStorageContainerSASToken -Container "data" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/data$($destinationSasKey)"
$azCopy_Data_container = & $azCopyCommand copy "https://stmsftbuild2024.blob.core.windows.net/data/" $destinationUri --recursive

if ($LASTEXITCODE -eq 0) {
    Write-Output "azcopy completed successfully."
} else {
    Write-Output "azcopy failed with exit code $LASTEXITCODE. Output: $azCopy_Data_container"
}

## mssql
Write-Host "---------Loading files to MS SQL DB--------"
Add-Content log.txt "-----Loading files to MS SQL DB-----"
$SQLScriptsPath="./artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/salesSqlDbScript.sql"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_database_name -Username $mssql_administrator_login -Password $sql_administrator_login_password
Write-Host "---------Loading files to MS SQL DB COMPLETE--------"
Add-Content log.txt "-----Loading files to MS SQL DB COMPLETE-----"

Write-Host  "---------Deploying the simulator web app-----------"
RefreshTokens

$zips = @("app-adx-thermostat-realtime")
foreach($zip in $zips)
{
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

# ADX Thermostat Realtime
$thermostat_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name thermostat --name thermostat | ConvertFrom-Json
$thermostat_endpoint = $thermostat_endpoint.primaryConnectionString

(Get-Content -path adx-config-appsetting.json -Raw) | Foreach-Object { $_ `
    -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_THERMOSTAT_ENDPOINT#', $thermostat_endpoint`
   -replace '#THERMOSTATTELEMETRY_URL#', $thermostat_telemetry_Realtime_URL`
} | Set-Content -Path adx-config-appsetting-with-replacement.json

$config = az webapp config appsettings set -g $rgName -n $sites_adx_thermostat_realtime_name --settings @adx-config-appsetting-with-replacement.json

# Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_adx_thermostat_realtime_name -ArchivePath ./artifacts/binaries/app-adx-thermostat-realtime.zip -Force

Write-Information "Deploying Realtime Simulator App"
cd app-adx-thermostat-realtime

# number of retries
$maxRetries = 2
# delay 
$retryDelay = 10

# Retry counter
$count = 0

while ($count -lt $maxRetries) {
    az webapp up --resource-group $rgName --name $sites_adx_thermostat_realtime_name --plan $serverfarm_adx_thermostat_realtime_name --location $region

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Web app build deployed successfully."
        break
    } else {
        Write-Host "Failed to deploy web app build. Retrying in $retryDelay seconds..."
        $count++
        Start-Sleep -Seconds $retryDelay
    }
}

if ($count -eq $maxRetries) {
    Write-Host "Failed to deploy web app build after $maxRetries attempts."
    exit 1
}
cd ..

##Role assingment for managed identity##
Write-Host "Assigning required roles to managed identity..."
$userassignedidentityid = (Get-AzUserAssignedIdentity -Name "ami-databricks-$suffix" -ResourceGroupName $rgName).clientid
$assignment1 = az role assignment create --role "Key Vault Reader" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName/providers/Microsoft.KeyVault/vaults/$keyVaultName
$assignment2 = az role assignment create --role "Storage Blob Data Contributor" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName
$asssignment3 = az role assignment create --role "Contributor" --assignee $userassignedidentityid --scope /subscriptions/$subscriptionId/resourcegroups/$rgName
$asssignment4 = az keyvault set-policy --name $keyVaultName --upn $signedinusername --secret-permissions set list get

$roleassigments = If ($assignment1,$assignment2,$assignment3,$asssignment4 -ne $null) {"Role assignment COMPLETE..."} Else {"Role assignment Failed"}
write-host $roleassigments

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$filesystemName = "containerdatabricksmetastore"
$dirname = "metastore_root/"
$directory = New-AzDataLakeGen2Item -Context $dataLakeContext -FileSystem $filesystemName -Path $dirname -Directory

$dir = if ($directory -ne $null) {"created container named containerdatabricksmetastore"} Else {"failed to create container containerdatabricksmetastore"}
write-host $dir 

## Create Directory in ADLS Gen2
#az storage fs directory create -n metastore_root -f "containerdatabricksmetastore" --connection-string myconnectionstring
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

$pattokenvalidation = if($pat_token -ne $null){"Pat token created"}Else{"Failed to create pat token"}
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

    $body = '{
    "cluster_name": "PersonalCluster",
    "spark_version": "13.3.x-scala2.12",
    "spark_conf": {
        "spark.master": "local[*, 4]",
        "spark.databricks.cluster.profile": "singleNode"
    },
    "azure_attributes": {
        "first_on_demand": 1,
        "availability": "ON_DEMAND_AZURE",
        "spot_bid_max_price": -1
    },
    "node_type_id": "Standard_DS3_v2",
    "driver_node_type_id": "Standard_DS3_v2",
    "custom_tags": {
        "ResourceClass": "SingleNode"
    },
    "autotermination_minutes": 45,
    "enable_elastic_disk": true,
    "data_security_mode": "SINGLE_USER",
    "runtime_engine": "STANDARD",
    "num_workers": 0
}'

$endPoint = $baseURL + "/api/2.0/clusters/create"
$clusterId_1 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$clusterstatus = if($clusterId_1.cluster_id -ne $Null) {"cluster has been created successfully."} else {"cluster creation failed."}
write-host $clusterstatus
$clusterId_1 = $clusterId_1.cluster_id

Write-Host "Creating ML CLUSTER in Azure Databricks..."

    $body = '{
    "cluster_name": "ML Cluster",
    "spark_version": "15.2.x-cpu-ml-scala2.12",
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

$MLclusterstatus = if($MLcluster.cluster_id -ne $Null) {"ML cluster has been created successfully."} else {"ML cluster creation failed."}
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
  "name": "metastore-'+$Region+'",
  "storage_root": "abfss://'+ $containerName + '@' + $dataLakeAccountName + '.dfs.core.windows.net/metastore_root",
  "region": "' + $Region +'"
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/metastores"
    $metastore= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Start-Sleep -Seconds 5
$metastorestatus = if($metastore.metastore_id -ne $Null) {"Metastore has been created successfully."} else {"Metastore creation failed."}
Write-host $metastorestatus
$metastoreid = $metastore.metastore_id


## Assigning metastore to workspace 
Write-Host "Assigning Metastore to your Azure Databricks workspace..."

$body = '{
  "metastore_id": "' + $metastoreid + '"
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/workspaces/$dbsId/metastore"
    $metastorews= Invoke-RestMethod $endPoint `
        -Method PUT `
        -Headers $requestHeaders `
        -Body $body

## fecthing workspace assignment
$endPoint = $baseURL + "/api/2.1/unity-catalog/current-metastore-assignment"
    $metastorewsassignment= Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders
        
$metastorewsassignmentstatus = if($metastorewsassignment.metastore_id -ne $Null){"Metastore has been assigned to your Azure Databricks workspace."} else {" Failed to assign Metastore Azure Databricks workspace."}
write-host $metastorewsassignmentstatus

## Get SQL warehouse
$endPoint = $baseURL + "/api/2.0/sql/warehouses"
    $warehouse= Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders 

$warehouse = $warehouse.warehouses.id

## Start a warehouse
Write-Host "Starting SQL Warehouse, it may take a while..."

$endPoint = $baseURL + "/api/2.0/sql/warehouses/$warehouse/start"
    $warehouse= Invoke-RestMethod $endPoint `
        -Method POST `
        -Headers $requestHeaders 

Start-Sleep -Seconds 400
## Fecthing Warehouse State
$endPoint = $baseURL + "/api/2.0/sql/warehouses"
    $warehouse= Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders 

$warehousestate = $warehouse.warehouses.state

$warehousestatus = if($warehousestate -eq "RUNNING"){"Warehouse Started."} else {"Warehouse is $warehousestate" }
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
    $storagecred= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Start-Sleep -Seconds 5
$storagecredstatus = if($storagecred.id -ne $Null){"Storage credentials has been created successfully."} else {"Failed to create Storage Credentials."}
write-host $storagecredstatus

##Creating External location 
Write-Host "Creating External Location..."

$body = 
'{
  "name": "externalbuild",
  "url": "abfss://'+ $containerName + '@' + $dataLakeAccountName + '.dfs.core.windows.net/metastore_root",
  "credential_name": "storagecred",
  "read_only": false,
  "comment": "string",
  "skip_validation": true
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/external-locations"
    $extlocation= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Start-Sleep -Seconds 5
$extlocationstatus = if($extlocation.id -ne $Null){"External location has been created successfully."} else {"Failed to create External location."}
write-host $extlocationstatus

## creating Unity Catalog
Write-Host "Creating Unity Catalog..."

$body = 
'{
  "name": "litware_unity_catalog",
  "comment": "none",
  "properties": {},
  "storage_root": "abfss://'+ $containerName + '@' + $dataLakeAccountName + '.dfs.core.windows.net/metastore_root/catalog"
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/catalogs"
    $catalog = Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Start-Sleep -Seconds 5
$catalogstatus = if($catalog.id -ne $Null){"Unity Catalog has been created successfully."} else {"Failed to create Unity Catalog."}
write-host $catalogstatus

##Creating Schema
Write-Host "Creating Schema..."

$body = 
'{
  "name": "rag",
  "catalog_name": "litware_unity_catalog",
  "comment": "schema",
  "properties": {
  },
  "storage_root": "abfss://'+ $containerName + '@' + $dataLakeAccountName + '.dfs.core.windows.net/metastore_root/ragschema"
}'


$endPoint = $baseURL + "/api/2.1/unity-catalog/schemas"
    $schema= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Start-Sleep -Seconds 5
$schemastatus = if($schema.schema_id -ne $Null){"Schema has been created successfully."} else {"Failed to create Schema."}
write-host $schemastatus
$schema = $schema.schema_id

# create Volume
Write-Host "Creating Volume..."

$maxRetries = 1
$retryIntervalSeconds = 2

for ($i = 0; $i -lt $maxRetries; $i++) {
    
$body = '{
  "catalog_name": "litware_unity_catalog",
  "schema_name": "rag",
  "name": "documents_store",
  "volume_type": "MANAGED"
}'

$endPoint = $baseURL + "/api/2.1/unity-catalog/volumes"
    $volume= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body
    
    if ($volume.volume_id -ne $Null) {
        Write-Host "Volume has been created successfully."
        break  # Exit the loop if Volume is created.
    } else {
        Write-Host "creating Volume is in progress. Retrying in $retryIntervalSeconds seconds..."
        Start-Sleep -Seconds $retryIntervalSeconds
    }
}

if ($i -eq $maxRetries) {
    Write-Host "Max retries reached. Failed to create Volume."
}

# create Directory 
Write-Host "Creating Directories in Volume..."

$endPoint = $baseURL + "/api/2.0/fs/directories/Volumes/litware_unity_catalog/rag/documents_store/pdf_documents"
    $volume= Invoke-RestMethod $endPoint `
        -Method PUT `
        -Headers $requestHeaders 

## MKT Data Directory
$endPoint = $baseURL + "/api/2.0/fs/directories/Volumes/litware_unity_catalog/rag/documents_store/MktData"
    $volume= Invoke-RestMethod $endPoint `
        -Method PUT `
        -Headers $requestHeaders 

Write-Host "Directories creation in Volume. COMPLETE.."

# create diretory in Shared folder
Write-Host "Creating directory in Shared folder..."
##RetrievalAugmentedGeneration

$body = '{
  "path": "/Workspace/Shared/RetrievalAugmentedGeneration"
}'

$endPoint = $baseURL + "/api/2.0/workspace/mkdirs"
    $volume= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

##Analytics with ADB

$body = '{
  "path": "/Workspace/Shared/Analytics with ADB"
}'

$endPoint = $baseURL + "/api/2.0/workspace/mkdirs"
    $volume= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Write-Host "Directory created successfully in shared folder."
Start-Sleep -Seconds 5

(Get-Content -path "artifacts/databricks/02 ML Solutions in a Box.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#DATABRICKS_TOKEN#', $pat_token `
            -replace '#WORKSPACE_URL#', $baseUrl `
} | Set-Content -Path "artifacts/databricks/02 ML Solutions in a Box.ipynb"


#uploading Notebooks
Write-Host "Uploading Notebooks in shared folder..."

$files = Get-ChildItem -path "artifacts/databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
    Set-Location ./artifacts/databricks
   foreach ($file in $files) {
    if ($file.Name -eq "00-init.ipynb" -or $file.Name -eq "1. Create a delta table from UC volume with Autoloader.ipynb" -or $file.Name -eq "2. Ingesting and preparing PDF for LLM and Self Managed Vector Search Embeddings.ipynb") {
        $fileContent = Get-Content -Raw $file.FullName
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
        
        # Extract the name without extension
        $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $body = '{"content": "' + $fileContentEncoded + '",  "path": "/Workspace/Shared/RetrievalAugmentedGeneration/' + $nameWithoutExtension + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
            #get job list
            $endPoint = $baseURL + "/api/2.0/workspace/import"
            $result = Invoke-RestMethod $endPoint `
                -ContentType 'application/json' `
                -Method Post `
                -Headers $requestHeaders `
                -Body $body
        }
        elseif ($file.Name  -eq "3. Register and Deploy RAG model as Endpoint.ipynb" -or $file.Name -eq "4. Notebook to analyze customer churn.ipynb" -or $file.Name -eq "2.1 (Azure OpenAI) Ingesting and preparing PDF for LLM and Self Managed Vector Search Embeddings.ipynb") { 
        $fileContent = Get-Content -Raw $file.FullName
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
        $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $body = '{"content": "' + $fileContentEncoded + '",  "path": "/Workspace/Shared/RetrievalAugmentedGeneration/' + $nameWithoutExtension + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
            #get job list
            $endPoint = $baseURL + "/api/2.0/workspace/import"
            Invoke-RestMethod $endPoint `
                -ContentType 'application/json' `
                -Method Post `
                -Headers $requestHeaders `
                -Body $body
        }
        elseif ($file.Name  -eq "01 DLT Notebook.ipynb" -or $file.Name -eq "02 ML Solutions in a Box.ipynb") { 
        $fileContent = Get-Content -Raw $file.FullName
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
        $nameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $body = '{"content": "' + $fileContentEncoded + '",  "path": "/Workspace/Shared/Analytics with ADB/' + $nameWithoutExtension + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
            #get job list
            $endPoint = $baseURL + "/api/2.0/workspace/import"
            Invoke-RestMethod $endPoint `
                -ContentType 'application/json' `
                -Method Post `
                -Headers $requestHeaders `
                -Body $body

         }
   }

Set-Location ../../

if ($LASTEXITCODE -eq 0) {
    Write-Output "Notebooks upload completed successfully."
} else {
    Write-Output "Notebooks upload failed with exit code $LASTEXITCODE."
}


## fecthing Volume id 

$endPoint = $baseURL + "/api/2.1/unity-catalog/volumes/litware_unity_catalog.rag.documents_store"
    $volume= Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders 

$volumestatus = if($volume -ne $null){"Volume have been created successfully"}Else{"Failed to create volume"}
$volumeid = $volume.volume_id
write-host $volumestatus

## uploading PDFs to volume 
Write-Host "Uploading PDFs to volume... "

$destinationSasKey = New-AzStorageContainerSASToken -Container "containerdatabricksmetastore" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/containerdatabricksmetastore/metastore_root/ragschema/__unitystorage/schemas/$($schema)/volumes/$($volumeid)/pdf_documents$($destinationSasKey)"
$volupload1 = & $azCopyCommand copy "https://stmsftbuild2024.blob.core.windows.net/pdfs/*" $destinationUri --recursive

$volupload1 = if ($LASTEXITCODE -eq 0) {
    "PDF upload to volume COMPLETE...."
} else {
     "Upload failed with exit code $LASTEXITCODE. Output: $volupload1"
}
write-host $volupload1

# Uploading CSV to Volume
Write-Host "Uploading CSVs to volume... "

$destinationSasKey = New-AzStorageContainerSASToken -Container "containerdatabricksmetastore" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/containerdatabricksmetastore/metastore_root/ragschema/__unitystorage/schemas/$($schema)/volumes/$($volumeid)/MktData$($destinationSasKey)"
$volupload2 = & $azCopyCommand copy "https://stmsftbuild2024.blob.core.windows.net/silverchurn/*" $destinationUri --recursive

$volupload2 = if ($LASTEXITCODE -eq 0) {
    "CSVs upload to volume COMPLETE...."
} else {
     "Upload failed with exit code $LASTEXITCODE. Output: $volupload2"
}
write-host $volupload2



#Creating Jobs to run Notebooks
Write-Host "Creating Jobs to run Notebooks..."

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
        "notebook_path": "/Shared/RetrievalAugmentedGeneration/1. Create a delta table from UC volume with Autoloader",
        "source": "WORKSPACE"
      },
      "existing_cluster_id": "'+$clusterId_1+'",
      "timeout_seconds": 0,
      "email_notifications": {}
    }
  ]
}'

  $endPoint = $baseURL + "/api/2.1/jobs/create"
    $job1= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

$job1status = if($Null -ne $job1.job_id){"Created a job for first Notebook."} else {"Failed to create a job for first Notebook."}
write-host $job1status
$job1id = $job1.job_id


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
        "notebook_path": "/Shared/RetrievalAugmentedGeneration/2. Ingesting and preparing PDF for LLM and Self Managed Vector Search Embeddings",
        "source": "WORKSPACE"
      },
      "existing_cluster_id": "'+$clusterId_1+'",
      "timeout_seconds": 0,
      "email_notifications": {}
    }
  ]
}'

$endPoint = $baseURL + "/api/2.1/jobs/create"
    $job2= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

$job2status = if($job2.job_id -ne $null){"Created a job for second Notebook."} else {"Failed to create a job for second Notebook."}
write-host $job2status
$job2id = $job2.job_id

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
        "notebook_path": "/Shared/RetrievalAugmentedGeneration/2.1 (Azure OpenAI) Ingesting and preparing PDF for LLM and Self Managed Vector Search Embeddings",
        "source": "WORKSPACE"
      },
      "existing_cluster_id": "'+$clusterId_1+'",
      "timeout_seconds": 0,
      "email_notifications": {}
    }
  ]
}'

$endPoint = $baseURL + "/api/2.1/jobs/create"
    $job3= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

$job3status = if($job3.job_id -ne $null){"Created a job for Third Notebook."} else {"Failed to create a job for Third Notebook."}
write-host $job3status
$job3id = $job3.job_id

#Create a job for Fourth notebook
Write-Host "Creating job for Fourth Notebook..."

$body = '{
  "name": "fourth notebook run",
  "email_notifications": {
    "no_alert_for_skipped_runs": false
  },
  "webhook_notifications": {},
  "timeout_seconds": 0,
  "max_concurrent_runs": 1,
  "tasks": [
    {
      "task_key": "fourth_notebook_run",
      "run_if": "ALL_SUCCESS",
      "notebook_task": {
        "notebook_path": "/Shared/RetrievalAugmentedGeneration/3. Register and Deploy RAG model as Endpoint",
        "source": "WORKSPACE"
      },
      "existing_cluster_id": "'+$MLcluster+'",
      "timeout_seconds": 0,
      "email_notifications": {}
    }
  ]
}'

$endPoint = $baseURL + "/api/2.1/jobs/create"
    $job4= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

$job4status = if($job4.job_id -ne $null){"Created a job for Fourth Notebook."} else {"Failed to create a job for Fourth Notebook."}
write-host $job4status
$job4id = $job4.job_id

#Running jobs
#Running job1
Write-Host "Running job1"

$maxRetries = 3
$retryIntervalSeconds = 300
$clusterState = $null
$run1 = $null

# Loop to retrieve cluster state and check if it's "RUNNING"
for ($i = 0; $i -lt $maxRetries; $i++) {
    $body = '{"cluster_id": "' + $clusterId_1 + '"}'
    $endPoint = $baseURL + "/api/2.0/clusters/get"
    $clusterResponse = Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body
    
    $clusterState = $clusterResponse.state
    
    if ($clusterState -eq "RUNNING") {
        Write-Host "Cluster is running. Proceeding with job execution."
        $jobBody = '{"job_id": "' + $job1id + '"}'
        $jobEndPoint = $baseURL + "/api/2.1/jobs/run-now"
        $run1 = Invoke-RestMethod $jobEndPoint `
            -Method Post `
            -Headers $requestHeaders `
            -Body $jobBody
        break  # Exit the loop if cluster is running
    } else {
        Write-Host "Cluster is provisioning. Retrying in $retryIntervalSeconds seconds..."
        Start-Sleep -Seconds $retryIntervalSeconds
    }
}

if ($i -eq $maxRetries) {
    Write-Host "Max retries reached. Cluster is still not running."
} else {
    Start-Sleep -Seconds 300
    
    # Stop job1
    Write-Host "Stopping job1"

    if ($run1 -ne $null) {
        $body = '{"run_id": "' + $run1.run_id + '"}'
        $endPoint = $baseURL + "/api/2.1/jobs/runs/cancel"
        $run1 = Invoke-RestMethod $endPoint `
            -Method Post `
            -Headers $requestHeaders `
            -Body $body
        Write-Host "Job1 stopped successfully."
    } else {
        Write-Host "Error: Failed to stop job1, please stop the job manually."
    }
}


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

$endpoint_vector = if($endpoint_vector -ne $null){"Enpoint have been created successfully."} else {"Failed to create an Endpoint for vector index."}
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

$Secscope = if($createScopeCommand -ne $null){"Secret scope have been created successfully."} else {"Failed to create secret scope."}
Write-Host $Secscope


if ($useOpenAI -eq "yes") {

#creating Keyvault backed secret scope
write-host "creating Azure openAI resource..."

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-TemplateFile "OpenAI.json" `
-Mode Incremental `
-location $OpenAIregion `
-aoai_fabric_adb $openAIResource `
-Force

#creating model
$openAIModel1 = az cognitiveservices account deployment create -g $rgName -n $openAIResource --deployment-name "text-embedding-ada-002" --model-name "text-embedding-ada-002" --model-version "2" --model-format OpenAI --sku-capacity 30 --sku-name "Standard"

#retrieving openai endpoint
$openAIEndpoint = az cognitiveservices account show -n $openAIResource -g $rgName | jq -r .properties.endpoint

$openAIbase = "https://$openAIResource.openai.azure.com/"
#retirieving primary key
$openAIPrimaryKey = az cognitiveservices account keys list -n $openAIResource -g $rgName | jq -r .key1

write-host "Adding OpenAI key in the Keyvault..."

$secret2 = az keyvault secret set --name "openai-key" --value $openAIPrimaryKey --vault-name $keyVaultName

write-host "Registering OpenAI text-embedding-ada-002 as external model..."

$body = '{
  "name": "text-embedding-ada-002-Azure-OpenAI",
  "config": {
    "served_entities": [
      {
        "name": "text-embedding-ada-002",
        "external_model": {
          "name": "text-embedding-ada-002",
          "provider": "openai",
          "task": "llm/v1/embeddings",
          "openai_config": {
            "openai_api_key": "{{secrets/databricksscope/openai-key}}",
            "openai_api_type": "azure",
            "openai_api_base": "'+$openAIbase+'",
            "openai_api_version": "2024-02-15-preview",
            "openai_deployment_name": "text-embedding-ada-002"
             
          }
        }
      }
    ]
  }
}'

$endPoint = $baseURL + "/api/2.0/serving-endpoints"
$extendpoint = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$extendpoint = if($extendpoint -ne $null){"registered OpenAI text-embedding-ada-002 as external model."} else {"Failed to register OpenAI text-embedding-ada-002 as external model."}
Write-Host $extendpoint 

#Running job3
Write-Host "Running job3"

$body = '{"job_id": "'+$job3id+'"}'

$endPoint = $baseURL + "/api/2.1/jobs/run-now"
    $run3= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Write-Host "Please wait while the job is ready..."
Start-Sleep -Seconds 400

## creating Vector index
Write-Host "Creating vector index..."

$body = '{
  "name": "litware_unity_catalog.rag.vector_search_index",
  "endpoint_name": "vector_search_endpoint",
  "primary_key": "id",
  "index_type": "DELTA_SYNC",
  "delta_sync_index_spec": {
    "source_table": "litware_unity_catalog.rag.documents_embedding_openai",
    "pipeline_type": "TRIGGERED",
    "embedding_source_columns": [
      {
        "name": "content",
        "embedding_model_endpoint_name": "text-embedding-ada-002-Azure-OpenAI"
      }
    ]
  }
}'


$endPoint = $baseURL + "/api/2.0/vector-search/indexes"
    $Vectorindex = Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

$Vectorindex = if($Vectorindex -ne $null){"Vector Index have been created successfully."} else {"Failed to create vector index."}

Write-Host $Vectorindex 

} elseif ($useOpenAI -eq "no") {

#Running job2 
Write-Host "Running job2"

$body = '{"job_id": "'+$job2id+'"}'

$endPoint = $baseURL + "/api/2.1/jobs/run-now"
    $run2= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Write-Host "Please wait while the job is ready..."
Start-Sleep -Seconds 400

## creating Vector index
Write-Host "Creating vector index..."

$body = '{
  "name": "litware_unity_catalog.rag.vector_search_index",
  "endpoint_name": "vector_search_endpoint",
  "primary_key": "id",
  "index_type": "DELTA_SYNC",
  "delta_sync_index_spec": {
    "source_table": "litware_unity_catalog.rag.documents_embedding",
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

$Vectorindex = if($Vectorindex -ne $null){"Vector Index have been created successfully."} else {"Failed to create vector index."}

Write-Host $Vectorindex

}
else {
    Write-Host "Invalid input. Please enter 'yes' or 'no'."
}

Write-Host "It takes around 10 minutes for Vector Index after being created to change its status to Online..."
Write-Host "Please wait..."
Start-Sleep -Seconds 600

# # Function to fetch updated status of runs
function FetchUpdatedStatus {
    $endPoint = $baseURL + "/api/2.1/jobs/runs/list"
    $updatedStatus = Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders 

    return $updatedStatus.runs
}

# Main function to fetch and process runs
function FetchAndProcessRuns {
    $runs = FetchUpdatedStatus

    foreach ($run in $runs) {
        $state = $run.state.life_cycle_state
        $run_name = $run.run_name
        $result_state = $run.state.result_state
        $user_cancelled = $run.state.user_cancelled_or_timedout

        if ($state -eq "RUNNING") {
            Write-Host "Run '$run_name' is still running..."
            Start-Sleep -Seconds 60
            $runs = FetchUpdatedStatus
        }
        else {
            if ($result_state -eq "SUCCESS") {
                Write-Host "Run '$run_name' succeeded."
            }
            elseif ($result_state -eq "CANCELED") {
                if ($user_cancelled) {
                    Write-Host "Run '$run_name' was stopped by user once it was completed."
                }
                else {
                    Write-Host "Run '$run_name' was canceled."
                }
            }
            else {
                Write-Host "Run '$run_name' failed."
            }
        }
    }
}

# Call the main function to start fetching and processing runs
FetchAndProcessRuns

#Running job4 
Write-Host "Running job4"

$body = '{"job_id": "'+$job4id+'"}'

$endPoint = $baseURL + "/api/2.1/jobs/run-now"
    $run4= Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

Write-Host "Deploying Resources on Azure Databricks Completed... "


$endtime=get-date
$executiontime=$endtime-$starttime
Write-Host "Execution Time - "$executiontime.TotalMinutes

Write-Host "List of resources deployed in $rgName resource group"
$deployed_resources = Get-AzResource -resourcegroup $rgName
$deployed_resources = $deployed_resources | Select-Object Name, Type | Format-Table -AutoSize
Write-Output $deployed_resources

RefreshTokens
Write-Host "List of resources deployed in $contosoSalesWsName workspace"
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsIdContosoSales/items"
$fabric_items = Invoke-RestMethod $endPoint `
        -Method GET `
        -Headers $requestHeaders 

$table = $fabric_items.value | Select-Object DisplayName, Type | Format-Table -AutoSize
Write-Output $Table

$operationStatus = @("mainTemplate : $deploymentStatus","DatabricksConnector : $datbricksconnectorstatus",$roleassigments,$dir,$pattokenvalidation,$clusterstatus,$MLcluster,$metastorestatus,$metastorewsassignmentstatus,$warehousestatus,$storagecredstatus,$extlocationstatus,$catalogstatus,$schemastatus,$volupload1,$volupload2,$job1status,$job2status,$job3status,$endpoint_vector,$Vectorindex,$Secscope)
$executionStatus = if ($operationStatus -contains $Null) {"Execution completed with errors."} else {"-----------------EXECUTION COMPLETED---------------"}
Write-Host "Operation Status:"
$operationStatus
Write-Host $executionStatus
Stop-Transcript




