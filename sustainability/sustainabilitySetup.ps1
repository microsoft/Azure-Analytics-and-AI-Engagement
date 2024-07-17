function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
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
$starttime = get-date

az login

$subscriptionId = (az account show --query 'id' -o tsv)
 
#for powershell...
Connect-AzAccount -DeviceCode -SubscriptionId $subscriptionId

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

Write-Host "------------Prerequisites------------"
## Checking Requirements
Write-host "----------------Checking pre-requisites------------------"

$subscriptionId = (Get-AzContext).Subscription.Id
$signedinusername = az ad signed-in-user show | ConvertFrom-Json
$signedinusername = $signedinusername.userPrincipalName

# Check if the user has Contributor role on the subscription
Write-Host "Check if the Contributor has Owner role on the subscription..."

$roleAssignments = az role assignment list --assignee $signedinusername --subscription $subscriptionId | ConvertFrom-Json
$hasContributorRole = $roleAssignments | Where-Object { $_.roleDefinitionName -eq "Contributor" }
$hasOwnerRole = $roleAssignments | Where-Object { $_.roleDefinitionName -eq "Owner" }

if ($null -ne $hasContributorRole) {
    Write-Host "User has Contributor permission on the subscription. Proceeding..." -ForegroundColor Green
} elseif ($null -ne $hasOwnerRole) {
    Write-Host "User has Owner permission on the subscription. Proceeding..." -ForegroundColor Green
} else {
    Write-Host "User does not have Contributor or Owner permission on the subscription. Deployment will fail. Would you still like to continue? (Yes/No)" -ForegroundColor Red

    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "Yes") {
        Write-Host "Proceeding with deployment..."
    } else {
        Write-Host "Aborting deployment."
        exit
    }
}

