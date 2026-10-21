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

    az login

    $subscriptionId = (az account show --query 'id' -o tsv)
    $tenantId = (Get-AzContext).Tenant.Id

    Connect-AzAccount -DeviceCode -SubscriptionId $subscriptionId
    $starttime = get-date

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
        }
        else {
            Write-Host "Aborting deployment."
            exit
        }
    }

    # 1. Variables Definition
    [string]$suffix = -join ((48..57) + (97..122) | Get-Random -Count 7 | % { [char]$_ })
    $rgName = "rg-ui-$suffix"
    $Region = read-host "Enter the region for deployment (e.g., northcentralus)"

    # # Define variables matching all ARM template parameters
    $storage_account_name = "storage$suffix"
    $containerName = 'enterprise-knowledgebase'
    # $asp_aca_name = "asp-aca-$suffix"
    # $app_aca_name = "app-aca-$suffix"
    # $func_mcp_reconcile_tool = "func-mcp-reconcile-$suffix"
    # $asp_func_mcp_reconcile_tool = "asp-func-mcp-reconcile-$suffix"
    # $userAssignedIdentities_aca_global_demo_identity_name = "id-aca-global-demo-$suffix"
    # $userAssignedIdentities_id_aks_automatic_aca_openai_name = "id-aks-openai-$suffix"
    # $containerapps_container_app_express_aca_name = "app-express-$suffix"
    # $containerapps_caldova_contract_classifier_name = "app-classifier-$suffix"
    # $managedEnvironments_caldova_global_aca_env_name = "cae-caldova-global-$suffix"
    # $containerapps_invoice_agent_name = "app-invoice-agent-$suffix"
    # $containerapps_agents_launchpad_aca_name = "app-agents-launchpad-$suffix"
    # $acr_aca_name = "acraca$suffix" # ACR names must be lowercase alphanumeric only
    # $managedClusters_aks_automatic_aca_prod_name = "aks-automatic-$suffix"
    # $workbooks_aca_name = "workbook-aca-$suffix"
    # $log_analytics_workspace_name = "law-aca-$suffix"
    # $virtualNetworks_ACA_vnet_name = "vnet-aca-$suffix"
    # $subnetName = "subnet-aca-env"
    # $sandboxGroupName = "sandbox-group-$suffix"
    # $apimName = "apim-$suffix"
    # $appInsightsName = "appi-$suffix"
    # $connectionName = 'ACA to Foundry'

    # Core Resources
    $aiServicesName = "hub-aifoundry-ui-$suffix"
    $workspaces_prj_name = "proj-aifoundry-ui-$suffix"
    $searchServiceName = "srch-ui-$suffix"

    # Model 1 (gpt-5.5)
    $model1Deployment = "gpt-5.5"
    $model1Name = "gpt-5.5"
    $model1Version = "2026-04-24"
    $model1Format = "OpenAI"
    $model1SkuName = "GlobalStandard"
    $model1Capacity = 100

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

    # Create Storage Account
    az storage account create `
        --name $storage_account_name `
        --resource-group $rgName `
        --location $Region `
        --sku Standard_LRS `
        --kind StorageV2 `
        --access-tier Hot `
        --allow-blob-public-access $true

    # Retrieve Storage Account Key for container creation authorization
    $storageKey = (az storage account keys list --resource-group $rgName --account-name $storage_account_name --query "[0].value" -o tsv)

    # Create Blob Container
    az storage container create `
        --name $containerName `
        --account-name $storage_account_name `
        --account-key $storageKey

    # Create AI Services Account (Foundry Hub)
    az cognitiveservices account create `
        --name $aiServicesName `
        --resource-group $rgName `
        --kind AIServices `
        --sku S0 `
        --location $Region `
        --allow-project-management `
        --custom-domain $aiServicesName

    # Create Azure AI Search Service
    az search service create `
        --name $searchServiceName `
        --resource-group $rgName `
        --sku basic `
        --location $Region `
        --partition-count 1 `
        --replica-count 1

    # Create AI Foundry Project
    # Create AI Foundry Project
    az cognitiveservices account project create `
        --name $aiServicesName `
        --resource-group $rgName `
        --project-name $workspaces_prj_name `
        --location $Region `
        --assign-identity
        
    # 3. Model Deployments

    # Deploy Model 1
    az cognitiveservices account deployment create `
        --name $aiServicesName `
        --resource-group $rgName `
        --deployment-name $model1Deployment `
        --model-name $model1Name `
        --model-version $model1Version `
        --model-format OpenAI `
        --sku-name GlobalStandard `
        --sku-capacity $model1Capacity

    # Deploy Model 2
    az cognitiveservices account deployment create `
        --name $aiServicesName `
        --resource-group $rgName `
        --deployment-name $model2Deployment `
        --model-name $model2Name `
        --model-version $model2Version `
        --model-format OpenAI `
        --sku-name GlobalStandard `
        --sku-capacity $model2Capacity

    # 4. Configurations and Connections

    # Disable Defender for AI Settings
    az resource create --resource-group $rgName --namespace Microsoft.CognitiveServices --parent "accounts/$aiServicesName" --resource-type defenderForAISettings --name "Default" --properties '{"state":"Disabled"}' --api-version "2026-05-01"

    # 1. endpoints and resource scopes based on deployment
    $PROJ_SCOPE = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$aiServicesName/projects/$workspaces_prj_name"
    $PROJECT_ENDPOINT = "https://${aiServicesName}.services.ai.azure.com/api/projects/${workspaces_prj_name}"
    $SEARCH_ENDPOINT = "https://${searchServiceName}.search.windows.net"
    $STORAGE_RESOURCE_ID = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storage_account_name"
    $AOAI_ENDPOINT = "https://${aiServicesName}.openai.azure.com"
    $model2Deployment = az cognitiveservices account deployment list --name $aiServicesName --resource-group $rgName --query "[?contains(properties.model.name, 'embedding')].name | [0]" --output tsv
    $model1Deployment = az cognitiveservices account deployment list --name $aiServicesName --resource-group $rgName --query "[?properties.model.name != 'text-embedding-3-large'].name | [0]" --output tsv
    
    # 2. Assign standard metadata and logical names provided by AI team
    $KB_NAME = "unified-knowledgebase"
    $KS_NAME = "unified-knowledgesource"
    $KB_CONNECTION_NAME = "foundry-iq-kb-connection"
    $WORK_IQ_CONNECTION_NAME = ""
    $AGENT_NAME = "supply-chain-intelligence-agent"
    $BLOB_CONTAINER = "enterprise-knowledgebase"

    # 3. Navigate to foundry artifact directory and update the .env file
    $targetDir = (Get-ChildItem -Recurse -Filter "create_agent.py" | Select-Object -ExpandProperty DirectoryName -First 1)
    Set-Location $targetDir
    Write-Host "Current Directory: $(Get-Location)" -ForegroundColor Green

    $filepath = ".env"

    $envContent = @"
