$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "I accept the license agreement."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "I do not accept and wish to stop execution."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$title = "Agreement"
$message = "By typing [Y], I hereby confirm that I have read the license ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/license.md ) and disclaimers ( available at https://github.com/microsoft/Azure-Analytics-and-AI-Engagement/blob/main/README.md ) and hereby accept the terms of the license and agree that the terms and conditions set forth therein govern my use of the code made available hereunder. (Type [Y] for Yes or [N] for No and press enter)"
$result = $host.ui.PromptForChoice($title, $message, $options, 1)
if ($result -eq 1) {
    write-host "Thank you. Please ensure you delete the resources created with template to avoid further cost implications."
}
else {
    function RefreshTokens() {
        $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
        $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
        $global:fabric = ((az account get-access-token --resource https://api.fabric.microsoft.com) | ConvertFrom-Json).accessToken
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

        } catch {
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
    # $subscriptionId = (Get-AzContext).Subscription.Id
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

    # 1. Variables Definition
    [string]$suffix = -join ((48..57) + (97..122) | Get-Random -Count 7 | % { [char]$_ })
    $rgName = "rg-fsi-iq-$suffix"
    $Region = read-host "Enter the region for deployment"
    $wsId =  Read-Host "Enter your 'FSI IQ Demo' PowerBI workspace Id "
    $storage_account_name = "storage$suffix"
    $asp_fsi_name = "asp-fsi-$suffix"
    $app_fsi_name = "app-fsi-$suffix"
    $func_app_mortgage = "func-app-mortage-$suffix"
    $asp_func_app_mortgage = "asp-func-app-mortage-$suffix"

    # Core Resources
    $aiServicesName = "hub-aifoundry-fsi-$suffix"
    $workspaces_prj_name = "proj-aifoundry-fsi-$suffix"
    $searchServiceName = "srch-fsi-$suffix"

    # Model 1 (gpt-5.5)
    $model1Deployment = "gpt-5-4-mini"
    $model1Name = "gpt-5.4-mini"
    $model1Version = "2026-03-17"
    $model1Capacity = 50

    # Model 2 (text-embedding-3-large)
    $model2Deployment = "text-embedding-3-large"
    $model2Name = "text-embedding-3-large"
    $model2Version = "1"
    $model2Capacity = 10

    #### 

    Write-Host "Deploying Resources on Microsoft Azure Started ..."
    Write-Host "Creating $rgName resource group in $Region ..."
    New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
    Write-Host "Resource group $rgName creation COMPLETE"

    # 1. Fetch Subscription ID and dynamically build the Scope
    $subId = (az account show --query id -o tsv).Trim()
    $scope = "/subscriptions/$subId/resourceGroups/$rgName"

    # 2. Dynamically fetch the signed-in identity's Object ID
    $objectId = (az ad signed-in-user show --query id -o tsv).Trim()

    Write-Host "Target Scope: $scope" -ForegroundColor Yellow
    Write-Host "Target Object ID: $objectId" -ForegroundColor Green

    # 3. Assign the roles using the proper --scope syntax
    Write-Host "Assigning 'Azure AI Developer' role..." -ForegroundColor Cyan
    az role assignment create `
    --assignee $objectId `
    --role "Azure AI Developer" `
    --scope $scope

    Write-Host "Assigning 'Cognitive Services Contributor' role..." -ForegroundColor Cyan
    az role assignment create `
    --assignee $objectId `
    --role "Cognitive Services Contributor" `
    --scope $scope

    Write-Host "Assigning 'Foundry Owner' role..." -ForegroundColor Cyan
    az role assignment create `
    --assignee $objectId `
    --role "Foundry Owner" `
    --scope $scope

    Write-Host "Assigning 'Foundry Project Manager' role..." -ForegroundColor Cyan
    az role assignment create `
    --assignee $objectId `
    --role "Foundry Project Manager" `
    --scope $scope

    Write-Host "Assigning 'Foundry User' role..." -ForegroundColor Cyan
    az role assignment create `
    --assignee $objectId `
    --role "Foundry User" `
    --scope $scope

    Write-Host "Creating resources in $rgName..."
    New-AzResourceGroupDeployment -ResourceGroupName $rgName `
        -TemplateFile "mainTemplate.json" `
        -Mode Complete `
        -location $Region `
        -storage_account_name $storage_account_name `
        -asp_fsi_name $asp_fsi_name `
        -app_fsi_name $app_fsi_name `
        -asp_func_app_mortgage_name $asp_func_app_mortgage `
        -func_app_mortgage_name $func_app_mortgage `
        -Force
    
    $templatedeployment = Get-AzResourceGroupDeployment -Name "mainTemplate" -ResourceGroupName $rgName
    $deploymentStatus = $templatedeployment.ProvisioningState
    Write-Host "Deployment in $rgName : $deploymentStatus"

    Add-Content log.txt "------Copying assets to the Storage Account------"
    Write-Host "------------Copying assets to the Storage Account------------"

    ## storage AZ Copy
    $storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storage_account_name)[0].Value
    $dataLakeContext = New-AzStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_account_key

    $destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
    if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey" }
    $destinationUri = "https://$($storage_account_name).blob.core.windows.net/webappassets$($destinationSasKey)"
    $azCopy_Data_container = azcopy copy "https://stfsiiqdpoc.blob.core.windows.net/webappassets/" $destinationUri --recursive

    Write-Host "webappassets copied"

    # 2. Core Resource Creation

    # Create AI Services Account (Foundry Hub)
    az cognitiveservices account create `
        --name $aiServicesName `
        --resource-group $rgName `
        --kind AIServices `
        --sku S0 `
        --location $Region `
        --allow-project-management `
        --custom-domain $aiServicesName
    
    # # Create AI Services Account (Foundry Hub)
    # az cognitiveservices account create `
    #     --name $aiServicesName `
    #     --resource-group $rgName `
    #     --kind AIServices `
    #     --sku S0 `
    #     --location $location `
    #     --allow-project-management `
    #     --custom-domain $aiServicesName

    # Create Azure AI Search Service
    az search service create `
        --name $searchServiceName `
        --resource-group $rgName `
        --sku basic `
        --location $Region `
        --partition-count 1 `
        --replica-count 1

    # Create AI Foundry Project
    az cognitiveservices account project create `
        --name $aiServicesName `
        --resource-group $rgName `
        --project-name $workspaces_prj_name `
        --location $Region

    # # Create AI Foundry Project
    # az cognitiveservices account project create `
    #     --name $aiServicesName `
    #     --resource-group $rgName `
    #     --project-name $workspaces_prj_name `
    #     --location $location

    # 3. Model Deployments

    # Deploy Model 1 (gpt-5.4-mini)
    az cognitiveservices account deployment create `
        --name $aiServicesName `
        --resource-group $rgName `
        --deployment-name $model1Deployment `
        --model-name $model1Name `
        --model-version $model1Version `
        --model-format OpenAI `
        --sku-name GlobalStandard `
        --sku-capacity $model1Capacity

    # Deploy Model 2 (text-embedding-3-large)
    az cognitiveservices account deployment create `
        --name $aiServicesName `
        --resource-group $rgName `
        --deployment-name $model2Deployment `
        --model-name $model2Name `
        --model-version $model2Version `
        --model-format OpenAI `
        --sku-name Standard `
        --sku-capacity $model2Capacity

    # 4. Configurations and Connections

    # Disable Defender for AI Settings
    az resource create --resource-group $rgName --namespace Microsoft.CognitiveServices --parent "accounts/$aiServicesName" --resource-type defenderForAISettings --name "Default" --properties '{"state":"Disabled"}' --api-version "2026-05-01"

    # Update the connection properties to include "authType": "None"
    $connectionProps = '{"authType":"None","category":"RemoteTool","target":"https://' + $searchServiceName + '.search.windows.net/knowledgebases/spike-kb/mcp?api-version=2025-11-01-preview","useWorkspaceManagedIdentity":false,"isSharedToAll":false,"sharedUserList":[],"peRequirement":"NotRequired","peStatus":"NotApplicable","metadata":{"ApiType":"Azure"}}'

    # Hub-Level Connection
    az resource create --resource-group $rgName --namespace Microsoft.CognitiveServices --parent "accounts/$aiServicesName" --resource-type connections --name "spike-kb-mcp-hub-connection" --properties $connectionProps --api-version "2026-05-01"

    # Project-Level Connection
    az resource create --resource-group $rgName --namespace Microsoft.CognitiveServices --parent "accounts/$aiServicesName/projects/$workspaces_prj_name" --resource-type connections --name "spike-kb-mcp-project-connection" --properties $connectionProps --api-version "2026-05-01"

    ####

    ### Fabric starts here

    RefreshTokens
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId"
    $fabricWorkspace = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" }
    $fabricWorkspaceName = $fabricWorkspace.name

    $fsiLakehouse = "fsiLakehouse_$suffix"
    $aiLakehouse = "aiLakehouse_$suffix"

    Add-Content log.txt "------FABRIC assets deployment STARTS HERE------"
    Write-Host "------------FABRIC assets deployment STARTS HERE------------"

    Add-Content log.txt "------Creating Lakehouses in '$fabricWorkspaceName' workspace------"
    Write-Host "------Creating Lakehouses in '$fabricWorkspaceName' workspace------"

    # fsiLakehouse WITH schemas (true), aiLakehouse WITHOUT schemas (false)
    $lakehouseConfigs = @(
        @{ Name = $fsiLakehouse; EnableSchemas = $true; Description = "Lakehouse with schemas enabled" },
        @{ Name = $aiLakehouse; EnableSchemas = $false; Description = "Schema-less Lakehouse" }
    )

    $schemas = @('dbo', 'credit_bureau', 'crm', 'marketing', 'mortgage', 'operations', 'property', 'ref')

    $pat_token = $fabric
    $headers = @{
        Authorization = "Bearer $global:fabric"
    }

    foreach ($config in $lakehouseConfigs) {
        $lakehouseName = $config.Name
        $enableSchemas = $config.EnableSchemas
        $lakehouseId = $null

        # Check if Lakehouse already exists to avoid 409 Conflict
        $listUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/lakehouses"
        $existingLakehouses = Invoke-RestMethod -Method Get -Uri $listUri -Headers $headers -ErrorAction SilentlyContinue
        $existingLakehouse = $existingLakehouses.value | Where-Object { $_.displayName -eq $lakehouseName }

        if ($existingLakehouse) {
            Write-Host "Lakehouse '$lakehouseName' already exists. Skipping creation."
            $lakehouseId = $existingLakehouse.id
        } 
        else {
            # Fabric API Rule: If false, DO NOT include a creationPayload property
            if ($enableSchemas) {
                $requestBody = @{
                    type            = "Lakehouse"
                    displayName     = $lakehouseName
                    description     = $config.Description
                    creationPayload = @{
                        enableSchemas = $true
                    }
                } | ConvertTo-Json -Depth 3
            } 
            else {
                $requestBody = @{
                    type        = "Lakehouse"
                    displayName = $lakehouseName
                    description = $config.Description
                } | ConvertTo-Json -Depth 3
            }

            $createUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items"

            try {
                $response = Invoke-RestMethod -Method Post -Uri $createUri -Headers $headers -Body $requestBody -ContentType "application/json"
                $lakehouseId = $response.id
                Write-Host "Lakehouse '$lakehouseName' created successfully (EnableSchemas: $enableSchemas)."
                
                # Wait for Fabric backend to initialize the Lakehouse
                Start-Sleep -Seconds 10
            }
            catch {
                Write-Host "Error creating Lakehouse '$lakehouseName': $_"
                if ($_.ErrorDetails.Message) { Write-Host "Response Body: $($_.ErrorDetails.Message)" }
                elseif ($_.Exception.Response -is [System.Net.Http.HttpResponseMessage]) { Write-Host "Response Body: $($_.Exception.Response.Content.ReadAsStringAsync().Result)" }
                elseif ($_.Exception.Response -ne $null) {
                    $stream = $_.Exception.Response.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($stream)
                    Write-Host "Response Body: $($reader.ReadToEnd())"
                }
                continue 
            }
        }

        # Create directories/schemas only if enableSchemas is true for that specific Lakehouse
        if ($lakehouseId -and $enableSchemas) {
            try {
                Write-Host "--- Getting Storage Token for OneLake DFS ---"
                $storageTokenObj = az account get-access-token --resource "https://storage.azure.com/" | ConvertFrom-Json
                $storageToken = $storageTokenObj.accessToken

                Write-Host "--- Creating Schemas in $lakehouseName ---"
                foreach ($schema in $schemas) {
                    $schemaUri = "https://onelake.dfs.fabric.microsoft.com/$wsId/$lakehouseId/Tables/$schema`?resource=directory"
                
                    Invoke-RestMethod -Method Put -Uri $schemaUri -Headers @{ Authorization = "Bearer $storageToken" } -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "Schema '$schema' ready."
                }
            }
            catch {
                Write-Host "Error creating schemas for '$lakehouseName': $_"
            }
        }
    }

    Add-Content log.txt "------Creation of Lakehouses in '$fabricWorkspaceName' workspace COMPLETED------"
    Write-Host "-----Creation of Lakehouses in '$fabricWorkspaceName' workspace COMPLETED------"


    # 1. Refresh the Fabric token to prevent authentication failures
    $global:fabric = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
    $requestHeaders = @{
        Authorization  = "Bearer $global:fabric"
        "Content-Type" = "application/json"
    }

    # 2. Fetch Lakehouses from the workspace
    $endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/lakehouses"
    $Lakehouses = Invoke-RestMethod $endPoint -Method GET -Headers $requestHeaders

    $fsiLakehouseId = ($Lakehouses.value | Where-Object { $_.displayName -eq $fsiLakehouse }).id
    $aiLakehouseId  = ($Lakehouses.value | Where-Object { $_.displayName -eq $aiLakehouse }).id

    Write-Output "FSI Lakehouse ID: $fsiLakehouseId"
    Write-Output "AI Lakehouse ID: $aiLakehouseId"

    Add-Content log.txt "------Uploading assets to Lakehouses------"
    Write-Host "------------Uploading assets to Lakehouses------------"

    # 3. Upload tables to FSI Lakehouse (With Schemas)
    Write-Host "Copying Tables to FSI Lakehouse Schemas..."
    foreach ($schema in $schemas) {
        Write-Host "Copying data from storage folder '$schema' into FSI Lakehouse schema '$schema'..."
        
        $sourceUri = "https://stfsiiqdpoc.blob.core.windows.net/lakehousetables/$schema/*"
        $destUri = "https://onelake.blob.fabric.microsoft.com/$fabricWorkspaceName/$fsiLakehouse.Lakehouse/Tables/$schema"
        
        & $azCopyCommand copy $sourceUri $destUri --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes="onelake.blob.fabric.microsoft.com" --log-level=INFO
    }

    # 4. Upload tables to AI Lakehouse (Schema-less, directly from 'dbo' directory)
    Write-Host "Copying Tables directly to AI Lakehouse (Schema-less from 'dbo' directory)..."
    $aiSourceUri = "https://stfsiiqdpoc.blob.core.windows.net/lakehousetables/dbo/*"
    $aiDestUri = "https://onelake.blob.fabric.microsoft.com/$fabricWorkspaceName/$aiLakehouse.Lakehouse/Tables"

    & $azCopyCommand copy $aiSourceUri $aiDestUri --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes="onelake.blob.fabric.microsoft.com" --log-level=INFO

    # 5. Copy Files to FSI Lakehouse
    Write-Host "Copying Files to FSI Lakehouse..."
    & $azCopyCommand copy "https://stfsiiqdpoc.blob.core.windows.net/lakehousefiles/*" "https://onelake.blob.fabric.microsoft.com/$fabricWorkspaceName/$fsiLakehouse.Lakehouse/Files" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes="onelake.blob.fabric.microsoft.com" --log-level=INFO

   
    # 1. Configuration & Token Initialization (Targeting AI Lakehouse)
    
    # Generate fresh access token and define headers
    $global:fabric = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
    $headers = @{
        Authorization  = "Bearer $global:fabric"
        "Content-Type" = "application/json"
    }

    # Dynamically fetch the AI Lakehouse ID and Name ($aiLakehouse from your previous step)
    Write-Host "Fetching AI Lakehouse ID for '$aiLakehouse'..."
    $lakehousesResponse = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/lakehouses" -Headers $headers
    $targetLakehouse = $lakehousesResponse.value | Where-Object { $_.displayName -eq $aiLakehouse }

    if (-not $targetLakehouse) {
        throw "AI Lakehouse '$aiLakehouse' was not found in the workspace. Ensure it was created first."
    }

    $newLakehouseId   = $targetLakehouse.id
    $newLakehouseName = $aiLakehouse
    Write-Host "Targeting AI Lakehouse: '$newLakehouseName' (ID: $newLakehouseId)"

    $oldSemanticModelId = "5036e527-27b1-4800-8feb-544756996f2e" 
    $oldOntologyId      = "febef30c-df4f-42e6-a1f5-2350b5635261"
    $oldLakehouseName   = "FSI_IQ_Lakehouse"
    $oldOntologyName    = "FSI_Ontology"

    
    # 2. Case-Insensitive Universal Update Function & Polling
    
    function Update-FabricDefinition($definitionData, $oWs, $nWs, $oLh, $nLh, $oLhName, $nLhName, $oSm, $nSm, $oOnt, $nOnt, $oOntName, $nOntName) {
        foreach ($part in $definitionData.definition.parts) {
            if ($part.payloadType -eq "InlineBase64" -and $part.payload) {
                $text = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($part.payload))
                
                # Case-insensitive universal replacements
                if ($oWs -and $nWs) { $text = [System.Text.RegularExpressions.Regex]::Replace($text, [System.Text.RegularExpressions.Regex]::Escape($oWs), $nWs, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) }
                if ($oLh -and $nLh) { $text = [System.Text.RegularExpressions.Regex]::Replace($text, [System.Text.RegularExpressions.Regex]::Escape($oLh), $nLh, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) }
                if ($oSm -and $nSm) { $text = [System.Text.RegularExpressions.Regex]::Replace($text, [System.Text.RegularExpressions.Regex]::Escape($oSm), $nSm, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) }
                if ($oOnt -and $nOnt) { $text = [System.Text.RegularExpressions.Regex]::Replace($text, [System.Text.RegularExpressions.Regex]::Escape($oOnt), $nOnt, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) }
                
                if ($oLhName -and $nLhName) { $text = [System.Text.RegularExpressions.Regex]::Replace($text, [System.Text.RegularExpressions.Regex]::Escape($oLhName), $nLhName, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) }
                if ($oOntName -and $nOntName) { $text = [System.Text.RegularExpressions.Regex]::Replace($text, [System.Text.RegularExpressions.Regex]::Escape($oOntName), $nOntName, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) }
                
                $part.payload = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
            }
        }
        return $definitionData
    }

    function Wait-FabricOperation($resHeaders, $headers) {
        $opUrl = $resHeaders["Location"]
        if ($opUrl -is [array]) { $opUrl = $opUrl[0] }
        if (-not $opUrl) { return }
        
        do {
            Start-Sleep -Seconds 5
            $status = Invoke-RestMethod -Method Get -Uri $opUrl -Headers $headers
            Write-Host "Status: $($status.status)"
        } while ($status.status -in @("Running", "NotStarted"))
        
        if ($status.status -ne "Succeeded") {
            throw "Operation failed with status: $($status.status)"
        }
    }

    # 3. Extract Old Workspace and Lakehouse IDs Automatically
    
    Write-Host "Extracting old IDs from Semantic Model definition..."
    $smData = Get-Content "./artifacts/fabricAssets/SemanticModelDefinition.json" -Raw | ConvertFrom-Json
    $exprPart = $smData.definition.parts | Where-Object { $_.path -eq 'definition/expressions.tmdl' }
    $decodedExpr = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($exprPart.payload))

    $oldWsId = ""
    $oldLakehouseId = ""
    if ($decodedExpr -match "https://onelake\.dfs\.fabric\.microsoft\.com/([a-fA-F0-9\-]{36})/([a-fA-F0-9\-]{36})") {
        $oldWsId = $Matches[1]
        $oldLakehouseId = $Matches[2]
        Write-Host "Auto-Detected Old Workspace ID: $oldWsId"
        Write-Host "Auto-Detected Old Lakehouse ID: $oldLakehouseId"
    }

    
    # 4. Lakehouse Preparation (Metadata Sync & Service Principal Access)
    
    Write-Host "Forcing SQL Analytics Endpoint to recreate table metadata..."
    $lhApiUrl = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/lakehouses/$newLakehouseId"
    $lhDetails = Invoke-RestMethod -Method Get -Uri $lhApiUrl -Headers $headers
    $sqlEndpointId = $lhDetails.properties.sqlEndpointProperties.id

    if ($sqlEndpointId) {
        $refreshUrl = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/sqlEndpoints/$sqlEndpointId/refreshMetadata"
        $refreshBody = @{ recreateTables = $true } | ConvertTo-Json

        Invoke-RestMethod -Method Post -Uri $refreshUrl -Headers $headers -Body $refreshBody -ResponseHeadersVariable refreshHeaders | Out-Null
        Wait-FabricOperation -resHeaders $refreshHeaders -headers $headers
        Write-Host "Metadata recreation completed successfully!"
    }

    Write-Host "Granting ReadAll permission to Service Principal on Lakehouse..."
    $spObjectId = az ad sp show --id $appId --query "id" -o tsv
    $roleAssignmentUrl = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items/$newLakehouseId/roleAssignments"
    $roleAssignmentBody = @{
        principal = @{ id = $spObjectId; type = "App" }
        role      = "ReadAll"
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Method Post -Uri $roleAssignmentUrl -Headers $headers -Body $roleAssignmentBody | Out-Null
        Write-Host "ReadAll permission successfully granted."
    } catch {
        Write-Host "Note: Role assignment may already exist."
    }

    
    # 5. Process & Deploy Semantic Model
    
    Write-Host "Deploying Semantic Model..."
    $smData = Update-FabricDefinition -definitionData $smData -oWs $oldWsId -nWs $wsId -oLh $oldLakehouseId -nLh $newLakehouseId -oLhName $oldLakehouseName -nLhName $newLakehouseName -oSm $oldSemanticModelId -nSm $null -oOnt $oldOntologyId -nOnt $null -oOntName $oldOntologyName -nOntName $null

    $smName = "FSI_IQ_Model_$suffix"
    $importBody = @{ displayName = $smName; type = "SemanticModel"; definition = $smData.definition } | ConvertTo-Json -Depth 10

    Invoke-RestMethod -Method Post -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items" -Headers $headers -Body $importBody -ResponseHeadersVariable resHeaders | Out-Null
    Wait-FabricOperation -resHeaders $resHeaders -headers $headers

    $items = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items?type=SemanticModel" -Headers $headers
    $newSemanticModelId = ($items.value | Where-Object { $_.displayName -eq $smName }).id
    Write-Host "Semantic Model Deployed! New ID: $newSemanticModelId"

    
    # 6. Process & Deploy Ontology (Unique Name Generation)
    
    Write-Host "Deploying Ontology..."
    $ontData = Get-Content "./artifacts/fabricAssets/OntologyDefinition.json" -Raw | ConvertFrom-Json
    $ontName = "FSI_Ontology_$suffix"

    $ontData = Update-FabricDefinition -definitionData $ontData -oWs $oldWsId -nWs $wsId -oLh $oldLakehouseId -nLh $newLakehouseId -oLhName $oldLakehouseName -nLhName $newLakehouseName -oSm $oldSemanticModelId -nSm $newSemanticModelId -oOnt $oldOntologyId -nOnt $null -oOntName $oldOntologyName -nOntName $ontName

    $ontBody = @{ displayName = $ontName; description = "Migrated Ontology"; definition = $ontData.definition } | ConvertTo-Json -Depth 10

    Invoke-RestMethod -Method Post -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/ontologies" -Headers $headers -Body $ontBody -ResponseHeadersVariable resHeaders | Out-Null
    Wait-FabricOperation -resHeaders $resHeaders -headers $headers

    $ontologies = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items?type=Ontology" -Headers $headers
    $newOntologyId = ($ontologies.value | Where-Object { $_.displayName -eq $ontName }).id
    Write-Host "Ontology Deployed as '$ontName'! New ID: $newOntologyId"

    
    function Update-FabricDefinition {
        param(
            [Parameter(Mandatory)] [PSCustomObject]$definitionData,
            [string]$oWs, [string]$nWs,
            [string]$oLh, [string]$nLh,
            [string]$oLhName, [string]$nLhName,
            [string]$oSm, [string]$nSm,
            [string]$oOnt, [string]$nOnt,
            [string]$oOntName, [string]$nOntName
        )

        # 1. Perform top-level string replacements
        $jsonStr = $definitionData | ConvertTo-Json -Depth 10

        if ($oWs -and $nWs) { $jsonStr = $jsonStr -replace [regex]::Escape($oWs), $nWs }
        if ($oLh -and $nLh) { $jsonStr = $jsonStr -replace [regex]::Escape($oLh), $nLh }
        if ($oLhName -and $nLhName) { $jsonStr = $jsonStr -replace [regex]::Escape($oLhName), $nLhName }
        if ($oSm -and $nSm) { $jsonStr = $jsonStr -replace [regex]::Escape($oSm), $nSm }
        if ($oOnt -and $nOnt) { $jsonStr = $jsonStr -replace [regex]::Escape($oOnt), $nOnt }
        if ($oOntName -and $nOntName) { $jsonStr = $jsonStr -replace [regex]::Escape($oOntName), $nOntName }

        $updatedData = $jsonStr | ConvertFrom-Json

        # 2. Process definition parts (updating both paths and Base64 payloads)
        if ($updatedData.definition -and $updatedData.definition.parts) {
            foreach ($part in $updatedData.definition.parts) {
                # Update path if it references the old ontology name
                if ($oOntName -and $nOntName -and $part.path) {
                    $part.path = $part.path -replace [regex]::Escape($oOntName), $nOntName
                }

                # Update Base64 encoded payload content
                if ($part.payloadType -eq "InlineBase64" -and $part.payload) {
                    $decodedBytes = [System.Convert]::FromBase64String($part.payload)
                    $content = [System.Text.Encoding]::UTF8.GetString($decodedBytes)

                    if ($oWs -and $nWs) { $content = $content -replace [regex]::Escape($oWs), $nWs }
                    if ($oLh -and $nLh) { $content = $content -replace [regex]::Escape($oLh), $nLh }
                    if ($oLhName -and $nLhName) { $content = $content -replace [regex]::Escape($oLhName), $nLhName }
                    if ($oSm -and $nSm) { $content = $content -replace [regex]::Escape($oSm), $nSm }
                    if ($oOnt -and $nOnt) { $content = $content -replace [regex]::Escape($oOnt), $nOnt }
                    if ($oOntName -and $nOntName) { $content = $content -replace [regex]::Escape($oOntName), $nOntName }

                    $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                    $part.payload = [System.Convert]::ToBase64String($encodedBytes)
                }
            }
        }

        return $updatedData
    }

    # Refresh the Azure CLI access token for Fabric
    $token = (az account get-access-token --resource "https://api.fabric.microsoft.com" --query "accessToken" -o tsv)
    $headers = @{ Authorization = "Bearer $token" }

    # 7. Process & Deploy Data Agent (Binds to Unique Ontology Name & ID)

    Write-Host "Deploying Data Agent..."
    $agentData = Get-Content "./artifacts/fabricAssets/AgentDefinition.json" -Raw | ConvertFrom-Json

    $oldOntologyId = "087e42e8-4785-4fff-8767-1531190b678a"
    $oldOntologyName = "FSI_Ontology"

    $agentData = Update-FabricDefinition -definitionData $agentData `
        -oWs $oldWsId -nWs $wsId `
        -oLh $oldLakehouseId -nLh $newLakehouseId `
        -oLhName $oldLakehouseName -nLhName $newLakehouseName `
        -oSm $oldSemanticModelId -nSm $newSemanticModelId `
        -oOnt $oldOntologyId -nOnt $newOntologyId `
        -oOntName $oldOntologyName -nOntName $ontName

    $agentName = "FSI_IQ_Agent_$suffix"
    $agentBody = @{ 
        displayName = $agentName
        description = "Migrated Data Agent"
        definition  = $agentData.definition 
    } | ConvertTo-Json -Depth 10

    Invoke-RestMethod -Method Post -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/dataAgents" -Headers $headers -Body $agentBody -ContentType "application/json" -ResponseHeadersVariable resHeaders | Out-Null
    Wait-FabricOperation -resHeaders $resHeaders -headers $headers

    Write-Host "Data Agent successfully deployed and bound to the AI Lakehouse '$newLakehouseName' and Ontology '$ontName'!"

    
    # 1. Configuration & Authentication
    
    $eventhouseName  = "eh_fsi_$suffix"
    $eventstreamName = "Ingest_Marketing_Signal_$suffix"

    # Refresh Fabric access token via Azure CLI
    $global:fabric = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
    $headers = @{
        Authorization  = "Bearer $global:fabric"
        "Content-Type" = "application/json"
    }

    
    # Create Eventhouse (Auto-generates default KQL DB) & Capture URIs
    
    Write-Host "Creating Eventhouse ($eventhouseName)..."
    $ehBody = @{ displayName = $eventhouseName } | ConvertTo-Json
    Invoke-RestMethod -Method Post -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/eventhouses" -Headers $headers -Body $ehBody -ResponseHeadersVariable ehHeaders | Out-Null
    Wait-FabricOperation -resHeaders $ehHeaders -headers $headers

    Write-Host "Fetching default KQL Database connection properties..."
    Start-Sleep -Seconds 5

    $kqlList = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/kqlDatabases" -Headers $headers

    # Output available databases for visibility
    $kqlList.value | Select-Object id, displayName

    # Match by name, with a fallback to the first available database
    $defaultKqlDb = $kqlList.value | Where-Object { $_.displayName -eq $eventhouseName }
    if (-not $defaultKqlDb) {
        $defaultKqlDb = $kqlList.value | Select-Object -First 1
    }

    if (-not $defaultKqlDb) {
        Write-Error "No KQL databases found in workspace $wsId."
        exit 1
    }

    # Explicitly assign the ID from the selected database object
    $kqlDbId = $defaultKqlDb.id

    # Retrieve the specific KQL database details (Get endpoint returns the resource object directly, not wrapped in .value)
    $kqlDetailsUrl = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/kqlDatabases/$kqlDbId"
    $kqlDetails = Invoke-RestMethod -Method Get -Uri $kqlDetailsUrl -Headers $headers

    $kqlIngestionUri = $kqlDetails.properties.ingestionServiceUri
    $kqlQueryUri     = $kqlDetails.properties.queryServiceUri

    Write-Host "KQL Database ID:   $kqlDbId"
    Write-Host "KQL Ingestion URI: $kqlIngestionUri"
    Write-Host "KQL Query URI:     $kqlQueryUri"
    
    # Create an Empty Eventstream Resource

    $body = @{
        displayName = $eventstreamName
        type        = "Eventstream"
    } | ConvertTo-Json

    # Capture the response directly from the creation call
    $response = Invoke-RestMethod -Method Post -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items" -Headers $headers -Body $body
    $eventstreamId = $response.id

    # Fallback query if the direct response body is empty or delayed
    if (-not $eventstreamId) {
        Start-Sleep -Seconds 3
        $items = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items?type=Eventstream" -Headers $headers
        $eventstreamId = ($items.value | Where-Object { $_.displayName -eq $eventstreamName }).id
    }

    Write-Host "Eventstream ID: $eventstreamId"


# Configure Eventstream with Source and Required Default Stream

$streamName = "$($eventstreamName)-stream"

$esJson = @"
{
  "compatibilityLevel": "1.0",
  "sources": [
    {
      "name": "CustomEndpoint-Source",
      "type": "CustomEndpoint",
      "properties": {}
    }
  ],
  "destinations": [],
  "streams": [
    {
      "name": "$streamName",
      "type": "DefaultStream",
      "properties": {},
      "inputNodes": [
        {
          "name": "CustomEndpoint-Source"
        }
      ]
    }
  ],
  "operators": []
}
"@

# Base64-encode the definition
$esBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($esJson))

