function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

function ReplaceTokensInFile($ht, $filePath)
{
    $template = Get-Content -Raw -Path $filePath
	
    foreach ($paramName in $ht.Keys) 
    {
		$template = $template.Replace($paramName, $ht[$paramName])
	}

    return $template;
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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$keyVaultName = "kv-$suffix"
$sqlUser = "labsqladmin"
$synapseWorkspaceName = "synapsesustain$init$random"
$subscriptionId = (Get-AzContext).Subscription.Id
$sqlPoolName = "SustainabilityDW"
$concatString = "$init$random"
$dataLakeAccountName = "stsustain$concatString"
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

#Cosmos keys
$cosmos_account_key=az cosmosdb keys list -n $cosmosdb_sustainability_name -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

Write-Host "Setting Key Vault Access Policy"
#Import-Module Az.KeyVault
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,get,list
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText

Add-Content log.txt "------linked Services------"
Write-Host "----linked Services------"
#Creating linked services
RefreshTokens
$templatepath="../artifacts/linkedservices/"

# AutoResolveIntegrationRuntime
$FilePathRT="../artifacts/linkedservices/AutoResolveIntegrationRuntime.json" 
$itemRT = Get-Content -Path $FilePathRT
$uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
Add-Content log.txt $result

# IntegrationRuntime
$FilePathRT="../artifacts/linkedservices/IntegrationRuntime.json" 
$itemRT = Get-Content -Path $FilePathRT
$uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/IntegrationRuntime?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
Add-Content log.txt $result

##LsSustainSQLOnDemand
Write-Host "Creating linked Service: LsSustainSQLOnDemand"
$filepath=$templatepath+"LsSustainSQLOnDemand.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/LsSustainSQLOnDemand?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##AzureSynapseAnalytics1
Write-Host "Creating linked Service: AzureSynapseAnalytics1"
$filepath=$templatepath+"AzureSynapseAnalytics1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureSynapseAnalytics1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##cosmos linked service
Write-Host "Creating linked Service: cosmosdbsustainabilityprod"
$filepath=$templatepath+"cosmosdbsustainabilityprod.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmosdb_sustainability_name).Replace("#COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/cosmosdbsustainabilityprod?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# Oracle linked services
Write-Host "Creating linked Service: Oracle"
$filepath=$templatepath+"Oracle.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Oracle?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# retailsynapse
Write-Host "Creating linked Service: retailsynapse"
$filepath=$templatepath+"retailsynapse.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/retailsynapse?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##SapHana linked services
Write-Host "Creating linked Service: SapHana1"
$filepath=$templatepath+"SapHana1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# SustainSyn1
Write-Host "Creating linked Service: SustainSyn1"
$filepath=$templatepath+"SustainSyn1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SustainSyn1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##SynSustainabilityDW
Write-Host "Creating linked Service: SynSustainabilityDW"
$filepath=$templatepath+"SynSustainabilityDW.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SynSustainabilityDW?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# synsustainabilityprod-WorkspaceDefaultSqlServer
Write-Host "Creating linked Service: synsustainabilityprod-WorkspaceDefaultSqlServer"
$filepath=$templatepath+"synsustainabilityprod-WorkspaceDefaultSqlServer.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synsustainabilityprod-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# synsustainabilityprod-WorkspaceDefaultStorage
Write-Host "Creating linked Service: synsustainabilityprod-WorkspaceDefaultStorage"
$filepath=$templatepath+"synsustainabilityprod-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synsustainabilityprod-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# Teradata linked services
Write-Host "Creating linked Service: Teradata"
$filepath=$templatepath+"Teradata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result
