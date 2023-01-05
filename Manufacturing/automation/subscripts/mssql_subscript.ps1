#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#will be done as part of the cloud shell start - README

#remove-item MfgAI -recurse -force
#git clone -b real-time https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git MfgAI

#cd 'MfgAI/Manufacturing/automation'

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

#User Inputs
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$concatString = "$init$random"
$mssql_server_name = "sqlserver-$suffix"
$mssql_db_name = "wwi"
$mssql_admin_user = "labsqladmin"
$keyVaultName = "kv-$init";

$dataLakeAccountName = "dreamdemostrggen2"+($concatString.substring(0,7))
$synapseWorkspaceName = "manufacturingdemo$init$random"
$subscriptionId = (Get-AzContext).Subscription.Id

$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
New-AzRoleAssignment -Objectid $id -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;
New-AzRoleAssignment -SignInName $username -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName" -ErrorAction SilentlyContinue;

Write-Host "Setting Key Vault Access Policy"
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

Write-Host  "-----------------MSSQL server --------------"

#creating sql schema
Write-Host "Create tables in SQL DB"
$MSSQLScriptsPath="./artifacts/mssql"
$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/Schema-SQL.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

Write-Host "adding tables data in SQL DB"
$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/AspNetUsers.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/Categories.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/dms_truncation_safeguard.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/Orders.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/Products.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/OrderDetails.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/CartItems.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/Stores.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($MSSQLScriptsPath)/RainChecks.txt"
$sqlEndpoint="$($mssql_server_name).database.windows.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $mssql_db_name -Username $mssql_admin_user -Password $sqlPassword
Add-Content log.txt $result