$updateBody = @{
    definition = @{
        parts = @(
            @{
                path        = "eventstream.json"
                payloadType = "InlineBase64"
                payload     = $esBase64
            }
        )
    }
} | ConvertTo-Json -Depth 10

Write-Host "Updating Eventstream definition with DefaultStream..."
$updateUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/eventstreams/$eventstreamId/updateDefinition"

Invoke-RestMethod -Method Post -Uri $updateUri -Headers $headers -Body $updateBody -ResponseHeadersVariable updateHeaders | Out-Null
Wait-FabricOperation -resHeaders $updateHeaders -headers $headers

Write-Host "Eventstream definition updated successfully!"

# 1. Re-fetch and explicitly validate the KQL database ID and Name
$kqlDatabases = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/kqlDatabases" -Headers $headers
$targetKqlDb  = $kqlDatabases.value | Select-Object -First 1

if (-not $targetKqlDb) {
    throw "No KQL databases found in workspace $wsId."
}

$script:kqlDbId   = $targetKqlDb.id
$script:kqlDbName = $targetKqlDb.displayName

Write-Host "Validated KQL Database ID:   $script:kqlDbId"
Write-Host "Validated KQL Database Name: $script:kqlDbName"

# 2. Build topology payload using the explicitly set variables
$streamName = "$($eventstreamName)-stream"

