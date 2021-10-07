#should auto for this.
az login

#if they have many subs...
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
    Write-Host "Selecting the $selectedSubName subscription"
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
}

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$location = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$synapseWorkspaceName = "synapsefsi$init$random"
$sqlPoolName = "FsiDW"
$concatString = "$init$random"
if($concatString.length -gt 16)
{
$dataLakeAccountName = "stfsi"+($concatString.substring(0,19))
}
else
{
	$dataLakeAccountName = "stfsi"+ $concatString
}
$sqlUser = "labsqladmin"
$databricks_workspace_name = "fsi-dbrs-$suffix"
$storageAccountName = $dataLakeAccountName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#databricks
Write-Host "--------- databricks---------"
$dbswsId = $(az resource show `
        --resource-type Microsoft.Databricks/workspaces `
        -g "$rgName" `
        -n "$databricks_workspace_name" `
        --query id -o tsv)

# Get a token for the global Databricks application.
# The resource ID is fixed and never changes.
$token_response = $(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d) | ConvertFrom-Json
$token = $token_response.accessToken

# Get a token for the Azure management API
$token_response = $(az account get-access-token --resource https://management.core.windows.net/) | ConvertFrom-Json
$azToken = $token_response.accessToken
$uri = "https://$($location).azuredatabricks.net/api/2.0/token/create"
$baseUrl = "https://$($location).azuredatabricks.net"

# You can also generate a PAT token. Note the quota limit of 600 tokens.
$body = '{"lifetime_seconds": 100000, "comment": "Ranatest" }';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")
$headers.Add("X-Databricks-Azure-SP-Management-Token", "$azToken")
$headers.Add("X-Databricks-Azure-Workspace-Resource-Id", "$dbswsId")
$pat_token = Invoke-RestMethod -Uri $uri -Method Post -Body $body -H $headers 
#Create a dir in dbfs & workspace to store the scipt files and init file
$requestHeaders = @{
    Authorization  = "Bearer" + " " + $pat_token.token_value
    "Content-Type" = "application/json"
}
    
$body = '{"path": "dbfs:/FileStore/geospatial_fraud_detection" }';
#get job list
$endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$body = '{"path": "dbfs:/FileStore/demo-fsi/geoscan/python" }';
#get job list
$endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

$body = '{"path": "dbfs:/FileStore/demo-fsi/geoscan/synapse_migration" }';   
#get job list
$endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body

 $body = '{"path": "dbfs:/FileStore/demo-fsi/geoscan/tables" }';   
#get job list
$endPoint = $baseURL + "/api/2.0/dbfs/mkdirs"
Invoke-RestMethod $endPoint `
    -Method Post `
    -Headers $requestHeaders `
    -Body $body   

(Get-Content -path ../artifacts/databricks/03_esg_market.ipynb -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path ../artifacts/databricks/03_esg_market.ipynb

(Get-Content -path ../artifacts/databricks/01_esg.ipynb -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path ../artifacts/databricks/01_esg.ipynb

(Get-Content -path ../artifacts/databricks/Customer_Churn.ipynb -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path ../artifacts/databricks/Customer_Churn.ipynb

(Get-Content -path ../artifacts/databricks/02_esg_scoring.scala -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path ../artifacts/databricks/02_esg_scoring.scala

(Get-Content -path ../artifacts/databricks/Fraud_Migration.ipynb -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_NAME#', $synapseWorkspaceName `
        -replace '#DATABASE_NAME#', $sqlPoolName `
        -replace '#SQL_USERNAME#', $sqlUser`
        -replace '#SQL_PASSWORD#', $sqlPassword `
        -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName `
        -replace '#STORAGE_ACCOUNT_KEY#', $storage_account_key `
} | Set-Content -Path ../artifacts/databricks/Fraud_Migration.ipynb

$files = Get-ChildItem -path "../artifacts/databricks" -File -Recurse  #all files uploaded in one folder change config paths in python jobs
Set-Location ../artifacts/databricks
foreach ($name in $files.name) {
  if( $name -eq "miami.csv" )
    {
          $fileContent = get-content -raw $name
          $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
          $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
          $requestHeaders = @{
              Authorization = "Bearer" + " " + $pat_token.token_value
          }
          $body = '{"path": "dbfs:/FileStore/geospatial_fraud_detection/miami.csv","contents":"' + $fileContentEncoded + '" }';
          #get job list
          $endPoint = $baseURL + "/api/2.0/dbfs/put"
          Invoke-RestMethod $endPoint `
              -ContentType 'application/json' `
              -Method Post `
              -Headers $requestHeaders `
              -Body $body
    }
    elseif( $name -eq "02_esg_scoring.scala" )
    { 
          $fileContent = get-content -raw $name
          $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
          $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
          $requestHeaders = @{
              Authorization = "Bearer" + " " + $pat_token.token_value
	      			}
          $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "SCALA", "format": "SOURCE"}'
          
	      			$endPoint = $baseURL + "/api/2.0/workspace/import"
	      			Invoke-RestMethod $endPoint `
              -ContentType 'application/json' `
              -Method Post `
              -Headers $requestHeaders `
              -Body $body
    } 
  else
    {
          $fileContent = get-content -raw $name
          $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
          $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)
          $requestHeaders = @{
              Authorization = "Bearer" + " " + $pat_token.token_value
	      			}
          $body = '{"content": "' + $fileContentEncoded + '",  "path": "/' + $name + '",  "language": "PYTHON","overwrite": true,  "format": "JUPYTER"}'
          
	      			$endPoint = $baseURL + "/api/2.0/workspace/import"
	      			Invoke-RestMethod $endPoint `
              -ContentType 'application/json' `
              -Method Post `
              -Headers $requestHeaders `
              -Body $body
    }
}
Set-Location ../../