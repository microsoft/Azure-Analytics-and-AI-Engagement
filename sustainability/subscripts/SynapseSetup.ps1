function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
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
$rglocation = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$wsId =  (Get-AzResourceGroup -Name $rgName).Tags["WsId"]        
$synapseWorkspaceName = "synapsesustain$init$random"
$sqlPoolName = "SustainabilityDW"
$concatString = "$init$random"
$dataLakeAccountName = "stsustain$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$cosmosdb_sustainability_name = "cosmosdb-sustain-$random$init";
if($cosmosdb_sustainability_name.length -gt 43)
{
$cosmosdb_sustainability_name = $cosmosdb_sustainability_name.substring(0,43)
}
$cosmos_database_name_sustain = "sustainbusridershipdb";
$sqlUser = "labsqladmin";
$concatString = "$random$init";
$sparkPoolName = "Sustainability"
$keyVaultName = "kv-$suffix";
$amlworkspacename = "amlws-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName


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

#refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

###################################################################
New-Item log.txt

# Install-Module -Name MicrosoftPowerBIMgmt -Force
# $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","I have enough permissions for PowerBI login."
# $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","I will run PowerBI setup seperately."
# $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
# $title = "PowerBI login"
# $message = " (Type [Y] for Yes or [N] for No and press enter)"
# $result = $host.ui.PromptForChoice($title, $message, $options, 1)
# if($result -eq 0)
# {
#  Login-PowerBI 
# }
	
# RefreshTokens
# Add-Content log.txt "------asa powerbi connection-----"
# Write-Host "----ASA Powerbi Connection-----"
# #connecting asa and powerbi
# $principal=az resource show -g $rgName -n $asa_name_sustainability --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
# $principalId=$principal.identity.principalId
# Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Admin

RefreshTokens
Write-Host "-----Enable Transparent Data Encryption----------"
$result = New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile "../artifacts/templates/transparentDataEncryption.json" -workspace_name_synapse $synapseWorkspaceName -sql_compute_name $sqlPoolName -ErrorAction SilentlyContinue
$result = az synapse spark pool update --name $sparkPoolName --workspace-name $synapseWorkspaceName --resource-group $rgName --library-requirements "../artifacts/templates/requirements.txt"

#download azcopy command
if ([System.Environment]::OSVersion.Platform -eq "Unix")
{
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-linux"

        if (!$azCopyLink)
        {
                $azCopyLink = "https://azcopyvnext.azureedge.net/release20200709/azcopy_linux_amd64_10.5.0.tar.gz"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.tar.gz"
        tar -xf "azCopy.tar.gz"
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy).Directory.FullName

        if ($azCopyCommand.count -gt 1)
        {
            $azCopyCommand = $azCopyCommand[0];
        }

        cd $azCopyCommand
        chmod +x azcopy
        cd ..
        $azCopyCommand += "\azcopy"
} else {
        $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

        if (!$azCopyLink)
        {
                $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
        }

        Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
        Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
        $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName

        if ($azCopyCommand.count -gt 1)
        {
            $azCopyCommand = $azCopyCommand[0];
        }

        $azCopyCommand += "\azcopy"
}

#Uploading to storage containers
Add-Content log.txt "-----------Uploading to storage containers-----------------"
Write-Host "----Uploading to Storage Containers-----"
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

RefreshTokens

$destinationSasKey = New-AzStorageContainerSASToken -Container "customcsv" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/customcsv$($destinationSasKey)"
& $azCopyCommand copy "https://sustainabilitypoc.blob.core.windows.net/customcsv" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/webappassets$($destinationSasKey)"
& $azCopyCommand copy "https://sustainabilitypoc.blob.core.windows.net/webappassets" $destinationUri --recursive

#storage assests copy
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$containers=Get-ChildItem "../artifacts/storageassets" | Select BaseName

foreach($container in $containers)
{
    $destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
    $destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
    & $azCopyCommand copy "../artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive
}

##############################

Add-Content log.txt "------sql schema-----"
Write-Host "----Sql Schema------"
RefreshTokens
#creating sql schema
Write-Host "Create tables in $($sqlPoolName)"
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

$sqlQuery = Get-Content -Raw -Path "$($SQLScriptsPath)/sql_user_sustainability.sql"
$result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
Add-Content log.txt $result

$sqlQuery  = "CREATE DATABASE SustainabilityOnDemand"
$sqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"

try{
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
} catch {
    $result=Invoke-SqlCmd -Query $sqlQuery -ServerInstance $sqlEndpoint -Database 'master' -Username $sqlUser -Password $sqlPassword
}
Add-Content log.txt $result	
 
