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
    $demoType = "Healthcare2.0"
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
    $concatString = "$init$random"
    $cpuShell = "healthcare-compute"
    $forms_healthcare2_name = "form-healthcare2-$suffix"
    $synapseWorkspaceName = "synhealthcare2$concatString"
    $sqlPoolName = "HealthcareDW"
    $dataLakeAccountName = "sthealthcare2$concatString"
    if($dataLakeAccountName.length -gt 24)
    {
    $dataLakeAccountName = $dataLakeAccountName.substring(0,24)
    }
    $amlworkspacename = "aml-hc2-$suffix"
    $databricks_workspace_name = "databricks-hc2-$suffix"
    $sqlUser = "labsqladmin"
    $mssql_server_name = "mssqlhc2-$suffix"
    $sqlDatabaseName = "InventoryDB"
    $accounts_purviewhealthcare2_name = "purviewhc2$suffix"
    $purviewCollectionName1 = "ADLS"
    $purviewCollectionName2 = "AzureSynapseAnalytics"
    $purviewCollectionName3 = "AzureCosmosDB"
    $purviewCollectionName4 = "PowerBI"
    $namespaces_evh_patient_monitoring_name = "evh-patient-monitoring-hc2-$suffix"
    $sites_patient_data_simulator_name = "app-patient-data-simulator-$suffix"
    $sites_clinical_notes_name = "app-clinical-notes-$suffix"
    $sites_doc_search_name = "app-health-search-$suffix"
    $sites_open_ai_name = "app-open-ai-$suffix"
    $app_healthcare2_name = "app-healthcare2-$suffix"
    $streamingjobs_deltadata_asa_name = "asa-hc2-deltadata-$suffix"
    $cosmos_healthcare2_name = "cosmos-healthcare2-$random$init"
    if ($cosmos_healthcare2_name.length -gt 43) {
        $cosmos_healthcare2_name = $cosmos_healthcare2_name.substring(0, 43)
    }
    $cosmosDatabaseName = "healthcare"
    $searchName = "srch-healthcare2-$suffix"
    $cognitive_service_name = "cog-healthcare2-$suffix"
    $keyVaultName = "kv-hc2-$concatString"
    if($keyVaultName.length -gt 24)
    {
    $keyVaultName = $keyVaultName.substring(0,24)
    }
    $func_payor_storage_name = "stfuncgeneratorhc2$concatString"
    if($func_payor_storage_name.length -gt 24)
    {
    $func_payor_storage_name = $func_payor_storage_name.substring(0,24)
    }
    $func_payor_generator_name = "func-payor-generator-hc2-$suffix"
    $subscriptionId = (Get-AzContext).Subscription.Id
    $tenantId = (Get-AzContext).Tenant.Id
    $usercred = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
    $kustoPoolName = "hc2kustopool$init"
    $kustoDatabaseName = "HC2KustoDB$init"
    $openAIResource = "openAIservicehc2$concatString"
    if($openAIResource.length -gt 24)
    {
    $openAIResource = $openAIResource.substring(0,24)
    }

    $storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value

    $id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
    New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
    New-AzRoleAssignment -SignInName $usercred -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

    Write-Host "Setting Key Vault Access Policy"
    #Import-Module Az.KeyVault
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $usercred -PermissionsToSecrets set,get,list
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

    $purview_id = (Get-AzADServicePrincipal -DisplayName $accounts_purviewhealthcare2_name).id
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $purview_id -PermissionsToSecrets set,get,list

    $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
    $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
    try {
    $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
    } finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
    }
    $sqlPassword = $secretValueText

    $forms_hc2_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_healthcare2_name
    
    #Cosmos keys
    $cosmos_account_key = az cosmosdb keys list -n $cosmos_healthcare2_name -g $rgName | ConvertFrom-Json
    $cosmos_account_key = $cosmos_account_key.primarymasterkey

    #retrieving openai endpoint
    $openAIEndpoint = az cognitiveservices account show -n $openAIResource -g $rgName | jq -r .properties.endpoint

    #retirieving primary key
    $openAIPrimaryKey = az cognitiveservices account keys list -n $openAIResource -g $rgName | jq -r .key1
    
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

    $destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/customcsv" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "data-source" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/data-source$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/data-source" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "delta-files" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/delta-files$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/delta-files" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "fhirdata" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/fhirdata$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/fhirdata" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "formrecogoutput" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/formrecogoutput$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/formrecogoutput" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "hospitalincidentkdm" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/hospitalincidentkdm$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/hospitalincidentkdm" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "hospitalincidentsearch-skillset-image-projection" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/hospitalincidentsearch-skillset-image-projection$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/hospitalincidentsearch-skillset-image-projection" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "patientintakeform" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/patientintakeform$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/patientintakeform" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "predictiveanalytics" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/predictiveanalytics$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/predictiveanalytics" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "twitter" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/twitter$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/twitter" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/webappassets$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/webappassets" $destinationUri --recursive
  
    $destinationSasKey = New-AzStorageContainerSASToken -Container "healthcare-reports" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/healthcare-reports$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/healthcare-reports" $destinationUri --recursive
  
    $destinationSasKey = New-AzStorageContainerSASToken -Container "consolidated-report" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/consolidated-report$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/consolidated-report" $destinationUri --recursive
  
    $destinationSasKey = New-AzStorageContainerSASToken -Container "sthealthcare2" -Context $dataLakeContext -Permission rwdl
    $destinationUri = "https://$($dataLakeAccountName).blob.core.windows.net/sthealthcare2$($destinationSasKey)"
    & $azCopyCommand copy "https://pochealthcare2.blob.core.windows.net/sthealthcare2" $destinationUri --recursive

    #databricks
    Add-Content log.txt "------databricks------"
    Write-Host "--------- Databricks---------"
    $dbswsId = $(az resource show `
            --resource-type Microsoft.Databricks/workspaces `
            -g "$rgName" `
            -n "$databricks_workspace_name" `
            --query id -o tsv)

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
            -n "$databricks_workspace_name" `
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

    $body = '{
    "autoscale": {
        "min_workers": 2,
        "max_workers": 5
    },
    "cluster_name": "healthcare2-cluster",
    "spark_version": "11.3.x-cpu-ml-scala2.12",
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
    "enable_local_disk_encryption": false,
    "cluster_source": "UI",
    "data_security_mode": "NONE",
    "runtime_engine": "STANDARD"
}'

    $endPoint = $baseURL + "/api/2.0/clusters/create"
    $clusterId = Invoke-RestMethod $endPoint `
        -Method Post `
        -Headers $requestHeaders `
        -Body $body

    $clusterId = $clusterId.cluster_id

    $tenant = get-aztenant
    $tenantid = $tenant.id
    $appdatabricks = az ad app create --display-name "healthcare2" | ConvertFrom-Json
    $clientId = $appdatabricks.appId
    $appCredential = az ad app credential reset --id $clientId | ConvertFrom-Json
    $clientsecpwddatabricks = $appCredential.password
    $appid = az ad app show --id $clientid | ConvertFrom-Json
    $appid = $appid.appid
    az ad sp create --id $clientId | Out-Null
    $principalId = az ad sp show --id $clientId --query "id" -o tsv
    New-AzRoleAssignment -Objectid $principalId -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
