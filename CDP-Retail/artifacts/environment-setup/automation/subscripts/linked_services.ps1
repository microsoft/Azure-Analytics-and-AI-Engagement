function List-StorageAccountKeys {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $Name
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($Name)/listKeys?api-version=2015-05-01-preview"

    Write-Debug "Calling endpoint $uri"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method POST -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
 
    Write-Debug $result

    return $result.key1
}

function Create-KeyVaultLinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name
    )

    $keyVaultTemplate = Get-Content -Path "$($TemplatesPath)/key_vault_linked_service.json"
    $keyVault = $keyVaultTemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#KEY_VAULT_NAME#", $Name)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedservices/$($Name)?api-version=2019-06-01-preview"


    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $keyVault -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 
    return $result
}

function Create-PowerBILinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceId
    )

    $powerBITemplate = Get-Content -Path "$($TemplatesPath)/powerbi_linked_service.json"
    $powerBI = $powerBITemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#POWERBI_WORKSPACE_ID#", $WorkspaceId)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedservices/$($Name)?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $powerBI -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
 
    return $result
}

function Create-DataLakeLinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $Key
    )

    $itemTemplate = Get-Content -Path "$($TemplatesPath)/data_lake_linked_service.json"
    $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#STORAGE_ACCOUNT_NAME#", $Name).Replace("#STORAGE_ACCOUNT_KEY#", $Key)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedservices/$($Name)?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    return $result
}

function Create-SQLPoolKeyVaultLinkedService {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [String]
    $DatabaseName,

    [parameter(Mandatory=$true)]
    [String]
    $UserName,

    [parameter(Mandatory=$true)]
    [String]
    $KeyVaultLinkedServiceName,

    [parameter(Mandatory=$true)]
    [String]
    $SecretName
    )

    $itemTemplate = Get-Content -Path "$($TemplatesPath)/sql_pool_key_vault_linked_service.json"
    $item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", $Name).Replace("#WORKSPACE_NAME#", $WorkspaceName).Replace("#DATABASE_NAME#", $DatabaseName).Replace("#USER_NAME#", $UserName).Replace("#KEY_VAULT_LINKED_SERVICE_NAME#", $KeyVaultLinkedServiceName).Replace("#SECRET_NAME#", $SecretName)
    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/linkedServices/$($Name)?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"

    return $result
}

function Create-IntegrationRuntime {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TemplatesPath,

    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,

    [parameter(Mandatory=$true)]
    [Int32]
    $CoreCount,

    [parameter(Mandatory=$true)]
    [Int32]
    $TimeToLive
    )

    $integrationRuntimeTemplate = Get-Content -Path "$($TemplatesPath)/integration_runtime.json"
    $integrationRuntime = $integrationRuntimeTemplate.Replace("#INTEGRATION_RUNTIME_NAME#", $Name).Replace("#CORE_COUNT#", $CoreCount).Replace("#TIME_TO_LIVE#", $TimeToLive)
    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/integrationruntimes/$($Name)?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $integrationRuntime -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
 
    return $result
}

function Wait-ForOperation {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$false)]
    [String]
    $OperationId
    )

    if ([string]::IsNullOrWhiteSpace($OperationId)) {
        Write-Information "Cannot wait on an empty operation id."
        return
    }

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/operationResults/$($OperationId)?api-version=2019-06-01-preview"
    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }

    while ($result.status -ne $null) {
        
        if ($result.status -eq "Failed") {
            throw $result.error
        }

        Write-Information "Waiting for operation to complete (status is $($result.status))..."
        Start-Sleep -Seconds 10
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    }

    return $result
}


