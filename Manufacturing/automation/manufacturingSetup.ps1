az login
$subscription=Read-Host "Copy a subscription name from above list and paste here"
az account set --subscription $subscription
$subscriptionId=az account show|ConvertFrom-Json
$subscriptionId=$subscriptionId.Id
$global:logindomain = (Get-AzContext).Tenant.Id
$tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$tokenValue = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
$synapseToken = $tokenValue; 
$synapseWorkspaceName
$wsId=""#workspaceid powerBI
$workspaceName  #synapse workspace
$sqlPoolName
$dataLakeAccountName





#Creating spark notebooks
Write-Information "Creating Spark notebooks..."
$notebooks=Get-ChildItem "./artifacts/notebooks" | Select BaseName 
$cellParams = [ordered]@{
        "#SQL_POOL_NAME#"       = $sqlPoolName
        "#SUBSCRIPTION_ID#"     = $subscriptionId
        "#RESOURCE_GROUP_NAME#" = $resourceGroupName
        "#WORKSPACE_NAME#"  = $synapseWorkspaceName
        "#DATA_LAKE_NAME#" = $dataLakeAccountName
}
foreach($name in $notebooks)
	{
		$template=Get-Content -Raw -Path "./artifacts/templates/spark_notebook.json"
		foreach ($paramName in $cellParams.Keys) {
			$template = $template.Replace($paramName, $cellParams[$paramName])
		}
		$jsonItem = ConvertFrom-Json $template
	    $path="./artifacts/notebooks/"+$name+".ipynb"
		$notebook=Get-Content -Raw -Path $path
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
		$uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/notebooks/$($name)?api-version=2019-06-01-preview"
		$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
		#$result = Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
	}	

#uploading powerbi reports
Write-Information "Uploading power BI reports"
Connect-PowerBIServiceAccount
$reportList = New-Object System.Collections.ArrayList

$reportList.Add($temp)
$reports=Get-ChildItem "./artifacts/reports" | Select BaseName 
foreach($name in $reports)
{
		$FilePath="./artifacts/reports/"+$name+".pbix"
		New-PowerBIReport -Path $FilePath -Name $name -WorkspaceId $wsId
		$temp = "" | select-object @{Name = "Name"; Expression = {$name}}, 
                                @{Name = "PowerBIDataSetId"; Expression = {""}},
								@{Name = "SourceServer"; Expression = {"cdpvisionworkspace.sql.azuresynapse.net"}}, 
                                @{Name = "SourceDatabase"; Expression = {"AzureSynapseDW"}}
		$dataSets=Get-PowerBIDataset;
		foreach($set in $dataSets)
       {
        if($set.name -eq $name)
        {
            temp.PowerBIDataSetId= $set.id;
        }
       }
		$reportList.Add($temp)
		Start-Sleep -s 5	
		
}

#creating Pipelines
Write-Information "Creating pipelines"
$pipelines=Get-ChildItem "./artifacts/reports" | Select BaseName
$pipelineList = New-Object System.Collections.ArrayList

$pipelineList.Add($temp)
foreach($name in $pipelines)
{
	$FilePath="./artifacts/pipelines/"+$name+".json"
	$temp = "" | select-object @{Name = "FileName"; Expression = {$name}} , @{Name = "Name"; Expression = {$name.ToUpper()}}, @{Name = "PowerBIReportName"; Expression = {""}}
	$pipelineList.Add($temp)
	 $item = Get-Content -Path $FilePath
	 $item=$item.Replace("#DATA_LAKE_STORAGE_NAME #",$dataLakeAccountName)
	 $defaultStorage=$workspaceName + "-WorkspaceDefaultStorage"
	 $item=$item.Replace("#DEFAULT_STORAGE  #",$defaultStorage)
	 $uri = "https://$($workspaceName).dev.azuresynapse.net/pipelines/$($name)?api-version=2019-06-01-preview"
     $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
	 #Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
	 
}



#Establish powerbi reports dataset connections
Write-Information "Uploading power BI reports"	
$powerBIDataSetConnectionTemplate = Get-Content -Path "./artifacts/templates/powerbi_dataset_connection.json"
$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "$($workspaceName).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String
foreach($report in $reportList)
{
   Write-Information "Setting database connection for $($report.Name)"
   $powerBIReportDataSetConnectionUpdateRequest = $powerBIDataSetConnectionUpdateRequest.Replace("#SOURCE_SERVER#", $powerBIReport.SourceServer).Replace("#SOURCE_DATABASE#", $powerBIReport.SourceDatabase) |Out-String
   $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsid/datasets/$report.PowerBIDataSetId/Default.UpdateDatasources";
    $result = Invoke-RestMethod -Uri $url -Method POST -Body $powerBIReportDataSetConnectionUpdateRequest -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" };
   
}







