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

    function RefreshTokens()
    {
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

    $response = az ad signed-in-user show | ConvertFrom-Json
    $date = get-date
    $demoType = "OpenAI"
    $body = '{"demoType":"#demoType#","userPrincipalName":"#userPrincipalName#","displayName":"#displayName#","companyName":"#companyName#","mail":"#mail#","date":"#date#"}'
    $body = $body.Replace("#userPrincipalName#", $response.userPrincipalName)
    $body = $body.Replace("#displayName#", $response.displayName)
    $body = $body.Replace("#companyName#", $response.companyName)
    $body = $body.Replace("#mail#", $response.mail)
    $body = $body.Replace("#date#", $date)
    $body = $body.Replace("#demoType#", $demoType)

    $uri = "https://registerddibuser.azurewebsites.net/api/registeruser?code=pTrmFDqp25iVSxrJ/ykJ5l0xeTOg5nxio9MjZedaXwiEH8oh3NeqMg=="
    $result = Invoke-RestMethod  -Uri $uri -Method POST -Body $body -Headers @{} -ContentType "application/json"

    [string]$suffix =  -join ((48..57) + (97..122) | Get-Random -Count 7 | % {[char]$_})
    $rgName = "fabric-dpoc-$suffix"
    $Region = read-host "Enter the region for deployment"    
    $databricks_name="databricks$suffix"
    $databricks_rgname="databricks-rg$suffix"
    $namespaces_adx_thermostat_occupancy_name = "adx-thermostat-occupancy-$suffix"
    $sites_adx_thermostat_realtime_name = "app-realtime-kpi-analytics-$suffix"
    $serverfarm_adx_thermostat_realtime_name = "asp-realtime-kpi-analytics-$suffix"
    $subscriptionId = (Get-AzContext).Subscription.Id
    $tenantId = (Get-AzContext).Tenant.Id
    $storage_account_name = "storage$suffix"
    $mssql_server_name = "mssql$suffix"
    $mssql_database_name = "SalesDb"
    $mssql_administrator_login = "labsqladmin"
    $complexPassword = 0
    $sql_administrator_login_password=""
    while ($complexPassword -ne 1)
    {
        $sql_administrator_login_password = Read-Host "Enter a password to use for the $mssql_administrator_login login.
        `The password must meet complexity requirements:
        ` - Minimum 8 characters. 
        ` - At least one upper case English letter [A-Z]
        ` - At least one lower case English letter [a-z]
        ` - At least one digit [0-9]
        ` - At least one special character (!,@,#,%,^,&,$)
        ` "

        if(($sql_administrator_login_password -cmatch '[a-z]') -and ($sql_administrator_login_password -cmatch '[A-Z]') -and ($sql_administrator_login_password -match '\d') -and ($sql_administrator_login_password.length -ge 8) -and ($sql_administrator_login_password -match '!|@|#|%|^|&|$'))
        {
            $complexPassword = 1
        Write-Output "Password $sql_administrator_login_password accepted. Make sure you remember this!"
        }
        else
        {
            Write-Output "$sql_administrator_login_password does not meet the compexity requirements."
        }
    }


    Write-Host "Creating $rgName resource group in $Region ..."
    New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
    Write-Host "Resource group $rgName creation COMPLETE"

    Write-Host "Creating resources in $rgName..."
    New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile "mainTemplate.json" `
    -Mode Complete `
    -location $Region `
    -databricks_workspace_name $databricks_name `
    -databricks_managed_resource_group_name $databricks_rgname `
    -sites_adx_thermostat_realtime_name $sites_adx_thermostat_realtime_name `
    -serverfarm_adx_thermostat_realtime_name $serverfarm_adx_thermostat_realtime_name `
    -namespaces_adx_thermostat_occupancy_name $namespaces_adx_thermostat_occupancy_name `
    -storage_account_name $storage_account_name `
    -mssql_server_name $mssql_server_name `
    -mssql_database_name $mssql_database_name `
    -mssql_administrator_login $mssql_administrator_login `
    -sql_administrator_login_password $sql_administrator_login_password `
    -Force

    Write-Host "Resource creation $rgName COMPLETE"

    $thermostat_telemetry_Realtime_URL =  ""
    $occupancy_data_Realtime_URL =  ""

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
            "min_workers": 2,
            "max_workers": 4
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
    $app = az ad app create --display-name "fabric $suffix" | ConvertFrom-Json
    $clientId = $app.appId
    $appCredential = az ad app credential reset --id $clientId | ConvertFrom-Json
    $clientsecpwd = $appCredential.password
    $appid = az ad app show --id $clientid | ConvertFrom-Json
    $appid = $appid.appid
    az ad sp create --id $clientId | Out-Null
    $principalId = az ad sp show --id $clientId --query "id" -o tsv
    New-AzRoleAssignment -Objectid $principalId -RoleDefinitionName "Contributor" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Databricks/workspaces/$databricks_name" -ErrorAction SilentlyContinue;

    (Get-Content -path "artifacts/databricks/01_Setup-Onelake_Integration_with_Databrick.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#TENANT_ID#', $tenantid `
            -replace '#SECRET_KEY#', $clientsecpwd `
            -replace '#APP_ID#', $appid `
    } | Set-Content -Path "artifacts/databricks/01_Setup-Onelake_Integration_with_Databrick.ipynb"

    (Get-Content -path "artifacts/databricks/03_ML_Solutions_in_a_Box.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#DATABRICKS_TOKEN#', $pat_token `
            -replace '#WORKSPACE_URL#', $baseUrl `
    } | Set-Content -Path "artifacts/databricks/03_ML_Solutions_in_a_Box.ipynb"

    $files = Get-ChildItem -path "artifacts/databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
    Set-Location ./artifacts/databricks
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
    Set-Location ../../

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

    ## storage AZ Copy
    $storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storage_account_name)[0].Value
    $dataLakeContext = New-AzStorageContext -StorageAccountName $storage_account_name -StorageAccountKey $storage_account_key

    $destinationSasKey = New-AzStorageContainerSASToken -Container "adlsfabricshortcut" -Context $dataLakeContext -Permission rwdl
    $destinationSasKey = "?$destinationSasKey"
    $destinationUri = "https://$($storage_account_name).blob.core.windows.net/adlsfabricshortcut$($destinationSasKey)"
    & $azCopyCommand copy "https://fabricddib.blob.core.windows.net/adlsfabricshortcut/" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "bronzeshortcutdata" -Context $dataLakeContext -Permission rwdl
    $destinationSasKey = "?$destinationSasKey"
    $destinationUri = "https://$($storage_account_name).blob.core.windows.net/bronzeshortcutdata$($destinationSasKey)"
    & $azCopyCommand copy "https://fabricddib.blob.core.windows.net/bronzeshortcutdata/" $destinationUri --recursive

    $destinationSasKey = New-AzStorageContainerSASToken -Container "data-source" -Context $dataLakeContext -Permission rwdl
    $destinationSasKey = "?$destinationSasKey"
    $destinationUri = "https://$($storage_account_name).blob.core.windows.net/data-source$($destinationSasKey)"
    & $azCopyCommand copy "https://fabricddib.blob.core.windows.net/data-source/" $destinationUri --recursive

    # $destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
    # $destinationUri = "https://$($storage_account_name).blob.core.windows.net/webappassets$($destinationSasKey)"
    # & $azCopyCommand copy "https://fabricddib.blob.core.windows.net/webappassets/" $destinationUri --recursive

    ## mssql
    Add-Content log.txt "-----Ms Sql-----"
    Write-Host "----Ms Sql----"
    $SQLScriptsPath="./artifacts/sqlscripts"
    $sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/salesSqlDbScript.sql"
    $sqlEndpoint="$($mssql_server_name).database.windows.net"
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_database_name -Username $mssql_administrator_login -Password $sql_administrator_login_password
    Add-Content log.txt $result

    #Web app
    Add-Content log.txt "------deploy poc web app------"
    Write-Host  "-----------------Deploy web app---------------"
    RefreshTokens

    $zips = @("app-adx-thermostat-realtime")
    foreach($zip in $zips)
    {
        expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
    }

    # ADX Thermostat Realtime
    $occupancy_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name occupancy --name occupancy | ConvertFrom-Json
    $occupancy_endpoint = $occupancy_endpoint.primaryConnectionString
    $thermostat_endpoint = az eventhubs eventhub authorization-rule keys list --resource-group $rgName --namespace-name $namespaces_adx_thermostat_occupancy_name --eventhub-name thermostat --name thermostat | ConvertFrom-Json
    $thermostat_endpoint = $thermostat_endpoint.primaryConnectionString

    (Get-Content -path adx-config-appsetting.json -Raw) | Foreach-Object { $_ `
        -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_THERMOSTAT_ENDPOINT#', $thermostat_endpoint`
        -replace '#NAMESPACES_ADX_THERMOSTAT_OCCUPANCY_OCCUPANCY_ENDPOINT#', $occupancy_endpoint`
    -replace '#THERMOSTATTELEMETRY_URL#', $thermostat_telemetry_Realtime_URL`
    -replace '#OCCUPANCYDATA_URL#', $occupancy_data_Realtime_URL`
    } | Set-Content -Path adx-config-appsetting-with-replacement.json

    $config = az webapp config appsettings set -g $rgName -n $sites_adx_thermostat_realtime_name --settings @adx-config-appsetting-with-replacement.json

    # Publish-AzWebApp -ResourceGroupName $rgName -Name $sites_adx_thermostat_realtime_name -ArchivePath ./artifacts/binaries/app-adx-thermostat-realtime.zip -Force

    Write-Information "Deploying ADX Thermostat Realtime App"
    cd app-adx-thermostat-realtime
    az webapp up --resource-group $rgName --name $sites_adx_thermostat_realtime_name --plan $serverfarm_adx_thermostat_realtime_name --location $Region
    cd ..
    Start-Sleep -s 10

    az webapp start --name $sites_adx_thermostat_realtime_name --resource-group $rgName

    $endtime=get-date
    $executiontime=$endtime-$starttime
    Write-Host "Execution Time"$executiontime.TotalMinutes
    Add-Content log.txt "-----------------Execution Complete---------------"

    Write-Host  "-----------------Execution Complete----------------"
}