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
        #Copy external blob content
        $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
        $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
        $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
        $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
        $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
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

    az login

    #for powershell...
    Connect-AzAccount -DeviceCode
    $starttime = get-date
    $subs = Get-AzSubscription | Select-Object -ExpandProperty Name
    if ($subs.GetType().IsArray -and $subs.length -gt 1) {
        $subOptions = [System.Collections.ArrayList]::new()
        for ($subIdx = 0; $subIdx -lt $subs.length; $subIdx++) {
            $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
            $subOptions.Add($opt)
        }
        $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
        $selectedSubName = $subs[$selectedSubIdx]
        Write-Host "Selecting the subscription : $selectedSubName "
        $title = 'Subscription selection'
        $question = 'Are you sure you want to select this subscription for this lab?'
        $choices = '&Yes', '&No'
        $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
        if ($decision -eq 0) {
            Select-AzSubscription -SubscriptionName $selectedSubName
            az account set --subscription $selectedSubName
        }
        else {
            $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
            $selectedSubName = $subs[$selectedSubIdx]
            Write-Host "Selecting the subscription : $selectedSubName "
            Select-AzSubscription -SubscriptionName $selectedSubName
            az account set --subscription $selectedSubName
        }
    }

    $response = az ad signed-in-user show | ConvertFrom-Json
    $date = get-date
    $demoType = "MIDP_Cosmos"
    $body = '{"demoType":"#demoType#","userPrincipalName":"#userPrincipalName#","displayName":"#displayName#","companyName":"#companyName#","mail":"#mail#","date":"#date#"}'
    $body = $body.Replace("#userPrincipalName#", $response.userPrincipalName)
    $body = $body.Replace("#displayName#", $response.displayName)
    $body = $body.Replace("#companyName#", $response.companyName)
    $body = $body.Replace("#mail#", $response.mail)
    $body = $body.Replace("#date#", $date)
    $body = $body.Replace("#demoType#", $demoType)

    $uri = "https://registerddibuser.azurewebsites.net/api/registeruser?code=pTrmFDqp25iVSxrJ/ykJ5l0xeTOg5nxio9MjZedaXwiEH8oh3NeqMg=="
    $result = Invoke-RestMethod  -Uri $uri -Method POST -Body $body -Headers @{} -ContentType "application/json"

    $rgName = read-host "Enter the resource Group Name";
    $Region = (Get-AzResourceGroup -Name $rgName).Location
    $init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
    $random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
    $cco_realtime_config_url =  (Get-AzResourceGroup -Name $rgName).Tags["cco_realtime_config_url"]
    $store_telemetry_realtime_url =  (Get-AzResourceGroup -Name $rgName).Tags["store_telemetry_realtime_url"]
    $wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"] 
    $suffix = "$random-$init"
    $cpuShell = "wwi-cluster"
    $synapseWorkspaceName = "synapse$suffix"
    $sqlPoolName = "MidpCosmosDW"
    $concatString = "$init$random"
    $sparkPoolName = "MidpSparkPool"
    $dataLakeAccountName = "stmidp$concatString"
    if($dataLakeAccountName.length -gt 24)
    {
    $dataLakeAccountName = $dataLakeAccountName.substring(0,24)
    }
    $amlworkspacename = "amlws-$suffix"
    $databricks_name = "databricks-$suffix"
    $databricks_rgname = "databricks-rg$suffix"
    $mssql_server_name = "mssql$suffix"
    $sqlDatabaseName = "InventoryDB"
    $sqlUser = "labsqladmin"
    $accounts_purview_midpcosmos_name = "purviewmidpcosmos$suffix"
    $purviewCollectionName1 = "ADLS"
    $purviewCollectionName2 = "AzureSynapseAnalytics"
    $purviewCollectionName3 = "AzureSQLDatabase"
    $purviewCollectionName4 = "PowerBI"
    $namespaces_adx_thermostat_occupancy_name = "adx-thermostat-occupancy-$suffix"
    $sites_adx_thermostat_realtime_name = "app-realtime-kpi-midpcosmos-$suffix"
    $serverfarm_adx_thermostat_realtime_name = "asp-realtime-kpi-midpcosmos-$suffix"
    $app_midpcosmosdemo_name = "app-midp-azcosmosdb-$suffix"
    $asp_midpcosmosdemo_name = "asp-midp-azcosmosdb-$suffix"
    $asa_name_midpcosmos = "asa-$suffix"
    $cosmos_midpcosmos_name = "azure-cosmos-$random$init"
    if ($cosmos_midpcosmos_name.length -gt 43) {
        $cosmos_midpcosmos_name = $cosmos_midpcosmos_name.substring(0, 43)
    }
    $cosmosDatabaseName = "Telemetry"
    $keyVaultName = "kv-$suffix";
    $serverfarms_func_cosmos_generator = "asp-func-cosmos-$suffix"
    $func_cosmos_generator_storage_name = "stfuncgenerator$concatString"
    if($func_cosmos_generator_storage_name.length -gt 24)
    {
    $func_cosmos_generator_storage_name = $func_cosmos_generator_storage_name.substring(0,24)
    }
    $func_cosmos_generator_ai_name = "ai-func-comos-$suffix"
    $func_cosmos_generator_name = "func-cosmos-$suffix"
    $subscriptionId = (Get-AzContext).Subscription.Id
    $tenantId = (Get-AzContext).Tenant.Id
    $usercred = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
    $kustoPoolName = "midpcosmoskusto$init"
    $kustoDatabaseName = "MidpCosmosKustoDB"

    $storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value

    $id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
    New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
    New-AzRoleAssignment -SignInName $usercred -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

    Write-Host "Setting Key Vault Access Policy"
    #Import-Module Az.KeyVault
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $usercred -PermissionsToSecrets set,get,list
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

    $purview_id = (Get-AzADServicePrincipal -DisplayName $accounts_purview_midpcosmos_name).id
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $purview_id -PermissionsToSecrets set,get,list

    $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
    $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
    try {
    $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
    } finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
    }
    $SqlPassword = $secretValueText

    #Cosmos keys
    $cosmos_account_key = az cosmosdb keys list -n $cosmos_midpcosmos_name -g $rgName | ConvertFrom-Json
    $cosmos_account_key = $cosmos_account_key.primarymasterkey

    $thermostat_telemetry_Realtime_URL = ""
    $occupancy_data_Realtime_URL = ""
    $website_data_Realtime_URL = ""

    RefreshTokens
    Write-Host "-----Enable Transparent Data Encryption----------"
    $result = New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile "./artifacts/templates/transparentDataEncryption.json" -workspace_name_synapse $synapseWorkspaceName -sql_compute_name $sqlPoolName -ErrorAction SilentlyContinue

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

    #Uploading to storage containers
    Add-Content log.txt "-----------Uploading to storage containers-----------------"
    Write-Host "----Uploading to Storage Containers-----"

    $dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

    RefreshTokens

    $destinationSasKey = New-AzStorageContainerSASToken -Container "data-source" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/data-source$($destinationSasKey)"
    & $azCopyCommand copy "https://nrfdemo.blob.core.windows.net/data-source" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "delta-files" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/delta-files$($destinationSasKey)"
    & $azCopyCommand copy "https://nrfdemo.blob.core.windows.net/delta-files" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
    & $azCopyCommand copy "https://nrfdemo.blob.core.windows.net/customcsv" $destinationUri --recursive

    #databricks
    Add-Content log.txt "------databricks------"
    Write-Host "--------- Databricks---------"
    $dbswsId = $(az resource show `
            --resource-type Microsoft.Databricks/workspaces `
            -g "$rgName" `
            -n "$databricks_name" `
            --query id -o tsv)

    ##Get databricks workspaceId
    # $workspaceId = $(az resource show `
    #         --resource-type Microsoft.Databricks/workspaces `
    #         -g "$rgName" `
    #         -n "$databricks_name" `
    #         --query properties.workspaceId -o tsv)

    # Get a token for the global Databricks application.
    # The resource ID is fixed and never changes.
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

    # # to create forder in the databricks workspace
    # $body = '{"path": "dbfs:/FileStore/Campaign_Analytics" }';
    # #get job list
    # $endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
    # Invoke-RestMethod $endPoint `
    #     -Method Post `
    #     -Headers $requestHeaders `
    #     -Body $body

    # to create a new cluster
    $body = '{
    "autoscale": {
        "min_workers": 2,
        "max_workers": 5
    },
    "cluster_name": "MidpCosmos-Cluster",
    "spark_version": "11.2.x-cpu-ml-scala2.12",
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
    "autotermination_minutes": 45,
    "enable_elastic_disk": true,
    "cluster_source": "UI",
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
    $appdatabricks = az ad app create --display-name "midpcosmos" | ConvertFrom-Json
    $clientId = $appdatabricks.appId
    $appCredential = az ad app credential reset --id $clientId | ConvertFrom-Json
    $clientsecpwddatabricks = $appCredential.password
    $appid = az ad app show --id $clientid | ConvertFrom-Json
    $appid = $appid.appid
    az ad sp create --id $clientId | Out-Null
    $principalId = az ad sp show --id $clientId --query "id" -o tsv
    New-AzRoleAssignment -Objectid $principalId -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