Write-Host "Registering resource providers..."
# List of resource providers to check and register if not registered
$resourceProviders = @(
    "Microsoft.Fabric",
    "Microsoft.App",
    "Microsoft.Web",
    "Microsoft.CognitiveServices",
    "Microsoft.Storage"
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


$esc = [char]27
Write-Host "$esc[1mOther prerequisites need to be ensured before the deployment:$esc[0m"
Write-Host "-An Azure Account with the ability to create Fabric Workspace."
Write-Host "-A Power BI with Fabric License to host Power BI reports."
Write-Host "-Make sure your Power BI administrator can provide service principal access on your Power BI tenant."
Write-Host "-Make sure you use the same valid credentials to log into Azure and Power BI."

Write-Host "    -----------------   "
Write-Host "    -----------------   "
Write-Host "If you fulfill the above requirements please process otherwise press 'Ctrl+C' to end script execution."
Write-Host "    -----------------   "
Write-Host "    -----------------   "

Start-Sleep -s 30

[string]$suffix = -join ((48..57) + (97..122) | Get-Random -Count 7 | % { [char]$_ })
#$rgName = "dpoc-test"
$rgName = "sustainability-dpoc-$suffix"
$Region = Read-Host "Enter the region for deployment "
$storageAccountName = "stsustainability$suffix"
if($storageAccountName.length -gt 24)
{
$storageAccountName = $storageAccountName.substring(0,24)
}
$speech_service_name = "speech-service-$suffix"
$app_sustainability_name = "app-sustainability-$suffix"
$asp_sustainability_name = "asp-sustainability-$suffix"
$tenantId = (Get-AzContext).Tenant.Id

##Fetch PowerBI workspace name
$wsId = Read-Host "Enter your 'PowerBI' workspace Id "

Add-Content log.txt "------Creating Fabric Assets------"
Write-Host "------------Creating Fabric Assets------------"

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId";
$wsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
$wsName = $wsName.name

$lakehouseBronze = "lakehouseBronze$suffix"
$lakehouseSilver = "lakehouseSilver$suffix"
$lakehouseGold = "lakehouseGold$suffix"

Add-Content log.txt "------Creating Lakehouses------"
Write-Host "------Creating Lakehouses------"
$lakehouseNames = @($lakehouseBronze, $lakehouseSilver, $lakehouseGold)
# Set the token and request headers
$pat_token = $fabric
$requestHeaders = @{
Authorization  = "Bearer" + " " + $pat_token
"Content-Type" = "application/json"
"Scope"        = "itemType.ReadWrite.All"
}

    # Iterate through each Lakehouse name and create it
    foreach ($lakehouseName in $lakehouseNames) {
    # Create the body for the Lakehouse creation
    $body = @{
        displayName = $lakehouseName
        type        = "Lakehouse"
    } | ConvertTo-Json

    # Set the API endpoint
    $endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items/"

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

Add-Content log.txt "------Lakehouse Creation Complete------"
Write-Host "------Lakehouse Creation Complete------"

Add-Content log.txt "------Uploading assets to Lakehouses------"
Write-Host "------------Uploading assets to Lakehouses------------"

& $azCopyCommand  copy "https://sustainability2poc.blob.core.windows.net/bronzelakehousefiles/*" "https://onelake.blob.fabric.microsoft.com/$wsName/$lakehouseBronze.Lakehouse/Files/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
& $azCopyCommand  copy "https://sustainability2poc.blob.core.windows.net/bronzelakehousetables/*" "https://onelake.blob.fabric.microsoft.com/$wsName/$lakehouseBronze.Lakehouse/Tables/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
& $azCopyCommand  copy "https://sustainability2poc.blob.core.windows.net/silverlakehousefiles/*" "https://onelake.blob.fabric.microsoft.com/$wsName/$lakehouseSilver.Lakehouse/Files/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
& $azCopyCommand  copy "https://sustainability2poc.blob.core.windows.net/silverlakehousetables/*" "https://onelake.blob.fabric.microsoft.com/$wsName/$lakehouseSilver.Lakehouse/Tables/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
& $azCopyCommand  copy "https://sustainability2poc.blob.core.windows.net/goldlakehousetables/*" "https://onelake.blob.fabric.microsoft.com/$wsName/$lakehouseGold.Lakehouse/Tables/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;

Add-Content log.txt "------Uploading assets to the Lakehouses COMPLETE------"
Write-Host "------------Uploading assets to the Lakehouses COMPLETE------------"

RefreshTokens
$endpoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/lakehouses/"
$Lakehouses = Invoke-RestMethod -Uri $endpoint -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" }

# Iterate through each item in the "value" array to fetch Lakehouse IDs
foreach ($item in $Lakehouses.value) {
    if ($item.displayName -eq $lakehouseBronze) {
        $lakehouseBronzeId = $item.id
    }
    elseif ($item.displayName -eq $lakehouseSilver) {
        $lakehouseSilverId = $item.id
    }
    elseif ($item.displayName -eq $lakehouseGold) {
        $lakehouseGoldId = $item.id
    }
}

## notebooks
Add-Content log.txt "-----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses-----"
Write-Host "----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses----"

(Get-Content -path "artifacts/fabricnotebooks/01_Load_Transform_MSM_CSVToParquet_Into_Bronze_Layer.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
} | Set-Content -Path "artifacts/fabricnotebooks/01_Load_Transform_MSM_CSVToParquet_Into_Bronze_Layer.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/02_Load_Parquet_Files_Into_Lakehouse_Bronze_Tables.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#WORKSPACE_ID#', $wsId `
    -replace '#BRONZE_LAKEHOUSE_ID#', $lakehouseBronzeId `
} | Set-Content -Path "artifacts/fabricnotebooks/02_Load_Parquet_Files_Into_Lakehouse_Bronze_Tables.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/03_Transform_MSM_Data_To_ESG_Data_Model.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#WORKSPACE_ID#', $wsId `
    -replace '#BRONZE_LAKEHOUSE_ID#', $lakehouseBronzeId `
} | Set-Content -Path "artifacts/fabricnotebooks/03_Transform_MSM_Data_To_ESG_Data_Model.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/04_Load_ESG_Model_Data_Into_Silver_Layer.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#WORKSPACE_ID#', $wsId `
    -replace '#BRONZE_LAKEHOUSE_ID#', $lakehouseBronzeId `
    -replace '#SILVER_LAKEHOUSE_ID#', $lakehouseSilverId `
} | Set-Content -Path "artifacts/fabricnotebooks/04_Load_ESG_Model_Data_Into_Silver_Layer.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/05_Social_And_Governance_ESG_Aggregated_Data_To_Gold_Layer.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#LAKEHOUSE_SILVER_NAME#', $lakehouseSilver `
    -replace '#LAKEHOUSE_GOLD_NAME#', $lakehouseGold `
} | Set-Content -Path "artifacts/fabricnotebooks/05_Social_And_Governance_ESG_Aggregated_Data_To_Gold_Layer.ipynb"
                                                            
(Get-Content -path "artifacts/fabricnotebooks/06_Waste_Aggregated_Data_To_Gold_Layer.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#LAKEHOUSE_SILVER_NAME#', $lakehouseSilver `
    -replace '#LAKEHOUSE_GOLD_NAME#', $lakehouseGold `
} | Set-Content -Path "artifacts/fabricnotebooks/06_Waste_Aggregated_Data_To_Gold_Layer.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/07_Social_Governance_Aggregated_Data_To_Gold_Layer.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#LAKEHOUSE_SILVER_NAME#', $lakehouseSilver `
    -replace '#LAKEHOUSE_GOLD_NAME#', $lakehouseGold `
} | Set-Content -Path "artifacts/fabricnotebooks/07_Social_Governance_Aggregated_Data_To_Gold_Layer.ipynb"
                                                            
(Get-Content -path "artifacts/fabricnotebooks/08_Azure_Usage_And_Emission_Data_To_Lakehouse.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#LAKEHOUSE_SILVER_NAME#', $lakehouseSilver `
} | Set-Content -Path "artifacts/fabricnotebooks/08_Azure_Usage_And_Emission_Data_To_Lakehouse.ipynb"

