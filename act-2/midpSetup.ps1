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
    $demoType = "Act-2"
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
    $wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"] 
    $suffix = "$random-$init"
    $synapseWorkspaceName = "synapse$suffix"
    $sqlPoolName = "MidpCosmosDW"
    $concatString = "$init$random"
    $sparkPoolName = "MidpSparkPool"
    $dataLakeAccountName = "stmidp$concatString"
    if($dataLakeAccountName.length -gt 24)
    {
    $dataLakeAccountName = $dataLakeAccountName.substring(0,24)
    }
    $mssql_server_name = "mssql$suffix"
    $sqlDatabaseName = "InventoryDB"
    $sqlUser = "labsqladmin"
    $namespaces_adx_thermostat_occupancy_name = "adx-thermostat-occupancy-$suffix"
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
    $func_cosmos_generator_storage_name = "stfuncgenerator"
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

    az webapp start --name $app_midpcosmosdemo_name --resource-group $rgName

    #start ASA
    Write-Host "----Starting ASA-----"
    Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $asa_name_midpcosmos -OutputStartMode 'JobStartTime'
    
    #####################################################
    # Write-Host "------COSMOS data Upload -------------"

    # [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # Install-Module -Name PowerShellGet -Force
    # Install-Module -Name CosmosDB -Force
    # $cosmosDbAccountName = $cosmos_midpcosmos_name
    # $cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

    # foreach ($name in $cosmos) {
    #     $collection = $name.BaseName 
    #     $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmosDatabaseName -ResourceGroup $rgName
    #     $path = "./artifacts/cosmos/" + $name.BaseName + ".json"
    #     $document = Get-Content -Raw -Path $path
    #     $document = ConvertFrom-Json $document

    #     foreach ($json in $document) {
    #         $key = $json.id
    #         $body = ConvertTo-Json $json
    #         $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    #     }
    # } 

    $endtime = get-date
    $executiontime = $endtime - $starttime
    Write-Host "Execution Time - "$executiontime.TotalMinutes
    Add-Content log.txt "-----------------Execution Complete---------------"

    Write-Host  "-----------------Execution Complete----------------"
}