(Get-Content -path "artifacts/databricks/ADB_Initial_Setup.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#APP_SECRET#', $clientsecpwddatabricks `
            -replace '#APP_ID#', $appid `
    } | Set-Content -Path "artifacts/databricks/ADB_Initial_Setup.ipynb"

(Get-Content -path "artifacts/databricks/ML Solutions in a Box.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#AML_WORKSPACE_NAME#', $amlworkspacename `
            -replace '#SUBSCRIPTION_ID#', $subscriptionId `
            -replace '#RESOURCE_GROUP_NAME#', $rgName `
            -replace '#LOCATION#', $Region `
            -replace '#DATABRICKS_TOKEN#', $pat_token `
            -replace '#WORKSPACE_URL#', $workspaceUrl `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#APP_SECRET#', $clientsecpwddatabricks `
            -replace '#APP_ID#', $appid `
    } | Set-Content -Path "artifacts/databricks/ML Solutions in a Box.ipynb"

    $files = Get-ChildItem -path "artifacts/databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
    Set-Location ./artifacts/databricks
    foreach ($name in $files.name) {
        if ($name -eq "01_campaign_analytics_DLT.ipynb" -or $name -eq "02_Twitter_Sentiment_Score_Pred_Custom_ML_Model.ipynb" -or $name -eq "03_Sentiment_Analytics_On_Delta_Live_Tables.ipynb") {
            $fileContent = get-content -raw $name
            $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
            $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
            $requestHeaders = @{
                Authorization = "Bearer" + " " + $pat_token
            }
            $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
            #get job list
            $endPoint = $baseURL + "/api/2.0/workspace/import"
            Invoke-RestMethod $endPoint `
                -ContentType 'application/json' `
                -Method Post `
                -Headers $requestHeaders `
                -Body $body
        }
        elseif ($name -eq "04_SQL_Analytics_On_Delta_Live_Tables.ipynb" -or $name -eq "ADB_Initial_Setup.ipynb" -or $name -eq "DLT notebook.ipynb" -or $name -eq "Twitter Campaign DLT notebook.ipynb") { 
            $fileContent = get-content -raw $name
            $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
            $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
            $requestHeaders = @{
                Authorization = "Bearer" + " " + $pat_token
            }
            $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
            #get job list
            $endPoint = $baseURL + "/api/2.0/workspace/import"
            Invoke-RestMethod $endPoint `
                -ContentType 'application/json' `
                -Method Post `
                -Headers $requestHeaders `
                -Body $body
        } 
        elseif ($name -eq "Campaign Powered by Twitter.ipynb" -or $name -eq "ML Solutions in a Box.ipynb" -or $name -eq "Retail Sales Data Prep Using Spark DLT.ipynb") { 
            $fileContent = get-content -raw $name
            $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
            $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
            $requestHeaders = @{
                Authorization = "Bearer" + " " + $pat_token
            }
            $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
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

    Add-Content log.txt "-----Ms Sql-----"
    Write-Host "----Ms Sql----"
    $SQLScriptsPath = "./artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/InventoryScript.sql"
    $sqlEndpoint = "$($mssql_server_name).database.windows.net"
    $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlDatabaseName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    ##############################

    Add-Content log.txt "------sql schema-----"
    Write-Host "----Sql Schema------"
    RefreshTokens
    #creating sql schema
    Write-Host "Create tables in $($sqlPoolName)"
    $SQLScriptsPath = "./artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    #uploading Sql Scripts
    Add-Content log.txt "-----------uploading Sql Script-----------------"
    Write-Host "----Sql Scripts------"
    RefreshTokens
    $scripts = Get-ChildItem "./artifacts/sqlscripts" | Select BaseName
    $TemplatesPath = "./artifacts/templates";	
    
    $dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
    $sasTokenAcc = New-AzStorageAccountSASToken -Context $dataLakeContext -Service Blob -ResourceType Service -Permission rwdl

    foreach ($name in $scripts) {
        if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "InventoryScript") {
            continue;
        }
        $item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
        $item = $item.Replace("#SQL_SCRIPT_NAME#", $name.BaseName)
        $item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
        $jsonItem = ConvertFrom-Json $item 
        $ScriptFileName = "./artifacts/sqlscripts/" + $name.BaseName + ".sql"
    
        $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
        $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
        $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmos_midpcosmos_name)
        $query = $query.Replace("#COSMOSDB_ACCOUNT_KEY#", $cosmos_account_key)
        $query = $query.Replace("#SAS_TOKEN#", $sasTokenAcc)
	
        if ($Parameters -ne $null) {
            foreach ($key in $Parameters.Keys) {
                $query = $query.Replace("#$($key)#", $Parameters[$key])
            }
        }

        Write-Host "Uploading Sql Script : $($name.BaseName)"
        $query = ConvertFrom-Json (ConvertTo-Json $query)
        $jsonItem.properties.content.query = $query
        $item = ConvertTo-Json $jsonItem -Depth 100
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name.BaseName)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
        Add-Content log.txt $result
    }

    ## Running a sql script in Sql serverless Pool

    $name = "2 Create External Table In Serverless Pool"
    $ScriptFileName = "./artifacts/sqlscripts/" + $name + ".sql"

    $sqlQuery = "Create DATABASE SQLServerlessPool"
    $sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
    try {
        $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
    }
    catch {
        $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
    }
    Add-Content log.txt $result	
 
    $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
    $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $query = $query.Replace("#SAS_TOKEN#", $sasTokenAcc)
    $sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $query -ServerInstance $sqlEndpoint -Database SQLServerlessPool -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result	

    #Azure Purview
    Write-Host "-----------------Azure Purview---------------"
    RefreshTokens

    #create collections
    $body = @{
        parentCollection = @{
            referenceName = $accounts_purview_midpcosmos_name
        }
    }
  
    $body = $body | ConvertTo-Json
  
    RefreshTokens
    $uri = "https://$($accounts_purview_midpcosmos_name).purview.azure.com/account/collections/$($purviewCollectionName1)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purview_midpcosmos_name).purview.azure.com/account/collections/$($purviewCollectionName2)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purview_midpcosmos_name).purview.azure.com/account/collections/$($purviewCollectionName3)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purview_midpcosmos_name).purview.azure.com/account/collections/$($purviewCollectionName4)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    #create sources
    $body = @{
        kind       = "AdlsGen2"
        properties = @{
            collection     = @{
                referenceName = $purviewCollectionName1
                type          = 'CollectionReference'
            }
            location       = $Region
            endpoint       = "https://${dataLakeAccountName}.dfs.core.windows.net/"
            resourceGroup  = $rgName
            resourceName   = $dataLakeAccountName
            subscriptionId = $subscriptionId
        }
    }
  
    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purview_midpcosmos_name).purview.azure.com/scan/datasources/AzureDataLakeStorage?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    $body = @{
        kind       = "AzureSynapseWorkspace"
        properties = @{
            dedicatedSqlEndpoint  = "$($synapseWorkspaceName).sql.azuresynapse.net"
            serverlessSqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
            subscriptionId        = $subscriptionId
            resourceGroup         = $rgName
            location              = $Region
            resourceName          = $synapseWorkspaceName
            collection            = @{
                type          = "CollectionReference"
                referenceName = $purviewCollectionName2
            }
        }
    }
  
    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purview_midpcosmos_name).purview.azure.com/scan/datasources/AzureSynapseAnalytics?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    # 6. Create a Source (Azure SQL Database)
    $body = @{
        kind       = "AzureSqlDatabase"
        properties = @{
            collection     = @{
                referenceName = $purviewCollectionName3
                type          = 'CollectionReference'
            }
            location       = $Region
            resourceGroup  = $rgName
            resourceName   = $mssql_server_name
            serverEndpoint = "${mssql_server_name}.database.windows.net"
            subscriptionId = $subscriptionId
        }
    }
  
    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purview_midpcosmos_name).purview.azure.com/scan/datasources/AzureSqlDatabase?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    $body = @{
        kind       = "PowerBI"
        properties = @{
            tenant     = $tenantId
            collection = @{
                type          = "CollectionReference"
                referenceName = $purviewCollectionName4
            }
        }
    }
  
    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purview_midpcosmos_name).purview.azure.com/scan/datasources/PowerBI?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"  

    Add-Content log.txt "------linked Services------"
    Write-Host "----linked Services------"
    #Creating linked services
    RefreshTokens
    $templatepath = "./artifacts/linkedService/"

    # AutoResolveIntegrationRuntime
    $FilePathRT = "./artifacts/linkedService/AutoResolveIntegrationRuntime.json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization = "Bearer $managementToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureBlob
    Write-Host "Creating linked Service: AzureBlob"
    $filepath = $templatepath + "AzureBlob.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureBlob?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # # AzureDatabricksAnalyticsSolutions
    # Write-Host "Creating linked Service: AzureDatabricksAnalyticsSolutions"
    # $filepath=$templatepath+"AzureDatabricksAnalyticsSolutions.json"
    # $itemTemplate = Get-Content -Path $filepath
    # $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token)
    # $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksAnalyticsSolutions?api-version=2019-06-01-preview"
    # $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    # Add-Content log.txt $result          

    # # AzureDatabricksDeltaLake
    # Write-Host "Creating linked Service: AzureDatabricksDeltaLake"
    # $filepath=$templatepath+"AzureDatabricksDeltaLake.json"
    # $itemTemplate = Get-Content -Path $filepath
    # $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token).Replace("#CLUSTER_ID#", $clusterId_1)
    # $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksDeltaLake?api-version=2019-06-01-preview"
    # $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    # Add-Content log.txt $result

    # # AzureDatabricksDeltaLakeTwitterData
    # Write-Host "Creating linked Service: AzureDatabricksDeltaLakeTwitterData"
    # $filepath=$templatepath+"AzureDatabricksDeltaLakeTwitterData.json"
    # $itemTemplate = Get-Content -Path $filepath
    # $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token).Replace("#CLUSTER_ID#", $clusterId_1)
    # $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksDeltaLakeTwitterData?api-version=2019-06-01-preview"
    # $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    # Add-Content log.txt $result

    # AzureSqlDatabase
    Write-Host "Creating linked Service: AzureSqlDatabase"
    $filepath = $templatepath + "AzureSqlDatabase.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#SERVER_NAME#", $mssql_server_name).Replace("#DATABASE_NAME#", $sqlDatabaseName).Replace("#USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureSqlDatabase?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # CosmosDbNoSql
    Write-Host "Creating linked Service: CosmosDbNoSql"
    $filepath = $templatepath + "CosmosDbNoSql.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#COSMOSDB_NAME#", $cosmos_midpcosmos_name).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/CosmosDbNoSql?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # # AzureDataLakeStorageTwitterData
    # Write-Host "Creating linked Service: AzureDataLakeStorageTwitterData"
    # $filepath = $templatepath + "AzureDataLakeStorageTwitterData.json"
    # $itemTemplate = Get-Content -Path $filepath
    # $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    # $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDataLakeStorageTwitterData?api-version=2019-06-01-preview"
    # $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    # Add-Content log.txt $result

    # OracleDB linked services
    Write-Host "Creating linked Service: OracleDB"
    $filepath = $templatepath + "OracleDB.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/OracleDB?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # SalesDB
    Write-Host "Creating linked Service: SalesDB"
    $filepath = $templatepath + "SalesDB.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#SERVER_NAME#", $mssql_server_name).Replace("#DATABASE_NAME#", $sqlDatabaseName).Replace("#USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SalesDB?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # Snowflake linked services
    Write-Host "Creating linked Service: Snowflake"
    $filepath = $templatepath + "Snowflake.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Snowflake?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # SynapseNRF
    Write-Host "Creating linked Service: SynapseNRF"
    $filepath = $templatepath + "SynapseNRF.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SynapseNRF?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # synnrfdemodev-WorkspaceDefaultSqlServer
    Write-Host "Creating linked Service: synnrfdemodev-WorkspaceDefaultSqlServer"
    $filepath = $templatepath + "synnrfdemodev-WorkspaceDefaultSqlServer.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synnrfdemodev-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # synnrfdemodev-WorkspaceDefaultStorage
    Write-Host "Creating linked Service: synnrfdemodev-WorkspaceDefaultStorage"
    $filepath = $templatepath + "synnrfdemodev-WorkspaceDefaultStorage.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synnrfdemodev-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # Teradata linked services
    Write-Host "Creating linked Service: Teradata"
    $filepath = $templatepath + "Teradata.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    #Creating Datasets
    Add-Content log.txt "------datasets------"
    Write-Host "--------Datasets--------"
    RefreshTokens
    $DatasetsPath = "./artifacts/dataset";	
    $datasets = Get-ChildItem "./artifacts/dataset" | Select BaseName
    foreach ($dataset in $datasets) {
        Write-Host "Creating dataset : $($dataset.BaseName)"
        $itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset.BaseName).json"
        $item = $itemTemplate
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset.BaseName)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
        Add-Content log.txt $result
    }
 
    #creating Dataflows
    Add-Content log.txt "------Dataflows-----"
    Write-Host "--------Dataflows--------"
    RefreshTokens
    $workloadDataflows = Get-ChildItem "./artifacts/dataflow" | Select BaseName 

    $DataflowPath = "./artifacts/dataflow"

    foreach ($dataflow in $workloadDataflows) {
        $Name = $dataflow.BaseName
        Write-Host "Creating dataflow : $($Name)"
        $item = Get-Content -Path "$($DataflowPath)/$($Name).json"
    
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/dataflows/$($Name)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    
        #waiting for operation completion
        Start-Sleep -Seconds 10
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization = "Bearer $synapseToken" }
        Add-Content log.txt $result
    }

    #creating Pipelines
    Add-Content log.txt "------pipelines------"
    Write-Host "-------Pipelines-----------"
    RefreshTokens
    $pipelines = Get-ChildItem "./artifacts/pipeline" | Select BaseName
    $pipelineList = New-Object System.Collections.ArrayList
    foreach ($name in $pipelines) {
        $FilePath = "./artifacts/pipeline/" + $name.BaseName + ".json"
        Write-Host "Creating pipeline : $($name.BaseName)"

        $item = Get-Content -Path $FilePath
        $item = $item.Replace("#DATA_LAKE_STORAGE_NAME#", $dataLakeAccountName)
        $defaultStorage = $synapseWorkspaceName + "-WorkspaceDefaultStorage"
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    
        #waiting for operation completion
        Start-Sleep -Seconds 10
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization = "Bearer $synapseToken" }
        Add-Content log.txt $result 
    }

    #creating Triggers
    Add-Content log.txt "------triggers------"
    Write-Host "-------Triggers-----------"
    RefreshTokens
    $triggers = Get-ChildItem "./artifacts/trigger" | Select BaseName
    foreach ($name in $triggers) {
        $FilePath = "./artifacts/trigger/" + $name.BaseName + ".json"
        Write-Host "Creating trigger : $($name.BaseName)"

        $item = Get-Content -Path $FilePath
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/triggers/$($name.BaseName)?api-version=2020-12-01"
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"

        #waiting for operation completion
        Start-Sleep -Seconds 10
        $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization = "Bearer $synapseToken" }
        Add-Content log.txt $result 
    }

    #uploading Sql Scripts
    Add-Content log.txt "-----------uploading KQL Scripts-----------------"
    Write-Host "----KQL Scripts------"
    RefreshTokens
    $scripts = Get-ChildItem "./artifacts/kqlscripts" | Select BaseName

    foreach ($name in $scripts) {
        $ScriptFileName = "./artifacts/kqlscripts/" + $name.BaseName + ".kql"
        Write-Host "Uploading Kql Script : $($name.BaseName)"
        New-AzSynapseKqlScript -WorkspaceName $synapseWorkspaceName -DefinitionFile $ScriptFileName
    }

    Add-Content log.txt "------powerbi reports upload------"
    Write-Host "------------Powerbi Reports Upload ------------"
    #Connect-PowerBIServiceAccount
    RefreshTokens
    $reportList = New-Object System.Collections.ArrayList
    $reports = Get-ChildItem "./artifacts/reports" | Select BaseName 
    foreach ($name in $reports) {
        $FilePath = "./artifacts/reports/$($name.BaseName)" + ".pbix"
        #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
        
        write-host "Uploading PowerBI Report : $($name.BaseName)";
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/imports?datasetDisplayName=$($name.BaseName)&nameConflict=CreateOrOverwrite";
        $fullyQualifiedPath = Resolve-Path -path $FilePath
        $fileBytes = [System.IO.File]::ReadAllBytes($fullyQualifiedPath);
        $fileEnc = [system.text.encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes);
        $boundary = [System.Guid]::NewGuid().ToString();
        $LF = "`r`n";
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data",
            "",
            $fileEnc,
            "--$boundary--$LF"
        ) -join $LF

        $result = Invoke-RestMethod -Uri $url -Method POST -Body $bodyLines -ContentType "multipart/form-data; boundary=`"--$boundary`"" -Headers @{ Authorization = "Bearer $powerbitoken" }
        Start-Sleep -s 5 
		
        Add-Content log.txt $result
        $reportId = $result.id;

        $temp = "" | select-object @{Name = "FileName"; Expression = { "$($name.BaseName)" } }, 
        @{Name = "Name"; Expression = { "$($name.BaseName)" } }, 
        @{Name = "PowerBIDataSetId"; Expression = { "" } },
        @{Name = "ReportId"; Expression = { "" } },
        @{Name = "SourceServer"; Expression = { "" } }, 
        @{Name = "SourceDatabase"; Expression = { "" } }
		                        
        # get dataset                         
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets";
        $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
		
        Add-Content log.txt $dataSets
        
        $temp.ReportId = $reportId;

        foreach ($res in $dataSets.value) {
            if ($res.name -eq $name.BaseName) {
                $temp.PowerBIDataSetId = $res.id;
            }
        }
                
        $list = $reportList.Add($temp)
    }
    Start-Sleep -s 60

    Write-Host  "-----------------AML Workspace ---------------"
    Add-Content log.txt "-----------AML Workspace -------------"
    RefreshTokens

    #create aml workspace
    az extension add -n azure-cli-ml
    az ml workspace create -n $amlworkspacename -g $rgName

    #attach a folder to set resource group and workspace name (to skip passing ws and rg in calls after this line)
    az ml folder attach -w $amlworkspacename -g $rgName -e aml
    start-sleep -s 10

    #create and delete a compute instance to get the code folder created in default store
    az ml computetarget create computeinstance -n $cpuShell -s "STANDARD_DS2_V2" -v

    #get default data store
    $defaultdatastore = az ml datastore show-default --resource-group $rgName --workspace-name $amlworkspacename --output json | ConvertFrom-Json
    $defaultdatastoreaccname = $defaultdatastore.account_name

    #get fileshare and code folder within that
    $storageAcct = Get-AzStorageAccount -ResourceGroupName $rgName -Name $defaultdatastoreaccname
    $share = Get-AzStorageShare -Prefix 'code' -Context $storageAcct.Context 
    $shareName = $share[0].Name
    $notebooks = Get-ChildItem "./artifacts/amlnotebooks" | Select BaseName
    foreach ($notebook in $notebooks) {
        if ($notebook.BaseName -eq "forecasting_script" -or $notebook.BaseName -eq "run_forecast") {
            $source = "./artifacts/amlnotebooks/" + $notebook.BaseName + ".py"
            $path = $notebook.BaseName + ".py"
        }
        elseif ($notebook.BaseName -eq "department_visit_customer" -or $notebook.BaseName -eq "predictions" -or $notebook.BaseName -eq "retail_sales_dataset" -or $notebook.BaseName -eq "retail_sales_datasetv2" -or $notebook.BaseName -eq "solar-panel-demand-no") {
            $source = "./artifacts/amlnotebooks/" + $notebook.BaseName + ".csv"
            $path = $notebook.BaseName + ".csv"
        }
        elseif ($notebook.BaseName -eq "header" -or $notebook.BaseName -eq "iStock-1328873668") {
            $source = "./artifacts/amlnotebooks/" + $notebook.BaseName + ".jpg"
            $path = $notebook.BaseName + ".jpg"
        }
        else {
            $source = "./artifacts/amlnotebooks/" + $notebook.BaseName + ".ipynb"
            $path = $notebook.BaseName + ".ipynb"
        }

        Write-Host " Uplaoding AML assets : $($notebook.BaseName)"
        Set-AzStorageFileContent `
            -Context $storageAcct.Context `
            -ShareName $shareName `
            -Source $source `
            -Path $path
    }

    #delete aks compute
    az ml computetarget delete -n $cpuShell -v

    ##Establish powerbi reports dataset connections
    Add-Content log.txt "------pbi connections update------"
    Write-Host "---------PBI connections update---------"	

    RefreshTokens
    foreach ($report in $reportList) {
        if ($report.name -eq "ADX dashboard 8AM" -or $report.name -eq "Dashboard-Images" -or $report.name -eq "Global overview tiles" -or $report.name -eq "Realtime In Store Analytics") {
            continue;
        }
        elseif ($report.name -eq "6 ADX Website Bounce Rate Analysis") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"KustoServer`",
									`"newValue`": `"https://$($kustoPoolName).$($synapseWorkspaceName).kusto.azuresynapse.net`"
								},
								{
									`"name`": `"KustoDB`",
									`"newValue`": `"$($kustoDatabaseName)`"
								},
								{
									`"name`": `"Server`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "7 Product Recommendation DataBricks" -or $report.name -eq "Product Recommendation") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"ServerName`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "ADX Thermostat and Occupancy") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"ADX Server`",
									`"newValue`": `"https://$($kustoPoolName).$($synapseWorkspaceName).kusto.azuresynapse.net`"
								},
								{
									`"name`": `"ADX Database`",
									`"newValue`": `"$($kustoDatabaseName)`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "Campaign Analytics") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"SQL_Server`",
									`"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"SQLServerlessPool`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "CDP Vision Report" -or $report.name -eq "Customer Segmentation" -or $report.name -eq "Dwell Time Kpis and Charts" -or $report.name -eq "Location Analytics" -or $report.name -eq "Retail Group CEO KPI" -or $report.name -eq "Retail Predictive Analytics" -or $report.name -eq "World Map" -or $report.name -eq "WideWorldImporters") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "Revenue and Profitability") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server_Name`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"DB_Name`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
        }
	
        Write-Host "PBI connections updating for report : $($report.name)"	
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
        $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $powerbitoken" } -ErrorAction SilentlyContinue;
		
        start-sleep -s 5
    }

    #########################

    #Web App Section
    Add-Content log.txt "------unzipping poc web app------"
    Write-Host  "--------------Unzipping web app---------------"
    $zips = @("midpcosmos-demo-app", "func-cosmos-generator")
    foreach ($zip in $zips) {
        expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
    }

    #Web app
    Add-Content log.txt "------deploy poc web app------"
    Write-Host  "-----------------Deploy web app---------------"
    RefreshTokens

    $spname = "MidpComos Demo $init"

    $app = az ad app create --display-name $spname | ConvertFrom-Json
    $appId = $app.appId

    $mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
    $clientsecpwd = $mainAppCredential.password

    az ad sp create --id $appId | Out-Null    
    $sp = az ad sp show --id $appId --query "id" -o tsv
    start-sleep -s 60

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
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/users";
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