$esJson = @"
{
  "compatibilityLevel": "1.0",
  "sources": [
    {
      "name": "CustomEndpoint-Source",
      "type": "CustomEndpoint",
      "properties": {}
    }
  ],
  "streams": [
    {
      "name": "$streamName",
      "type": "DefaultStream",
      "properties": {},
      "inputNodes": [
        {
          "name": "CustomEndpoint-Source"
        }
      ]
    }
  ],
  "destinations": [
    {
      "name": "KQLDatabaseDestination",
      "type": "Eventhouse",
      "inputNodes": [
        {
          "name": "$streamName"
        }
      ],
      "properties": {
        "dataIngestionMode": "ProcessedIngestion",
        "workspaceId": "$wsId",
        "itemId": "$script:kqlDbId",
        "databaseName": "$script:kqlDbName",
        "tableName": "marketing_signal",
        "inputSerialization": {
          "type": "Json",
          "properties": {
            "encoding": "UTF8"
          }
        }
      }
    }
  ],
  "operators": []
}
"@

$esBase64   = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($esJson))
$updateBody = @{
    definition = @{
        parts = @(
            @{
                path        = "eventstream.json"
                payloadType = "InlineBase64"
                payload     = $esBase64
            }
        )
    }
} | ConvertTo-Json -Depth 10

$updateUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/eventstreams/$eventstreamId/updateDefinition"

Write-Host "Updating Eventstream definition..."
Invoke-RestMethod -Method Post -Uri $updateUri -Headers $headers -Body $updateBody -ResponseHeadersVariable updateHeaders | Out-Null
Wait-FabricOperation -resHeaders $updateHeaders -headers $headers

Write-Host "KQL Database destination successfully attached!"

###Fetching the CustomEndpoint EventHub Conn String

# 1. Ensure Workspace and Eventstream IDs are resolved
if (-not $wsId) {
    $workspaces = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces" -Headers $headers
    $wsId = ($workspaces.value | Where-Object { $_.displayName -eq "your_workspace_name" }).id # Update if needed, or assume $wsId is present
}

$items = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items?type=Eventstream" -Headers $headers
$targetEventstream = $items.value | Where-Object { $_.displayName -eq $eventstreamName }
$eventstreamId = $targetEventstream.id

Write-Host "Eventstream ID: $eventstreamId"

# 2. Fetch Eventstream definition to find the exact CustomEndpoint-Source GUID
$getDefUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/eventstreams/$eventstreamId/getDefinition"
$response = Invoke-RestMethod -Method Post -Uri $getDefUri -Headers $headers -ResponseHeadersVariable getDefHeaders

