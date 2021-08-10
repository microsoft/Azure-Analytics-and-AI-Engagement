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
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$deploymentId = $init
$mssql_server_name = "dbserver-marketingdata-$suffix"
$server  = $mssql_server_name+".database.windows.net"
$mssql_administrator_login = "labsqladmin"
$mssql_database_name = "db-geospatial"
$keyVaultName = "kv-$suffix";
$synapseWorkspaceName = "synapsefsi$init$random"
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id

Write-Host "Setting Key Vault Access Policy"
#Import-Module Az.KeyVault
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -UserPrincipalName $userName -PermissionsToSecrets set,get,list
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ObjectId $id -PermissionsToSecrets set,get,list

#$sqlPassword = $(Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword").SecretValueText
$secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
try {
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$sqlPassword = $secretValueText
$mssql_administrator_password = $sqlPassword

#MSSQL
Write-Host  "-----------Uploading MSSQL Data ---------------"
$SQLScriptsPath="../artifacts/sqlscripts"
$ip = Invoke-WebRequest https://api.ipify.org/
az sql server firewall-rule create `
    --name externalip `
    --resource-group $rgName `
    --server $mssql_server_name `
    --start-ip-address $ip.Content `
    --end-ip-address $ip.Content

Write-Host  "-----------Creating MSSQL Schema -------"
Invoke-Sqlcmd -ServerInstance $server `
    -Username $mssql_administrator_login `
    -Password $mssql_administrator_password `
    -Database $mssql_database_name `
    -InputFile "$($SQLScriptsPath)/sql-geospatial-schema.sql"  

Write-Host  "-----------Uploading MSSQL Data -------"
Invoke-Sqlcmd -ServerInstance $server `
    -Username $mssql_administrator_login `
    -Password $mssql_administrator_password `
    -Database $mssql_database_name `
    -InputFile "$($SQLScriptsPath)/sql-geospatial-data.sql"
	
az sql server firewall-rule delete `
    --name externalip `
    --resource-group $rgName `
    --server $mssql_server_name
	