(Get-Content -path "artifacts/fabricnotebooks/09_CO2_Emission_Forecasting_using_ARIMA.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#BRONZE_LAKEHOUSE_NAME#', $lakehouseBronze `
} | Set-Content -Path "artifacts/fabricnotebooks/09_CO2_Emission_Forecasting_using_ARIMA.ipynb"

Add-Content log.txt "-----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses COMPLETE-----"
Write-Host "----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses COMPLETE----"

Add-Content log.txt "-----Uploading Fabric Notebooks -----"
Write-Host "-----Uploading Fabric Notebooks -----"
RefreshTokens
$requestHeaders = @{
Authorization  = "Bearer " + $fabric
"Content-Type" = "application/json"
"Scope"        = "Notebook.ReadWrite.All"
}

$files = Get-ChildItem -Path "./artifacts/fabricnotebooks" -File -Recurse
Set-Location ./artifacts/fabricnotebooks

foreach ($name in $files.name) {
if ($name -eq "01_Load_Transform_MSM_CSVToParquet_Into_Bronze_Layer.ipynb" -or
    $name -eq "02_Load_Parquet_Files_Into_Lakehouse_Bronze_Tables.ipynb" -or 
    $name -eq "03_Transform_MSM_Data_To_ESG_Data_Model.ipynb" -or 
    $name -eq "04_Load_ESG_Model_Data_Into_Silver_Layer.ipynb" -or 
    $name -eq "05_Social_And_Governance_ESG_Aggregated_Data_To_Gold_Layer.ipynb" -or 
    $name -eq "06_Waste_Aggregated_Data_To_Gold_Layer.ipynb" -or 
    $name -eq "07_Social_Governance_Aggregated_Data_To_Gold_Layer.ipynb" -or 
    $name -eq "08_Azure_Usage_And_Emission_Data_To_Lakehouse.ipynb" -or 
    $name -eq "09_CO2_Emission_Forecasting_using_ARIMA.ipynb" -or 
    $name -eq "MCFS_Azure_Data.ipynb" -or 
    $name -eq "Water_Quality_Prediction_A_Data_Driven_Approach.ipynb" ) {
    
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

    $endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items/"
    $Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

    Write-Host "Notebook uploaded: $name"
    }
}

Add-Content log.txt "-----Uploading Notebooks Complete-----"
Write-Host "-----Uploading Notebooks Complete-----"

cd..
cd..

Add-Content log.txt "------Fabric Assets Creation COMPLETE------"
Write-Host "------------Fabric Assets Creation COMPLETE------------"

Add-Content log.txt "------Creating Azure Assets------"
Write-Host "------------Creating Azure Assets------------"

Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
Write-Host "Resource group $rgName creation COMPLETE"