if ($getDefHeaders["Location"]) {
    $opUrl = $getDefHeaders["Location"]
    do {
        Start-Sleep -Seconds 3
        $opStatus = Invoke-RestMethod -Method Get -Uri $opUrl -Headers $headers
    } while ($opStatus.status -eq "Running")
    $definitionData = $opStatus.result
} else {
    $definitionData = $response
}

$esPart = $definitionData.definition.parts | Where-Object { $_.path -eq "eventstream.json" }
$decodedBytes = [System.Convert]::FromBase64String($esPart.payload)
$esJsonString = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
$esObj = $esJsonString | ConvertFrom-Json

$sourceNode = $esObj.sources | Where-Object { $_.type -eq "CustomEndpoint" }
if (-not $sourceNode) {
    throw "CustomEndpoint source not found in Eventstream definition."
}
$sourceId = $sourceNode.id
Write-Host "Source ID: $sourceId"

Start-Sleep -Seconds 60

# 3. Retrieve connection properties from the topology endpoint
$connectionUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/eventstreams/$eventstreamId/sources/$sourceId/connection"
Write-Host "Calling connection URI: $connectionUri"
$connResponse = Invoke-RestMethod -Method Get -Uri $connectionUri -Headers $headers

# Extract the correct nested properties based on the Fabric API schema
$sasConnectionString = $connResponse.accessKeys.primaryConnectionString
$eventHubName        = $connResponse.eventHubName

if (-not $sasConnectionString) {
    throw "Failed to retrieve primary connection string from accessKeys."
}

Write-Host ""
Write-Host "--- Successfully Extracted Credentials ---"
Write-Host "Event Hub Name:                 $eventHubName"
Write-Host "Connection String Primary Key:  $sasConnectionString"
Write-Host "------------------------------------------"

# Retrieve the Fabric access token from your active Cloud Shell context
$secureToken = (Get-AzAccessToken -AsSecureString -ResourceUrl "https://api.fabric.microsoft.com").Token
$token = ConvertFrom-SecureString -SecureString $secureToken -AsPlainText

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type"  = "application/json"
}

# Query the Microsoft Fabric REST API
$response = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId" -Headers $headers -Method GET
$wsName = $response.displayName

Write-Host "Workspace Name: $($wsName)" -ForegroundColor Green

# 4. Inject values into the Notebook
$notebookPath = "./artifacts/notebooks/Generate_Realtime_Marketing_Signal_data.ipynb"

if (Test-Path $notebookPath) {
    $notebookContent = Get-Content -Path $notebookPath -Raw
    
    # Perform replacements for both placeholders
    $notebookContent = $notebookContent -replace '###CONNECTION_STR###', $sasConnectionString
    $notebookContent = $notebookContent -replace '###EVENT_HUB_NAME###', $eventHubName
    $notebookContent = $notebookContent -replace '###WORKSPACE_NAME###', $wsName
    $notebookContent = $notebookContent -replace '###LAKEHOUSE_NAME###', $fsiLakehouse
    $notebookContent = $notebookContent -replace '###KUSTO_URI###', $kqlQueryUri
    $notebookContent = $notebookContent -replace '###KQL_DB_NAME###', $kqlDbName
    
    Set-Content -Path $notebookPath -Value $notebookContent -NoNewline
    Write-Host "Successfully injected credentials into: $notebookPath"
} else {
    Write-Error "Notebook path not found at: $notebookPath"
}

# Deploy Local Jupyter Notebook to Fabric and Execute It (Using Azure CLI Token)
# Obtain a fresh and valid token using Azure CLI, which is natively authenticated in Cloud Shell
$token = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
if (-not $token) {
    throw "Failed to acquire access token. Please ensure you are logged in via 'az login'."
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

Start-Sleep -Seconds 30

$notebookName = "Generate_Realtime_Marketing_Signal_data"
$notebookPath = Join-Path (Get-Location) "artifacts/notebooks/Generate_Realtime_Marketing_Signal_data.ipynb"

if (-not (Test-Path $notebookPath)) {
    throw "Notebook file not found at path: $notebookPath"
}

# 1. Read and Base64 encode the notebook file
$nbBytes  = [System.IO.File]::ReadAllBytes($notebookPath)
$nbBase64 = [System.Convert]::ToBase64String($nbBytes)

$cleanName = $notebookName -replace '\.ipynb$', ''
$notebooks = (Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/notebooks" -Headers $headers).value
$existingNotebook = $notebooks | Where-Object { $_.displayName -eq $cleanName -or $_.displayName -eq $notebookName }

$notebookPayload = @{
    format = "ipynb"
    parts = @(@{ path = "notebook-content.ipynb"; payloadType = "InlineBase64"; payload = $nbBase64 })
}

if ($existingNotebook) {
    $notebookId = $existingNotebook.id
    Write-Host "Updating notebook (ID: $notebookId)..."
    $uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/notebooks/$notebookId/updateDefinition"
    $body = @{ definition = $notebookPayload } | ConvertTo-Json -Depth 10
} else {
    Write-Host "Creating new notebook..."
    $uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/notebooks"
    $body = @{ displayName = $cleanName; definition = $notebookPayload } | ConvertTo-Json -Depth 10
}

$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ResponseHeadersVariable resHeaders

Start-Sleep -Seconds 30

# Fallback & Verification Retry Loop for Eventual Consistency
$maxRetries = 6
$retryCount = 0
$notebookName = "Generate_Realtime_Marketing_Signal_data"

while (-not $notebookId -and $retryCount -lt $maxRetries) {
    Write-Host "Notebook ID not immediately returned. Querying workspace items (Attempt $($retryCount + 1))..."
    Start-Sleep -Seconds 4
    
    $workspaceItems = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items?type=Notebook" -Headers $headers
    $foundItem = $workspaceItems.value | Where-Object { $_.displayName -eq $notebookName }
    
    if ($foundItem) {
        $notebookId = $foundItem.id
        break
    }
    $retryCount++
}

if (-not $notebookId) {
    throw "Could not resolve Notebook ID for '$notebookName' after multiple attempts."
}

Write-Host "Notebook ID: $notebookId"

# 3. Trigger Notebook Execution On-Demand
Write-Host "Triggering notebook execution job..."
$runUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/notebooks/$notebookId/jobs/execute/instances?beta=false"
Invoke-RestMethod -Method Post -Uri $runUri -Headers $headers -ResponseHeadersVariable runHeaders | Out-Null

if ($runHeaders["Location"]) {
    $runLocation = @($runHeaders["Location"])[0]
    Write-Host "Job submitted. Monitoring execution status..."
    do {
        Start-Sleep -Seconds 5
        $jobStatus = Invoke-RestMethod -Method Get -Uri $runLocation -Headers $headers
        Write-Host "Current Job Status: $($jobStatus.status)"
    } while ($jobStatus.status -eq "Running" -or $jobStatus.status -eq "NotStarted" -or $jobStatus.status -eq "InProgress")

    if ($jobStatus.status -eq "Completed") {
        Write-Host "Notebook execution completed successfully! Data is now streaming into your Eventstream and target KQL table."
    } else {
        Write-Error "Notebook execution finished with status: $($jobStatus.status)"
    }
} else {
    Write-Host "Notebook execution request accepted successfully."
}

# Precise Real-Time Dashboard Deployment with Retry for Name Availability

$jsonPath = "./RealTimeDashboardDefinition.json"
if (-not (Test-Path $jsonPath)) {
    $jsonPath = "./artifacts/fabricAssets/RealTimeDashboardDefinition.json"
}
if (-not (Test-Path $jsonPath)) {
    throw "Could not find 'RealTimeDashboardDefinition.json'."
}

$dashboardName = "FSI_Real_Time_Dashboard_$suffix"

# 1. Obtain Fabric API token
$fabricToken = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$headers = @{
    "Authorization" = "Bearer $fabricToken"
    "Content-Type"  = "application/json"
}

# 2. Resolve target KQL Database details
Write-Host "Resolving target KQL Database in workspace $wsId..."
$targetKqlDbs = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/kqlDatabases" -Headers $headers
$targetKql = $targetKqlDbs.value | Select-Object -First 1
if (-not $targetKql) {
    throw "No KQL databases found in target workspace $wsId."
}

$targetKqlDbId   = $targetKql.id
$targetKqlDbName = $targetKql.displayName
$targetQueryUri  = $targetKql.properties.queryServiceUri

# 3. Read saved definition file
$definitionData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

# 4. Cleanly rewire dataSources to strictly match Fabric schema rules
foreach ($part in $definitionData.definition.parts) {
    if ($part.path -match "\.json$" -and $part.payloadType -eq "InlineBase64") {
        $decodedBytes = [System.Convert]::FromBase64String($part.payload)
        $innerJsonString = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
        
        $innerJsonString = $innerJsonString -replace 'marketing_signals', 'marketing_signal'
        
        $dashboardObj = $innerJsonString | ConvertFrom-Json -AsHashtable

        if ($dashboardObj.ContainsKey("dataSources") -and $dashboardObj["dataSources"] -is [Array]) {
            foreach ($ds in $dashboardObj["dataSources"]) {
                $ds["kind"] = "kusto"
                $ds["workspaceId"] = $wsId
                $ds["databaseArtifactId"] = $targetKqlDbId
                $ds["database"] = $targetKqlDbName
                $ds["clusterUri"] = $targetQueryUri
                
                if ($ds.ContainsKey("queryUri")) { $ds.Remove("queryUri") }
                if ($ds.ContainsKey("itemId")) { $ds.Remove("itemId") }
            }
        }

        $updatedInnerJson = $dashboardObj | ConvertTo-Json -Depth 100 -Compress
        $part.payload = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedInnerJson))
    }
}