#uploading Sql Scripts
Add-Content log.txt "-----------uploading Sql Scripts-----------------"
Write-Host "----Sql Scripts------"
RefreshTokens
$scripts=Get-ChildItem "../artifacts/sqlscripts" | Select BaseName
$TemplatesPath="../artifacts/templates";	

foreach ($name in $scripts) 
{
    if ($name.BaseName -eq "tableschema" -or $name.BaseName -eq "storedprocedures" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sql_user_sustainability")
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
    $query = $query.Replace("#COSMOSDB_ACCOUNT_NAME#", $cosmosdb_sustainability_name)
    $query = $query.Replace("#COSMOSDB_ACCOUNT_KEY#", $cosmos_account_key)
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

#Creating Datasets
Add-Content log.txt "------datasets------"
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
 
#Creating spark notebooks
Add-Content log.txt "--------------Spark Notebooks---------------"
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
		"#COSMOS_LINKED_SERVICE#" = $cosmosdb_sustainability_name
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

#creating Dataflows
Add-Content log.txt "------Dataflows-----"
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

#creating Pipelines
Add-Content log.txt "------pipelines------"
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

Add-Content log.txt "------uploading sql data------"
Write-Host  "-------------Uploading Sql Data ---------------"
RefreshTokens
#uploading sql data
$dataTableList = New-Object System.Collections.ArrayList

$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"AvgDailyRidership"}} , @{Name = "TABLE_NAME"; Expression = {"AvgDailyRidership"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleServicingTrend_old"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleServicingTrend_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Facility-FactSales"}} , @{Name = "TABLE_NAME"; Expression = {"Facility-FactSales"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Airquality"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Airquality"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Airqualitydetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Airqualitydetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_ArticlePublished"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_ArticlePublished"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Citizensentimentdetail"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Citizensentimentdetail"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Citizensentimentsummmary"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Citizensentimentsummmary"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Eneryconsumptionsdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Eneryconsumptionsdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_FacilityManagementdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_FacilityManagementdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Fleetmaintenancecost"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Fleetmaintenancecost"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_Fleetmanagementdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_Fleetmanagementdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_TransportMaintenanceCost"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_TransportMaintenanceCost"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleBreakdown"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleBreakdown"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleManufacturingData"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleManufacturingData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_vehiclesdetails"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_vehiclesdetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleServicingTrend"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleServicingTrend"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fact_VehicleServicingTrend_old"}} , @{Name = "TABLE_NAME"; Expression = {"Fact_VehicleServicingTrend_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"KPIsValuesFleetManager"}} , @{Name = "TABLE_NAME"; Expression = {"KPIsValuesFleetManager"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"KPIsValuesFleetManager_old"}} , @{Name = "TABLE_NAME"; Expression = {"KPIsValuesFleetManager_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"PowerManagement"}} , @{Name = "TABLE_NAME"; Expression = {"PowerManagement"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleBreakDown"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleBreakDown"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleDetails"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleDetails"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleServiceLog"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleServiceLog"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleServiceLog_old"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleServiceLog_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"aqi_test_df"}} , @{Name = "TABLE_NAME"; Expression = {"aqi_test_df"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TweeterSentiments"}} , @{Name = "TABLE_NAME"; Expression = {"TweeterSentiments"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"RealtimeAIRQualityAPI"}} , @{Name = "TABLE_NAME"; Expression = {"RealtimeAIRQualityAPI"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"TweeterUserInfo"}} , @{Name = "TABLE_NAME"; Expression = {"TweeterUserInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"twitterRawData"}} , @{Name = "TABLE_NAME"; Expression = {"twitterRawData"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Vehicle_Analytics"}} , @{Name = "TABLE_NAME"; Expression = {"Vehicle_Analytics"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleBreakDown_old"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleBreakDown_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"VehicleDetails_old"}} , @{Name = "TABLE_NAME"; Expression = {"VehicleDetails_old"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"Fleet-FactExpense"}} , @{Name = "TABLE_NAME"; Expression = {"Fleet-FactExpense"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
$list = $dataTableList.Add($temp)
$temp = "" | select-object @{Name = "CSV_FILE_NAME"; Expression = {"FacilityInfo"}} , @{Name = "TABLE_NAME"; Expression = {"FacilityInfo"}}, @{Name = "DATA_START_ROW_NUMBER"; Expression = {2}}
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

#uploading powerbi reports
RefreshTokens

Add-Content log.txt "------powerbi reports upload------"
Write-Host "------------Powerbi Reports Upload ------------"
#Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList
$reports=Get-ChildItem "../artifacts/reports" | Select BaseName 
foreach($name in $reports)
{
        $FilePath="../artifacts/reports/$($name.BaseName)"+".pbix"
        #New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
        
        write-host "Uploading PowerBI Report : $($name.BaseName)";
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/imports?datasetDisplayName=$($name.BaseName)&nameConflict=CreateOrOverwrite";
		$fullyQualifiedPath=Resolve-Path -path $FilePath
        $fileBytes = [System.IO.File]::ReadAllBytes($fullyQualifiedPath);
        $fileEnc = [system.text.encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes);
        $boundary = [System.Guid]::NewGuid().ToString();
        $LF = "`r`n";
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data",
            "",
            $fileEnc,
            "--$boundary--$LF"
        ) -join $LF

        $result = Invoke-RestMethod -Uri $url -Method POST -Body $bodyLines -ContentType "multipart/form-data; boundary=`"--$boundary`"" -Headers @{ Authorization="Bearer $powerbitoken" }
		Start-Sleep -s 5 
		
        Add-Content log.txt $result
        $reportId = $result.id;

        $temp = "" | select-object @{Name = "FileName"; Expression = {"$($name.BaseName)"}}, 
		@{Name = "Name"; Expression = {"$($name.BaseName)"}}, 
        @{Name = "PowerBIDataSetId"; Expression = {""}},
        @{Name = "ReportId"; Expression = {""}},
        @{Name = "SourceServer"; Expression = {""}}, 
        @{Name = "SourceDatabase"; Expression = {""}}
		                        
        # get dataset                         
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets";
        $dataSets = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization="Bearer $powerbitoken" };
		
        Add-Content log.txt $dataSets
        
        $temp.ReportId = $reportId;

        foreach($res in $dataSets.value)
        {
            if($res.name -eq $name.BaseName)
            {
                $temp.PowerBIDataSetId = $res.id;
            }
       }
                
      $list = $reportList.Add($temp)
}
Start-Sleep -s 60

##Establish powerbi reports dataset connections
Add-Content log.txt "------pbi connections update------"
Write-Host "--------- PBI connections update---------"	

foreach($report in $reportList)
{
    if($report.name -eq "Master Images")
    {
        continue;
    }
    elseif($report.name -eq "Budget dashboard" -or $report.name -eq "Fleet Manager Dashboard" -or $report.name -eq "Mayor Dashboard" -or $report.name -eq  "Power Management" -or $report.name -eq "Realtime Air Quality Report Static" -or $report.name -eq "Transportation Head Dashboard" -or $report.name -eq "Twitter Report Static" -or $report.name -eq "Transport Deep Dive")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"Server`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"Database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
    elseif($report.name -eq "Sustainability Column Level Security (Azure Synapse)" -or $report.name -eq "Sustainability Row Level Security (Azure Synapse)")
    {
      $body = "{
			`"updateDetails`": [
								{
									`"name`": `"servername`",
									`"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
								},
								{
									`"name`": `"database`",
									`"newValue`": `"$($sqlPoolName)`"
								}
								]
								}"	
	}
    elseif($report.name -eq "Sustainability Dynamic Data Masking (Azure Synapse)")
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"ServerNew`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                                
                            },
                            {
                                `"name`": `"Pool`",
                                `"newValue`": `"$($sqlPoolName)`"
                            }
                            ]
                            }"	
	}
    elseif($report.name -eq "Demand and Bus Frequency")
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Server`",
                                `"newValue`": `"https://$($cosmosdb_sustainability_name).documents.azure.com:443/`"
                                
                            },
                            {
                                `"name`": `"Database`",
                                `"newValue`": `"$($cosmos_database_name_sustain)`"
                            }
                            ]
                            }"	
	}
    elseif($report.name -eq "NYC_AQI" -or $report.name -eq "Billion Rows Demo" )
    {
        $body = "{
        `"updateDetails`": [
                            {
                                `"name`": `"Connection_String`",
                                `"newValue`": `"$($synapseWorkspaceName).sql.azuresynapse.net`"
                                
                            },
                            {
                                `"name`": `"Database_Name`",
                                `"newValue`": `"$($sqlPoolName)`"
                            }
                            ]
                            }"	
	}
	
	Write-Host "PBI connections updating for report : $($report.name)"	
    $url = "https://api.powerbi.com/v1.0/myorg/groups/$($wsId)/datasets/$($report.PowerBIDataSetId)/Default.UpdateParameters"
    $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken"} -ErrorAction SilentlyContinue;
		
    start-sleep -s 5
}
