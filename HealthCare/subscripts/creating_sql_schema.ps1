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
$sqlPoolName = "HealthCareDW"
$synapseWorkspaceName = "synapsehealthcare$init$random"
$sqlUser = "labsqladmin"
$keyVaultName = "kv-$init";
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText
$concatString = "$init$random"
$cosmos_account_name_heathcare = "cosmosdb-healthcare-$concatString"
if($cosmos_account_name_heathcare.length -gt 43 )
{
$cosmos_account_name_heathcare = $cosmos_account_name_heathcare.substring(0,43)
}
$cosmos_mongo_account_name_heathcare = "cosmos-healthcare-mongodb-$concatString" 
if($cosmos_mongo_account_name_heathcare.length -gt 43 )
{
$cosmos_mongo_account_name_heathcare = $cosmos_mongo_account_name_heathcare.substring(0,43)
}
$cosmos_account_key_mongo=az cosmosdb keys list -n $cosmos_mongo_account_name_heathcare -g $rgName |ConvertFrom-Json
$cosmos_account_key_mongo=$cosmos_account_key_mongo.primarymasterkey
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))

Write-Host "------sql schema-----"
RefreshTokens
#creating sql schema
Write-Host "Create tables in $($sqlPoolName)"
$SQLScriptsPath="../artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Write-Host $result

#$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
(Get-Content -path "$($SQLScriptsPath)/sqluser.sql" -Raw) | Foreach-Object { $_ `
                -replace '#SQL_PASSWORD#', $sqlPassword`		
        } | Set-Content -Path "$($SQLScriptsPath)/sqluser.sql"		
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Write-Host $result

$sqlQuery="CREATE USER [BillingStaff] FOR LOGIN [BillingStaff] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Write-Host $result

$sqlQuery="CREATE USER [ChiefOperatingManager] FOR LOGIN [ChiefOperatingManager] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Write-Host $result

$sqlQuery="CREATE USER [CareManagerLosAngeles] FOR LOGIN [CareManagerLosAngeles] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Write-Host $result

$sqlQuery="CREATE USER [CareManagerMiami] FOR LOGIN [CareManagerMiami] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Write-Host $result

$sqlQuery="CREATE USER [CareManager] FOR LOGIN [CareManager] WITH DEFAULT_SCHEMA=[dbo]"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Write-Host $result

$sqlQuery  = "CREATE DATABASE HealthCareSqlOnDemand"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database master -Username $sqlUser -Password $sqlPassword
Write-Host $result	
 
(Get-Content -path "$($SQLScriptsPath)/sqlOnDemandSchema.sql" -Raw) | Foreach-Object { $_ `
                -replace '#COSMOS_ACCOUNT_MONGO#', $cosmos_mongo_account_name_heathcare`
				-replace '#COSMOS_KEY_MONGO#', $cosmos_account_key_mongo`
                -replace '#STORAGE_ACCOUNT#', $dataLakeAccountName`            
        } | Set-Content -Path "$($SQLScriptsPath)/sqlOnDemandSchema.sql"		
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqlOnDemandSchema.sql"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database HealthCareSqlOnDemand -Username $sqlUser -Password $sqlPassword
Write-Host $result	