# 5. Check if Dashboard exists, then create or update with automatic retry for name availability
Write-Host "Checking if dashboard '$dashboardName' exists in target workspace..."
$targetItems = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items?type=KQLDashboard" -Headers $headers
$existingDash = $targetItems.value | Where-Object { $_.displayName -eq $dashboardName }

$maxRetries = 6
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        if ($existingDash) {
            $dashId = $existingDash.id
            Write-Host "Dashboard exists (ID: $dashId). Updating definition..."
            
            $updateBody = @{
                definition = $definitionData.definition
            } | ConvertTo-Json -Depth 10
            
            $updateUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items/$dashId/updateDefinition"
            Invoke-RestMethod -Method Post -Uri $updateUri -Headers $headers -Body $updateBody -ResponseHeadersVariable updateHeaders | Out-Null
            
            if ($updateHeaders["Location"]) {
                $opUrl = @($updateHeaders["Location"])[0]
                do {
                    Start-Sleep -Seconds 3
                    $opStatus = Invoke-RestMethod -Method Get -Uri $opUrl -Headers $headers
                } while ($opStatus.status -eq "Running")
            }
            Write-Host "Dashboard successfully updated and validated against Fabric schema!"
        } else {
            Write-Host "Creating new Real-Time Dashboard (Attempt $($retryCount + 1))..."
            
            $createBody = @{
                displayName = $dashboardName
                type        = "KQLDashboard"
                definition  = $definitionData.definition
            } | ConvertTo-Json -Depth 10
            
            $createUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items"
            $createResponse = Invoke-RestMethod -Method Post -Uri $createUri -Headers $headers -Body $createBody -ResponseHeadersVariable createHeaders
            
            if ($createHeaders["Location"]) {
                $opUrl = @($createHeaders["Location"])[0]
                do {
                    Start-Sleep -Seconds 3
                    $opStatus = Invoke-RestMethod -Method Get -Uri $opUrl -Headers $headers
                } while ($opStatus.status -eq "Running")
                $dashId = $opStatus.result.id
            } else {
                $dashId = $createResponse.id
            }
            Write-Host "Dashboard successfully created (ID: $dashId) and validated against Fabric schema!"
        }
        $success = $true
    } catch {
        $exMessage = $_.Exception.Message
        if ($exMessage -match "ItemDisplayNameNotAvailableYet" -and $retryCount -lt ($maxRetries - 1)) {
            Write-Warning "Display name is locked or releasing from a previous deletion. Waiting 5 seconds before retry..."
            Start-Sleep -Seconds 5
            $retryCount++
        } else {
            throw $_
        }
    }
}


# Standalone Clean Creation Script for 'Operations agent'


$jsonPath  = "./artifacts/fabricAssets/OperationsAgentDefinition.json"
$agentName = "FSI_Operations_Agent_$suffix"

if (-not (Test-Path $jsonPath)) {
    throw "Could not find definition file at '$jsonPath'. Please ensure it has been extracted first."
}

# 1. Obtain Fabric API token
$fabricToken = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$headers = @{
    "Authorization" = "Bearer $fabricToken"
    "Content-Type"  = "application/json"
}

# 2. Resolve target KQL Database details in current workspace ($wsId)
Write-Host "Resolving target KQL Database in workspace $wsId..."
$targetKqlDbs = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/kqlDatabases" -Headers $headers
$targetKql = $targetKqlDbs.value | Select-Object -First 1
if (-not $targetKql) {
    throw "No KQL databases found in target workspace $wsId."
}
$targetKqlDbId = $targetKql.id
Write-Host "Found Target KQL Database ID: $targetKqlDbId"
Write-Host "Target Workspace ID:          $wsId"

# 3. Read saved definition file and parse JSON
$definitionData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

# 4. Process 'Configurations.json' part to rewire dataSources to current workspace & KQL database
foreach ($part in $definitionData.definition.parts) {
    if ($part.path -eq "Configurations.json" -and $part.payloadType -eq "InlineBase64") {
        $decodedBytes    = [System.Convert]::FromBase64String($part.payload)
        $innerJsonString = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
        
        $configObj = $innerJsonString | ConvertFrom-Json -AsHashtable

        if ($configObj.ContainsKey("configuration") -and $configObj["configuration"].ContainsKey("dataSources")) {
            $dataSources = $configObj["configuration"]["dataSources"]
            $oldKeys     = @($dataSources.Keys)

            foreach ($oldKey in $oldKeys) {
                $dsValue = $dataSources[$oldKey]
                $dataSources.Remove($oldKey)

                # Update inner properties to point to the current workspace and target KQL database
                $dsValue["id"]          = $targetKqlDbId
                $dsValue["workspaceId"] = $wsId

                # Re-add using the correct target KQL database ID as the key
                $dataSources[$targetKqlDbId] = $dsValue
                Write-Host "Rewired data source key/ID from '$oldKey' to '$targetKqlDbId'"
            }
        }

        # Convert back to JSON string, re-encode to Base64
        $updatedInnerJson = $configObj | ConvertTo-Json -Depth 100 -Compress
        $part.payload     = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedInnerJson))
    }
}

# 5. Create Operations Agent in target workspace with retry logic for name availability
Write-Host "Creating new Operations agent '$agentName' in target workspace..."
$createBody = @{
    displayName = $agentName
    definition  = $definitionData.definition
} | ConvertTo-Json -Depth 10

$createUri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/operationsAgents"

