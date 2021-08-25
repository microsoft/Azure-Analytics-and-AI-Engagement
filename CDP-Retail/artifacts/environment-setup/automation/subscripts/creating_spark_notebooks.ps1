function Create-SparkNotebook {
    
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
        $SparkPoolName,
    
        [parameter(Mandatory=$true)]
        [String]
        $Name,
    
        [parameter(Mandatory=$true)]
        [String]
        $NotebookFileName,
    
        [parameter(Mandatory=$false)]
        [String]
        $TemplateFileName = "spark_notebook",
    
        [parameter(Mandatory=$false)]
        [Hashtable]
        $CellParams
        )
    
    
        $item = Get-Content -Raw -Path "$($TemplatesPath)/$($TemplateFileName).json"
        $params = @{
            "#NOTEBOOK_NAME#" = $Name
            "#SPARK_POOL_NAME#" = $SparkPoolName
            "#SUBSCRIPTION_ID#" = $SubscriptionId
            "#RESOURCE_GROUP_NAME#" = $ResourceGroupName
            "#WORKSPACE_NAME#" = $WorkspaceName
        }
        foreach ($paramName in $params.Keys) {
            $item = $item.Replace($paramName, $params[$paramName])
        }
        $jsonItem = ConvertFrom-Json $item
        
        $notebook = Get-Content -Raw -Path $NotebookFileName
        $jsonNotebook = ConvertFrom-Json $notebook
        
        $jsonItem.properties.cells = $jsonNotebook.cells
    
        if ($CellParams) {
            foreach ($cellParamName in $cellParams.Keys) {
                foreach ($cell in $jsonItem.properties.cells) {
                    for ($i = 0; $i -lt $cell.source.Count; $i++) {
                        $cell.source[$i] = $cell.source[$i].Replace($cellParamName, $CellParams[$cellParamName])
                    }
                }
            }
        }
        
        $item = ConvertTo-Json $jsonItem -Depth 100
    
        $uri = "https://$($WorkspaceName).dev.azuresynapse.net/notebooks/$($Name)?api-version=2019-06-01-preview"
    
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
        
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
    
    Write-Information "Assign Ownership to Proctors on Synapse Workspace"
    Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "6e4bf58a-b8e1-4cc3-bbf9-d73143322b78" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Workspace Admin
    Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "7af0c69a-a548-47d6-aea3-d00e69bd83aa" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # SQL Admin
    Assign-SynapseRole -WorkspaceName $workspaceName -RoleId "c3a6d2f1-a26f-4810-9b0f-591308d5cbf1" -PrincipalId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e"  # Apache Spark Admin
    
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
        
        $templatesPath = "..\templates"

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
$workspaceName = "asaexpworkspace$($uniqueId)"
$sqlPoolName = "SQLPool01"
$amlWorkspaceName = "amlworkspace$($uniqueId)"
$subscriptionId = (Get-AzContext).Subscription.Id
$dataLakeAccountName = "asaexpdatalake$($uniqueId)"
$sparkPoolName = "SparkPool01"

Write-Information "Creating Spark notebooks..."

$notebooks = [ordered]@{
        "3 Campaign Analytics Data Prep"    = "..\notebooks"
        "1 Products Recommendation"   = "..\notebooks"
        "2 AutoML Number of Customer Visit to Department" = "..\notebooks"
}

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $resourceGroupName
        "#AML_WORKSPACE_NAME#"  = $amlWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
}

foreach ($notebookName in $notebooks.Keys) {

        $notebookFileName = "$($notebooks[$notebookName])\$($notebookName).ipynb"
        Write-Information "Creating notebook $($notebookName) from $($notebookFileName)"
        
        $result = Create-SparkNotebook -TemplatesPath $templatesPath -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName `
                -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName -Name $notebookName -NotebookFileName $notebookFileName -CellParams $cellParams
        #$result = Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
        #$result
}