Write-Host "Creating resources in $rgName..."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile "mainTemplate.json" `
    -Mode Complete `
    -location $Region `
    -speech_service_name $speech_service_name `
    -storageAccountName $storageAccountName `
    -app_sustainability_name $app_sustainability_name `
    -asp_sustainability_name $asp_sustainability_name `
    -Force

Write-Host "Resource creation in $rgName resource group COMPLETE"

# Adding workspace id tag to resourceGroup
$Tag = @{
    "Workspace ID" = $wsId
    "suffix" = $suffix
}
Set-AzResourceGroup -ResourceGroupName $rgName -Tag $Tag

#fetching storage account key
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storageAccountName)[0].Value

#Uploading to storage containers
Add-Content log.txt "-----------Uploading to storage containers-----------------"
Write-Host "----Uploading to Storage Containers-----"

$dataLakeContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storage_account_key

RefreshTokens

$destinationSasKey = New-AzStorageContainerSASToken -Container "sustainability" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storageAccountName).blob.core.windows.net/sustainability$($destinationSasKey)"
& $azCopyCommand copy "https://sustainability2poc.blob.core.windows.net/sustainability" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "dataverse-sustainability" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storageAccountName).blob.core.windows.net/dataverse-sustainability$($destinationSasKey)"
& $azCopyCommand copy "https://sustainability2poc.blob.core.windows.net/dataverse-sustainability" $destinationUri --recursive

Add-Content log.txt "-----------Uploading to storage containers COMPLETE-----------------"
Write-Host "----Uploading to Storage Containers COMPLETE-----"

#Assigning Admin Rights to Service Principal to PowerBI Workspace
Add-Content log.txt "------Assigning Admin Rights to Service Principal to PowerBI Workspace------"
Write-Host  "-----------------Assigning Admin Rights to Service Principal to PowerBI Workspace---------------"
RefreshTokens

$spname = "Sustainability $suffix"

$app = az ad app create --display-name $spname | ConvertFrom-Json
$appId = $app.appId

$mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$clientsecpwd = $mainAppCredential.password

az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "id" -o tsv
start-sleep -s 20

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
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/users";
$post = "{
`"identifier`":`"$($sp)`",
`"groupUserAccessRight`":`"Admin`",
`"principalType`":`"App`"
}";

$result = Invoke-RestMethod -Uri $url -Method POST -body $post -ContentType "application/json" -Headers @{ Authorization = "Bearer $powerbitoken" } -ea SilentlyContinue;

#get the power bi app...
$powerBIApp = Get-AzADServicePrincipal -DisplayNameBeginsWith "Power BI service"
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

$credential = New-Object PSCredential($appId, (ConvertTo-SecureString $clientsecpwd -AsPlainText -Force))

# Connect to Power BI using the service principal
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenantId

#PowerBI report upload section
Add-Content log.txt "------Uploading PowerBI Reports to the Workspace------"
Write-Host  "--------------Uploading PowerBI Reports to the Workspace---------------"

# Uploading Reports to PowerBI Workspace
$PowerBIFiles = Get-ChildItem "./artifacts/reports" -Recurse -Filter *.pbix
$reportList = @()

foreach ($Pbix in $PowerBIFiles) {
Write-Output "Uploading report: $($Pbix.BaseName +'.pbix')"

$report = New-PowerBIReport -Path $Pbix.FullName -WorkspaceId $wsId -ConflictAction CreateOrOverwrite

if ($report -ne $null) {
    Write-Output "Report uploaded successfully: $($report.Name +'.pbix')"
} else {
    Write-Output "Failed to upload report: $($report.Name +'.pbix')"
}
}

#PowerBI report upload section
Add-Content log.txt "------Uploading PowerBI Reports to the Workspace COMPLETE------"
Write-Host  "--------------Uploading PowerBI Reports to the Workspace COMPLETE---------------"

#retirieving search service key
$speech_service_key = az cognitiveservices account keys list --name $speech_service_name --resource-group $rgName | jq -r .key1