$maxRetries = 6
$retryCount = 0
$success = $false
$targetAgentId = $null

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $response = Invoke-RestMethod -Method Post -Uri $createUri -Headers $headers -Body $createBody -ResponseHeadersVariable createHeaders
        
        if ($createHeaders["Location"]) {
            $opUrl = @($createHeaders["Location"])[0]
            do {
                Start-Sleep -Seconds 3
                $opStatus = Invoke-RestMethod -Method Get -Uri $opUrl -Headers $headers
            } while ($opStatus.status -eq "Running")
            $targetAgentId = $opStatus.result.id
        } else {
            $targetAgentId = $response.id
        }
        
        Write-Host "Operations agent successfully created with ID: $targetAgentId and fully wired to current workspace!"
        $success = $true
    } catch {
        $exMessage = $_.Exception.Message
        if ($exMessage -match "ItemDisplayNameNotAvailableYet" -and $retryCount -lt ($maxRetries - 1)) {
            Write-Warning "Display name is locked or releasing from a previous deletion. Waiting 5 seconds before retry..."
            Start-Sleep -Seconds 5
            $retryCount++
        } else {
            throw $_
        }
    }
}



    # Function App Loan Mortgage
    
    $storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storage_account_name)[0].Value
    $webjobs = "DefaultEndpointsProtocol=https;AccountName=" + $storage_account_name + ";AccountKey=" + $storage_account_key + ";EndpointSuffix=core.windows.net"

    $aiAccount = az cognitiveservices account show --name $aiServicesName --resource-group $rgName | ConvertFrom-Json
    $baseUrl = $aiAccount.properties.endpoint.TrimEnd('/')
    $AZURE_AI_PROJECT_ENDPOINT = "$baseUrl/api/projects/$workspaces_prj_name"


    Write-Host "1. Configuring all App Settings..." -ForegroundColor Cyan
    $config = az functionapp config appsettings set `
        --resource-group $rgName `
        --name $func_app_mortgage `
        --settings `
            "FUNCTIONS_EXTENSION_VERSION=~4" `
            "FUNCTIONS_WORKER_RUNTIME=python" `
            "AzureWebJobsStorage=$webjobs" `
            "PROJECT_ENDPOINT=$AZURE_AI_PROJECT_ENDPOINT" `
            "WORKFLOW_NAME=FSIIQ-Workflow" `
            "PYTHON_ENABLE_BUILD_WITH_PIP=true" `
            "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
            "FORCE_TOKEN_REFRESH=$(Get-Random)"

    Write-Host "2. Configuring Linux Runtime and Always On..." -ForegroundColor Cyan
    $config = az functionapp config set `
        --resource-group $rgName `
        --name $func_app_mortgage `
        --linux-fx-version "PYTHON|3.11" `
        --always-on true

    Write-Host "Function App configuration applied successfully!" -ForegroundColor Green

    # Compress-Archive -Path "./artifacts/functionApp/*" -DestinationPath "./functionApp.zip" -Force

    # az webapp deploy --resource-group rg-fsi-iq-vqek17b --name $func_app_mortgage --src-path ./functionApp.zip --type zip
    
    $maxRetries = 3
    $retryDelaySeconds = 15
    $success = $false

    Push-Location ./artifacts/functionApp
    try {
        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            try {
                Write-Host "Publishing Python function app '$func_app_mortgage' (Attempt $attempt of $maxRetries)..."
                
                func azure functionapp publish $func_app_mortgage --publish-local-settings --python
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Function app published successfully." -ForegroundColor Green
                    $success = $true
                    break
                } else {
                    throw "Azure Functions CLI exited with non-zero code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Warning "Publish attempt $attempt failed: $_"
                if ($attempt -eq $maxRetries) {
                    throw "All $maxRetries function app deployment attempts failed."
                }
                Write-Host "Waiting $retryDelaySeconds seconds before retrying..."
                Start-Sleep -Seconds $retryDelaySeconds
            }
        }
    }
    finally {
        Pop-Location
    }

    if ($success) {
        Start-Sleep -Seconds 10
    }


    Add-Content log.txt "------PowerBI authentication STARTS HERE------"
    Write-Host "------------PowerBI authentication STARTS HERE------------"


    $spname = "FSI IQ $suffix"
 
    $app = az ad app create --display-name $spname | ConvertFrom-Json
    $appId = $app.appId
    
    $mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
    $clientsecpwdapp = $mainAppCredential.password
    
    az ad sp create --id $appId | Out-Null    
    $sp = az ad sp show --id $appId --query "id" -o tsv
    start-sleep -s 15
    
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
    
    Add-Content log.txt "------Uploading PowerBI Reports------"
    Write-Host "------------Uploading PowerBI Reports------------"

    $PowerBIFiles = Get-ChildItem "./artifacts/reports" -Recurse -Filter *.pbix
    $reportList = @()

    foreach ($Pbix in $PowerBIFiles) {
    Write-Output "Uploading report: $($Pbix.BaseName +'.pbix')"

    $report = New-PowerBIReport -Path $Pbix.FullName -WorkspaceId $wsId -ConflictAction CreateOrOverwrite

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
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets"
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


    #Web app
    Add-Content log.txt "------Deploying Web Apps------"
    Write-Host  "----------------Deploying Web Apps---------------"
    RefreshTokens

    $zips = @("fsi-iq-dpoc")
    foreach($zip in $zips)
    {
        expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
    }

    (Get-Content -path fsi-iq-dpoc/appsettings.json -Raw) | Foreach-Object { $_ `
            -replace '#WORKSPACE_ID#', $wsId`
            -replace '#CLIENT_ID#', $appId`
            -replace '#CLIENT_SECRET#', $clientsecpwdapp`
            -replace '#TENANT_ID#', $tenantId`
    } | Set-Content -Path fsi-iq-dpoc/appsettings.json

    $filepath = "./fsi-iq-dpoc/wwwroot/config.js"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#BLOB_STORAGE_ACCOUNT#", $storage_account_name).Replace("#STORAGE_ACCOUNT#", $storage_account_name).Replace("#BACKEND_API_URL#", $app_fsi_name).Replace("#WORKSPACE_ID#", $wsId).Replace("#POWERBI_SERVER#", "app-common-powerbi-server").Replace("#FUNC_MORTGAGE_LOAN#", $func_app_mortgage).Replace("#PBI_WORKSPACE_ID#", $wsId)
    Set-Content -Path $filepath -Value $item

    RefreshTokens
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
    $reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
    $reportList = $reportList.Value

    #update all th report ids in the poc web app...
    $ht = new-object system.collections.hashtable
    $ht.add("#PBI_REPORT_ID#", $($reportList | where { $_.name -eq "MortgagePerformanceDashboard" }).id)
    
    $filePath = "./fsi-iq-dpoc/wwwroot/config.js";
    Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

    Compress-Archive -Path "./fsi-iq-dpoc/*" -DestinationPath "./fsi-iq-dpoc.zip" -Update

    # fetching authentication token
    $TOKEN = az account get-access-token --query accessToken | tr -d '"'

    az webapp stop --name $app_fsi_name --resource-group $rgName

    $maxRetries = 3
    $retryDelaySeconds = 10
    $success = $false

    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            Write-Host "Starting deployment attempt $attempt of $maxRetries..."
            
            # Using Azure CLI for a more precise, synchronous zip deployment
            $deployOutput = az webapp deployment source config-zip `
                --resource-group $rgName `
                --name $app_fsi_name `
                --src "./fsi-iq-dpoc.zip" 2>&1
            
            # az commands don't automatically throw PowerShell exceptions, so we check the exit code
            if ($LASTEXITCODE -ne 0) {
                throw "Azure CLI deployment failed: $deployOutput"
            }
            
            Write-Host "Deployment package published successfully." -ForegroundColor Green
            $success = $true
            break
        }
        catch {
            Write-Warning "Attempt $attempt failed: $_"
            if ($attempt -eq $maxRetries) {
                throw "All $maxRetries deployment attempts failed."
            }
            Write-Host "Waiting $retryDelaySeconds seconds before retrying..."
            Start-Sleep -Seconds $retryDelaySeconds
        }
    }
    # Added verification check to ensure the web app is live and responding
    Write-Host "Verifying web app health and response..." -ForegroundColor Cyan
    $appUrl = "https://$app_fsi_name.azurewebsites.net"
    $maxHealthTries = 6
    $healthHealthy = $false

    for ($i = 1; $i -le $maxHealthTries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $appUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                Write-Host "Web app is up and responding (HTTP status: $($response.StatusCode))." -ForegroundColor Green
                $healthHealthy = $true
                break
            }
        }
        catch {
            Write-Host "Attempt $i/($maxHealthTries): Web app is still initializing..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
    }

    if (-not $healthHealthy) {
        Write-Warning "Web app started, but did not respond with a valid status code within the timeout window."
    }

    
    az webapp start --name $app_fsi_name --resource-group $rgName

$webAppHostName = az webapp show --name $app_fsi_name --resource-group $rgName --query "defaultHostName" -o tsv

