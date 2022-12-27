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

[string]$random =  -join ((48..57) + (97..122) | Get-Random -Count 7 | % {[char]$_})

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$complexPassword = 0
$SqlPassword=""
while ($complexPassword -ne 1)
{
    $SqlPassword = Read-Host "Enter a password to use for the $sqlUser login.
    `The password must meet complexity requirements:
    ` - Minimum 8 characters. 
    ` - At least one upper case English letter [A-Z]
    ` - At least one lower case English letter [a-z]
    ` - At least one digit [0-9]
    ` - At least one special character (!,@,#,%,^,&,$)
    ` "

    if(($SqlPassword -cmatch '[a-z]') -and ($SqlPassword -cmatch '[A-Z]') -and ($SqlPassword -match '\d') -and ($SqlPassword.length -ge 8) -and ($SqlPassword -match '!|@|#|%|^|&|$'))
    {
        $complexPassword = 1
	  Write-Output "Password $SqlPassword accepted. Make sure you remember this!"
    }
    else
    {
        Write-Output "$SqlPassword does not meet the compexity requirements."
    }
}
$wsId =  Read-Host "Enter your PowerBI workspace Id"

$location = (Get-AzResourceGroup -Name $rgName).Location
$init = (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random = (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"

$subscriptionId = (Get-AzContext).Subscription.Id
$synapseWorkspaceName = "synapseretail$init$random"
$sqlUser = "labsqladmin"
$suffix = "$random-$init"
$keyVaultName = "kv-$suffix";
$sqlPoolName = "RetailDW"
$concatString = "$init$random"
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

Write-Host "Creating Synapse Analytics resource in $rgName resource group..."

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
  -TemplateFile "synapse_template.json" `
  -Mode Incremental `
  -workspace_name_synapseretail $synapseWorkspaceName `
  -storage_account_name $dataLakeAccountName `
  -sql_administrator_login_password $SqlPassword `
  -key_vault_name $keyVaultName
  -location $location `
  -Force


$id = (Get-AzADServicePrincipal -DisplayName $synapseWorkspaceName).id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
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
$cosmosdb_retail2_name = "cosmosdb-retail2-$random$init";
if($cosmosdb_retail2_name.length -gt 43)
{
$cosmosdb_retail2_name = $cosmosdb_retail2_name.substring(0,43)
}
$cosmos_database_name= "retail-foottraffic";
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$amlworkspacename = "amlws-$suffix"


#############################

Write-Host "----linked Services------"
#Creating linked services
RefreshTokens

$templatepath="../artifacts/linkedservices/"

##SynapseDev linked services
Write-Host "Creating linked Service: SynapseDev"
$filepath=$templatepath+"SynapseDev.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SynapseDev?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##synretailprod-WorkspaceDefaultSqlServer linked services
Write-Host "Creating linked Service: synretailprod-WorkspaceDefaultSqlServer"
$filepath=$templatepath+"synretailprod-WorkspaceDefaultSqlServer.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synretailprod-WorkspaceDefaultSqlServer?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##PowerBIWorkspace linked services
Write-Host "Creating linked Service: PowerBIWorkspace"
$filepath=$templatepath+"PowerBIWorkspace.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/PowerBIWorkspace?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##SapHana linked services
Write-Host "Creating linked Service: SapHana"
$filepath=$templatepath+"SapHana.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/SapHana?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##blob linked services
Write-Host "Creating linked Service: synretailprod-WorkspaceDefaultStorage"
$filepath=$templatepath+"synretailprod-WorkspaceDefaultStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/synretailprod-WorkspaceDefaultStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##Teradata linked services
Write-Host "Creating linked Service: Teradata"
$filepath=$templatepath+"Teradata.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#LINKED_SERVICE_NAME#", "Teradata").Replace("#WORKSPACE_ID#", $wsId)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Teradata?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##Sale_DataLakeStorage linked services
Write-Host "Creating linked Service: Sale_DataLakeStorage"
$filepath=$templatepath+"Sale_DataLakeStorage.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/Sale_DataLakeStorage?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##RetailProd linked services
Write-Host "Creating linked Service: RetailProd"
$filepath=$templatepath+"RetailProd.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/RetailProd?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##OracleDB linked services
Write-Host "Creating linked Service: OracleDB"
$filepath=$templatepath+"OracleDB.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/OracleDB?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##cosmosdbretail2prod linked services
Write-Host "Creating linked Service: cosmosdbretail2prod"
$filepath=$templatepath+"cosmosdbretail2prod.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmosdb_retail2_name).Replace("#COSMOS_DATABASE#", $cosmos_database_name).Replace("COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/cosmosdbretail2prod?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##cosmosdbretail2 linked services for inventory db
Write-Host "Creating linked Service: cosmosdbretail2"
$filepath=$templatepath+"cosmosdbretail2.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#COSMOS_ACCOUNT#", $cosmosdb_retail2_name).Replace("#COSMOS_DATABASE#", $cosmos_database_name_retailinventorydb).Replace("COSMOS_ACCOUNT_KEY#", $cosmos_account_key)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/cosmosdbretail2?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##CDPProd linked services
Write-Host "Creating linked Service: CDPProd"
$filepath=$templatepath+"CDPProd.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#WORKSPACE_NAME#", $synapseWorkspaceName).Replace("#DATABASE_NAME#", $sqlPoolName).Replace("#SQL_USERNAME#", $sqlUser).Replace("#SQL_PASSWORD#", $sqlPassword)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/CDPProd?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##AzureMLService1 linked services
Write-Host "Creating linked Service: AzureMLService1"
$filepath=$templatepath+"AzureMLService1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#SUBSCRIPTION_ID#", $subscriptionId).Replace("#RESOURCE_GROUP_NAME#", $rgName).Replace("#ML_WORKSPACE_NAME#", $amlworkspacename)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureMLService1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

##AzureDataExplorer1 linked services
Write-Host "Creating linked Service: AzureDataExplorer1"
$filepath=$templatepath+"AzureDataExplorer1.json"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#SUBSCRIPTION_ID#", $subscriptionId).Replace("#RESOURCE_GROUP_NAME#", $rgName).Replace("#ML_WORKSPACE_NAME#", $amlworkspacename)
$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/linkedservices/AzureDataExplorer1?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
Add-Content log.txt $result

# AutoResolveIntegrationRuntime
$FilePathRT="../artifacts/linkedservices/AutoResolveIntegrationRuntime.json" 
$itemRT = Get-Content -Path $FilePathRT
$uriRT = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($rgName)/providers/Microsoft.Synapse/workspaces/$($synapseWorkspaceName)/integrationRuntimes/AutoResolveIntegrationRuntime?api-version=2019-06-01-preview"
$result = Invoke-RestMethod  -Uri $uriRT -Method PUT -Body  $itemRT -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
Add-Content log.txt $result
  
#######################################

#Creating Datasets
Write-Host "--------Datasets--------"
RefreshTokens
$DatasetsPath="../artifacts/datasets";	
$datasets=Get-ChildItem "../artifacts/datasets" | Select BaseName
foreach ($dataset in $datasets) 
{
    Write-Host "Creating dataset : $($dataset.BaseName)"
	$LinkedServiceName=$datasets[$dataset.BaseName]
	$itemTemplate = Get-Content -Path "$($DatasetsPath)/$($dataset.BaseName).json"
	$item = $itemTemplate
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/datasets/$($dataset.BaseName)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	Add-Content log.txt $result
}

########################################

#creating Dataflows
Write-Host "--------Dataflows--------"
RefreshTokens
$workloadDataflows = Get-ChildItem "../artifacts/dataflow" | Select BaseName 

$DataflowPath="../artifacts/dataflow"

foreach ($dataflow in $workloadDataflows) 
{
    $Name=$dataflow.BaseName
    Write-Host "Creating dataflow : $($Name)"
    $item = Get-Content -Path "$($DataflowPath)/$($Name).json"
    
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/dataflows/$($Name)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
	Start-Sleep -Seconds 10
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
	Add-Content log.txt $result
}

########################################

#creating Pipelines
Write-Host "-------Pipelines-----------"
RefreshTokens
$pipelines=Get-ChildItem "../artifacts/pipeline" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList
foreach($name in $pipelines)
{
    $FilePath="../artifacts/pipeline/"+$name.BaseName+".json"
    Write-Host "Creating pipeline : $($name.BaseName)"

    $item = Get-Content -Path $FilePath
    $item=$item.Replace("#DATA_LAKE_STORAGE_NAME#",$dataLakeAccountName)
    $defaultStorage=$synapseWorkspaceName + "-WorkspaceDefaultStorage"
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/pipelines/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    
    #waiting for operation completion
    Start-Sleep -Seconds 10
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    Add-Content log.txt $result 
}

########################################

#uploading Sql Scripts
Write-Host "----Sql Scripts------"
RefreshTokens
$scripts=Get-ChildItem "../artifacts/sqlscripts" | Select BaseName
$TemplatesPath="../artifacts/templates";	


foreach ($name in $scripts) 
{
    if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "storedprocedures" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sql_user_retail")
    {
        continue;
    }

    $item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
    $item = $item.Replace("#SQL_SCRIPT_NAME#", $name.BaseName)
    $item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
    $jsonItem = ConvertFrom-Json $item 
    $ScriptFileName="../artifacts/sqlscripts/"+$name.BaseName+".sql"
    
    $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
    $query = $query.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
    $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmosdb_retail2_name)
    $query = $query.Replace("#LOCATION#", $rglocation)
    $query = $query.Replace("#SQL_PASSWORD#", $sqlPassword)
	
    if ($Parameters -ne $null) 
    {
        foreach ($key in $Parameters.Keys) 
        {
            $query = $query.Replace("#$($key)#", $Parameters[$key])
        }
    }

    Write-Host "Uploading Sql Script : $($name.BaseName)"
    $query = ConvertFrom-Json (ConvertTo-Json $query)
    $jsonItem.properties.content.query = $query
    $item = ConvertTo-Json $jsonItem -Depth 100
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
    Add-Content log.txt $result
}

###################################

#Creating spark notebooks
Write-Host "--------Spark notebooks--------"
RefreshTokens
$notebooks=Get-ChildItem "../artifacts/notebooks" | Select BaseName 

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $rgName
        "#WORKSPACE_NAME#"  = $synapseWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
		"#SPARK_POOL_NAME#" = $sparkPoolName
		"#STORAGE_ACCOUNT_KEY#" = $storage_account_key
		"#COSMOS_LINKED_SERVICE#" = $cosmosdb_retail2_name
		"#STORAGE_ACCOUNT_NAME#" = $dataLakeAccountName
		"#LOCATION#"=$rglocation
		"#AML_WORKSPACE_NAME#"=$amlWorkSpaceName
}

foreach($name in $notebooks)
{
	$template=Get-Content -Raw -Path "../artifacts/templates/spark_notebook.json"
	foreach ($paramName in $cellParams.Keys) 
    {
		$template = $template.Replace($paramName, $cellParams[$paramName])
	}
	$template=$template.Replace("#NOTEBOOK_NAME#",$name.BaseName)
    $jsonItem = ConvertFrom-Json $template
	$path="../artifacts/notebooks/"+$name.BaseName+".ipynb"
	$notebook=Get-Content -Raw -Path $path
	$jsonNotebook = ConvertFrom-Json $notebook
	$jsonItem.properties.cells = $jsonNotebook.cells
	
    if ($CellParams) 
    {
        foreach ($cellParamName in $cellParams.Keys) 
        {
            foreach ($cell in $jsonItem.properties.cells) 
            {
                for ($i = 0; $i -lt $cell.source.Count; $i++) 
                {
                    $cell.source[$i] = $cell.source[$i].Replace($cellParamName, $CellParams[$cellParamName])
                }
            }
        }
    }

     Write-Host "Creating notebook : $($name.BaseName)"
	$item = ConvertTo-Json $jsonItem -Depth 100
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/notebooks/$($name.BaseName)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	#waiting for operation completion
	Start-Sleep -Seconds 10
	Add-Content log.txt $result
}

#######################################

#uploading Sql Scripts
Write-Host "----KQL Scripts------"
RefreshTokens
$scripts=Get-ChildItem "../artifacts/kqlscripts" | Select BaseName

foreach ($name in $scripts) 
{
    $ScriptFileName="../artifacts/kqlscripts/"+$name.BaseName+".kql"
    Write-Host "Uploading Kql Script : $($name.BaseName)"
    New-AzSynapseKqlScript -WorkspaceName $synapseWorkspaceName -DefinitionFile $ScriptFileName
}

#######################################

Write-Host "----Sql Schema------"
RefreshTokens
#creating sql schema
Write-Host "------Create tables in $($sqlPoolName)-------"
$SQLScriptsPath="../artifacts/sqlscripts"
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/tableschema.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/storedprocedures.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
(Get-Content -path "$($SQLScriptsPath)/sqluser.sql" -Raw) | Foreach-Object { $_ `
                -replace '#SQL_PASSWORD#', $sqlPassword`		
        } | Set-Content -Path "$($SQLScriptsPath)/sqluser.sql"		
$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sqluser.sql"
$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sql_user_retail.sql"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery  = "CREATE DATABASE RetailSqlOnDemand"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result	


Write-Host  "-------------Uploading Sql Data ---------------"
RefreshTokens
#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgCompanyVsTopicProbability"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgCompanyVsTopicProbability"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGOrgConnections"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGOrgConnections"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgContribution"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgContribution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgDetractors"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgDetractors"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgOrgWordCloudData"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgOrgWordCloudData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGScores"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGScores"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgSentimentAndCustomerChurn"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgSentimentAndCustomerChurn"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_EsgSentimentVsMarketPerformance"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_EsgSentimentVsMarketPerformance"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ADB_ESGWeightedScore"}} , @{Name = "TABLE_NAME"; Expression = {"ADB_ESGWeightedScore"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"AggregatedSales_SAPHANA"}} , @{Name = "TABLE_NAME"; Expression = {"AggregatedSales_SAPHANA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaign_Analytics_New"}} , @{Name = "TABLE_NAME"; Expression = {"Campaign_Analytics_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalyticLatest"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalyticLatest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Campaigns"}} , @{Name = "TABLE_NAME"; Expression = {"Campaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ConflictofInterest"}} , @{Name = "TABLE_NAME"; Expression = {"ConflictofInterest"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Country"}} , @{Name = "TABLE_NAME"; Expression = {"Country"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerInfo"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerSalesHana"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerSalesHana"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CustomerVisitF"}} , @{Name = "TABLE_NAME"; Expression = {"CustomerVisitF"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"customerVisitsInPersonByLocation"}} , @{Name = "TABLE_NAME"; Expression = {"customerVisitsInPersonByLocation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DailyStockData"}} , @{Name = "TABLE_NAME"; Expression = {"DailyStockData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Dim_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Dim_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"DimData"}} , @{Name = "TABLE_NAME"; Expression = {"DimData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"EmailAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"EmailAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Engagement_ActualVsForecast"}} , @{Name = "TABLE_NAME"; Expression = {"Engagement_ActualVsForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ESGOrganisation"}} , @{Name = "TABLE_NAME"; Expression = {"ESGOrganisation"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinalRevenue"}} , @{Name = "TABLE_NAME"; Expression = {"FinalRevenue"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FinanceSales"}} , @{Name = "TABLE_NAME"; Expression = {"FinanceSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FPA"}} , @{Name = "TABLE_NAME"; Expression = {"FPA"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"HeaderWIP"}} , @{Name = "TABLE_NAME"; Expression = {"HeaderWIP"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Location_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Location_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Address"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Address"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Customer"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Customer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_CustomerGender"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_CustomerGender"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Order"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Order"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_OrderLineStatus_New"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_OrderLineStatus_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Magento_Product_New"}} , @{Name = "TABLE_NAME"; Expression = {"Magento_Product_New"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"MillennialCustomers"}} , @{Name = "TABLE_NAME"; Expression = {"MillennialCustomers"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"NewsAndSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"NewsAndSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OperatingExpenses"}} , @{Name = "TABLE_NAME"; Expression = {"OperatingExpenses"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBalanceSheet"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBalanceSheet"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBankCustomerRanking"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBankCustomerRanking"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBedOccupancyForecasted"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBedOccupancyForecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiCustomer"}} , @{Name = "TABLE_NAME"; Expression = {"pbiCustomer"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiESG"}} , @{Name = "TABLE_NAME"; Expression = {"pbiESG"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgArticleSentiment"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgArticleSentiment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgBigram"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgBigram"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgDetractor"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgDetractor"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgInitiativesComparison"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgInitiativesComparison"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgInstitutionUnitPolicyScore"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgInstitutionUnitPolicyScore"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiEsgPolicy"}} , @{Name = "TABLE_NAME"; Expression = {"pbiEsgPolicy"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitution"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitution"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiInstitutionUnit"}} , @{Name = "TABLE_NAME"; Expression = {"pbiInstitutionUnit"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiKPI"}} , @{Name = "TABLE_NAME"; Expression = {"pbiKPI"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiRegion"}} , @{Name = "TABLE_NAME"; Expression = {"pbiRegion"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiWaitTimeForecast"}} , @{Name = "TABLE_NAME"; Expression = {"PbiWaitTimeForecast"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pred_anomaly"}} , @{Name = "TABLE_NAME"; Expression = {"pred_anomaly"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductLink2"}} , @{Name = "TABLE_NAME"; Expression = {"ProductLink2"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"ProductRecommendations"}} , @{Name = "TABLE_NAME"; Expression = {"ProductRecommendations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Products"}} , @{Name = "TABLE_NAME"; Expression = {"Products"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RevenueVsMarketingCost"}} , @{Name = "TABLE_NAME"; Expression = {"RevenueVsMarketingCost"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Role"}} , @{Name = "TABLE_NAME"; Expression = {"Role"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMaster"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMaster"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMasters"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMasters"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesMasterUpdated"}} , @{Name = "TABLE_NAME"; Expression = {"SalesMasterUpdated"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SalesVsExpense"}} , @{Name = "TABLE_NAME"; Expression = {"SalesVsExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SiteSecurity"}} , @{Name = "TABLE_NAME"; Expression = {"SiteSecurity"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"SortedCampaigns"}} , @{Name = "TABLE_NAME"; Expression = {"SortedCampaigns"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Travel_Entertainment"}} , @{Name = "TABLE_NAME"; Expression = {"Travel_Entertainment"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterRawData"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterRawData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TwitterAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"TwitterAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VTBByChannel"}} , @{Name = "TABLE_NAME"; Expression = {"VTBByChannel"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"vwPbiESGSlicerOrganizations"}} , @{Name = "TABLE_NAME"; Expression = {"vwPbiESGSlicerOrganizations"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalytics"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}} , @{Name = "TABLE_NAME"; Expression = {"WebsiteSocialAnalyticsPBIData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WWIBrands"}} , @{Name = "TABLE_NAME"; Expression = {"WWIBrands"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"WWIProducts"}} , @{Name = "TABLE_NAME"; Expression = {"WWIProducts"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Automotive"}} , @{Name = "TABLE_NAME"; Expression = {"Automotive"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CampaignAnalyticLatestBKP"}} , @{Name = "TABLE_NAME"; Expression = {"CampaignAnalyticLatestBKP"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"CohortAnalysis"}} , @{Name = "TABLE_NAME"; Expression = {"CohortAnalysis"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"customer_segment_rfm"}} , @{Name = "TABLE_NAME"; Expression = {"customer_segment_rfm"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"iot-foottraffic-data"}} , @{Name = "TABLE_NAME"; Expression = {"iot-foottraffic-data"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"KS_CustomerInfo"}} , @{Name = "TABLE_NAME"; Expression = {"KS_CustomerInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OccupancyDate_0001"}} , @{Name = "TABLE_NAME"; Expression = {"OccupancyDate_0001"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OccupancyDateNews"}} , @{Name = "TABLE_NAME"; Expression = {"OccupancyDateNews"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"occupancyHistoricalData"}} , @{Name = "TABLE_NAME"; Expression = {"occupancyHistoricalData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"occupancyHistoricalData2021"}} , @{Name = "TABLE_NAME"; Expression = {"occupancyHistoricalData2021"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"OnlineRetailData"}} , @{Name = "TABLE_NAME"; Expression = {"OnlineRetailData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"pbiBankGlobalRanking"}} , @{Name = "TABLE_NAME"; Expression = {"pbiBankGlobalRanking"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiReadmissionPrediction"}} , @{Name = "TABLE_NAME"; Expression = {"PbiReadmissionPrediction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PbiRetailPrediction"}} , @{Name = "TABLE_NAME"; Expression = {"PbiRetailPrediction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RealTimeTwitterData"}} , @{Name = "TABLE_NAME"; Expression = {"RealTimeTwitterData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Sales"}} , @{Name = "TABLE_NAME"; Expression = {"Sales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Salestransaction"}} , @{Name = "TABLE_NAME"; Expression = {"Salestransaction"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"testtable"}} , @{Name = "TABLE_NAME"; Expression = {"testtable"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"thermostatHistoricalData"}} , @{Name = "TABLE_NAME"; Expression = {"thermostatHistoricalData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"thermostatHistoricalData2021"}} , @{Name = "TABLE_NAME"; Expression = {"thermostatHistoricalData2021"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Wait_Time_Forecasted"}} , @{Name = "TABLE_NAME"; Expression = {"Wait_Time_Forecasted"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)

$sqlEndpoint="$($synapseWorkspaceName).sql.azuresynapse.net"
foreach ($dataTableLoad in $dataTableList) {
    Write-output "Loading data for $($dataTableLoad.TABLE_NAME)"
    $sqlQuery = Get-Content -Raw -Path "../artifacts/templates/load_csv.sql"
    $sqlQuery = $sqlQuery.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
    $Parameters =@{
            CSV_FILE_NAME = $dataTableLoad.CSV_FILE_NAME
            TABLE_NAME = $dataTableLoad.TABLE_NAME
            DATA_START_ROW_NUMBER = $dataTableLoad.DATA_START_ROW_NUMBER
     }
    foreach ($key in $Parameters.Keys) {
            $sqlQuery = $sqlQuery.Replace("#$($key)#", $Parameters[$key])
        }
    Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
}


