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
    $rgName = "rg-aca-$suffix"
    $Region = read-host "Enter the region for deployment (e.g., westus3)"

    # Define variables matching all ARM template parameters
    $storage_account_name = "storage$suffix"
    $func_mcp_reconcile_tool = "func-mcp-reconcile-$suffix"
    $userAssignedIdentities_aca_global_demo_identity_name = "id-aca-global-demo-$suffix"
    $userAssignedIdentities_id_aks_automatic_aca_openai_name = "id-aks-openai-$suffix"
    $containerapps_container_app_express_aca_name = "app-express-$suffix"
    $containerapps_caldova_contract_classifier_name = "app-classifier-$suffix"
    $managedEnvironments_caldova_global_aca_env_name = "cae-caldova-global-$suffix"
    $containerapps_invoice_agent_name = "app-invoice-agent-$suffix"
    $containerapps_agents_launchpad_aca_name = "app-agents-launchpad-$suffix"
    $acr_aca_name = "acraca$suffix" # ACR names must be lowercase alphanumeric only
    $managedClusters_aks_automatic_aca_prod_name = "aks-automatic-$suffix"
    $workbooks_aca_name = "workbook-aca-$suffix"
    $log_analytics_workspace_name = "law-aca-$suffix"
    $virtualNetworks_ACA_vnet_name = "vnet-aca-$suffix"
    $subnetName = "subnet-aca-env"
    $sandboxGroupName = "sandbox-group-$suffix"
    $apimName = "apim-$suffix"
    $appInsightsName = "appi-$suffix"
    $connectionName = 'ACA to Foundry'
    $azureMonitorWorkspace = "monitor-aca-$suffix-$Region"

    # Core Resources
    $aiServicesName = "hub-aifoundry-aca-$suffix"
    $workspaces_prj_name = "proj-aifoundry-aca-$suffix"

    # Model 1 (gpt-5.5)
    $model1Deployment = "gpt-5.5"
    $model1Name = "gpt-5.5"
    $model1Version = "2026-04-24"
    $model1Format = "OpenAI"
    $model1SkuName = "GlobalStandard"
    $model1Capacity = 100

    # Model 2 (text-embedding-3-small)
    $model2Deployment = "text-embedding-3-small"
    $model2Name = "text-embedding-3-small"
    $model2Version = "1"
    $model2Format = "OpenAI"
    $model2SkuName = "GlobalStandard"
    $model2Capacity = 110

    #### 

    Write-Host "Deploying Resources on Microsoft Azure Started ..."
    Write-Host "Creating $rgName resource group in $Region ..."
    New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
    Write-Host "Resource group $rgName creation COMPLETE"

    Write-Host "Creating APIM, Foundry Hub and Models..."

    # 1. Fetch logged-in user email and display name dynamically
    $publisherEmail = az account show --query user.name -o tsv
    $publisherName = (az ad signed-in-user show --query displayName -o tsv)

    # Fallback if display name query returns empty
    if (-not $publisherName) {
        $publisherName = $publisherEmail.Split('@')[0]
    }

    # 2. Create Azure API Management (APIM) using dynamic user info
    Write-Host "Creating API Management ($apimName) for user: $publisherEmail..."
    az apim create `
        --name $apimName `
        --resource-group $rgName `
        --location $Region `
        --publisher-email $publisherEmail `
        --publisher-name $publisherName `
        --sku-name Standard `
        --no-wait

    # 3. Create AI Services Account (Foundry Hub)
    Write-Host "Creating AI Services / Foundry Hub: $aiServicesName..."
    az cognitiveservices account create `
        --name $aiServicesName `
        --resource-group $rgName `
        --kind AIServices `
        --sku S0 `
        --location $Region `
        --allow-project-management $true `
        --custom-domain $aiServicesName

    # 4. Create AI Foundry Project
    Write-Host "Creating AI Foundry Project: $workspaces_prj_name..."
    az cognitiveservices account project create `
        --name $aiServicesName `
        --resource-group $rgName `
        --project-name $workspaces_prj_name `
        --location $Region

    # 5. Deploy Model 1
    Write-Host "Deploying Model 1 ($model1Name)..."
    az cognitiveservices account deployment create `
        --name $aiServicesName `
        --resource-group $rgName `
        --deployment-name $model1Deployment `
        --model-name $model1Name `
        --model-version $model1Version `
        --model-format $model1Format `
        --sku-name $model1SkuName `
        --sku-capacity $model1Capacity

    # 6. Deploy Model 2
    Write-Host "Deploying Model 2 ($model2Name)..."
    az cognitiveservices account deployment create `
        --name $aiServicesName `
        --resource-group $rgName `
        --deployment-name $model2Deployment `
        --model-name $model2Name `
        --model-version $model2Version `
        --model-format $model2Format `
        --sku-name $model2SkuName `
        --sku-capacity $model2Capacity

    $customRaiPolicy = '{"basePolicyName":"Microsoft.Default","mode":"Blocking","contentFilters":[{"name":"Hate","severityThreshold":"Medium","blocking":true,"enabled":true,"source":"Prompt","action":"NONE"},{"name":"Hate","severityThreshold":"Medium","blocking":true,"enabled":true,"source":"Completion","action":"NONE"}]}'

    az resource create `
        --resource-group $rgName `
        --namespace Microsoft.CognitiveServices `
        --parent "accounts/$aiServicesName" `
        --resource-type raiPolicies `
        --name "my-custom-rai-policy" `
        --properties $customRaiPolicy `
        --api-version "2026-05-15-preview"

    Write-Host "APIM and AI Foundry setup completed successfully!"

    Write-Host "Please be patient while the script runs—this is an infrastructure-heavy deployment that requires some time to complete. To keep your CloudShell session from expiring, stay on the screen and give your mouse a gentle hover or click every few minutes."

    Write-Host "Creating resources in $rgName..."

    # Build Template Parameter Hashtable for all parameters
    $templateParameters = @{
        location                                                = $Region
        storage_account_name                                    = $storage_account_name
        userAssignedIdentities_aca_global_demo_identity_name    = $userAssignedIdentities_aca_global_demo_identity_name
        userAssignedIdentities_id_aks_automatic_aca_openai_name = $userAssignedIdentities_id_aks_automatic_aca_openai_name
        containerapps_container_app_express_aca_name            = $containerapps_container_app_express_aca_name
        containerapps_caldova_contract_classifier_name          = $containerapps_caldova_contract_classifier_name
        managedEnvironments_caldova_global_aca_env_name         = $managedEnvironments_caldova_global_aca_env_name
        containerapps_invoice_agent_name                        = $containerapps_invoice_agent_name
        containerapps_agents_launchpad_aca_name                 = $containerapps_agents_launchpad_aca_name
        acr_aca_name                                            = $acr_aca_name
        workbooks_aca_name                                      = $workbooks_aca_name
        log_analytics_workspace_name                            = $log_analytics_workspace_name
    }

    New-AzResourceGroupDeployment `
        -ResourceGroupName $rgName `
        -TemplateFile "mainTemplate.json" `
        -Mode Incremental `
        -TemplateParameterObject $templateParameters `
        -Force

    $templatedeployment = Get-AzResourceGroupDeployment -Name "mainTemplate" -ResourceGroupName $rgName
    $deploymentStatus = $templatedeployment.ProvisioningState
    Write-Host "Deployment in through template $rgName : $deploymentStatus"

    Write-Host "Deploying AKS Automatic Cluster"

    # 1. Deploy AKS Cluster matching the exact ARM Template specifications
    az aks create `
        --resource-group $rgName `
        --name $managedClusters_aks_automatic_aca_prod_name `
        --location $Region `
        --kubernetes-version "1.35" `
        --tier "Standard" `
        --nodepool-name "nodepool1" `
        --node-count 3 `
        --node-vm-size "standard_d4lds_v5" `
        --node-osdisk-size 150 `
        --node-osdisk-type "Ephemeral" `
        --zones 1 2 3 `
        --os-sku "AzureLinux" `
        --network-plugin "azure" `
        --network-plugin-mode "overlay" `
        --network-dataplane "cilium" `
        --outbound-type "managedNATGateway" `
        --pod-cidr "10.244.0.0/16" `
        --service-cidr "10.0.0.0/16" `
        --dns-service-ip "10.0.0.10" `
        --enable-managed-identity `
        --enable-aad `
        --enable-azure-rbac `
        --disable-local-accounts `
        --enable-oidc-issuer `
        --enable-workload-identity `
        --enable-keda `
        --enable-vpa `
        --enable-app-routing `
        --enable-image-cleaner `
        --image-cleaner-interval-hours 168 `
        --enable-addons "azure-keyvault-secrets-provider,azure-policy" `
        --enable-secret-rotation

    Write-Host "Deployment of AKS Automatic Cluster COMPLETE"

    Write-Host "Deploying Function App on Flex Consumption Plan"

    # Create Function App on Flex Consumption Plan
    Write-Host "Creating Function App $func_mcp_reconcile_tool on Flex Consumption Plan..."
    az functionapp create `
        --name $func_mcp_reconcile_tool `
        --resource-group $rgName `
        --storage-account $storage_account_name `
        --flexconsumption-location $Region `
        --os-type Linux `
        --runtime python `
        --runtime-version 3.11 `
        --functions-version 4

    Write-Host "Deploying Function App on Flex Consumption Plan COMPLETE"

    # Fetch Workspace IDs and Keys automatically
    $WORKSPACE_RES_ID = az monitor log-analytics workspace show -g $rgName -n $log_analytics_workspace_name --query id -o tsv

    $WORKSPACE_CUST_ID = az monitor log-analytics workspace show -g $rgName -n $log_analytics_workspace_name --query customerId -o tsv

    $WORKSPACE_KEY = az monitor log-analytics workspace get-shared-keys -g $rgName -n $log_analytics_workspace_name --query primarySharedKey -o tsv

    Write-Host "Restore Log Analytics to Container Apps Environment, Container Insights on AKS, Microsoft Defender on AKS, Update AKS with Microsoft Defender using the JSON file"

    # Restore Log Analytics to Container Apps Environment
    az containerapp env update `
        --name $managedEnvironments_caldova_global_aca_env_name `
        --resource-group $rgName `
        --logs-destination log-analytics `
        --logs-workspace-id $WORKSPACE_CUST_ID `
        --logs-workspace-key $WORKSPACE_KEY

    Write-Host "Restore Log Analytics to Container Apps Environment COMPLETE"

    # Restore Container Insights on AKS
    az aks enable-addons `
        --resource-group $rgName `
        --name $managedClusters_aks_automatic_aca_prod_name `
        --addons monitoring `
        --workspace-resource-id $WORKSPACE_RES_ID

    Write-Host "Restore Container Insights on AKS COMPLETE"

    # Restore Microsoft Defender on AKS
    # 1. Create a local JSON configuration file for Defender
    $defenderConfig = @{
        logAnalyticsWorkspaceResourceId = $WORKSPACE_RES_ID
    } | ConvertTo-Json

    $defenderConfig | Out-File -Encoding utf8 defender.json

    Write-Host "Restore Microsoft Defender on AKS COMPLETE"

    # 2. Update AKS with Microsoft Defender using the JSON file
    az aks update `
        --resource-group $rgName `
        --name $managedClusters_aks_automatic_aca_prod_name `
        --enable-defender `
        --defender-config defender.json

    Write-Host "Update AKS with Microsoft Defender using the JSON file COMPLETE"

    # 3. Clean up the temporary local file
    Remove-Item defender.json -ErrorAction SilentlyContinue

    # Application Insights Integration Script
    az config set extension.dynamic_install_allow_preview=true
    az config set extension.use_dynamic_install=yes_without_prompt

    Write-Host "Create Workspace-Based Application Insights Instance"

    # 1. Create Workspace-Based Application Insights Instance
    Write-Host "Creating Application Insights: $appInsightsName..."
    az monitor app-insights component create `
        --app $appInsightsName `
        --resource-group $rgName `
        --location $Region `
        --workspace $WORKSPACE_RES_ID `
        --application-type web

    # 2. Retrieve Connection String for AI Foundry Tracing & Telemetry
    $appInsightsId = az monitor app-insights component show --app $appInsightsName --resource-group $rgName --query id -o tsv

    $appInsightsConnString = az monitor app-insights component show --app $appInsightsName --resource-group $rgName --query connectionString -o tsv

    Write-Host "Application Insights created and linked successfully!"
    Write-Host "Connection String: $appInsightsConnString"

    Add-Content log.txt "------Creating VNet and Container Apps Sandbox group------"
    Write-Host "------------Creating VNet and Container Apps Sandbox group------------"

    # VNet, Subnet, & Container Apps Sandbox Group Setup Script

    # 2. Create Virtual Network via Azure CLI
    Write-Host "Creating Virtual Network: $virtualNetworks_ACA_vnet_name..."
    az network vnet create `
        --resource-group $rgName `
        --name $virtualNetworks_ACA_vnet_name `
        --location $Region `
        --address-prefixes 10.0.0.0/16

    # 3. Create Subnet for the Sandbox Group
    Write-Host "Creating Subnet: $subnetName..."
    az network vnet subnet create `
        --resource-group $rgName `
        --vnet-name $virtualNetworks_ACA_vnet_name `
        --name $subnetName `
        --address-prefixes 10.0.0.0/23

    # 4. Retrieve Subnet Resource ID
    $subnetId = az network vnet subnet show `
        --resource-group $rgName `
        --vnet-name $virtualNetworks_ACA_vnet_name `
        --name $subnetName `
        --query id -o tsv

    az network vnet subnet update `
    --resource-group $rgName `
    --vnet-name $virtualNetworks_ACA_vnet_name `
    --name $subnetName `
    --delegations Microsoft.App/environments

    # 5. Install standalone aca CLI to User Space (CloudShell compatible, no sudo)
    Write-Host "Installing standalone aca CLI..."
    mkdir -p "$HOME/.local/bin"
    bash -c '
    TEMP_DIR=$(mktemp -d)
    curl -fsSL -o "$TEMP_DIR/aca.tar.gz" https://github.com/microsoft/azure-container-apps/releases/download/aca-cli-v1.0.0-preview.4/aca-cli-v1.0.0-preview.4-linux-x64.tar.gz
    tar -xzf "$TEMP_DIR/aca.tar.gz" -C "$TEMP_DIR"
    find "$TEMP_DIR" -type f -name "aca" -exec cp {} "$HOME/.local/bin/" \;
    chmod +x "$HOME/.local/bin/aca"
    rm -rf "$TEMP_DIR"
    '
    $env:PATH = "$HOME/.local/bin;$env:PATH"

    # 6. Create the Sandbox Group (Microsoft.App/sandboxGroups) with VNet integration
    Write-Host "Creating Sandbox Group ($sandboxGroupName) with VNet integration..."

    # Embed location inside the full object body to satisfy ARM requirements
    $resourceBody = @{
        location = $Region
        properties = @{
            networkProfile = @{
                subnets = @(
                    @{ id = $subnetId }
                )
            }
        }
    } | ConvertTo-Json -Depth 5 -Compress

    az resource create `
        --resource-group $rgName `
        --namespace "Microsoft.App" `
        --resource-type "sandboxGroups" `
        --name $sandboxGroupName `
        --properties $resourceBody `
        --is-full-object

    # 7. Configure default context for aca CLI operations
    Write-Host "Configuring aca CLI default context..."
    & "$HOME/.local/bin/aca" config set --sandbox-group $sandboxGroupName --resource-group $rgName --region $Region

    $connectionName = "aca-vnet"

    # 2. Define the REST endpoint for the vnetConnection child resource
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.App/sandboxGroups/$sandboxGroupName/vnetConnections/$connectionName`?api-version=2026-07-01"

    # 3. Construct the payload matching the portal's VNet connection form
    $payload = @{
        location   = $Region
        properties = @{
            subnetId = $subnetId
        }
    } | ConvertTo-Json -Depth 5 -Compress

    Write-Host "Creating VNet connection '$connectionName' in sandbox group '$sandboxGroupName'..." -ForegroundColor Cyan

    # 4. Execute PUT request
    az rest --method PUT --uri $uri --body $payload

    Write-Host "VNet connection created successfully!" -ForegroundColor Green

    Write-Host "Sandbox Group and VNet integration setup completed successfully!"

    Write-Host "Image Pull from Public ACR to Current ACR!"

    # Image Pull from Public ACR to Current ACR
    
    az acr import `
        --name $acr_aca_name `
        --source acrappsiqdpoc.azurecr.io/invoice-agent:20260930110800458741 `
        --image invoice-agent:module1

    # az acr import `
    #     --name $acr_aca_name `
    #     --source acrappsiqdpoc.azurecr.io/invoice-agent:mod1 `
    #     --image invoice-agent:mod1

    az acr import `
        --name $acr_aca_name `
        --source acrappsiqdpoc.azurecr.io/agent-launchpad:latest `
        --image agent-launchpad:module2

    az acr import `
        --name $acr_aca_name `
        --source acrappsiqdpoc.azurecr.io/invoice-agent:20260930110800458741 `
        --image invoice-agent:module4

    az acr import `
        --name $acr_aca_name `
        --source acrappsiqdpoc.azurecr.io/invoice-contract-classifier:v2 `
        --image invoice-contract-classifier:module3acaeclassifier

    az acr import `
    --name $acr_aca_name `
    --source acrappsiqdpoc.azurecr.io/invoice-agent:v2 `
    --image invoice-agent:module3acaexpress

    az acr import `
    --name $acr_aca_name `
    --source acrappsiqdpoc.azurecr.io/invoice-agent:sha256-68ccdf1899888f329088bbd26bea41154636e1580622a992f0916fdc84ae3e93 `
    --repository invoice-agent

    Write-Host "Image Pull from Public ACR to Current ACR COMPLETE!"

    Write-Host "Sandbox role assignment for the logged-in user starts here !"

    # 1. Fetch the Object ID of the currently logged-in user in Cloud Shell
    $userId = az ad signed-in-user show --query id -o tsv
    if (-not $userId) {$contextUser = az account show --query user.name -o tsv
        $userId = az ad user show --id$contextUser --query id -o tsv
    }

    # 2. Fetch the resource ID scope for the sandbox group
    $sandboxScope = az resource show `
        --resource-group $rgName `
        --namespace "Microsoft.App" `
        --resource-type "sandboxGroups" `
        --name $sandboxGroupName `
        --query id `
        --output tsv

    # 3. Assign the Container Apps SandboxGroup Data Owner role to your user account
    Write-Host "Assigning sandbox permissions to current user ($userId)..."
    az role assignment create `
        --assignee $userId `
        --role "Container Apps SandboxGroup Data Owner" `
        --scope $sandboxScope

    Write-Host "Sandbox role assignment completed successfully for the logged-in user!"

    # RBAC Assignment Script for Managed Identities

    # 1. Fetch Principal IDs of the Managed Identities
    Write-Host "Fetching principal IDs for managed identities..."
    $id1PrincipalId = az identity show --resource-group $rgName --name $userAssignedIdentities_aca_global_demo_identity_name --query principalId -o tsv
    $id2PrincipalId = az identity show --resource-group $rgName --name $userAssignedIdentities_id_aks_automatic_aca_openai_name --query principalId -o tsv

    # 2. Define Scope Paths
    $acrScope     = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.ContainerRegistry/registries/$acr_aca_name"
    $hubScope     = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$aiServicesName"
    $projectScope = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$aiServicesName/projects/$workspaces_prj_name"
    $sandboxScope = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.App/sandboxGroups/$sandboxGroupName"
    $rgScope      = "/subscriptions/$subscriptionId/resourceGroups/$rgName"

    # Identity 1: aca-global-demo-identity
    Write-Host "Assigning roles to aca-global-demo-identity..."

    # AcrPull over ACR
    az role assignment create --assignee $id1PrincipalId --role "AcrPull" --scope $acrScope

    # Foundry User over foundry project
    az role assignment create --assignee $id1PrincipalId --role "Foundry User" --scope $projectScope

    # Container Apps SandboxGroup Data Owner over sandbox group
    az role assignment create --assignee $id1PrincipalId --role "Container Apps SandboxGroup Data Owner" --scope $sandboxScope

    # Cognitive Services OpenAI User over foundry hub
    az role assignment create --assignee $id1PrincipalId --role "Cognitive Services OpenAI User" --scope $hubScope

    # Identity 2: id-aks-automatic-aca-openai
    Write-Host "Assigning roles to id-aks-automatic-aca-openai..."

    # Container Apps SandboxGroup Data Owner over resource group
    az role assignment create --assignee $id2PrincipalId --role "Container Apps SandboxGroup Data Owner" --scope $rgScope

    # Container Registry Repository Writer over ACR
    az role assignment create --assignee $id2PrincipalId --role "Container Registry Repository Writer" --scope $acrScope

    # AcrPull over ACR
    az role assignment create --assignee $id2PrincipalId --role "AcrPull" --scope $acrScope

    # Cognitive Services OpenAI User over foundry hub
    az role assignment create --assignee $id2PrincipalId --role "Cognitive Services OpenAI User" --scope $hubScope

    # Foundry User over foundry project
    az role assignment create --assignee $id2PrincipalId --role "Foundry User" --scope $projectScope

    Write-Host "All RBAC role assignments completed successfully!"

    Write-Host "Configuring Azure Container Apps" -ForegroundColor Cyan
    
    $acaIdentityResourceId = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$userAssignedIdentities_aca_global_demo_identity_name"

    $acaIdentityClientId = az identity show `
    --resource-group $rgName `
    --name $userAssignedIdentities_aca_global_demo_identity_name `
    --query clientId `
    -o tsv
    
    $acaIdentityPrincipalId = az identity show `
    --resource-group $rgName `
    --name $userAssignedIdentities_aca_global_demo_identity_name `
    --query principalId `
    -o tsv
    
    Write-Host "Identity Resource ID : $acaIdentityResourceId"
    Write-Host "Identity Client ID   : $acaIdentityClientId"
    Write-Host "Identity Principal ID: $acaIdentityPrincipalId"
    

    # 1. Fetch the Azure AI Foundry Hub (Service) Endpoint
    $hubEndpoint = az cognitiveservices account show `
        --name $aiServicesName `
        --resource-group $rgName `
        --query properties.endpoint `
        --output tsv

    Write-Host "Foundry Hub Endpoint: $hubEndpoint"

    # 2. Fetch the Azure AI Foundry Project Endpoint
    $projectEndpoint = az cognitiveservices account project show `
        --name $aiServicesName `
        --resource-group $rgName `
        --project-name $workspaces_prj_name `
        --query 'properties.endpoints."AI Foundry API"' `
        --output tsv

    Write-Host "Foundry Project Endpoint: $projectEndpoint"

    # 2. Get ACR login server
    
    Write-Host "Resolving ACR details..." -ForegroundColor Cyan
    
    $acrLoginServer = az acr show `
    --name $acr_aca_name `
    --resource-group $rgName `
    --query loginServer `
    -o tsv
    
    $acrScope = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.ContainerRegistry/registries/$acr_aca_name"
    
    Write-Host "ACR Name        : $acr_aca_name"
    Write-Host "ACR Login Server: $acrLoginServer"
    
    # 3. Enable ACR ARM-token authentication
    
    Write-Host "Enabling ACR ARM authentication..." -ForegroundColor Cyan
    
    az acr config authentication-as-arm update `
    --registry $acr_aca_name `
    --status enabled
    
    Write-Host "ACR ARM authentication enabled." -ForegroundColor Green

    # 5. Resolve Foundry / OpenAI configuration
    
    Write-Host "Resolving Foundry configuration..." -ForegroundColor Cyan
    
    # Foundry API key
    $AZURE_OPENAI_API_KEY = az cognitiveservices account keys list `
    --name $aiServicesName `
    --resource-group $rgName `
    --query "key1" `
    -o tsv

    if (-not $AZURE_OPENAI_API_KEY) {
    Write-Warning "Azure OpenAI API key could not be retrieved."
    }
    
    # Display non-secret values
    Write-Host "Foundry Resource       : $aiServicesName"
    Write-Host "Foundry Project        : $workspaces_prj_name"
    Write-Host "Model Deployment       : $model1Deployment"
    Write-Host "Project Endpoint       : $projectEndpoint"
    Write-Host "OpenAI Endpoint        : $hubEndpoint"
    Write-Host "OpenAI API Key         : [RETRIEVED]" -ForegroundColor Yellow

    # Build Module 1 image names

    # 1. Retrieve the full Resource ID of the User-Assigned Managed Identity
    $identityId = (az identity show --name $userAssignedIdentities_aca_global_demo_identity_name --resource-group $rgName --query id -o tsv)

    # 2. Assign the Managed Identity to the Container App
    Write-Host "Assigning managed identity to Container App $containerapps_invoice_agent_name..."
    az containerapp identity assign `
        --name $containerapps_invoice_agent_name `
        --resource-group $rgName `
        --user-assigned $identityId

    Write-Host "Managed identity assigned successfully!"

    $mod1InvoiceAgentImage = "$acrLoginServer/invoice-agent:module1"

    Write-Host "Module 1 Image   : $mod1InvoiceAgentImage"

    Write-Host "Assigning ACA Managed Identity to Module 1 resource..."
    
    # 1. Enable admin user on your target ACR to generate credentials
    az acr update --name $acr_aca_name --admin-enabled $true

    # 2. Retrieve the ACR username and password
    $acrCreds    = az acr credential show --name $acr_aca_name | ConvertFrom-Json
    $acrUsername = $acrCreds.username
    $acrPassword = $acrCreds.passwords[0].value
    $acrServer   = "$acr_aca_name.azurecr.io"

    # 3. Update the Container App registry authentication to Secrets/Credentials
    Write-Host "Switching Container App registry authentication to Secrets for $containerapps_invoice_agent_name..."
    az containerapp registry set `
        --name $containerapps_invoice_agent_name `
        --resource-group $rgName `
        --server $acrServer `
        --username $acrUsername `
        --password $acrPassword

    Write-Host "Container registry authentication updated successfully!"

    $clientId = az containerapp show `
        --name $containerapps_invoice_agent_name `
        --resource-group $rgName `
        --query "identity.userAssignedIdentities.*.clientId | [0]" `
        --output tsv

    Write-Host "Client ID: $clientId"

    Write-Host "Updating ACR Image and Environment Variables..."
    
    az containerapp update `
    --name $containerapps_invoice_agent_name `
    --resource-group $rgName `
    --image $mod1InvoiceAgentImage `
    --min-replicas 0 `
    --max-replicas 2 `
    --workload-profile-name "Consumption" `
    --set-env-vars `
        "FOUNDRY_PROJECT_ENDPOINT=$projectEndpoint" `
        "AZURE_AI_MODEL_DEPLOYMENT_NAME=$model1Deployment" `
        "AZURE_SUBSCRIPTION_ID=$subscriptionId" `
        "AZURE_REGION=$Region" `
        "AZURE_RESOURCE_GROUP=$rgName" `
        "AZURE_SANDBOX_GROUP=$sandboxGroupName" `
        "AZURE_CLIENT_ID=$clientId"

    Write-Host "Module 1 ACA updated successfully." -ForegroundColor Green

    # Build Module 2 image names

    $mod2LaunchpadImage = "$acrLoginServer/agent-launchpad:module2"

    # Fetch the FQDN ingress URL of the Container App
    $appFqdn = az containerapp show `
        --name $containerapps_invoice_agent_name `
        --resource-group $rgName `
        --query properties.configuration.ingress.fqdn `
        --output tsv

    $appUrl = "https://$appFqdn"
    Write-Host "Application URL: $appUrl"

    Write-Host "Module 2 Image: $mod2LaunchpadImage"

    # 1. Enable admin user on your target ACR to generate credentials
    az acr update --name $acr_aca_name --admin-enabled $true

    # 2. Retrieve the ACR username and password
    $acrCreds    = az acr credential show --name $acr_aca_name | ConvertFrom-Json
    $acrUsername = $acrCreds.username
    $acrPassword = $acrCreds.passwords[0].value
    $acrServer   = "$acr_aca_name.azurecr.io"

    # 3. Update the Container App registry authentication to Secrets/Credentials
    Write-Host "Switching Container App registry authentication to Secrets for $containerapps_invoice_agent_name..."
    az containerapp registry set `
        --name $containerapps_agents_launchpad_aca_name `
        --resource-group $rgName `
        --server $acrServer `
        --username $acrUsername `
        --password $acrPassword

    Write-Host "Container registry authentication updated successfully!"

    # Update ACR Image and Environment Variables

    Write-Host "Updating ACR Image and Environment Variables..."
    
    az containerapp update `
    --name $containerapps_agents_launchpad_aca_name `
    --resource-group $rgName `
    --image $mod2LaunchpadImage `
    --min-replicas 0 `
    --max-replicas 2 `
    --workload-profile-name "Consumption" `
    --set-env-vars `
        "FOUNDRY_ENVIRONMENT_URL=$projectEndpoint" `
        "FOUNDRY_API_KEY=$AZURE_OPENAI_API_KEY" `
        "FOUNDRY_TENANT_ID=$tenantId" `
        "CONNECTION_NAME=$connectionName" `
        "INVOICE_AGENT_URL=$appUrl"
        
    Write-Host "Module 2 ACA updated successfully." -ForegroundColor Green


    # 6. Build the Module 3 image names

    $ExpressImage = "$acrLoginServer/invoice-agent:module3acaexpress"
    
    $ClassifierImage = "$acrLoginServer/invoice-contract-classifier:module3acaeclassifier"
    
    Write-Host "Express Image   : $ExpressImage"
    Write-Host "Classifier Image: $ClassifierImage"
    
    Write-Host "Assigning ACA Managed Identity to classifier..."
    
    az containerapp identity assign `
    --name $containerapps_caldova_contract_classifier_name `
    --resource-group $rgName `
    --user-assigned $acaIdentityResourceId
    
    Write-Host "Configuring ACR registry identity for classifier..."

    az containerapp registry set `
    --name $containerapps_caldova_contract_classifier_name `
    --resource-group $rgName `
    --server $acrLoginServer `
    --identity $acaIdentityResourceId
    
    
    # Update ACR Image and Environment Variables

    # 1. Enable admin credentials on the Azure Container Registry
    Write-Host "Enabling admin user on ACR $acr_aca_name..."
    az acr update --name $acr_aca_name --resource-group $rgName --admin-enabled true

    # 2. Retrieve ACR credentials
    $acrUsername = (az acr credential show --name $acr_aca_name --resource-group $rgName --query "username" -o tsv)
    $acrPassword = (az acr credential show --name $acr_aca_name --resource-group $rgName --query "passwords[0].value" -o tsv)

    # 3. Configure the Container App with registry pull credentials
    Write-Host "Configuring registry credentials for Container App..."
    az containerapp registry set `
        --name $containerapps_caldova_contract_classifier_name `
        --resource-group $rgName `
        --server "$acr_aca_name.azurecr.io" `
        --username $acrUsername `
        --password $acrPassword

    # 4. Re-run your Container App update
    Write-Host "Updating Container App..."
    az containerapp update `
        --name $containerapps_caldova_contract_classifier_name `
        --resource-group $rgName `
        --image $ClassifierImage `
        --min-replicas 0 `
        --max-replicas 2 `
        --workload-profile-name "gpu-t4" `
        --set-env-vars `
            "FOUNDRY_RESOURCE_NAME=$aiServicesName" `
            "MODEL_DEPLOYMENT_NAME=$model1Deployment" `
            "AZURE_CLIENT_ID=$acaIdentityClientId"
    
    Write-Host "Classifier ACA updated successfully." -ForegroundColor Green
    
    # 8. Configure existing EXPRESS ACA
    
    $ExpressApp = $containerapps_container_app_express_aca_name
    
    Write-Host "Assigning ACA Managed Identity to Express..."
    
    az containerapp identity assign `
    --name $ExpressApp `
    --resource-group $rgName `
    --user-assigned $acaIdentityResourceId
    
    Write-Host "Configuring ACR registry identity for Express..."
    
    az containerapp registry set `
    --name $ExpressApp `
    --resource-group $rgName `
    --server $acrLoginServer `
    --identity $acaIdentityResourceId
    
    # Classifier endpoint
    #
    # IMPORTANT:
    # The classifier FastAPI application exposes POST /infer.
    # Therefore /infer MUST be part of this URL.
    
    $CALDOVA_CLASSIFIER_URL = "https://$containerapps_caldova_contract_classifier_name.$(
    az containerapp show `
        --name $containerapps_caldova_contract_classifier_name `
        --resource-group $rgName `
        --query "properties.configuration.ingress.fqdn" `
        -o tsv
    )"
    
    # The previous command already returns the FQDN, so construct
    # the final endpoint explicitly.
    $ClassifierFqdn = az containerapp show `
    --name $containerapps_caldova_contract_classifier_name `
    --resource-group $rgName `
    --query "properties.configuration.ingress.fqdn" `
    -o tsv
    
    $CALDOVA_CLASSIFIER_URL = "https://$ClassifierFqdn/infer"
    
    Write-Host "Classifier URL: $CALDOVA_CLASSIFIER_URL"
    
    # Update Express image + ALL required environment variables
    
    Write-Host "Updating Express image and environment variables..."
    
    az containerapp update `
    --name $ExpressApp `
    --resource-group $rgName `
    --image $ExpressImage `
    --min-replicas 0 `
    --max-replicas 3 `
    --set-env-vars `
        "AZURE_REGION=$Region" `
        "AZURE_SUBSCRIPTION_ID=$subscriptionId" `
        "AZURE_RESOURCE_GROUP=$rgName" `
        "AZURE_SANDBOX_GROUP=$sandboxGroupName" `
        "AZURE_AI_MODEL_DEPLOYMENT_NAME=$model1Deployment" `
        "AZURE_AI_PROJECT_ENDPOINT=$projectEndpoint" `
        "AZURE_OPENAI_ENDPOINT=$hubEndpoint" `
        "AZURE_OPENAI_API_KEY=$AZURE_OPENAI_API_KEY" `
        "FOUNDRY_PROJECT_ENDPOINT=$projectEndpoint" `
        "CALDOVA_CLASSIFIER_URL=$CALDOVA_CLASSIFIER_URL" `
        "FOUNDRY_RBAC_FIXED=1" `
        "AZURE_CLIENT_ID=$acaIdentityClientId"
        
    Write-Host "Express ACA updated successfully." -ForegroundColor Green

    #Module 4
    # Navigate to the target directory and push the current path onto the stack
    pushd ./artifacts/aks/

    $signedinusername = az ad signed-in-user show | ConvertFrom-Json
    $signedinusername = $signedinusername.userPrincipalName

    $Tag = "module4"

    Write-Host "=== Step 1: Attaching ACR to AKS ==="

    ## Attach ACR to AKS

    $attachedAcr = az aks update -n $managedClusters_aks_automatic_aca_prod_name -g $rgName  --attach-acr $acr_aca_name

    $attachedAcr
    Write-Host "ACR attachment completed."

    Write-Host "=== Step 2: Preparing AKS identity and service account ==="
    $AKSClientId = az identity show --name $userAssignedIdentities_id_aks_automatic_aca_openai_name --resource-group $rgName --query clientId -o tsv

    $AKSClientId

    (Get-Content ".\invoice-agent-sa.yaml") -replace '#clientID#', $AKSClientId | Set-Content ".\invoice-agent-sa.yaml"
    Write-Host "Updated invoice-agent service account manifest with the AKS client ID."

    # Connect to AKS

    az aks get-credentials --resource-group $rgName --name $managedClusters_aks_automatic_aca_prod_name --overwrite-existing
    Write-Host "Connected to the AKS cluster."

    ## Create namespace for agent platform
    # Get your Azure object ID
    $userId = (az ad signed-in-user show --query id -o tsv)

    # Get the resource ID of your AKS cluster
    $aksId = (az aks show --name $managedClusters_aks_automatic_aca_prod_name --resource-group $rgName --query id -o tsv)

    # Assign the RBAC Cluster Admin role
    az role assignment create `
        --role "Azure Kubernetes Service RBAC Cluster Admin" `
        --assignee $userId `
        --scope $aksId

    kubectl create namespace agent-platform
    Write-Host "Namespace agent-platform is ready."

    ## Apply service account yml
    kubectl apply -f invoice-agent-sa.yaml
    Write-Host "Applied service account configuration."

    ## Get OIDC

    $OIDCIssuerUrl = az aks show -g $rgName -n $managedClusters_aks_automatic_aca_prod_name --query oidcIssuerProfile.issuerUrl -o tsv

    $OIDCIssuerUrl

    ## Create federated credentials

    az identity federated-credential create --identity-name $userAssignedIdentities_id_aks_automatic_aca_openai_name --resource-group $rgName --name invoice-agent-federation --issuer $OIDCIssuerUrl --subject system:serviceaccount:agent-platform:invoice-agent --audience api://AzureADTokenExchange
    Write-Host "Federated credential created for the invoice agent."

    ## variables for invoice agent deployment

    $FOUNDRY_PROJECT_ENDPOINT = "https://hub-aifoundry-aca-$suffix.services.ai.azure.com/api/projects/proj-aifoundry-aca-$suffix"

    Write-Host "=== Step 3: Deploying invoice agent ==="

    ## Inoice agent deployment

    (Get-Content .\invoice-agent.yaml -Raw) -Replace('#FOUNDRY_PROJECT_ENDPOINT#', $FOUNDRY_PROJECT_ENDPOINT) -Replace('#SUBSCRIPTION_ID#', $subscriptionId) -Replace('#RESOURCE_GROUP#', $rgName) -Replace('#REGION#', $Region) -Replace('#Tag#', $Tag) -Replace('#ACR_ACA_NAME#', $acr_aca_name) -Replace('#SANDBOX_GROUP#', $sandboxGroupName) | Set-Content .\invoice-agent.yaml
    Write-Host "Updated the invoice agent manifest with environment values."

    ## Apply invoice agent deployment
    kubectl apply -f invoice-agent.yaml
    Write-Host "Invoice agent deployment applied."

    ## Apply scaler deployment
    kubectl apply -f scaler.yaml
    Write-Host "Scaler deployment applied."

    ## Apply svc
    kubectl apply -f service.yaml
    Write-Host "Service deployed."

    Write-Host "=== Step 4: Configuring TLS / cert-manager ==="
    ## testing cert manager to enable https for the invoice agent
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

    kubectl create namespace cert-manager

    helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set crds.enabled=true
    Write-Host "cert-manager installed and configured."

    ## replace the email address with your email address to get the cert

    (Get-Content ".\clusterissuer.yaml") -replace 'test@caldova.com', $signedinusername | Set-Content ".\clusterissuer.yaml"
    Write-Host "Updated cluster issuer email using the signed-in user account."

    kubectl apply -f clusterissuer.yaml
    Write-Host "ClusterIssuer applied for certificate issuance."

    Write-Host "=== Step 5: Detecting public endpoint ==="
    # Try to fetch the external IP from a LoadBalancer service (common for ingress controllers)
    $publicIp = kubectl get svc -A -o json | ConvertFrom-Json | Select-Object -ExpandProperty items | Where-Object { $_.status.loadBalancer.ingress } | ForEach-Object { $_.status.loadBalancer.ingress[0].ip } | Where-Object { $_ }
    if (-not $publicIp) {
    # fallback: try hostname field
    $publicIp = kubectl get svc -A -o json | ConvertFrom-Json | Select-Object -ExpandProperty items | Where-Object { $_.status.loadBalancer.ingress } | ForEach-Object { $_.status.loadBalancer.ingress[0].hostname } | Where-Object { $_ }
    }
    if ($publicIp) {
    Write-Output "External IP/Hostname found: $publicIp"
    Write-Host "Public endpoint detected successfully."
    } else {
    Write-Output "No external IP found via kubectl. Listing public IP resources in the resource group:"
    az network public-ip list -g $rgName --query "[].{name:name,dns:dnsSettings.fqdn,ip:ipAddress}" -o table
    Write-Host "No public IP was detected from kubectl; listed the resource group's public IPs instead."
    }

    #az network public-ip show -g $rgName -n $publicIpName --query dnsSettings.fqdn -o tsv

    $nodeRg = az aks show -g $rgName -n $managedClusters_aks_automatic_aca_prod_name --query nodeResourceGroup -o tsv

    #az network public-ip list -g $nodeRg -o table

    ##ingress Ip
    $IngressIP = kubectl get svc nginx -n app-routing-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

    $IngressIP

    ## Public IP Name
    $PublicIpName = az network public-ip list -g $nodeRg --query "[?ipAddress=='$IngressIP'].name | [0]" -o tsv

    $PublicIpName 

    Write-Host "=== Step 6: Finalizing DNS and ingress ==="
    ## Assign DNS name to the public IP
    $DnsLabel = "invoice-agent-$suffix"

    az network public-ip update -g $nodeRg -n $PublicIpName --dns-name $DnsLabel
    Write-Host "Public IP DNS label updated to $DnsLabel."

    $HostName = az network public-ip show -g $nodeRg -n $PublicIpName --query dnsSettings.fqdn -o tsv

    $HostName

    ## Update ingress.yaml with the hostname
    (Get-Content .\ingress.yaml -Raw) -Replace('#HOSTNAME#', $HostName) | Set-Content .\ingress.yaml
    Write-Host "Ingress manifest updated with the hostname: $HostName"

    ##apply ingress.yaml
    kubectl apply -f ingress.yaml
    Write-Host "Ingress configuration applied successfully."
    Write-Host "Module 4 setup completed."

    (Get-Content -Path connecttoaks.ps1 -Raw) | ForEach-Object {
        $_ `
            -replace '##SUBSCRIPTION_ID##', $subscriptionId `
            -replace '##RESOURCE_GROUP##', $rgName `
            -replace '##AKS_AUTOMATIC##', $managedClusters_aks_automatic_aca_prod_name
    } | Set-Content -Path connecttoaks.ps1

    # 1. Retrieve storage account key and build connection string
    $storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storage_account_name)[0].Value
    $webjobs = "DefaultEndpointsProtocol=https;AccountName=" + $storage_account_name + ";AccountKey=" + $storage_account_key + ";EndpointSuffix=core.windows.net"

    # 2. Create the storage context
    $ctx = New-AzStorageContext -ConnectionString $webjobs

    # 3. Define container name and ensure it exists
    $containerName = "generated-yaml"
    New-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction SilentlyContinue | Out-Null
    Write-Host "Container '$containerName' is ready." -ForegroundColor Green

    # 4. Upload all YAML files from the current directory
    Get-ChildItem -Path $targetFolder -File | ForEach-Object {
        Write-Host "Uploading $_.Name..." -ForegroundColor Cyan
        Set-AzStorageBlobContent -File $_.FullName -Container $containerName -Context $ctx -Force | Out-Null
    }

    Write-Host "All files have been successfully uploaded to container '$containerName'!" -ForegroundColor Green
    
    # Return to your original directory
    popd

    Write-Host "Configuring Azure Container Apps COMPLETE" -ForegroundColor Cyan

    Write-Host "Creating Prometheus with Azure Monitor" -ForegroundColor Cyan

    az monitor account create --resource-group $rgName --name $azureMonitorWorkspace --location $Region

    Write-Host "Creating Prometheus Node Recording Rules Rule Group via ARM Template..." -ForegroundColor Cyan

    # 1. Dynamically fetch the Azure Monitor Workspace ID and AKS cluster resource ID
    $workspaceId = (az monitor account list --resource-group $rgName --query "[0].id" -o tsv)
    $clusterId = (az aks show --name $managedClusters_aks_automatic_aca_prod_name --resource-group $rgName --query "id" -o tsv)
    $ruleGroupName = "NodeRecordingRuleGroup-$managedClusters_aks_automatic_aca_prod_name-$suffix"

    # 2. Define the complete ARM Template JSON matching your requested structure
    $templatePath = "prometheus_rule_group.json"
    $templateJson = @{
        '$schema'      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
        contentVersion = "1.0.0.0"
        parameters     = @{
            prometheusRuleGroups_name = @{
                defaultValue = $ruleGroupName
                type         = "String"
            }
            monitorWorkspaceId = @{
                defaultValue = $workspaceId
                type         = "String"
            }
            clusterId = @{
                defaultValue = $clusterId
                type         = "String"
            }
        }
        variables      = @{}
        resources      = @(
            @{
                type       = "Microsoft.AlertsManagement/prometheusRuleGroups"
                apiVersion = "2023-03-01"
                name       = "[parameters('prometheusRuleGroups_name')]"
                location   = $Region
                tags       = @{
                    "used for " = "module 4 managed resources"
                }
                properties = @{
                    enabled     = $true
                    clusterName = $managedClusters_aks_automatic_aca_prod_name
                    scopes      = @(
                        "[parameters('monitorWorkspaceId')]",
                        "[parameters('clusterId')]"
                    )
                    rules       = @(
                        @{
                            record     = "instance:node_num_cpu:sum"
                            expression = 'count without (cpu, mode) (  node_cpu_seconds_total{job="node",mode="idle"})'
                        },
                        @{
                            record     = "instance:node_cpu_utilisation:rate5m"
                            expression = '1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job="node", mode=~"idle|iowait|steal"}[5m])))'
                        },
                        @{
                            record     = "instance:node_load1_per_cpu:ratio"
                            expression = '(  node_load1{job="node"}/  instance:node_num_cpu:sum{job="node"})'
                        },
                        @{
                            record     = "instance:node_memory_utilisation:ratio"
                            expression = '1 - (  (    node_memory_MemAvailable_bytes{job="node"}    or    (      node_memory_Buffers_bytes{job="node"}      +      node_memory_Cached_bytes{job="node"}      +      node_memory_MemFree_bytes{job="node"}      +      node_memory_Slab_bytes{job="node"}    )  )/  node_memory_MemTotal_bytes{job="node"})'
                        },
                        @{
                            record     = "instance:node_vmstat_pgmajfault:rate5m"
                            expression = 'rate(node_vmstat_pgmajfault{job="node"}[5m])'
                        },
                        @{
                            record     = "instance_device:node_disk_io_time_seconds:rate5m"
                            expression = 'rate(node_disk_io_time_seconds_total{job="node", device!=""}[5m])'
                        },
                        @{
                            record     = "instance_device:node_disk_io_time_weighted_seconds:rate5m"
                            expression = 'rate(node_disk_io_time_weighted_seconds_total{job="node", device!=""}[5m])'
                        },
                        @{
                            record     = "instance:node_network_receive_bytes_excluding_lo:rate5m"
                            expression = 'sum without (device) (  rate(node_network_receive_bytes_total{job="node", device!="lo"}[5m]))'
                        },
                        @{
                            record     = "instance:node_network_transmit_bytes_excluding_lo:rate5m"
                            expression = 'sum without (device) (  rate(node_network_transmit_bytes_total{job="node", device!="lo"}[5m]))'
                        },
                        @{
                            record     = "instance:node_network_receive_drop_excluding_lo:rate5m"
                            expression = 'sum without (device) (  rate(node_network_receive_drop_total{job="node", device!="lo"}[5m]))'
                        },
                        @{
                            record     = "instance:node_network_transmit_drop_excluding_lo:rate5m"
                            expression = 'sum without (device) (  rate(node_network_transmit_drop_total{job="node", device!="lo"}[5m]))'
                        }
                    )
                    interval    = "PT1M"
                }
            }
        )
    } | ConvertTo-Json -Depth 10

    Set-Content -Path $templatePath -Value $templateJson

    # 3. Deploy the ARM template to your resource group
    az deployment group create `
        --resource-group $rgName `
        --template-file $templatePath

    Write-Host "Prometheus Rule Group deployed successfully via ARM template!" -ForegroundColor Green

    Write-Host "Prometheus and Monitor created Successfully"

    # Function App MCP RECONCILE TOOL

    Write-Host "Function App Configuration and Deployment Begins"

    # Enable system-assigned managed identity for the Function App
    Write-Host "Enabling system-assigned managed identity for Function App $func_mcp_reconcile_tool..."
    az functionapp identity assign `
        --name $func_mcp_reconcile_tool `
        --resource-group $rgName

    Write-Host "System-assigned managed identity enabled successfully!"
    
    $storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storage_account_name)[0].Value
    $webjobs = "DefaultEndpointsProtocol=https;AccountName=" + $storage_account_name + ";AccountKey=" + $storage_account_key + ";EndpointSuffix=core.windows.net"

    $SANDBOX_STATE_BLOB_ACCOUNT_URL = "https://$storage_account_name.blob.core.windows.net"

    Write-Host "1. Configuring all App Settings..." -ForegroundColor Cyan
    $config = az functionapp config appsettings set `
        --resource-group $rgName `
        --name $func_mcp_reconcile_tool `
        --settings `
            "FUNCTIONS_EXTENSION_VERSION=~4" `
            "AzureWebJobsStorage=$webjobs" `
            "AZURE_REGION=$Region" `
            "AZURE_SUBSCRIPTION_ID=$subscriptionId" `
            "AZURE_RESOURCE_GROUP=$rgName" `
            "AZURE_SANDBOX_GROUP=$sandboxGroupName" `
            "SANDBOX_STATE_BLOB_ACCOUNT_URL=$SANDBOX_STATE_BLOB_ACCOUNT_URL" `
            "FORCE_TOKEN_REFRESH=$(Get-Random)"

    Write-Host "Function App configuration applied successfully!" -ForegroundColor Green

    # 1. Assign Owner role to yourself over the sandbox group
    $userId = (az ad signed-in-user show --query id -o tsv)
    $sandboxScope = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.App/sandboxGroups/$sandboxGroupName"

    Write-Host "Assigning Owner role to current user over sandbox group..."
    az role assignment create `
        --assignee $userId `
        --role "Owner" `
        --scope $sandboxScope

    # 2. Ensure aca CLI is present and available in PATH
    mkdir -p ~/.local/bin
    if (-not (Test-Path "$HOME/.local/bin/aca")) {
        curl -L https://github.com/microsoft/azure-container-apps/releases/download/aca-cli-v1.0.0-preview.4/aca-cli-v1.0.0-preview.4-linux-x64.tar.gz -o aca.tar.gz
        tar -xzf aca.tar.gz -C ~/.local/bin/
        chmod +x ~/.local/bin/aca
    }
    $env:PATH += ":$HOME/.local/bin"

    # 3. Wait for RBAC propagation and assign system-assigned identity
    Write-Host "Waiting 30 seconds for RBAC permissions to propagate..."
    Start-Sleep -Seconds 30

    $maxAcaRetries = 5
    $acaDelay = 15
    for ($i = 1; $i -le $maxAcaRetries; $i++) {
        try {
            Write-Host "Assigning system-assigned identity to sandbox group (Attempt $i of $maxAcaRetries)..."
            aca sandboxgroup identity assign --group $sandboxGroupName --resource-group $rgName --subscription $subscriptionId --system-assigned
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Sandbox group identity assigned successfully." -ForegroundColor Green
                break
            } else {
                throw "aca command exited with code $LASTEXITCODE"
            }
        }
        catch {
            if ($i -eq $maxAcaRetries) {
                throw "All sandbox group identity assignment attempts failed."
            }
            Write-Host "Waiting $acaDelay seconds for permissions to sync..."
            Start-Sleep -Seconds $acaDelay
        }
    }


    # Compress-Archive -Path "./artifacts/functionApp/*" -DestinationPath "./functionApp.zip" -Force

    # az webapp deploy --resource-group rg-fsi-iq-vqek17b --name $func_mcp_reconcile_tool --src-path ./functionApp.zip --type zip
    
        # Get the Resource Group scope ID
    $scope = (az group show --name $rgName --query id -o tsv)

    
    # 1. Function App System-Assigned Identity Assignments
    
    Write-Host "Retrieving Function App system-assigned identity Principal ID..."
    $funcPrincipalId = (az functionapp identity show `
        --name $func_mcp_reconcile_tool `
        --resource-group $rgName `
        --query principalId `
        --output tsv)

    Write-Host "Assigning roles to Function App identity..."
    az role assignment create `
        --assignee $funcPrincipalId `
        --role "Container Apps SandboxGroup Data Owner" `
        --scope $scope

    az role assignment create `
        --assignee $funcPrincipalId `
        --role "Storage Blob Data Contributor" `
        --scope $scope

    # 2. Local Developer (Signed-in User) Assignments
    
    Write-Host "Retrieving signed-in user object ID..."
    $userId = (az ad signed-in-user show --query id -o tsv)

    Write-Host "Assigning roles to local developer..."
    az role assignment create `
        --assignee $userId `
        --role "Container Apps SandboxGroup Data Owner" `
        --scope $scope

    az role assignment create `
        --assignee $userId `
        --role "Storage Blob Data Contributor" `
        --scope $scope

    Write-Host "All RBAC permissions assigned successfully!" -ForegroundColor Green

    $maxRetries = 3
    $retryDelaySeconds = 15
    $success =$false

    Push-Location ./artifacts/functionApp
    try {
        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            try {
                Write-Host "Publishing Python function app '$func_mcp_reconcile_tool' (Attempt $attempt of $maxRetries)..."
                
                # ADDED --build remote to ensure Azure builds the dependencies using 3.11, bypassing local 3.12 mismatches
                func azure functionapp publish $func_mcp_reconcile_tool --publish-local-settings --python --build remote
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Function app published successfully." -ForegroundColor Green
                    $success =$true
                    break
                } else {
                    throw "Azure Functions CLI exited with non-zero code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Warning "Publish attempt $attempt failed:$_"
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
    
    ### Fetching Values to be replace in the Foundry Automation ###
    Add-Content log.txt "------Foundry Automation------"
    Write-Host "------------Foundry Automation------------"

    # 1. Get the signed-in user object ID
    $userId = (az ad signed-in-user show --query id -o tsv)

    # 2. Get the Resource Group scope ID
    $rgScope = (az group show --name $rgName --query id -o tsv)

    # 3. Construct Hub and Project specific scope IDs
    $hubScope = "$rgScope/providers/Microsoft.CognitiveServices/accounts/$aiServicesName"
    $projectScope = "$rgScope/providers/Microsoft.CognitiveServices/accounts/$aiServicesName/projects/$workspaces_prj_name"

    # Define the role names
    $foundryRole = "Azure AI Developer"
    $logAnalyticsRole = "Log Analytics Reader"

    Write-Host "Assigning Foundry User over AI Hub to $userId..."
    az role assignment create `
        --assignee $userId `
        --role "Foundry User" `
        --scope $hubScope

    Write-Host "Assigning Foundry User over AI Project to$userId..."
    az role assignment create `
        --assignee $userId `
        --role "Foundry User" `
        --scope $projectScope

    # 6. Assign Log Analytics Reader over the Resource Group
    Write-Host "Assigning $logAnalyticsRole over Resource Group to $userId..."
    az role assignment create `
        --assignee $userId `
        --role $logAnalyticsRole `
        --scope $rgScope

    Write-Host "Assigning $foundryRole over AI Hub to $userId..."
    az role assignment create `
        --assignee $userId `
        --role "Azure AI Developer" `
        --scope $hubScope

    Write-Host "Assigning 'Azure AI Developer' to user..."
    az role assignment create `
        --assignee $userId `
        --role "Azure AI Developer" `
        --scope $projectScope

    Write-Host "Assigning 'Cognitive Services Contributor' to user..."
    az role assignment create `
        --assignee $userId `
        --role "Cognitive Services Contributor" `
        --scope $projectScope

    Write-Host "Assigning 'Cognitive Services OpenAI Contributor' to user..."
    az role assignment create `
        --assignee $userId `
        --role "Cognitive Services OpenAI Contributor" `
        --scope $projectScope

    Write-Host "All role assignments applied successfully!" -ForegroundColor Green
    
    Set-Location ./artifacts/foundry

    $filepath = ".env"
    $envTemplate = Get-Content -Path $filepath -Raw

    $envContent = $envTemplate.Replace("##AZURE_SUBSCRIPTION_ID##", $subscriptionId).Replace("##AZURE_RESOURCE_GROUP##", $rgName).Replace("##AZURE_AI_SERVICES_NAME##", $aiServicesName).Replace("##AZURE_AI_PROJECT_NAME##", $workspaces_prj_name).Replace("##AZURE_CHAT_DEPLOYMENT##", $model1Deployment).Replace("##FUNCTION_APP_NAME##", $func_mcp_reconcile_tool).Replace("##APIM_NAME##", $apimName).Replace("##APPINSIGHTS_NAME##", $appInsightsName)

    Set-Content -Path $filepath -Value $envContent

    # 1. Create and activate a virtual environment
    python -m venv .venv
    . .venv/bin/Activate.ps1

    # 2. Install requirements cleanly inside the venv
    python -m pip install --upgrade pip
    python -m pip install -r requirements.txt

    # 3. Run your deployment script
    python deploy_foundry_agent.py

    # 1. Deactivate the virtual environment if it is currently active
    deactivate

    # 2. Delete the .venv folder and its contents
    Remove-Item -Recurse -Force .venv

    cd..
    cd..

    Add-Content log.txt "------Foundry Automation COMPLETE------"
    Write-Host "------------Foundry Automation COMPLETE------------"

        
    Write-Host "Configuring Azure Workbook"

    # Automatically search and retrieve the workbook name and ID in your resource group
    Write-Host "Searching for workbooks in resource group $rgName..."
    $workbooksJson = az resource list --resource-group $rgName --resource-type "Microsoft.Insights/workbooks" --output json
    $workbooks = $workbooksJson | ConvertFrom-Json

    if (-not $workbooks -or $workbooks.Count -eq 0) {
        Write-Error "No workbooks found in resource group $rgName."
    } else {
        # Select the first workbook found
        $WORKBOOK_NAME = $workbooks[0].name
        $WORKBOOK_ID = $workbooks[0].id

        Write-Host "Successfully found Workbook!" -ForegroundColor Green
        Write-Host "Workbook Name: $WORKBOOK_NAME"
        Write-Host "Workbook ID:   $WORKBOOK_ID"
    }

    # 1. Read the exported JSON file
    $jsonPath = "./artifacts/workbook/old-workbook-full.json"
    $workbookObj = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

    $workbookObj.id            = $WORKBOOK_ID
    $workbookObj.location      = $Region
    $workbookObj.name          = $WORKBOOK_NAME

    # 2. Remove the old etag property to avoid concurrency conflicts
    if ($workbookObj.PSObject.Properties['etag']) {
        $workbookObj.PSObject.Properties.Remove('etag')
    }

    # 3. Clear the revision property so Azure generates a fresh one
    if ($workbookObj.properties.PSObject.Properties['revision']) {
        $workbookObj.properties.revision = $null
    }

    # 4. Save the cleaned payload
    $workbookObj | ConvertTo-Json -Depth 20 | Out-File -Encoding utf8 "new-workbook-payload.json"

    # 5. Redeploy via PUT
    Write-Host "Deploying clean workbook payload to $WORKBOOK_NAME..."
    # 1. Delete the workbook to clear the resource store conflict
    az rest --method DELETE --url "https://management.azure.com${WORKBOOK_ID}?api-version=2023-06-01"

    # 2. Recreate the workbook fresh with your payload
    az rest --method PUT --url "https://management.azure.com${WORKBOOK_ID}?api-version=2023-06-01" --body "@new-workbook-payload.json"

    Write-Host "Workbook deployed successfully!" -ForegroundColor Green

    Write-Host "=== 1. Azure Resources in $rgName ===" -ForegroundColor Cyan
    az resource list --resource-group $rgName --output table

    $endtime = get-date
    $executiontime = $endtime - $starttime
    
    Write-Host "Execution COMPLETE" -ForegroundColor Green
    
    Write-Host "Execution Time - "$executiontime.TotalMinutes

}
