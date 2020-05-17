Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB

#Connect-AzAccount                            # login using msazurelabs account
#$subs = Get-AzSubscription | Where-Object { $_.Name -like "*Azure Labs C*" -or $_.Name -like "*Azure Labs D*" } | Sort-Object -Property Name
$subs = Get-AzSubscription | Where-Object { $_.Name -like "*Azure Labs D*" } | Sort-Object -Property Name

#Select-AzSubscription -Subscription $sub.Id | Out-Null
foreach($sub in $subs)
{
    Select-AzSubscription -Subscription $sub.Id 

    $rgs = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like 'synapse-*' -and $_.Tags['LaunchId'] -eq '6648' }    
    foreach($rg in $rgs)
    {
        $resourceGroupName = $rg.ResourceGroupName
        $uniqueId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]
        $subscriptionId = $sub.Id
        $tenantId = $sub.TenantId

        $templatesPath = ".\artifacts\environment-setup\templates"
        $datasetsPath = ".\artifacts\environment-setup\datasets"
        $pipelinesPath = ".\artifacts\environment-setup\pipelines"
        $sqlScriptsPath = ".\artifacts\environment-setup\sql"
        $workspaceName = "asaworkspace$($uniqueId)"
        $cosmosDbAccountName = "asacosmosdb$($uniqueId)"
        $cosmosDbDatabase = "CustomerProfile"
        $cosmosDbContainer = "OnlineUserProfile01"
        $dataLakeAccountName = "asadatalake$($uniqueId)"
        $blobStorageAccountName = "asastore$($uniqueId)"
        $keyVaultName = "asakeyvault$($uniqueId)"
        $keyVaultSQLUserSecretName = "SQL-USER-ASA"
        $sqlPoolName = "SQLPool01"

        $userObjectId = "odl_user_" + $uniqueId + "@msazurelabs.onmicrosoft.com"
        $asaWorkspaceObjectId  = (Get-AzADServicePrincipal -DisplayName $workspaceName).Id
        $amlWorkspaceObjectId  = (Get-AzADServicePrincipal -DisplayName $amlWorkspaceName).Id

        # Initial Validation
        Get-AzRoleAssignment -SignInName $userObjectId -ResourceGroupName $resourceGroupName -ResourceName $dataLakeAccountName -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Blob Data Contributor"
        Get-AzRoleAssignment -SignInName $userObjectId -ResourceGroupName $resourceGroupName -ResourceName $blobStorageAccountName -ResourceType "Microsoft.Storage/storageAccounts" -RoleDefinitionName "Storage Blob Data Contributor"
    }
}

#Logout-AzAccount