(Get-Content -path "artifacts/databricks/BedOccupancy_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/BedOccupancy_dlt.ipynb"

(Get-Content -path "artifacts/databricks/BedOccupancySupplierAQI_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/BedOccupancySupplierAQI_dlt.ipynb"

(Get-Content -path "artifacts/databricks/CallCenter_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/CallCenter_dlt.ipynb"

(Get-Content -path "artifacts/databricks/Campaigns_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/Campaigns_dlt.ipynb"

(Get-Content -path "artifacts/databricks/Consolidated_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/Consolidated_dlt.ipynb"

(Get-Content -path "artifacts/databricks/HospitalInfo_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/HospitalInfo_dlt.ipynb"

(Get-Content -path "artifacts/databricks/Misc_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/Misc_dlt.ipynb"

(Get-Content -path "artifacts/databricks/Patient Profile dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/Patient Profile dlt.ipynb"

(Get-Content -path "artifacts/databricks/PatientExperience_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/PatientExperience_dlt.ipynb"

(Get-Content -path "artifacts/databricks/PatientParm_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/PatientParm_dlt.ipynb"

(Get-Content -path "artifacts/databricks/PatientPredictive_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/PatientPredictive_dlt.ipynb"

(Get-Content -path "artifacts/databricks/PbiPatientPredictive_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/PbiPatientPredictive_dlt.ipynb"

(Get-Content -path "artifacts/databricks/Predctive_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/Predctive_dlt.ipynb"
            
(Get-Content -path "artifacts/databricks/Sales_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/Sales_dlt.ipynb"

(Get-Content -path "artifacts/databricks/TotalBed_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/TotalBed_dlt.ipynb"
    
(Get-Content -path "artifacts/databricks/USMap_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/USMap_dlt.ipynb"
      
(Get-Content -path "artifacts/databricks/Initial setup.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
            -replace '#SERVICE_PRINCIPAL_NAME#', "healthcare2" `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SP_ID#', $appid `
            -replace '#SECRET_KEY#', $clientsecpwddatabricks `
    } | Set-Content -Path "artifacts/databricks/Initial setup.ipynb"
    
    $files = Get-ChildItem -path "artifacts/databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
    Set-Location ./artifacts/databricks
    foreach ($name in $files.name) {
        if ($name -eq "PatientParm_dlt.ipynb" -or $name -eq "PatientPredictive_dlt.ipynb" -or $name -eq "Sales_dlt.ipynb" -or $name -eq "PbiPatientPredictive_dlt.ipynb" -or $name -eq "Predctive_dlt.ipynb") {
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
        elseif ($name -eq "BedOccupancySupplierAQI_dlt.ipynb" -or $name -eq "BedOccupancy_dlt.ipynb" -or $name -eq "CallCenter_dlt.ipynb" -or $name -eq "Campaigns_dlt.ipynb" -or $name -eq "Consolidated_dlt.ipynb" -or $name -eq "HospitalInfo_dlt.ipynb" -or $name -eq "Misc_dlt.ipynb" -or $name -eq "Patient Profile dlt.ipynb" -or $name -eq "PatientExperience_dlt.ipynb") { 
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
        elseif ($name -eq "TotalBed_dlt.ipynb" -or $name -eq "USMap_dlt.ipynb" -or $name -eq "Initial setup.ipynb") { 
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
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/mssql_tables.sql"
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

    Write-Host "Create storedProcedure in $($sqlPoolName)"
    $SQLScriptsPath = "./artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/storedProcedure.sql"
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    Write-Host "Create view in $($sqlPoolName)"
    $SQLScriptsPath = "./artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/viewDedicatedPool.sql"
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    Write-Host "Create configurable table in $($sqlPoolName)"
    $SQLScriptsPath = "./artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/configurableTableQuery.sql"
    $openAIAppEndpoint = "https://" + $sites_open_ai_name + ".azurewebsites.net/"
    $query = $sqlQuery.Replace("#OPEN_AI_APP_ENDPOINT#", $openAIAppEndpoint).Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $sqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    $result = Invoke-SqlCmd -Query $query -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
    (Get-Content -path "$($SQLScriptsPath)/sqluser.sql" -Raw) | Foreach-Object { $_ `
                    -replace '#SQL_PASSWORD#', $sqlPassword`
            } | Set-Content -Path "$($SQLScriptsPath)/sqluser.sql"		
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
    $sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sql_user_hc2.sql"
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
    Add-Content log.txt $result

    ## Running a sql script in Sql serverless Pool
    $name = "SchemaForExternalTable"
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
    $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmos_healthcare2_name)
    $query = $query.Replace("#REGION#", $Region)
    $query = $query.Replace("#COSMOSDB_ACCOUNT_KEY#", $cosmos_account_key)
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
            referenceName = $accounts_purviewhealthcare2_name
        }
    }
  
    $body = $body | ConvertTo-Json
  
    RefreshTokens
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/account/collections/$($purviewCollectionName1)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/account/collections/$($purviewCollectionName2)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/account/collections/$($purviewCollectionName3)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/account/collections/$($purviewCollectionName4)?api-version=2019-11-01-preview"
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
  
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/scan/datasources/AzureDataLakeStorage?api-version=2018-12-01-preview"
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
  
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/scan/datasources/AzureSynapseAnalytics?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    #Create a Source (Azure Cosmos DB)
    $body = @{
        kind       = "AzureCosmosDb"
        properties = @{
            collection     = @{
                referenceName = $purviewCollectionName3
                type          = 'CollectionReference'
            }
            location       = $Region
            resourceGroup  = $rgName
            resourceName   = $cosmos_healthcare2_name
            accountUri = "${cosmos_healthcare2_name}.documents.azure.com:443/"
            subscriptionId = $subscriptionId
        }
    }

    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/scan/datasources/CosmosDB?api-version=2018-12-01-preview"
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
  
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/scan/datasources/PowerBI?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"  

    # Purview-API-PowerShell -APIDirect -HTTPMethod GET -PurviewAPIDirectURL "https://{$accounts_purviewhealthcare2_name}.purview.azure.com/scan/datasources?api-version=2021-07-01" 

    #uploading Sql Scripts
    Add-Content log.txt "-----------uploading Sql Script-----------------"
    Write-Host "----Sql Scripts------"
    RefreshTokens
    $scripts = Get-ChildItem "./artifacts/sqlscripts" | Select BaseName
    $TemplatesPath = "./artifacts/templates";	
    
    $dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
    $sasTokenAcc = New-AzStorageAccountSASToken -Context $dataLakeContext -Service Blob -ResourceType Service -Permission rwdl

    foreach ($name in $scripts) {
        if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "storedProcedure" -or $name.BaseName -eq "viewDedicatedPool" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sql_user_hc2" -or $name.BaseName -eq "configurableTableQuery") {
            continue;
        }
        $item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
        $item = $item.Replace("#SQL_SCRIPT_NAME#", $name.BaseName)
        $item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
        $jsonItem = ConvertFrom-Json $item 
        $ScriptFileName = "./artifacts/sqlscripts/" + $name.BaseName + ".sql"
    
        $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
        $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
        $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmos_healthcare2_name)
        $query = $query.Replace("#COSMOSDB_ACCOUNT_KEY#", $cosmos_account_key)
        $query = $query.Replace("#REGION#", $Region)
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

    ## Synapse Pipeline Chronology
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

    # IR-SAPHANA
    $FilePathRT = "./artifacts/linkedService/IR-SAPHANA.json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/IR-SAPHANA?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization = "Bearer $managementToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureBlobStorage
    Write-Host "Creating linked Service: AzureBlobStorage"
    $filepath = $templatepath + "AzureBlobStorage.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureBlobStorage?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureBlobStorage1
    Write-Host "Creating linked Service: AzureBlobStorage1"
    $filepath = $templatepath + "AzureBlobStorage1.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureBlobStorage1?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureCosmosDb
    Write-Host "Creating linked Service: AzureCosmosDb"
    $filepath = $templatepath + "AzureCosmosDb.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#COSMOSDB_NAME#", $cosmos_healthcare2_name).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureCosmosDb?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # AzureDataLakeStorageTwitterData
    Write-Host "Creating linked Service: AzureDataLakeStorageTwitterData"
    $filepath = $templatepath + "AzureDataLakeStorageTwitterData.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDataLakeStorageTwitterData?api-version=2019-06-01-preview"
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
    # $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token).Replace("#CLUSTER_ID#", $clusterId)
    # $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDatabricksDeltaLake?api-version=2019-06-01-preview"
    # $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    # Add-Content log.txt $result

    # # AzureDatabricksDeltaLakeTwitterData
    # Write-Host "Creating linked Service: AzureDatabricksDeltaLakeTwitterData"
    # $filepath=$templatepath+"AzureDatabricksDeltaLakeTwitterData.json"
    # $itemTemplate = Get-Content -Path $filepath
    # $item = $itemTemplate.Replace("#DOMAIN_NAME#", $baseUrl).Replace("#ACCESS_TOKEN#", $pat_token).Replace("#CLUSTER_ID#", $clusterId)
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

    # DynamicsHealthCare linked services
    Write-Host "Creating linked Service: DynamicsHealthCare"
    $filepath=$templatepath+"DynamicsHealthCare.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/DynamicsHealthCare?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # LS_SapHana linked services
    Write-Host "Creating linked Service: LS_SapHana"
    $filepath=$templatepath+"LS_SapHana.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/LS_SapHana?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # OracleDB linked services
    Write-Host "Creating linked Service: OracleDB"
    $filepath = $templatepath + "OracleDB.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/OracleDB?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
    
    # PowerBIWorkspace
    Write-Host "Creating linked Service: PowerBIWorkspace"
    $filepath = $templatepath + "PowerBIWorkspace.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_ID#", $wsId).Replace("#TENANT_ID#", $tenantId)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/PowerBIWorkspace?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # ProfiseeRestService linked services
    Write-Host "Creating linked Service: ProfiseeRestService"
    $filepath = $templatepath + "ProfiseeRestService.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/ProfiseeRestService?api-version=2019-06-01-preview"
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
    
    # SynapseAnalyticsProd
    Write-Host "Creating linked Service: SynapseAnalyticsProd"
    $filepath = $templatepath + "SynapseAnalyticsProd.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SynapseAnalyticsProd?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
    
    # synhealthcare2-WorkspaceDefaultSqlServer
    Write-Host "Creating linked Service: synhealthcare2-WorkspaceDefaultSqlServer"
    $filepath = $templatepath + "synhealthcare2-WorkspaceDefaultSqlServer.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synhealthcare2-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
    
    # synhealthcare2prod-WorkspaceDefaultSqlServer
    Write-Host "Creating linked Service: synhealthcare2prod-WorkspaceDefaultSqlServer"
    $filepath = $templatepath + "synhealthcare2prod-WorkspaceDefaultSqlServer.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synhealthcare2prod-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result

    # synhealthcare2prod-WorkspaceDefaultStorage
    Write-Host "Creating linked Service: synhealthcare2prod-WorkspaceDefaultStorage"
    $filepath = $templatepath + "synhealthcare2prod-WorkspaceDefaultStorage.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synhealthcare2prod-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
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

    # #creating Triggers
    # Add-Content log.txt "------triggers------"
    # Write-Host "-------Triggers-----------"
    # RefreshTokens
    # $triggers = Get-ChildItem "./artifacts/trigger" | Select BaseName
    # foreach ($name in $triggers) {
    #     $FilePath = "./artifacts/trigger/" + $name.BaseName + ".json"
    #     Write-Host "Creating trigger : $($name.BaseName)"

    #     $item = Get-Content -Path $FilePath
    #     $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/triggers/$($name.BaseName)?api-version=2020-12-01"
    #     $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization = "Bearer $synapseToken" } -ContentType "application/json"

    #     #waiting for operation completion
    #     Start-Sleep -Seconds 10
    #     $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
    #     $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization = "Bearer $synapseToken" }
    #     Add-Content log.txt $result 
    # }

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

    # az synapse kql-script import --resource-group $rgName --workspace-name $synapseWorkspaceName --file $ScriptFileName --name $name

    ##Search service 
    Write-Host "-----------------Search service ---------------"
    Add-Content log.txt "-----------------Search service ---------------"
    RefreshTokens
    # Create Search Service
    #$sku = "Standard"
    #New-AzSearchService -Name $searchName -ResourceGroupName $rgName -Sku $sku -Location $location
    
    # Create search query key
    Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
    $queryKey = "QueryKey"
    New-AzSearchQueryKey -Name $queryKey -ServiceName $searchName -ResourceGroupName $rgName
    
    # Get search primary admin key
    $adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $searchName
    $primaryAdminKey = $adminKeyPair.Primary
    
    #get list of keys - cognitiveservices
    $key=az cognitiveservices account keys list --name $cognitive_service_name -g $rgName|ConvertFrom-json
    $destinationKey=$key.key1
    
    # Fetch connection string
    $storageKey = (Get-AzStorageAccountKey -Name $dataLakeAccountName -ResourceGroupName $rgName)[0].Value
    $storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($dataLakeAccountName);AccountKey=$($storageKey);EndpointSuffix=core.windows.net"
    
    #resource id of cognitive_service_name
    $resource=az resource show -g $rgName -n $cognitive_service_name --resource-type "Microsoft.CognitiveServices/accounts"|ConvertFrom-Json
    $resourceId=$resource.id
    
    # Create Index
    Get-ChildItem "artifacts/search" -Filter hospitalincidentsearch-index.json |
            ForEach-Object {
                $indexDefinition = Get-Content $_.FullName -Raw
                $headers = @{
                    'api-key' = $primaryAdminKey
                    'Content-Type' = 'application/json'
                    'Accept' = 'application/json' }
    
                $url = "https://$searchName.search.windows.net/indexes?api-version=2020-06-30"
                Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
            }
    Start-Sleep -s 10
    
    # Create Datasource endpoint
    Get-ChildItem "artifacts/search" -Filter search_datasource.json |
            ForEach-Object {
                $datasourceDefinition = (Get-Content $_.FullName -Raw).replace("#STORAGE_CONNECTION#", $storageConnectionString)
                $headers = @{
                    'api-key' = $primaryAdminKey
                    'Content-Type' = 'application/json'
                    'Accept' = 'application/json' }
    
                 $url = "https://$searchName.search.windows.net/datasources?api-version=2020-06-30"
                 Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $dataSourceDefinition | ConvertTo-Json
            }
    Start-Sleep -s 10
    
    #Replace connection string in search_skillset.json
    (Get-Content -path artifacts/search/search_skillset.json -Raw) | Foreach-Object { $_ `
                    -replace '#RESOURCE_ID#', $resourceId`
                    -replace '#STORAGEACCOUNTNAME#', $dataLakeAccountName`
                    -replace '#STORAGEKEY#', $storageKey`
                    -replace '#COGNITIVE_API_KEY#', $destinationKey`
                } | Set-Content -Path artifacts/search/search_skillset.json
    
    # Creat Skillset
    Get-ChildItem "artifacts/search" -Filter search_skillset.json |
            ForEach-Object {
                $skillsetDefinition = Get-Content $_.FullName -Raw
                $headers = @{
                    'api-key' = $primaryAdminKey
                    'Content-Type' = 'application/json'
                    'Accept' = 'application/json' }
    
                $url = "https://$searchName.search.windows.net/skillsets?api-version=2020-06-30"
                Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $skillsetDefinition | ConvertTo-Json
            }
    Start-Sleep -s 10
    
    # Create Indexers
    Get-ChildItem "artifacts/search" -Filter search_indexer.json |
            ForEach-Object {
                $indexerDefinition = Get-Content $_.FullName -Raw
                $headers = @{
                    'api-key' = $primaryAdminKey
                    'Content-Type' = 'application/json'
                    'Accept' = 'application/json' }
    
                $url = "https://$searchName.search.windows.net/indexers?api-version=2020-06-30"
                Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexerDefinition | ConvertTo-Json
            }
    
    ## powerbi
    Add-Content log.txt "------powerbi reports upload------"
    Write-Host "------------Powerbi Reports Upload------------"
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
    Start-Sleep -s 30

    #Form Recognizer
    Add-Content log.txt "-------------Form Recognizer--------------"
    Write-Host "-----Form Recognizer-----"

    $dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

    $startingTime = Get-Date
    $endingTime = $startingTime.AddDays(6)
    $sasToken = New-AzStorageContainerSASToken -Container "patientintakeform" -Context $dataLakeContext -Permission rwdl -StartTime $startingTime -ExpiryTime $endingTime

    #Replace values in create_model.py
    (Get-Content -path artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
                    -replace '#LOCATION#', $Region`
                    -replace '#FORM_RECOGNIZER_NAME#', $forms_healthcare2_name`
                    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName`
                    -replace '#CONTAINER_NAME#', "patientintakeform"`
                    -replace '#SAS_TOKEN#', $sasToken`
                    -replace '#APIM_KEY#',  $forms_hc2_keys.Key1`
                } | Set-Content -Path artifacts/formrecognizer/create_model1.py
                
    $modelUrl = python "./artifacts/formrecognizer/create_model1.py"
    $modelId = $modelUrl.split("/")
    $modelId = $modelId[7]

    Write-Host  "-----------------AML Workspace ---------------"
    Add-Content log.txt "-----------AML Workspace -------------"
    RefreshTokens

    $forms_hc2_endpoint = "https://"+$forms_healthcare2_name+".cognitiveservices.azure.com/"
    
    #delpoying a model
    $openAIModel = az cognitiveservices account deployment create -g $rgName -n $openAIResource --deployment-name "text-davinci-003" --model-name "text-davinci-003" --model-version "1" --model-format OpenAI --scale-settings-scale-type "Standard"

    $filepath="./artifacts/amlnotebooks/Configurable.py"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key).Replace("#FORM_RECOGNIZER_ENDPOINT#", $forms_hc2_endpoint).Replace("#FORM_RECOGNIZER_API_KEY#", $forms_hc2_keys.Key1).Replace("#FORM_RECOGNIZER_MODEL_ID#", $modelId)
    $filepath="./artifacts/amlnotebooks/GlobalVariables.py"
    Set-Content -Path $filepath -Value $item

    $filepath="./artifacts/amlnotebooks/config.json"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#OPENAI_API_ENDPOINT#", $openAIEndpoint).Replace("#OPENAI_API_KEY#", $openAIPrimaryKey)
    $filepath="./artifacts/amlnotebooks/config.json"
    Set-Content -Path $filepath -Value $item

    # #deleting a model from openai
    # az cognitiveservices account deployment delete -g $myResourceGroupName -n $myResourceName --deployment-name MyModel

    # #deleting openai resource
    # az cognitiveservices account delete --name MyopenAIResource -g OAIResourceGroup

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

        if($notebook.BaseName -eq "GlobalVariables")
        {
            $source="./artifacts/amlnotebooks/"+$notebook.BaseName+".py"
            $path=$notebook.BaseName+".py"
        } 
        elseif($notebook.BaseName -eq "config")
        {
            $source="./artifacts/amlnotebooks/"+$notebook.BaseName+".json"
            $path=$notebook.BaseName+".json"
        } 
        elseif($notebook.BaseName -eq "Configurable")
        {
         continue;
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
        if ($report.name -eq "ER Wait Time KPIs" -or $report.name -eq "ER Wait Time KPIs 1" -or $report.name -eq "Healthcare - Before and After dashboard GIF" -or $report.name -eq "Healthcare chicklets" -or $report.name -eq "Healthcare Dashbaord Images-Final" -or $report.name -eq "Reports with Dashboard GIF" -or $report.name -eq "Healthcare - Call Center Power BI-After (with recc Script)") {
            continue;
        }
        elseif ($report.name -eq "Healthcare - Bed Occupancy ") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database_Name`",
									`"newValue`": `"$($sqlPoolName)`"
								},
								{
									`"name`": `"Serverless`",
									`"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database_Serverless`",
									`"newValue`": `"SQLServerlessPool`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "3 HealthCare Dynamic Data Masking (Azure Synapse)" -or $report.name -eq "4 HealthCare Column Level Security (Azure Synapse)" -or $report.name -eq "5 HealthCare Row Level Security (Azure Synapse)" -or $report.name -eq "Healthcare - HTAP-Lab-Data" -or $report.name -eq "Healthcare Miami Hospital Overview") {
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
        elseif ($report.name -eq "Healthcare FHIR") {
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
        elseif ($report.name -eq "Healthcare - Call Center Power BI Before" -or $report.name -eq "Healthcare - Call Center Power BI-After") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server_Name`",
									`"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
								},
								{
									`"name`": `"DB_Name`",
									`"newValue`": `"SQLServerlessPool`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "Healthcare - Patients Profile report") {
            $body = "{
			`"updateDetails`": [
                                {
                                    `"name`": `"Server`",
                                    `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                                },
                                {
                                    `"name`": `"Database_ChatBot`",
                                    `"newValue`": `"$($sqlPoolName)`"
                                },
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
        elseif ($report.name -eq "Healthcare - US Map" -or $report.name -eq "Healthcare Global overview tiles") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server`",
									`"newValue`": `"$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"SQLServerlessPool`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "Healthcare Consolidated Report") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server_Name`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database_Name`",
									`"newValue`": `"$($sqlPoolName)`"
								},
								{
									`"name`": `"BlobStorage`",
									`"newValue`": `"https://$($dataLakeAccountName).blob.core.windows.net/consolidated-report`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "Healthcare Global Occupational Safety Report") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Blob Location`",
									`"newValue`": `"https://$($dataLakeAccountName).dfs.core.windows.net/healthcare-reports/`"
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
        elseif ($report.name -eq "Healthcare Patient Overview") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Blob Storage`",
									`"newValue`": `"https://$($dataLakeAccountName).blob.core.windows.net/healthcare-reports`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "Static Realtime Healthcare analytics") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server_Gen2`",
									`"newValue`": `"https://$($dataLakeAccountName).dfs.core.windows.net/healthcare-reports/`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "Payor Dashboard report") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Blob Server`",
									`"newValue`": `"https://$($dataLakeAccountName).blob.core.windows.net/healthcare-reports`"
								}
								]
								}"	
        }
        elseif ($report.name -eq "HealthCare Predctive Analytics_V1") {
            $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Healthcare_server`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"HealthcareDW`",
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
    $zips = @("func-realtime-payor-generator-hc2", "healthcare2-demo-app", "app-clinical-notes", "app-open-ai")
    foreach ($zip in $zips) {
        expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
    }

    #Web app
    Add-Content log.txt "------deploy poc web app------"
    Write-Host  "-----------------Deploy web app---------------"
    RefreshTokens

    $spname = "Healthcare2 Demo $init"

    $app = az ad app create --display-name $spname | ConvertFrom-Json
    $appId = $app.appId

    $mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
    $clientsecpwd = $mainAppCredential.password

    az ad sp create --id $appId | Out-Null    
    $sp = az ad sp show --id $appId --query "id" -o tsv
    start-sleep -s 30

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

    #retrieving cognitive service endpoint
    $cognitiveEndpoint = az cognitiveservices account show -n $cognitive_service_name -g $rgName | jq -r .properties.endpoint

    #retirieving cognitive service key
    $cognitivePrimaryKey = az cognitiveservices account keys list -n $cognitive_service_name -g $rgName | jq -r .key1

(Get-Content -path healthcare2-demo-app/appsettings.json -Raw) | Foreach-Object { $_ `
            -replace '#WORKSPACE_ID#', $wsId`
            -replace '#APP_ID#', $appId`
            -replace '#APP_SECRET#', $clientsecpwd`
            -replace '#TENANT_ID#', $tenantId`
            -replace '#REGION#', $Region`
            -replace '#COGNITIVE_SERVICE_ENDPOINT#', $cognitiveEndpoint`
            -replace '#COGNITIVE_KEY#', $cognitivePrimaryKey`
    } | Set-Content -Path healthcare2-demo-app/appsettings.json

    $filepath = "./healthcare2-demo-app/wwwroot/config-poc.js"
    $itemTemplate = Get-Content -Path $filepath
    $item = $itemTemplate.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName).Replace("#SERVER_NAME#", $app_healthcare2_name).Replace("#APP_CRITICAL_NOTES#", $sites_clinical_notes_name).Replace("#APP_OPEN_AI#", $sites_open_ai_name).Replace("#SUBSCRIPTION_ID#", $subscriptionId).Replace("#RESOURCE_GROUP_NAME#", $rgName).Replace("#ML_WORKSPACE_NAME#", $amlworkspacename).Replace("#TENANT_ID#", $tenantId).Replace("#SYNAPSE_NAME#", $synapseWorkspaceName)
    Set-Content -Path $filepath -Value $item

    RefreshTokens
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
    $reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
    $reportList = $reportList.Value

    #update all th report ids in the poc web app...
    $ht = new-object system.collections.hashtable   
    # $ht.add("#Bing_Map_Key#", "AhBNZSn-fKVSNUE5xYFbW_qajVAZwWYc8OoSHlH8nmchGuDI6ykzYjrtbwuNSrR8")
    $ht.add("#Healthcare Global overview tiles#", $($reportList | where { $_.name -eq "Healthcare Global overview tiles" }).id)
    $ht.add("#Healthcare - US Map#", $($reportList | where { $_.name -eq "Healthcare - US Map" }).id)
    $ht.add("#Healthcare - Patients Profile report#", $($reportList | where { $_.name -eq "Healthcare - Patients Profile report" }).id)
    $ht.add("#Healthcare - Call Center Power BI-After#", $($reportList | where { $_.name -eq "Healthcare - Call Center Power BI-After" }).id)
    $ht.add("#Healthcare - Bed Occupancy & Availability Report#", $($reportList | where { $_.name -eq "Healthcare - Bed Occupancy " }).id)
    $ht.add("#Healthcare - HTAP-Lab-Data#", $($reportList | where { $_.name -eq "Healthcare - HTAP-Lab-Data" }).id)
    $ht.add("#Healthcare Consolidated Report#", $($reportList | where { $_.name -eq "Healthcare Consolidated Report" }).id)
    $ht.add("#Healthcare FHIR#", $($reportList | where { $_.name -eq "Healthcare FHIR" }).id)
    $ht.add("#Healthcare - Call Center Power BI Before#", $($reportList | where { $_.name -eq "Healthcare - Call Center Power BI Before" }).id)
    $ht.add("#Healthcare Miami Hospital Overview#", $($reportList | where { $_.name -eq "Healthcare Miami Hospital Overview" }).id)
    $ht.add("#Healthcare Patient Overview#", $($reportList | where { $_.name -eq "Healthcare Patient Overview" }).id)
    $ht.add("#Healthcare Global Occupational Safety Report#", $($reportList | where { $_.name -eq "Healthcare Global Occupational Safety Report" }).id)
    
    $filePath = "./healthcare2-demo-app/wwwroot/config-poc.js";
    Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

    Compress-Archive -Path "./healthcare2-demo-app/*" -DestinationPath "./healthcare2-demo-app.zip" -Update

    az webapp stop --name $app_healthcare2_name --resource-group $rgName
    try {
        az webapp deployment source config-zip --resource-group $rgName --name $app_healthcare2_name --src "./healthcare2-demo-app.zip"
    }
    catch {
    }
    
    az webapp start --name $app_healthcare2_name --resource-group $rgName

    Add-Content log.txt "-----Simulator apps zip deploy-------"
    Write-Host "----Simulator apps zip deploy------"

    # ADX Thermostat Realtime
    az webapp stop --name $sites_patient_data_simulator_name --resource-group $rgName

    $operational_analytics_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_evh_patient_monitoring_name --eventhub-name "operational-analytics" --name "operational" | ConvertFrom-Json
    $operational_analytics_endpoint = $operational_analytics_endpoint.primaryConnectionString
    $monitoring_device_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_evh_patient_monitoring_name --eventhub-name "monitoring-device" --name "device" | ConvertFrom-Json
    $monitoring_device_endpoint = $monitoring_device_endpoint.primaryConnectionString

    (Get-Content -path adx-config-appsetting.json -Raw) | Foreach-Object { $_ `
            -replace '#NAMESPACE_EVH_OPERATIONAL_ANALYTICS_ENDPOINT#', $operational_analytics_endpoint`
            -replace '#NAMESPACE_EVH_MONITORING_DEVICE_ENDPOINT#', $monitoring_device_endpoint`
            -replace '#STREAMING_DATASET_URL#', $streaming_dataset_url`
    } | Set-Content -Path adx-config-appsetting-with-replacement.json

    $config = az webapp config appsettings set -g $rgName -n $sites_patient_data_simulator_name --settings @adx-config-appsetting-with-replacement.json

    Write-Information "Deploying Patient Data Simulator App"
#     cd app-adx-thermostat-realtime
#     az webapp up --resource-group $rgName --name $sites_patient_data_simulator_name --plan $serverfarm_adx_thermostat_realtime_name --location $Region
#     cd ..
#     Start-Sleep -s 10
    Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_patient_data_simulator_name -ArchivePath ./artifacts/binaries/app-adx-thermostat-realtime.zip -Force

    az webapp start --name $sites_patient_data_simulator_name --resource-group $rgName

    # Function App Cosmos
    $payorRealtimePrimaryKey = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_evh_patient_monitoring_name --eventhub-name "payor-realtime-data" --name "realtime" | ConvertFrom-Json
    $payorRealtimePrimaryKey = $payorRealtimePrimaryKey.primaryKey

(Get-Content -path func-realtime-payor-generator-hc2/TimerTrigger1/run.ps1 -Raw) | Foreach-Object { $_ `
            -replace '#NAMESPACE_THERMOSTAT_OCCUPANCY#', $namespaces_evh_patient_monitoring_name`
            -replace '#EVENTHUB_ACCESS_POLICY_KEY#', $payorRealtimePrimaryKey`
    } | Set-Content -Path func-realtime-payor-generator-hc2/TimerTrigger1/run.ps1
    
    $func_payor_storage_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $func_payor_storage_name)[0].Value
    $webjobs = "DefaultEndpointsProtocol=https;AccountName=" + $func_payor_storage_name + ";AccountKey=" + $func_payor_storage_key + ";EndpointSuffix=core.windows.net"

    $config = az webapp config appsettings set -g $rgName -n $func_payor_generator_name --settings AzureWebJobsStorage=$webjobs
    $config = az webapp config appsettings set -g $rgName -n $func_payor_generator_name --settings FUNCTIONS_WORKER_RUNTIME="powershell"
    
    cd func-realtime-payor-generator-hc2
    func azure functionapp publish $func_payor_generator_name --powershell --force
    cd ..
    Start-Sleep -s 10

    ## Other Apps Deployment
    az webapp stop --name $sites_doc_search_name --resource-group $rgName
    az webapp stop --name $sites_clinical_notes_name --resource-group $rgName
    az webapp stop --name $sites_open_ai_name --resource-group $rgName

    #app doc search
    az webapp deployment source config-zip --resource-group $rgName --name $sites_doc_search_name --src "./artifacts/binaries/app-health-search.zip"
    # Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_doc_search_name -ArchivePath ./artifacts/binaries/app-health-search.zip -Force

    #app clinical notes
    (Get-Content -path app-clinical-notes/wwwroot/config.js -Raw) | Foreach-Object { $_ `
                -replace '#OPEN_AI_ENDPOINT#', $openAIEndpoint`
                -replace '#MODEL_NAME#', "text-davinci-003"`
                -replace '#SUBSCRIPTION_ID#', $subscriptionId`
                -replace '#RESOURCE_GROUP_NAME#', $rgName`
                -replace '#ML_WORKSPACE_NAME#', $amlworkspacename`
                -replace '#TENANT_ID#', $tenantId`
        } | Set-Content -Path app-clinical-notes/wwwroot/config.js
    Compress-Archive -Path "./app-clinical-notes/*" -DestinationPath "./app-clinical-notes.zip" -Update
    Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_clinical_notes_name -ArchivePath ./app-clinical-notes.zip -Force
    
    #app open ai
    (Get-Content -path app-open-ai/wwwroot/config.js -Raw) | Foreach-Object { $_ `
                -replace '#OPEN_AI_ENDPOINT#', $openAIEndpoint`
                -replace '#MODEL_NAME#', "text-davinci-003"`
                -replace '#OPEN_AI_KEY#', $openAIPrimaryKey`
        } | Set-Content -Path app-open-ai/wwwroot/config.js
    Compress-Archive -Path "./app-open-ai/*" -DestinationPath "./app-open-ai.zip" -Update
    Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_open_ai_name -ArchivePath ./app-open-ai.zip -Force
    
    az webapp start --name $sites_doc_search_name --resource-group $rgName
    az webapp start --name $sites_clinical_notes_name --resource-group $rgName
    az webapp start --name $sites_open_ai_name --resource-group $rgName
    
    #start ASA
    Write-Host "----Starting ASA-----"
    Start-AzStreamAnalyticsJob -ResourceGroupName $rgName -Name $streamingjobs_deltadata_asa_name -OutputStartMode 'JobStartTime'
    
    Add-Content log.txt "------Data Explorer Creation-----"
    Write-Host "----Data Explorer Creation-----"
    New-AzSynapseKustoPool -ResourceGroupName $rgName -WorkspaceName $synapseWorkspaceName -Name $kustoPoolName -Location $Region -SkuName "Compute optimized" -SkuSize Small

    New-AzSynapseKustoPoolDatabase -ResourceGroupName $rgName -WorkspaceName $synapseWorkspaceName -KustoPoolName $kustoPoolName -DatabaseName $kustoDatabaseName -Kind "ReadWrite" -Location $Region

    #####################################################
    Write-Host  "-----------------Uploading Cosmos Data Started--------------"
    #uploading Cosmos data
    Add-Content log.txt "-----------------uploading Cosmos data--------------"
    RefreshTokens
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name PowerShellGet -Force
    Install-Module -Name CosmosDB -Force
    $cosmosDbAccountName = $cosmos_healthcare2_name
    $databaseName = $cosmosDatabaseName
    $cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

    foreach($name in $cosmos)
    {
        $collection = $name.BaseName 
        $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $rgName
        $path="./artifacts/cosmos/"+$name.BaseName+".json"
        $document=Get-Content -Raw -Path $path
        $document=ConvertFrom-Json $document
        #$newRU=4000
        #az cosmosdb sql container throughput update -a $cosmosDbAccountName -g $rgName -d $databaseName -n $collection --throughput $newRU
        
        foreach($json in $document)
        {
            $key=$json.SyntheticPartitionKey
            $id = New-Guid
            if(![bool]($json.PSobject.Properties.name -eq "id"))
            {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
            if(![bool]($json.PSobject.Properties.name -eq "SyntheticPartitionKey"))
            {$json | Add-Member -MemberType NoteProperty -Name 'SyntheticPartitionKey' -Value $id}
            $body=ConvertTo-Json $json
            New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
        }
    } 

    $endtime = get-date
    $executiontime = $endtime - $starttime
    Write-Host "Execution Time - "$executiontime.TotalMinutes
    
    #################################

    Add-Content log.txt "------uploading sql data------"
    Write-Host  "-------------Uploading Sql Data ---------------"
    RefreshTokens
    #uploading sql data
    $dataTableList = New-Object System.Collections.ArrayList

    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Campaign_Analytics" } } , @{Name = "TABLE_NAME"; Expression = { "Campaign_Analytics" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Campaign_Analytics_New" } } , @{Name = "TABLE_NAME"; Expression = { "Campaign_Analytics_New" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "City and Race Data" } } , @{Name = "TABLE_NAME"; Expression = { "City and Race Data" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Claim" } } , @{Name = "TABLE_NAME"; Expression = { "Claim" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Diagnostic Report" } } , @{Name = "TABLE_NAME"; Expression = { "Diagnostic Report" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Document Reference" } } , @{Name = "TABLE_NAME"; Expression = { "Document Reference" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "dump" } } , @{Name = "TABLE_NAME"; Expression = { "dump" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "encounter" } } , @{Name = "TABLE_NAME"; Expression = { "encounter" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Fact_Airquality" } } , @{Name = "TABLE_NAME"; Expression = { "Fact_Airquality" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "HealthCare-FactSales" } } , @{Name = "TABLE_NAME"; Expression = { "HealthCare-FactSales" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "healthcare-pcr-json" } } , @{Name = "TABLE_NAME"; Expression = { "healthcare-pcr-json" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "healthcare-tablevalued" } } , @{Name = "TABLE_NAME"; Expression = { "healthcare-tablevalued" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Healthcare-Twitter-Data" } } , @{Name = "TABLE_NAME"; Expression = { "Healthcare-Twitter-Data" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "HospitalEmpPIIData" } } , @{Name = "TABLE_NAME"; Expression = { "HospitalEmpPIIData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "ImmunizationData" } } , @{Name = "TABLE_NAME"; Expression = { "ImmunizationData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Media" } } , @{Name = "TABLE_NAME"; Expression = { "Media" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "medication request" } } , @{Name = "TABLE_NAME"; Expression = { "medication request" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Miamihospitaloverview_Bed Occupancy" } } , @{Name = "TABLE_NAME"; Expression = { "Miamihospitaloverview_Bed Occupancy" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Mkt_CampaignAnalyticLatest" } } , @{Name = "TABLE_NAME"; Expression = { "Mkt_CampaignAnalyticLatest" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Mkt_WebsiteSocialAnalyticsPBIData" } } , @{Name = "TABLE_NAME"; Expression = { "Mkt_WebsiteSocialAnalyticsPBIData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "new race" } } , @{Name = "TABLE_NAME"; Expression = { "new race" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "observation" } } , @{Name = "TABLE_NAME"; Expression = { "observation" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "patient" } } , @{Name = "TABLE_NAME"; Expression = { "patient" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PatientInformation" } } , @{Name = "TABLE_NAME"; Expression = { "PatientInformation" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiBedOccupancyForecasted" } } , @{Name = "TABLE_NAME"; Expression = { "pbiBedOccupancyForecasted" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiDepartment" } } , @{Name = "TABLE_NAME"; Expression = { "pbiDepartment" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiManagementEmployee" } } , @{Name = "TABLE_NAME"; Expression = { "pbiManagementEmployee" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiPatient" } } , @{Name = "TABLE_NAME"; Expression = { "pbiPatient" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pbiPatientSurvey" } } , @{Name = "TABLE_NAME"; Expression = { "pbiPatientSurvey" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PbiReadmissionPrediction" } } , @{Name = "TABLE_NAME"; Expression = { "PbiReadmissionPrediction" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "PbiWaitTimeForecast" } } , @{Name = "TABLE_NAME"; Expression = { "PbiWaitTimeForecast" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "pred_anomaly" } } , @{Name = "TABLE_NAME"; Expression = { "pred_anomaly" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "race mapping" } } , @{Name = "TABLE_NAME"; Expression = { "race mapping" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "RoleNew" } } , @{Name = "TABLE_NAME"; Expression = { "RoleNew" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkCosmosDBKPIs" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkCosmosDBKPIs" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkCosmosDBLast3HoursQuality" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkCosmosDBLast3HoursQuality" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkCosmosDBLast7HoursQualityVerified" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkCosmosDBLast7HoursQualityVerified" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkCosmosDBWorkload" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkCosmosDBWorkload" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynapseLinkLabData" } } , @{Name = "TABLE_NAME"; Expression = { "SynapseLinkLabData" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "SynPatient" } } , @{Name = "TABLE_NAME"; Expression = { "SynPatient" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Vitals Graph" } } , @{Name = "TABLE_NAME"; Expression = { "Vitals Graph" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
    $list = $dataTableList.Add($temp)
    $temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = { "Web table" } } , @{Name = "TABLE_NAME"; Expression = { "Web table" } }, @{Name = "DATA_START_ROW_NUMBER"; Expression = { 2 } }
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
