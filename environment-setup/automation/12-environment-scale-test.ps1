Remove-Module solliance-synapse-automation
Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

$InformationPreference = "Continue"



# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB

#Connect-AzAccount            # YOU SHOULD LOGIN with INSTRUCTOR LOGIN
$userName="your_instructor_email"
$password="your_instructor_Password"

$subs = Get-AzSubscription | Where-Object { $_.Name -like "*Azure Labs C*" -or $_.Name -like "*Azure Labs D*" } | Sort-Object -Property Name


#Select-AzSubscription -Subscription $sub.Id | Out-Null
foreach($sub in $subs)
{
    Select-AzSubscription -Subscription $sub.Id 

    $rgs = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like 'synapse-*' -and $_.Tags['LaunchId'] -eq '6648' }    
    foreach($rg in $rgs)
    {
        $clientId="1950a258-227b-4e31-a9cf-717495945fc2"
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

        $ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
        $ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
        $ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
        $ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"

        $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                        -Method POST -Body $ropcBodySynapse -ContentType "application/x-www-form-urlencoded"
        $synapseToken = $result.access_token
        $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                        -Method POST -Body $ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
        $synapseSQLToken = $result.access_token
        $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
                        -Method POST -Body $ropcBodyManagement -ContentType "application/x-www-form-urlencoded"
        $managementToken = $result.access_token

        $resourceGroupName
        Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW3000c -Token $managementToken
        #Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW500c -Token $managementToken
    }
}

#Logout-AzAccount


