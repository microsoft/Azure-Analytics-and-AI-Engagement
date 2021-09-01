function Create-Pipeline {
    
        param(
        [parameter(Mandatory=$true)]
        [String]
        $PipelinesPath,
    
        [parameter(Mandatory=$true)]
        [String]
        $WorkspaceName,
    
        [parameter(Mandatory=$true)]
        [String]
        $Name,
    
        [parameter(Mandatory=$true)]
        [String]
        $FileName,
    
        [parameter(Mandatory=$false)]
        [Hashtable]
        $Parameters = $null
        )
    
        $item = Get-Content -Path "$($PipelinesPath)/$($FileName).json"
        
        if ($Parameters -ne $null) {
            foreach ($key in $Parameters.Keys) {
                $item = $item.Replace("#$($key)#", $Parameters[$key])
            }
        }
    
        $uri = "https://$($WorkspaceName).dev.azuresynapse.net/pipelines/$($Name)?api-version=2019-06-01-preview"
    
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
        
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
            Write-Host "Cannot wait on an empty operation id."
            return
        }
    
        $uri = "https://$($WorkspaceName).dev.azuresynapse.net/operationResults/$($OperationId)?api-version=2019-06-01-preview"
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    
        while ($result.status -ne $null) {
            
            if ($result.status -eq "Failed") {
                throw $result.error
            }
    
            Write-Host "Waiting for operation to complete (status is $($result.status))..."
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
            Write-Host "Refreshing $($TokenName) token."
            Refresh-Token $TokenName
            $tokenTimes[$TokenName] = $refTime
        }
    }

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode
    
subs = Get-AzSubscription | Select-Object -ExpandProperty Name
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

        $pipelinesPath = "..\pipelines"

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
    Write-Host "Selecting the $resourceGroupName resource group"
}
else{
$resourceGroupName=$resourceGroups
Write-Host "Selecting the $resourceGroupName resource group"
}

$uniqueId = (Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Synapse/workspaces).Name.Replace("asaexpworkspace", "")
$workspaceName = "asaexpworkspace$($uniqueId)"
$dataLakeAccountName = "asaexpdatalake$($uniqueId)"

Write-Host "Create pipelines"

$pipelineList = New-Object System.Collections.ArrayList
$temp = "" | select-object @{Name = "FileName"; Expression = {"sap_hana_to_adls"}} , @{Name = "Name"; Expression = {"SAP HANA TO ADLS"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"marketing_db_migration"}} , @{Name = "Name"; Expression = {"MarketingDBMigration"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"sales_db_migration"}} , @{Name = "Name"; Expression = {"SalesDBMigration"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"twitter_data_migration"}} , @{Name = "Name"; Expression = {"TwitterDataMigration"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_campaign_analytics"}} , @{Name = "Name"; Expression = {"Customize Campaign Analytics"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_decomposition_tree"}} , @{Name = "Name"; Expression = {"Customize Decomposition Tree"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_location_analytics"}} , @{Name = "Name"; Expression = {"Customize Location Analytics"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_revenue_profitability"}} , @{Name = "Name"; Expression = {"Customize Revenue Profitability"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"ML_Department_Visits_Predictions"}} , @{Name = "Name"; Expression = {"ML Department Visits Predictions"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"ML_Product_Recommendation"}} , @{Name = "Name"; Expression = {"ML Product Recommendation"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_recommendation_insights_ml"}} , @{Name = "Name"; Expression = {"Customize Recommendation Insights ML"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_email_analytics"}} , @{Name = "Name"; Expression = {"Customize EMail Analytics"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_all"}} , @{Name = "Name"; Expression = {"Customize All"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"customize_product_recommendations_ml"}} , @{Name = "Name"; Expression = {"Customize Product Recommendations ML"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"1_master_pipeline"}} , @{Name = "Name"; Expression = {"1 Master Pipeline"}}
$pipelineList.Add($temp)
$temp = "" | select-object @{Name = "FileName"; Expression = {"reset_ml_data"}} , @{Name = "Name"; Expression = {"Reset ML Data"}}
$pipelineList.Add($temp)

foreach ($pipeline in $pipelineList) {
        Write-Host "Creating workload pipeline $($pipeline.Name)"
        $result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $pipeline.Name -FileName $pipeline.FileName -Parameters @{
                DATA_LAKE_STORAGE_NAME = $dataLakeAccountName
                DEFAULT_STORAGE = $workspaceName + "-WorkspaceDefaultStorage"
         }
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}
