function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$sqlPoolName = "HealthCareDW"
$sparkPoolName = "HealthCare"
$subscriptionId = (Get-AzContext).Subscription.Id
$synapseWorkspaceName = "synapsehealthcare$init$random"
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$suffix = "$random-$init"
$searchName = "srch-healthcaredemo-$suffix";
$searchKey = $(az search admin-key show --resource-group $rgName --service-name $searchName | ConvertFrom-Json).primarykey;
$modelUrl = python "./artifacts/formrecognizer/create_model.py"
$modelId= $modelUrl.split("/")
$modelId = $modelId[7]
$location = (Get-AzResourceGroup -Name $rgName).Location
$forms_cogs_name = "cog-formrecognition-$suffix";
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_cogs_name
$cosmos_account_name_heathcare = "cosmosdb-healthcare-$concatString"
if($cosmos_account_name_heathcare.length -gt 43 )
{
$cosmos_account_name_heathcare = $cosmos_account_name_heathcare.substring(0,43)
}

#Creating spark notebooks
Add-Content log.txt "--------------Spark Notebooks---------------"
Write-Host "Creating Spark notebooks..."
RefreshTokens
$notebooks=Get-ChildItem "./artifacts/notebooks" | Select BaseName 

$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $rgName
        "#WORKSPACE_NAME#"  = $synapseWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
		"#SPARK_POOL_NAME#" = $sparkPoolName
		"#STORAGE_ACCOUNT_KEY#" = $storage_account_key
		"#COSMOS_LINKED_SERVICE#" = $cosmos_account_name_heathcare
		"#STORAGE_ACCOUNT_NAME#" = $dataLakeAccountName
		"#SEARCH_KEY#" = $searchKey
		"#SEARCH_NAME#" = $searchName
		"#MODEL_ID#"=$modelId
		"#LOCATION#"=$location
		"#APIM_KEY#"=$forms_cogs_keys.Key1
}

foreach($name in $notebooks)
{
	$template=Get-Content -Raw -Path "./artifacts/templates/spark_notebook.json"
	foreach ($paramName in $cellParams.Keys) 
    {
		$template = $template.Replace($paramName, $cellParams[$paramName])
	}
	$template=$template.Replace("#NOTEBOOK_NAME#",$name.BaseName)
    $jsonItem = ConvertFrom-Json $template
	$path="./artifacts/notebooks/"+$name.BaseName+".ipynb"
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

	$item = ConvertTo-Json $jsonItem -Depth 100
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/notebooks/$($name.BaseName)?api-version=2019-06-01-preview"
	$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	#waiting for operation completion
	Start-Sleep -Seconds 10
	$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/operationResults/$($result.operationId)?api-version=2019-06-01-preview"
	#$result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
	Add-Content log.txt $result
}	
