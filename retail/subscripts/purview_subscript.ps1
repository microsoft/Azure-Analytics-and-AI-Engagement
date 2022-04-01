function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$rglocation = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$accounts_purview_retail_name = "purviewretail$suffix"
$purviewCollectionName1 = "AzureDataLakeStorage"
$purviewCollectionName2 = "AzureSynapse"
$purviewCollectionName3 = "CosmosDB-Retail"
$purviewCollectionName4 = "PowerBI-Retail"

//create collections

$filepath=$templatepath+"purview_request_body.json"
$item = Get-Content -Path $filepath
$item = $item.Replace("#PURVIEW_ACCOUNT_NAME#", $accounts_purview_retail_name)
$uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName1)?api-version=2019-11-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

$filepath=$templatepath+"purview_request_body.json"
$item = Get-Content -Path $filepath
$item = $item.Replace("#PURVIEW_ACCOUNT_NAME#", $accounts_purview_retail_name)
$uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName2)?api-version=2019-11-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

$filepath=$templatepath+"purview_request_body.json"
$item = Get-Content -Path $filepath
$item = $item.Replace("#PURVIEW_ACCOUNT_NAME#", $accounts_purview_retail_name)
$uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName3)?api-version=2019-11-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

$filepath=$templatepath+"purview_request_body.json"
$item = Get-Content -Path $filepath
$item = $item.Replace("#PURVIEW_ACCOUNT_NAME#", $accounts_purview_retail_name)
$uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName4)?api-version=2019-11-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"



// create sources
RefreshTokens
$body = {
  "parentCollection": {
    "referenceName": "myParentCollection1"
  }
}

$body = @{
		kind = "AdlsGen2"
		properties = @{
			endpoint = "https://stretailas3103ufrjo7nuqk.dfs.core.windows.net/"
			collection = @{
			  type = "CollectionReference"
			  referenceName = "azuredatalakestorage"
			}
		}
    }
$uri = "https://purviewretailufrjo7nuqknly-as3103.scan.purview.azure.com/scan/datasources/AzureSynapseAnalytics-test?api-version=2018-12-01-preview"

$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

