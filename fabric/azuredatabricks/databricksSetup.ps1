function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

az login

#for powershell...
Connect-AzAccount -DeviceCode

$starttime=get-date

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
if($subs.GetType().IsArray -and $subs.length -gt 1)
{
$subOptions = [System.Collections.ArrayList]::new()
    for($subIdx=0; $subIdx -lt $subs.length; $subIdx++)
    {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    $title    = 'Subscription selection'
    $question = 'Are you sure you want to select this subscription for this lab?'
    $choices  = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if($decision -eq 0)
    {
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
    }
    else
    {
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
    }
}

$rgName = read-host "Enter the resource group name for deployment"
$Region = Get-AzResourceGroup -Name $rgName
$Region = $Region.Location
$suffix = az group show --name $rgName --query 'tags.suffix' --output tsv
$databricks_name="databricks$suffix"
$databricks_rgname="databricks-rg$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id

$wsIdContosoSales = az group show --name $rgName --query 'tags.wsIdContosoSales' --output tsv

$lakehouseBronze =  "lakehouseBronze_$suffix"
$lakehouseSilver =  "lakehouseSilver_$suffix"
$lakehouseGold =  "lakehouseGold_$suffix"

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoSales";
$contosoSalesWsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
$contosoSalesWsName = $contosoSalesWsName.name
# $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsIdContosoFinance"
# $contosoFinanceWsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
# $contosoFinanceWsName = $contosoFinanceWsName.name

Write-Host "Creating databricks resources in $rgName..."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-TemplateFile "databricksTemplate.json" `
-Mode Incremental `
-location $Region `
-databricks_workspace_name $databricks_name `
-databricks_managed_resource_group_name $databricks_rgname `
-Force

Write-Host "Databricks resource creation in $rgName COMPLETE"

# databricks
Add-Content log.txt "------databricks------"
Write-Host "--------- Databricks---------"
$dbswsId = az resource show --resource-type "Microsoft.Databricks/workspaces" -g $rgName -n $databricks_name --query id -o tsv

$token_response = $(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json) | ConvertFrom-Json
$token = $token_response.accessToken

# Get a token for the Azure management API
$token_response = $(az account get-access-token --resource https://management.core.windows.net/ --output json) | ConvertFrom-Json
$azToken = $token_response.accessToken

#fetch workspace URL
$workspaceUrl = $(az resource show `
        --resource-type Microsoft.Databricks/workspaces `
        -g "$rgName" `
        -n "$databricks_name" `
        --query properties.workspaceUrl -o tsv)

$uri = "https://$($workspaceUrl)/api/2.0/token/create"
$baseUrl = 'https://' + $workspaceUrl
# You can also generate a PAT token. Note the quota limit of 600 tokens.
$body = '{"lifetime_seconds": 100000, "comment": "Ranatest" }';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")
$headers.Add("X-Databricks-Azure-SP-Management-Token", "$azToken")
$headers.Add("X-Databricks-Azure-Workspace-Resource-Id", "$dbswsId")
$pat_token = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Header $headers 
$pat_token = $pat_token.token_value
#Create a dir in dbfs & workspace to store the scipt files and init file
$requestHeaders = @{
    Authorization  = "Bearer" + " " + $pat_token
    "Content-Type" = "application/json"
}

# to create a new cluster
$body =  '{
    "autoscale": {
        "min_workers": 1,
        "max_workers": 1
    },
    "cluster_name": "MFCluster",
    "spark_version": "13.1.x-cpu-ml-scala2.12",
    "spark_conf": {
        "spark.databricks.delta.preview.enabled": "true"
    },
    "azure_attributes": {
        "first_on_demand": 1,
        "availability": "ON_DEMAND_AZURE",
        "spot_bid_max_price": -1
    },
    "node_type_id": "Standard_DS3_v2",
    "driver_node_type_id": "Standard_DS3_v2",
    "autotermination_minutes": 60,
    "enable_elastic_disk": true,
    "enable_local_disk_encryption": false,
    "data_security_mode": "NONE",
    "runtime_engine": "STANDARD"
}'

$endPoint = $baseURL + "/api/2.0/clusters/create"
$clusterId_1 = Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$clusterId_1 = $clusterId_1.cluster_id

$tenant = get-aztenant
$tenantid = $tenant.id
$servicePrincipalName = "fabric w databricks $suffix"
$app = az ad app create --display-name $servicePrincipalName | ConvertFrom-Json
$clientId = $app.appId
$appCredential = az ad app credential reset --id $clientId | ConvertFrom-Json
$clientsecpwd = $appCredential.password
az ad sp create --id $clientId | Out-Null 
$principalId = az ad sp show --id $clientId --query "id" -o tsv
New-AzRoleAssignment -Objectid $principalId -RoleDefinitionName "Contributor" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Databricks/workspaces/$databricks_name" -ErrorAction SilentlyContinue;

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
`"identifier`":`"$($principalId)`",
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
`"clientId`":`"$clientId`",
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
`"clientId`":`"$clientId`",
`"consentType`":`"AllPrincipals`",
`"resourceId`":`"$powerBiAppId`",
`"scope`":`"User.Read Directory.AccessAsUser.All`",
`"expiryTime`":`"2021-03-29T14:35:32.4943409+03:00`",
`"startTime`":`"2020-03-29T14:35:32.4933413+03:00`"
}";

$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization = "Bearer $graphtoken" } -ea SilentlyContinue;


(Get-Content -path "databricks/01_Setup-Onelake_Integration_with_Databrick.ipynb" -Raw) | Foreach-Object { $_ `
        -replace '#TENANT_ID#', $tenantid `
        -replace '#SECRET_KEY#', $clientsecpwd `
        -replace '#APP_ID#', $clientId `
        -replace '#WORKSPACE_NAME#', $contosoSalesWsName `
        -replace '#LAKEHOUSE_BRONZE#', $lakehouseBronze `
        -replace '#LAKEHOUSE_SILVER#', $lakehouseSilver `
        -replace '#LAKEHOUSE_GOLD#', $lakehouseGold `
} | Set-Content -Path "databricks/01_Setup-Onelake_Integration_with_Databrick.ipynb"

(Get-Content -path "databricks/03_ML_Solutions_in_a_Box.ipynb" -Raw) | Foreach-Object { $_ `
        -replace '#DATABRICKS_TOKEN#', $pat_token `
        -replace '#WORKSPACE_URL#', $baseUrl `
} | Set-Content -Path "databricks/03_ML_Solutions_in_a_Box.ipynb"

$files = Get-ChildItem -path "databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
Set-Location ./databricks
foreach ($name in $files.name) {
    if($name -eq "01_Setup-Onelake_Integration_with_Databrick.ipynb" -or $name -eq "02_DLT_Notebook.ipynb" -or $name -eq "03_ML_Solutions_in_a_Box.ipynb")
    {
            $fileContent = get-content -raw $name
            $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
            $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
            $requestHeaders = @{
                Authorization = "Bearer" + " " + $pat_token
                        }
                $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
            #get job list
            $endPoint = $baseURL +  "/api/2.0/workspace/import"
            Invoke-RestMethod $endPoint `
                -ContentType 'application/json' `
                -Method Post `
                -Headers $requestHeaders `
                -Body $body
    }
}
Set-Location ../

$endtime=get-date
$executiontime=$endtime-$starttime
Write-Host "Execution Time"$executiontime.TotalMinutes
Add-Content log.txt "-----------------Execution Complete---------------"

Write-Host  "-----------------Execution Complete----------------"