az functionapp cors add `
    --name $func_app_mortgage `
    --resource-group $rgName `
    --allowed-origins "https://$webAppHostName" "https://portal.azure.com" "https://ms.portal.azure.com" 2>$null | Out-Null

### Fetching Values to be replace in the Foundry Automation ###
Add-Content log.txt "------Foundry Automation------"
Write-Host "------------Foundry Automation------------"

$aiAccount = az cognitiveservices account show --name $aiServicesName --resource-group $rgName | ConvertFrom-Json
$baseUrl = $aiAccount.properties.endpoint.TrimEnd('/')
$AZURE_AI_PROJECT_ENDPOINT = "$baseUrl/api/projects/$workspaces_prj_name"
Write-Host "AZURE_AI_PROJECT_ENDPOINT=$AZURE_AI_PROJECT_ENDPOINT"

$AZURE_AI_SERVICES_ENDPOINT = (az cognitiveservices account show --name $aiServicesName --resource-group $rgName --query "properties.endpoint" -o tsv).Trim()
Write-Host "AZURE_AI_SERVICES_ENDPOINT=$AZURE_AI_SERVICES_ENDPOINT"

$AZURE_AI_SERVICES_KEY = (az cognitiveservices account keys list --name $aiServicesName --resource-group $rgName --query "key1" -o tsv).Trim()
Write-Host "AZURE_AI_SERVICES_KEY=$AZURE_AI_SERVICES_KEY"

$AZURE_SEARCH_ENDPOINT = "https://$searchServiceName.search.windows.net"

$fabricToken = (az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv).Trim()

$headers = @{
    "Authorization" = "Bearer $fabricToken"
    "Content-Type"  = "application/json"
}

$agentName = "FSI_IQ_Agent_$suffix"
$itemsList = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items" -Headers $headers

$targetAgent = $itemsList.value | Where-Object { $_.displayName -eq $agentName }
if (-not $targetAgent) {
    $targetAgent = $itemsList.value | Where-Object { $_.displayName -like "*$agentName*" } | Select-Object -First 1
}

if ($targetAgent) {
    $script:agentId = $targetAgent.id
    Write-Host "Resolved Data Agent ID: $agentId" -ForegroundColor Green
} else {
    Write-Error "Data agent '$agentName' not found in workspace $wsId."
}

Set-Location ./artifacts/foundry

Copy-Item -Path ".env.sample" -Destination ".env" -Force

$filepath = ".env"
$envTemplate = Get-Content -Path $filepath -Raw

$envContent = $envTemplate.Replace("###AZURE_SUBSCRIPTION_ID###", $subscriptionId).Replace("###AZURE_RESOURCE_GROUP###", $rgName).Replace("###AZURE_LOCATION###", $Region).Replace("###AZURE_SEARCH_LOCATION###", $Region).Replace("###AZURE_AI_SERVICES_NAME###", $aiServicesName).Replace("###AZURE_AI_PROJECT_NAME###", $workspaces_prj_name).Replace("###AZURE_AI_PROJECT_ENDPOINT###", $AZURE_AI_PROJECT_ENDPOINT).Replace("###AZURE_AI_SERVICES_ENDPOINT###", $AZURE_AI_SERVICES_ENDPOINT).Replace("###AZURE_AI_SERVICES_KEY###", $AZURE_AI_SERVICES_KEY).Replace("###AZURE_KB_MODEL_DEPLOYMENT###", $model1Name).Replace("###AZURE_CHAT_DEPLOYMENT###", $model1Deployment).Replace("###AZURE_EMBEDDING_DEPLOYMENT###", $model2Deployment).Replace("###AZURE_SEARCH_NAME###", $searchServiceName).Replace("###AZURE_SEARCH_ENDPOINT###", $AZURE_SEARCH_ENDPOINT).Replace("###FABRIC_WORKSPACE_ID###", $wsId).Replace("###FABRIC_DATA_AGENT_ID###", $agentId)

Set-Content -Path $filepath -Value $envContent

python -m pip install --user -r requirements.txt
python deploy_foundry_agents.py

cd..
cd..


Add-Content log.txt "------Foundry Automation COMPLETE------"
Write-Host "------------Foundry Automation COMPLETE------------"

Write-Host "=== Assigning necessary permissions to resources Started ===" -ForegroundColor Cyan

    $SEARCH_SCOPE = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Search/searchServices/$searchServiceName"
    $HUB_SCOPE         = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$aiServicesName"
    $PROJ_SCOPE        = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$aiServicesName/projects/$workspaces_prj_name"

    az search service update --name $searchServiceName --resource-group $rgName --identity-type SystemAssigned

    # 3. Resolve Managed Identities
    $HUB_PRINCIPAL_ID  = az resource show --ids $HUB_SCOPE --query "identity.principalId" -o tsv 2>$null
    $PROJ_PRINCIPAL_ID = az resource show --ids $PROJ_SCOPE --query "identity.principalId" -o tsv 2>$null
    $FUNC_PRINCIPAL_ID = if ($func_app_mortgage) { az functionapp identity show -g $rgName -n $func_app_mortgage --query principalId -o tsv 2>$null } else { $null }
    $SEARCH_PRINCIPAL_ID = az search service show --name $searchServiceName --resource-group $rgName --query "identity.principalId" -o tsv

    Write-Host "Search Service Principal ID: $SEARCH_PRINCIPAL_ID"
    Write-Host "Hub Principal ID     : $HUB_PRINCIPAL_ID"
    Write-Host "Project Principal ID : $PROJ_PRINCIPAL_ID"
    Write-Host "Function App ID      : $FUNC_PRINCIPAL_ID"

# 4. Assign Search Roles to Foundry Hub & Project
Write-Host "`n==> Configuring Search Service RBAC for Foundry..." -ForegroundColor Cyan
if ($HUB_PRINCIPAL_ID) {
    az role assignment create --assignee-object-id $HUB_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Search Index Data Reader" --scope $SEARCH_SCOPE 2>$null | Out-Null
    az role assignment create --assignee-object-id $HUB_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Search Service Contributor" --scope $SEARCH_SCOPE 2>$null | Out-Null
}

if ($PROJ_PRINCIPAL_ID -and ($PROJ_PRINCIPAL_ID -ne $HUB_PRINCIPAL_ID)) {
    az role assignment create --assignee-object-id $PROJ_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Search Index Data Reader" --scope $SEARCH_SCOPE 2>$null | Out-Null
    az role assignment create --assignee-object-id $PROJ_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Search Service Contributor" --scope $SEARCH_SCOPE 2>$null | Out-Null
}

# 5. Assign Azure AI Developer Role to Function App

$RG_ID = az group show -n $rgName --query "id" -o tsv

if ($FUNC_PRINCIPAL_ID) {
    Write-Host "==> Granting Function App access to Foundry Workflow..." -ForegroundColor Cyan
    az role assignment create --assignee-object-id $FUNC_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Azure AI Developer" --scope $HUB_SCOPE 2>$null | Out-Null
    az role assignment create --assignee-object-id $FUNC_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Azure AI Developer" --scope $PROJ_SCOPE 2>$null | Out-Null
    az functionapp restart -g $rgName -n $func_app_mortgage 2>$null | Out-Null
    az role assignment create --assignee-object-id $FUNC_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Cognitive Services OpenAI Contributor" --scope $RG_ID 2>$null | Out-Null
    az role assignment create --assignee-object-id $FUNC_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Cognitive Services User" --scope $RG_ID 2>$null | Out-Null
}

# 6. Assign Cognitive Services OpenAI User to Search (if identity exists)
if ($SEARCH_PRINCIPAL_ID -and $HUB_SCOPE) {
    Write-Host "==> Granting Search Service identity access to Foundry..." -ForegroundColor Cyan
    az role assignment create --assignee-object-id $SEARCH_PRINCIPAL_ID --assignee-principal-type ServicePrincipal --role "Cognitive Services OpenAI User" --scope $HUB_SCOPE 2>$null | Out-Null
}

# 7. Print Active Search Roles
Write-Host "`nAssigned Roles on Search Service (${SEARCH_NAME}):" -ForegroundColor Green
az role assignment list --scope $SEARCH_SCOPE --query "[].{Principal:principalName, Role:roleDefinitionName, PrincipalId:principalId}" -o table

Write-Host "=== Assigning necessary permissions to resources COMPLETE ===" -ForegroundColor Cyan

Write-Host "=== 1. Azure Resources in $rgName ===" -ForegroundColor Cyan
az resource list --resource-group $rgName --output table

Write-Host "=== 2. AI Foundry & Cognitive Services in $rgName ===" -ForegroundColor Cyan
az cognitiveservices account list --resource-group $rgName --output table

Write-Host "=== 3. Microsoft Fabric Workspace Items ===" -ForegroundColor Cyan
$token = (az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv).Trim()
$headers = @{ "Authorization" = "Bearer $token" }
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $response.value | Select-Object id, displayName, type | Format-Table -AutoSize
}
catch {
    Write-Warning "Failed to fetch Fabric items: $_. Ensure you are logged in with az login and have workspace permissions."
}


    $endtime = get-date
    $executiontime = $endtime - $starttime
    Write-Host "Execution Time - "$executiontime.TotalMinutes

}
