function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#will be done as part of the cloud shell start - README

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

$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$synapseWorkspaceName = "synapsehealthcare$init$random"
$sqlPoolName = "HealthCareDW"
$sqlUser = "labsqladmin"
$subscriptionId = (Get-AzContext).Subscription.Id
$keyVaultName = "kv-$init";
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText
$cosmos_account_name_heathcare = "cosmosdb-healthcare-$concatString"
if($cosmos_account_name_heathcare.length -gt 43 )
{
$cosmos_account_name_heathcare = $cosmos_account_name_heathcare.substring(0,43)
}
$cosmos_database_name_healthcare = "healthcare"
#Cosmos keys
$cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name_heathcare -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value

Write-Host "------linked Services------"
#Creating linked services
RefreshTokens

$templatepath="../artifacts/templates/"

##cosmos linked services
$filepath=$templatepath+"HealthCareCosmosDb.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name_heathcare).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key).Replace("#COSMOS_DATABASE#", $cosmos_database_name_healthcare)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/HealthCareCosmosDb?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result
 
##Datalake linked services
$filepath=$templatepath+"HealthCareDataLakeStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/HealthCareDataLakeStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

##IOT Datalake linked services
$filepath=$templatepath+"IOT Data.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/IOT Data?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result
   
##Staging Datalake linked services
$filepath=$templatepath+"Staging.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Staging?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

##synapsehealthcare Datalake linked services
$filepath=$templatepath+"synapsehealthcaredev-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synapsehealthcaredev-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

##blob linked services
$filepath=$templatepath+"tweetstoblob.json"
$itemTemplate = Get-Content -Path $filepath
$name=$dataLakeAccountName+"blob"
$blobLinkedService=$name
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName).Replace("#STORAGE_ACCOUNT_KEY#", $storage_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/tweetstoblob?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result
 
##sql pool linked services
$filepath=$templatepath+"HealthCareSynapse.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/HealthCareSynapse?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

##synapse sql pool linked services
$filepath=$templatepath+"synapsehealthcaredev-WorkspaceDefaultSqlServer.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synapsehealthcaredev-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

##sap hana linked services
$filepath=$templatepath+"SapHana.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

##Dynamics linked services
$filepath=$templatepath+"DynamicsHealthCare.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/DynamicsHealthCare?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result
 
##powerbi linked services
$filepath=$templatepath+"powerbi_linked_service.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "HealthCareDemo").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/powerbi_linked_service?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

 ##Teradata linked services
$filepath=$templatepath+"Teradata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "Teradata").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

##Oracle linked services
$filepath=$templatepath+"Oracle.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "Oracle").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Oracle?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Write-Host $result

#AutoResolveIntegrationRuntime
    $FilePathRT="../artifacts/templates/AutoResolveIntegrationRuntime.json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
 Write-Host $result

#SelfHostedIntegrationRuntime
$integrationRuntimePath="../artifacts/IntergationRuntimes";	
$integrationRuntimes=Get-ChildItem "../artifacts/IntergationRuntimes" | Select BaseName
foreach ($integrationRuntime in $integrationRuntimes) 
{
    $FilePathRT="$($integrationRuntimePath)/$($integrationRuntime.BaseName).json" 
    $itemRT = Get-Content -Path $FilePathRT
    $uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/$($integrationRuntime.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
    Write-Host $result
}
