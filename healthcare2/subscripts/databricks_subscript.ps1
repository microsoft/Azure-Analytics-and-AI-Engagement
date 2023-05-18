function RefreshTokens() {
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

$rgName = read-host "Enter the resource Group Name"
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"] 
$suffix = "$random-$init"
$concatString = "$init$random"

$databricks_workspace_name = "databricks-hc2-$suffix"
$dataLakeAccountName = "sthealthcare2$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$subscriptionId = (Get-AzContext).Subscription.Id



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
(Get-Content -path "../artifacts/databricks/BedOccupancy_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/BedOccupancy_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/BedOccupancySupplierAQI_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/BedOccupancySupplierAQI_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/CallCenter_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/CallCenter_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/Campaigns_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/Campaigns_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/Consolidated_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/Consolidated_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/HospitalInfo_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/HospitalInfo_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/Misc_dlt.ipynb" -Raw) | Foreach-Object { $_ `
            -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/Misc_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/Patient Profile dlt.ipynb" -Raw) | Foreach-Object { $_ `
        -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/Patient Profile dlt.ipynb"

(Get-Content -path "../artifacts/databricks/PatientExperience_dlt.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/PatientExperience_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/PatientParm_dlt.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/PatientParm_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/PatientPredictive_dlt.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/PatientPredictive_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/PbiPatientPredictive_dlt.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/PbiPatientPredictive_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/Predctive_dlt.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/Predctive_dlt.ipynb"
            
(Get-Content -path "../artifacts/databricks/Sales_dlt.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/Sales_dlt.ipynb"

(Get-Content -path "../artifacts/databricks/TotalBed_dlt.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/TotalBed_dlt.ipynb"
    
(Get-Content -path "../artifacts/databricks/USMap_dlt.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/USMap_dlt.ipynb"
      
(Get-Content -path "../artifacts/databricks/Initial setup.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $dataLakeAccountName `
    } | Set-Content -Path "../artifacts/databricks/Initial setup.ipynb"
    
    $files = Get-ChildItem -path "../artifacts/databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
    Set-Location ../../artifacts/databricks
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