function Assign-SynapseRole {

    param(    
    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $RoleId,

    [parameter(Mandatory=$true)]
    [String]
    $PrincipalId
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/rbac/roleAssignments?api-version=2020-02-01-preview"
    $method = "POST"

    $id = $RoleId + "-" + $PrincipalId
    $body = "{ id: ""$id"", roleId: ""$RoleId"", principalId: ""$PrincipalId"" }"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method $method -Body $body -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    return $result
}

function Refresh-Token {
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TokenType
    )

    if(Test-Path C:\LabFiles\AzureCreds.ps1){
        if ($TokenType -eq "Synapse") {
            $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                -Method POST -Body $global:ropcBodySynapse -ContentType "application/x-www-form-urlencoded"
            $global:synapseToken = $result.access_token
        } elseif ($TokenType -eq "SynapseSQL") {
            $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                -Method POST -Body $global:ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
            $global:synapseSQLToken = $result.access_token
        } elseif ($TokenType -eq "Management") {
            $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                -Method POST -Body $global:ropcBodyManagement -ContentType "application/x-www-form-urlencoded"
            $global:managementToken = $result.access_token
        } elseif ($TokenType -eq "PowerBI") {
            $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($global:logindomain)/oauth2/v2.0/token" `
                -Method POST -Body $global:ropcBodyPowerBI -ContentType "application/x-www-form-urlencoded"
            $global:powerbitoken = $result.access_token
        }
        else {
            throw "The token type $($TokenType) is not supported."
        }
    } else {
        switch($TokenType) {
            "Synapse" {
                $tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
                $global:synapseToken = $tokenValue; 
                break;
            }
            "SynapseSQL" {
                $tokenValue = ((az account get-access-token --resource https://sql.azuresynapse.net) | ConvertFrom-Json).accessToken
                $global:synapseSQLToken = $tokenValue; 
                break;
            }
            "Management" {
                $tokenValue = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
                $global:managementToken = $tokenValue; 
                break;
            }
            "PowerBI" {
                $tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
                $global:powerbitoken = $tokenValue; 
                break;
            }
            default {throw "The token type $($TokenType) is not supported.";}
        }
    }
}

function Ensure-ValidTokens {
	
    for ($i = 0; $i -lt $tokenTimes.Count; $i++) {
        Ensure-ValidToken $($tokenTimes.Keys)[$i]
    }
}


function Ensure-ValidToken {
    param(
        [parameter(Mandatory=$true)]
        [String]
        $TokenName
    )

    $refTime = Get-Date

    if (($refTime - $tokenTimes[$TokenName]).TotalMinutes -gt 30) {
        Write-Information "Refreshing $($TokenName) token."
        Refresh-Token $TokenName
        $tokenTimes[$TokenName] = $refTime
    }
}


Write-Information "Assign Ownership to Proctors on Synapse Workspace"
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "6e4bf58a-b8e1-4cc3-bbf9-d73143322b78" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Workspace Admin
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "7af0c69a-a548-47d6-aea3-d00e69bd83aa" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # SQL Admin
Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "c3a6d2f1-a26f-4810-9b0f-591308d5cbf1" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Apache Spark Admin

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
        if($subs.GetType().IsArray -and $subs.length -gt 1){
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

$resourceGroups = az group list --query '[].name' -o tsv 

if($resourceGroups.GetType().IsArray -and $resourceGroups.length -gt 1){
    $rgOptions = [System.Collections.ArrayList]::new()
    for($rgIdx=0; $rgIdx -lt $resourceGroups.length; $rgIdx++){
        $optionName = $resourceGroups[$rgIdx]
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($optionName)", "Selects the $($resourceGroups[$rgIdx]) resource group."   
        $rgOptions.Add($opt)
    }
    $selectedRgIdx = $host.ui.PromptForChoice('Enter the desired Resource Group for this lab','Copy and paste the name of the resource group to make your choice.', $rgOptions.ToArray(),0)
    $resourceGroupName = $resourceGroups[$selectedRgIdx]
    Write-Information "Selecting the $resourceGroupName resource group"
}
else{
$resourceGroupName=$resourceGroups
Write-Information "Selecting the $resourceGroupName resource group"
}

$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$subscriptionId = (Get-AzContext).Subscription.Id
$keyVaultName = "asaexpkeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASAEXP"
$sqlPoolName = "SQLPool01"

$workspaceName = "asaexpworkspace$($uniqueId)"
$dataLakeAccountName = "asaexpdatalake$($uniqueId)"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$powerBIName = "asaexppowerbi$($uniqueId)"

$principal=az resource show -g $resourceGroupName -n $asaName --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
$wsId=Read-Host "Enter your powerBi workspace Id entered during template deployment"
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Contributor

Write-Information "Create KeyVault linked service $($keyVaultName)"

$result = Create-KeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $keyVaultName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create Integration Runtime $($integrationRuntimeName)"

$result = Create-IntegrationRuntime -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $integrationRuntimeName -CoreCount 16 -TimeToLive 60
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create Data Lake linked service $($dataLakeAccountName)"

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName
$result = Create-DataLakeLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $dataLakeAccountName  -Key $dataLakeAccountKey
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asaexp.sql.admin"

$linkedServiceName = $sqlPoolName.ToLower()
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                 -UserName "asaexp.sql.admin" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Copy TwitterData to Data Lake"

$publicDataUrl = "https://retailpocstorage.blob.core.windows.net/"
$dataLakeStorageUrl = "https://"+ $dataLakeAccountName + ".dfs.core.windows.net/"
$dataLakeStorageBlobUrl = "https://"+ $dataLakeAccountName + ".blob.core.windows.net/"

Write-Information "Create PowerBI linked service $($keyVaultName)"

$result = Create-PowerBILinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $powerBIName -WorkspaceId $wsid
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Refresh-Token -TokenType PowerBI