PROJECT_RESOURCE_ID=$PROJ_SCOPE
PROJECT_ENDPOINT=$PROJECT_ENDPOINT
SEARCH_ENDPOINT=$SEARCH_ENDPOINT
KB_NAME=$KB_NAME
KS_NAME=$KS_NAME
KB_CONNECTION_NAME=$KB_CONNECTION_NAME
WORK_IQ_CONNECTION_NAME=$WORK_IQ_CONNECTION_NAME
CHAT_DEPLOYMENT=$model1Deployment
AGENT_NAME=$AGENT_NAME
STORAGE_RESOURCE_ID=$STORAGE_RESOURCE_ID
BLOB_CONTAINER=$BLOB_CONTAINER
AOAI_ENDPOINT=$AOAI_ENDPOINT
EMBED_DEPLOYMENT=$model2Deployment
"@

    Set-Content -Path $filepath -Value $envContent
    
    Write-Host ".env file successfully updated with actual resource values!" -ForegroundColor Green

    # ==========================================
    # Dynamic Azure AI Foundry & Search Role Assignment Script
    # ==========================================

    $ErrorActionPreference = "Stop"


    # 4. Get User and Principals
    $signedinusername = (az ad signed-in-user show --query "userPrincipalName" -o tsv)
    Write-Host "Target User: $signedinusername" -ForegroundColor Cyan

    # Ensure System-Assigned Managed Identity is enabled on Search Service and fetch its Principal ID
    Write-Host "Ensuring Managed Identity is enabled on Search Service..." -ForegroundColor Cyan
    az search service update --name $searchServiceName --resource-group $rgName --identity-type "SystemAssigned" | Out-Null
    $searchPrincipalId = (az search service show --name $searchServiceName --resource-group $rgName --query "identity.principalId" -o tsv)
    Write-Host "Search Service Principal ID: $searchPrincipalId" -ForegroundColor Green

    # 5. Define Resource Scopes Dynamically
    $storageId = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storage_account_name"
    $searchId = (az resource show --resource-group $rgName --resource-type "Microsoft.Search/searchServices" --name $searchServiceName --query "id" -o tsv)
    $projectScope = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$aiServicesName/projects/$workspaces_prj_name"
    $rgScope = "/subscriptions/$subscriptionId/resourceGroups/$rgName"
    $hubId = (az cognitiveservices account show --name $aiServicesName --resource-group $rgName --query "id" -o tsv)

    
    Write-Host "`nAssigning Required Azure RBAC Roles..." -ForegroundColor Yellow

    # --- USER ASSIGNMENTS ---
    Write-Host "Assigning Storage Blob Data Contributor to user..." -ForegroundColor Cyan
    az role assignment create --assignee $signedinusername --role "Storage Blob Data Contributor" --scope $storageId | Out-Null

    Write-Host "Assigning Search Service Contributor to user..." -ForegroundColor Cyan
    az role assignment create --assignee $signedinusername --role "Search Service Contributor" --scope $searchId | Out-Null

    Write-Host "Assigning Search Index Data Contributor to user..." -ForegroundColor Cyan
    az role assignment create --assignee $signedinusername --role "Search Index Data Contributor" --scope $searchId | Out-Null

    Write-Host "Assigning Azure AI Developer to user..." -ForegroundColor Cyan
    az role assignment create --assignee $signedinusername --role "Azure AI Developer" --scope $projectScope | Out-Null

    Write-Host "Assigning Foundry User to user on Project..." -ForegroundColor Cyan
    az role assignment create --assignee $signedinusername --role "Foundry User" --scope $projectScope | Out-Null

    Write-Host "Assigning Azure AI Administrator to user on Hub..." -ForegroundColor Cyan
    az role assignment create --assignee $signedinusername --role "Azure AI Administrator" --scope $hubId | Out-Null

    Write-Host "Assigning Contributor to user on Resource Group..." -ForegroundColor Cyan
    az role assignment create --assignee $signedinusername --role "Contributor" --scope $rgScope | Out-Null

    # Get the PROJECT'S Managed Identity (Distinct from the Hub)
    $projectPrincipalId = (az resource show --id $projectScope --query "identity.principalId" -o tsv)
    Write-Host "AI Project Principal ID: $projectPrincipalId" -ForegroundColor Cyan

    # Assign Roles
    if ($projectPrincipalId) {
        Write-Host "Assigning Search Data-Plane roles to the AI Project Identity..." -ForegroundColor Yellow
        az role assignment create --assignee $projectPrincipalId --role "Search Index Data Reader" --scope $searchId | Out-Null
        az role assignment create --assignee $projectPrincipalId --role "Search Index Data Contributor" --scope $searchId | Out-Null
        az role assignment create --assignee $projectPrincipalId --role "Search Service Contributor" --scope $searchId | Out-Null
        Write-Host "Roles successfully assigned to AI Project Identity!" -ForegroundColor Green
    } else {
        Write-Warning "AI Project principal ID not found. Ensure identity is enabled on the project."
    }

    # --- MANAGED IDENTITY ASSIGNMENTS ---
    if ($searchPrincipalId) {
        Write-Host "Assigning Storage Blob Data Reader to Search service managed identity..." -ForegroundColor Cyan
        az role assignment create --assignee $searchPrincipalId --role "Storage Blob Data Reader" --scope $storageId | Out-Null
        
        Write-Host "Assigning Cognitive Services User to Search service managed identity..." -ForegroundColor Cyan
        az role assignment create `
        --assignee $searchPrincipalId `
        --role "Cognitive Services User" `
        --scope $hubId | Out-Null
        Write-Host "Cognitive Services User Roles successfully assigned !" -ForegroundColor Green
    } else {
        Write-Warning "Search service managed identity principal ID could not be retrieved."
    }

    Write-Host "Assigning Cognitive Services OpenAI User to Search Identity at Hub scope..." -ForegroundColor Cyan
    az role assignment create `
        --assignee $searchPrincipalId `
        --role "Cognitive Services OpenAI User" `
        --scope $hubId | Out-Null

    if ($projectPrincipalId) {
        Write-Host "Assigning Cognitive Services OpenAI User to Project Identity at Hub scope..." -ForegroundColor Cyan
        az role assignment create `
            --assignee $projectPrincipalId `
            --role "Cognitive Services OpenAI User" `
            --scope $hubId | Out-Null
    }

    Write-Host "`nAll dynamic role assignments have completed successfully!" -ForegroundColor Green
    Write-Host "Pausing for 3 minutes to allow Azure RBAC permissions to propagate globally..." -ForegroundColor Yellow
    Start-Sleep -Seconds 120

    # 6. Install dependencies and launch the Python agent creation script
    python -m pip install --user -r requirements.txt
    python create_agent.py

    # 7. Return to original directory
    cd ..
    cd ..

    Write-Host "=== 1. Azure Resources in $rgName ===" -ForegroundColor Cyan
    az resource list --resource-group $rgName --output table

    Write-Host "=== 2. AI Foundry & Cognitive Services in $rgName ===" -ForegroundColor Cyan
    az cognitiveservices account list --resource-group $rgName --output table


    $endtime = get-date
    $executiontime = $endtime - $starttime
    Write-Host "Execution Time - "$executiontime.TotalMinutes

}