#Web App Section
Add-Content log.txt "------unzipping poc web app------"
Write-Host  "--------------Unzipping web app---------------"
$zips = @("app-sustainability")
foreach ($zip in $zips) {
expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

Add-Content log.txt "------Deploying the main web app------"
Write-Host  "--------------Deploying the main web app---------------"

(Get-Content -path app-sustainability/appsettings.json -Raw) | Foreach-Object { $_ `
    -replace '#WORKSPACE_ID#', $wsId`
    -replace '#APP_ID#', $appId`
    -replace '#APP_SECRET#', $clientsecpwd`
    -replace '#TENANT_ID#', $tenantId`
} | Set-Content -Path app-sustainability/appsettings.json

$filepath = "./app-sustainability/wwwroot/environment.js"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#SPEECH_SERVICE_KEY#", $speech_service_key).Replace("#REGION#", $Region).Replace("#STORAGE_ACCOUNT_NAME#", $storageAccountName).Replace("#SERVER_NAME#", $app_sustainability_name).Replace("#WORKSPACE_ID#", $wsId)
Set-Content -Path $filepath -Value $item

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
$reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
$reportList = $reportList.Value

#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable   
# $ht.add("#Bing_Map_Key#", "AhBNZSn-fKVSNUE5xYFbW_qajVAZwWYc8OoSHlH8nmchGuDI6ykzYjrtbwuNSrR8")
$ht.add("#01_World Map KPIs Sustainability#", $($reportList | where { $_.name -eq "01_World Map KPIs Sustainability" }).id)
$ht.add("#15_Group CEO KPI#", $($reportList | where { $_.name -eq "15_Group CEO KPI" }).id)
$ht.add("#03_Carbon Emission Assessment Plan#", $($reportList | where { $_.name -eq "03_Carbon Emission Assessment Plan" }).id)
$ht.add("#05_Sales Demand and Greenhouse Gas Emissions Report#", $($reportList | where { $_.name -eq "05_Sales Demand and Greenhouse Gas Emissions Report" }).id)
$ht.add("#06_Transport Deep Dive#", $($reportList | where { $_.name -eq "06_Transport Deep Dive" }).id)
$ht.add("#08_ESG Waste Contoso#", $($reportList | where { $_.name -eq "08_ESG Waste Contoso" }).id)
$ht.add("#20_ESGWaste_Litware#", $($reportList | where { $_.name -eq "20_ESGWaste_Litware" }).id)
$ht.add("#09_ESG Waste Litware Acquisition#", $($reportList | where { $_.name -eq "09_ESG Waste Litware Acquisition" }).id)
$ht.add("#10_ESG Water Litware#", $($reportList | where { $_.name -eq "10_ESG Water Litware" }).id)
$ht.add("#11_Social & Governance Training#", $($reportList | where { $_.name -eq "11_Social & Governance Training" }).id)
$ht.add("#12_Workforce Health & Safety#", $($reportList | where { $_.name -eq "12_Workforce Health & Safety" }).id)
$ht.add("#13_Co2 Emissions Forecast#", $($reportList | where { $_.name -eq "13_Co2 Emissions Forecast" }).id)

$filePath = "./app-sustainability/wwwroot/environment.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./app-sustainability/*" -DestinationPath "./app-sustainability.zip" -Update

az webapp stop --name $app_sustainability_name --resource-group $rgName
try {
    Publish-AzWebApp -ResourceGroupName $rgName -Name $app_sustainability_name -ArchivePath "./app-sustainability.zip" -Force
}
catch {
}
az webapp start --name $app_sustainability_name --resource-group $rgName

Add-Content log.txt "------Main web app deployment COMPLETE------"
Write-Host  "--------------Main web app deployment COMPLETE---------------"

$end_deployment_time = get-date
$executiontime = $end_deployment_time - $starttime
Write-Host "Execution Time - "$executiontime.TotalMinutes
Add-Content log.txt "------Execution Time - '$executiontime.TotalMinutes'------"

Add-Content log.txt "------Azure Assets Creation COMPLETE------"
Write-Host "------------Azure Assets Creation COMPLETE------------"

Write-Host "List of resources deployed in $rgName resource group"
$deployed_resources = Get-AzResource -resourcegroup $rgName
$deployed_resources = $deployed_resources | Select-Object Name, Type | Format-Table -AutoSize
Write-Output $deployed_resources

Write-Host "List of resources deployed in $wsName workspace"
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items"
$fabric_items = Invoke-RestMethod $endPoint `
-Method GET `
-Headers $requestHeaders 

$table = $fabric_items.value | Select-Object DisplayName, Type | Format-Table -AutoSize

Write-Output $table

Write-Host  "-----------------Execution Complete----------------"
Add-Content log.txt "------Execution Complete------"