(Get-Content -path midpcosmos-demo-app/appsettings.json -Raw) | Foreach-Object { $_ `
            -replace '#WORKSPACE_ID#', $wsId`
            -replace '#APP_ID#', $appId`
            -replace '#APP_SECRET#', $clientsecpwd`
            -replace '#TENANT_ID#', $tenantId`				
    } | Set-Content -Path midpcosmos-demo-app/appsettings.json

    $filepath = "./midpcosmos-demo-app/wwwroot/config-poc.js"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName).Replace("#SERVER_NAME#", $app_midpcosmosdemo_name).Replace("#LOCATION#", $Region)
    Set-Content -Path $filepath -Value $item

    RefreshTokens
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
    $reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
    $reportList = $reportList.Value

    #update all th report ids in the poc web app...
    $ht = new-object system.collections.hashtable   
    # $ht.add("#Bing_Map_Key#", "AhBNZSn-fKVSNUE5xYFbW_qajVAZwWYc8OoSHlH8nmchGuDI6ykzYjrtbwuNSrR8")
    $ht.add("#Retail Group CEO KPI#", $($reportList | where { $_.name -eq "Retail Group CEO KPI" }).id)
    $ht.add("#ADX dashboard 8AM#", $($reportList | where { $_.name -eq "ADX dashboard 8AM" }).id)
    $ht.add("#World Map#", $($reportList | where { $_.name -eq "World Map" }).id)
    $ht.add("#Revenue and Profitability#", $($reportList | where { $_.name -eq "Revenue and Profitability" }).id)
    $ht.add("#Location Analytics#", $($reportList | where { $_.name -eq "Location Analytics" }).id)
    $ht.add("#ADX Thermostat and Occupancy#", $($reportList | where { $_.name -eq "ADX Thermostat and Occupancy" }).id)
    $ht.add("#Global overview tiles#", $($reportList | where { $_.name -eq "Global overview tiles" }).id)
    $ht.add("#WideWorldImporters#", $($reportList | where { $_.name -eq "WideWorldImporters" }).id)
    $ht.add("#Product Recommendation#", $($reportList | where { $_.name -eq "Product Recommendation" }).id)
    $ht.add("#Realtime In Store Analytics#", $($reportList | where { $_.name -eq "Realtime In Store Analytics" }).id)
    
    $filePath = "./midpcosmos-demo-app/wwwroot/config-poc.js";
    Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

    Compress-Archive -Path "./midpcosmos-demo-app/*" -DestinationPath "./midpcosmos-demo-app.zip" -Update

    az webapp stop --name $app_midpcosmosdemo_name --resource-group $rgName
    try {
        az webapp deployment source config-zip --resource-group $rgName --name $app_midpcosmosdemo_name --src "./midpcosmos-demo-app.zip"
    }
    catch {
    }

    Add-Content log.txt "-----Simulator apps zip deploy-------"
    Write-Host "----Simulator apps zip deploy------"

    # ADX Thermostat Realtime
    az webapp stop --name $sites_adx_thermostat_realtime_name --resource-group $rgName

    $occupancy_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name occupancy --name occupancy | ConvertFrom-Json
    $occupancy_endpoint = $occupancy_endpoint.primaryConnectionString
    $thermostat_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name thermostat --name thermostat | ConvertFrom-Json
    $thermostat_endpoint = $thermostat_endpoint.primaryConnectionString
    $website_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name websitedata --name policy1 | ConvertFrom-Json
    $website_endpoint = $website_endpoint.primaryConnectionString 

    # (Get-Content -path app-adx-thermostat-realtime/dev.env -Raw) | Foreach-Object { $_ `
    #             -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_THERMOSTAT_ENDPOINT#', $thermostat_endpoint`
    #             -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_OCCUPANCY_ENDPOINT#', $occupancy_endpoint`
    #             -replace '#NAMESPACES_ADX_WEBSITE_ENDPOINT#', $website_endpoint`
    #             -replace '#THERMOSTATTELEMETRY_URL#', $thermostat_telemetry_Realtime_URL`
    #             -replace '#OCCUPANCYDATA_URL#', $occupancy_data_Realtime_URL`
    #             -replace '#WEBSITEDATA_URL#', $website_data_Realtime_URL`
    #             -replace '#BEFORESCENARIO_CCO_REALTIME_CONFIG_URL#', $cco_realtime_config_url`
    #             -replace '#STORE_TELEMETRY_CONFIG#', $store_telemetry_realtime_url`
    #     } | Set-Content -Path app-adx-thermostat-realtime/dev.env

(Get-Content -path adx-config-appsetting.json -Raw) | Foreach-Object { $_ `
            -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_THERMOSTAT_ENDPOINT#', $thermostat_endpoint`
            -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_OCCUPANCY_ENDPOINT#', $occupancy_endpoint`
            -replace '#NAMESPACES_ADX_WEBSITE_ENDPOINT#', $website_endpoint`
            -replace '#THERMOSTATTELEMETRY_URL#', $thermostat_telemetry_Realtime_URL`
            -replace '#OCCUPANCYDATA_URL#', $occupancy_data_Realtime_URL`
            -replace '#WEBSITEDATA_URL#', $website_data_Realtime_URL`
            -replace '#BEFORESCENARIO_CCO_REALTIME_CONFIG_URL#', $cco_realtime_config_url`
            -replace '#STORE_TELEMETRY_CONFIG#', $store_telemetry_realtime_url`
    } | Set-Content -Path adx-config-appsetting-with-replacement.json

    $config = az webapp config appsettings set -g $rgName -n $sites_adx_thermostat_realtime_name --settings @adx-config-appsetting-with-replacement.json

    Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_adx_thermostat_realtime_name -ArchivePath ./artifacts/binaries/app-adx-thermostat-realtime.zip -Force

    # Write-Information "Deploying ADX Thermostat Realtime App"
    # cd app-adx-thermostat-realtime
    # az webapp up --resource-group $rgName --name $sites_adx_thermostat_realtime_name --plan $serverfarm_adx_thermostat_realtime_name --location $Region
    # cd ..
    # Start-Sleep -s 10

    # Function App Cosmos
    $inventoryPrimaryKey = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name inventory --name inventory | ConvertFrom-Json
    $inventoryPrimaryKey = $inventoryPrimaryKey.primaryKey

(Get-Content -path func-cosmos-generator/TimerTrigger1/run.ps1 -Raw) | Foreach-Object { $_ `
            -replace '#NAMESPACE_THERMOSTAT_OCCUPANCY#', $namespaces_adx_thermostat_occupancy_name`
            -replace '#EVENTHUB_ACCESS_POLICY_KEY#', $inventoryPrimaryKey`
    } | Set-Content -Path func-cosmos-generator/TimerTrigger1/run.ps1
    
    $func_cosmos_storage_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $func_cosmos_generator_storage_name)[0].Value
    $webjobs = "DefaultEndpointsProtocol=https;AccountName=" + $func_cosmos_generator_storage_name + ";AccountKey=" + $func_cosmos_storage_key + ";EndpointSuffix=core.windows.net"

    $config = az webapp config appsettings set -g $rgName -n $func_cosmos_generator_name --settings AzureWebJobsStorage=$webjobs
    $config = az webapp config appsettings set -g $rgName -n $func_cosmos_generator_name --settings FUNCTIONS_WORKER_RUNTIME="powershell"
    
    cd func-cosmos-generator
    func azure functionapp publish $func_cosmos_generator_name --powershell --force
    cd ..
    Start-Sleep -s 10

    az webapp start --name $sites_adx_thermostat_realtime_name --resource-group $rgName
    az webapp start --name $app_midpcosmosdemo_name --resource-group $rgName

    #start ASA
    Write-Host "----Starting ASA-----"
    Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_midpcosmos -OutputStartMode 'JobStartTime'
    
    Add-Content log.txt "------Data Explorer Creation-----"
    Write-Host "----Data Explorer Creation-----"
    New-AzSynapseKustoPool -ResourceGroupName $rgName -WorkspaceName $synapseWorkspaceName -Name $kustoPoolName -Location $Region -SkuName "Compute optimized" -SkuSize Small

    New-AzSynapseKustoPoolDatabase -ResourceGroupName $rgName -WorkspaceName $synapseWorkspaceName -KustoPoolName $kustoPoolName -DatabaseName $kustoDatabaseName -Kind "ReadWrite" -Location $Region

    #####################################################
    Write-Host "------COSMOS data Upload -------------"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name PowerShellGet -Force
    Install-Module -Name CosmosDB -Force
    $cosmosDbAccountName = $cosmos_midpcosmos_name
    $cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

    foreach ($name in $cosmos) {
        $collection = $name.BaseName 
        $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmosDatabaseName -ResourceGroup $rgName
        $path = "./artifacts/cosmos/" + $name.BaseName + ".json"
        $document = Get-Content -Raw -Path $path
        $document = ConvertFrom-Json $document

        foreach ($json in $document) {
            $key = $json.id
            $body = ConvertTo-Json $json
            $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
        }
    } 

    $endtime = get-date
    $executiontime = $endtime - $starttime
    Write-Host "Execution Time - "$executiontime.TotalMinutes
    Add-Content log.txt "-----------------Execution Complete---------------"

    #################################

    Add-Content log.txt "------uploading sql data------"
    Write-Host  "-------------Uploading Sql Data ---------------"
    RefreshTokens
    #uploading sql data
    $dataTableList = New-Object System.Collections.ArrayList

    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Campaign_AnalyticLatest" } } , @{Name = "TABLE_NAME"; Expression = { "Campaign_AnalyticLatest" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Campaigns" } } , @{Name = "TABLE_NAME"; Expression = { "Campaigns" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "CohortAnalysis" } } , @{Name = "TABLE_NAME"; Expression = { "CohortAnalysis" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "ConflictofInterest" } } , @{Name = "TABLE_NAME"; Expression = { "ConflictofInterest" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "CosmosDb" } } , @{Name = "TABLE_NAME"; Expression = { "CosmosDb" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Country" } } , @{Name = "TABLE_NAME"; Expression = { "Country" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Customer_Segment_RFM" } } , @{Name = "TABLE_NAME"; Expression = { "Customer_Segment_RFM" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "CustomerVisitForecast" } } , @{Name = "TABLE_NAME"; Expression = { "CustomerVisitForecast" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "CustomerVisitsIn_PersonByLocation" } } , @{Name = "TABLE_NAME"; Expression = { "CustomerVisitsIn_PersonByLocation" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "DemandForecast" } } , @{Name = "TABLE_NAME"; Expression = { "DemandForecast" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "DimData" } } , @{Name = "TABLE_NAME"; Expression = { "DimData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Engagement_ActualVsForecast" } } , @{Name = "TABLE_NAME"; Expression = { "Engagement_ActualVsForecast" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Engagement_ActualVsForecastLatest" } } , @{Name = "TABLE_NAME"; Expression = { "Engagement_ActualVsForecastLatest" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Finance_Sales" } } , @{Name = "TABLE_NAME"; Expression = { "Finance_Sales" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "FinanceSales" } } , @{Name = "TABLE_NAME"; Expression = { "FinanceSales" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "FPA" } } , @{Name = "TABLE_NAME"; Expression = { "FPA" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "HeaderWIP" } } , @{Name = "TABLE_NAME"; Expression = { "HeaderWIP" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Inventory" } } , @{Name = "TABLE_NAME"; Expression = { "Inventory" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "InventoryItem" } } , @{Name = "TABLE_NAME"; Expression = { "InventoryItem" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Location_Analytics_old" } } , @{Name = "TABLE_NAME"; Expression = { "Location_Analytics_old" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Location_AnalyticsLatest" } } , @{Name = "TABLE_NAME"; Expression = { "Location_AnalyticsLatest" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Location_AnalyticsNew" } } , @{Name = "TABLE_NAME"; Expression = { "Location_AnalyticsNew" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "MIDPSales" } } , @{Name = "TABLE_NAME"; Expression = { "MIDPSales" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "MIDPSupplier" } } , @{Name = "TABLE_NAME"; Expression = { "MIDPSupplier" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Models" } } , @{Name = "TABLE_NAME"; Expression = { "Models" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "OperatingExpenses" } } , @{Name = "TABLE_NAME"; Expression = { "OperatingExpenses" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiBalanceSheet" } } , @{Name = "TABLE_NAME"; Expression = { "pbiBalanceSheet" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiBedOccupancyForecasted" } } , @{Name = "TABLE_NAME"; Expression = { "pbiBedOccupancyForecasted" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiCustomer" } } , @{Name = "TABLE_NAME"; Expression = { "pbiCustomer" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PbiReadmissionPrediction" } } , @{Name = "TABLE_NAME"; Expression = { "PbiReadmissionPrediction" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PbiWaitTimeForecast" } } , @{Name = "TABLE_NAME"; Expression = { "PbiWaitTimeForecast" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pred_anomaly" } } , @{Name = "TABLE_NAME"; Expression = { "pred_anomaly" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PredictiveInventory" } } , @{Name = "TABLE_NAME"; Expression = { "PredictiveInventory" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "ProductLink2" } } , @{Name = "TABLE_NAME"; Expression = { "ProductLink2" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "ProductRecommendations" } } , @{Name = "TABLE_NAME"; Expression = { "ProductRecommendations" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Products Table" } } , @{Name = "TABLE_NAME"; Expression = { "Products Table" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "RevenueVsMarketingCostNew" } } , @{Name = "TABLE_NAME"; Expression = { "RevenueVsMarketingCostNew" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Sales" } } , @{Name = "TABLE_NAME"; Expression = { "Sales" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Salestransactionbkp" } } , @{Name = "TABLE_NAME"; Expression = { "Salestransactionbkp" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Salestransactions" } } , @{Name = "TABLE_NAME"; Expression = { "Salestransactions" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Salestransactions1" } } , @{Name = "TABLE_NAME"; Expression = { "Salestransactions1" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SalesVsExpense" } } , @{Name = "TABLE_NAME"; Expression = { "SalesVsExpense" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SiteSecurity" } } , @{Name = "TABLE_NAME"; Expression = { "SiteSecurity" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Temp" } } , @{Name = "TABLE_NAME"; Expression = { "Temp" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Travel_Entertainment" } } , @{Name = "TABLE_NAME"; Expression = { "Travel_Entertainment" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "VTBByChannel" } } , @{Name = "TABLE_NAME"; Expression = { "VTBByChannel" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "WebsiteSocialAnalytics_PBIData" } } , @{Name = "TABLE_NAME"; Expression = { "WebsiteSocialAnalytics_PBIData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Wait_Time_Forecasted" } } , @{Name = "TABLE_NAME"; Expression = { "Wait_Time_Forecasted" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Salestransaction" } } , @{Name = "TABLE_NAME"; Expression = { "Salestransaction" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PredictiveInventorySink" } } , @{Name = "TABLE_NAME"; Expression = { "PredictiveInventorySink" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "OnlineRetailData" } } , @{Name = "TABLE_NAME"; Expression = { "OnlineRetailData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Export" } } , @{Name = "TABLE_NAME"; Expression = { "Export" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)

    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    foreach ($dataTableLoad in $dataTableList) {
        Write-output "Loading data for $($dataTableLoad.TABLE_NAME)"
        $sqlQuery = Get-Content -Raw -Path "./artifacts/templates/load_csv.sql"
        $sqlQuery = $sqlQuery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
        $Parameters = @{
            CSV_FILE_NAME         = $dataTableLoad.CSV_FILE_NAME
            TABLE_NAME            = $dataTableLoad.TABLE_NAME
            DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
        }
        foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
        Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    }

    Write-Host  "-----------------Execution Complete----------------"
}
