function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

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
$subscriptionId = (Get-AzContext).Subscription.Id
$accounts_purview_retail_name = "purviewretail$suffix"
$purviewCollectionName1 = "AzureDataLakeStorage"
$purviewCollectionName2 = "AzureSynapse"
$purviewCollectionName3 = "CosmosDB-Retail"
$purviewCollectionName4 = "PowerBI-Retail"
$concatString = "$init$random"
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$storageAccountName = $dataLakeAccountName
$synapseWorkspaceName = "synapseretail$init$random"
$cosmosdb_retail2_name = "cosmosdb-retail2-$random$init";
if($cosmosdb_retail2_name.length -gt 43)
{
$cosmosdb_retail2_name = $cosmosdb_retail2_name.substring(0,43)
}
$tenantId = (Get-AzContext).Tenant.Id

#Azure Purview
Write-Host "-----------------Azure Purview---------------"
RefreshTokens

#create collections
$body = @{
  parentCollection = @{
    referenceName = $accounts_purview_retail_name
  }
}

$body = $body | ConvertTo-Json

RefreshTokens
$uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName1)?api-version=2019-11-01-preview"
$result = Invoke-RestMethod -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

RefreshTokens
$uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName2)?api-version=2019-11-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

RefreshTokens
$uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName3)?api-version=2019-11-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

RefreshTokens
$uri = "https://$($accounts_purview_retail_name).purview.azure.com/account/collections/$($purviewCollectionName4)?api-version=2019-11-01-preview"
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

#create sources
$body = @{
		kind = "AdlsGen2"
		properties = @{
			endpoint = "https://$($storageAccountName).dfs.core.windows.net/"
      subscriptionId = $subscriptionId
      resourceGroup = $rgName
      location = $rglocation
      resourceName = $storageAccountName
      collection = @{
			  type = "CollectionReference"
			  referenceName = $purviewCollectionName1
			}
		}
    }

$body = $body | ConvertTo-Json

$uri = "https://$($accounts_purview_retail_name).purview.azure.com/scan/datasources/AzureDataLakeStorage?api-version=2018-12-01-preview"
RefreshTokens
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

$body = @{
  kind = "AzureSynapseWorkspace"
  properties = @{
    dedicatedSqlEndpoint = "$($synapseWorkspaceName).sql.azuresynapse.net"
    serverlessSqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
    subscriptionId = $subscriptionId
    resourceGroup = $rgName
    location = $rglocation
    resourceName = $synapseWorkspaceName
    collection = @{
      type = "CollectionReference"
      referenceName = $purviewCollectionName2
    }
  }
}

$body = $body | ConvertTo-Json

$uri = "https://$($accounts_purview_retail_name).purview.azure.com/scan/datasources/AzureSynapseAnalytics?api-version=2018-12-01-preview"
RefreshTokens
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

$body = @{
  kind = "AzureCosmosDb"
  properties = @{
    accountUri = "https://$($cosmosdb_retail2_name).documents.azure.com:443/"
    subscriptionId = $subscriptionId
    resourceGroup = $rgName
    location = $rglocation
    resourceName = $cosmosdb_retail2_name
    collection = @{
      type = "CollectionReference"
      referenceName = $purviewCollectionName3
    }
  }
}

$body = $body | ConvertTo-Json

$uri = "https://$($accounts_purview_retail_name).purview.azure.com/scan/datasources/CosmosDB?api-version=2018-12-01-preview"
RefreshTokens
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"

$body = @{
  kind = "PowerBI"
  properties = @{
    tenant = $tenantId
    collection = @{
      type = "CollectionReference"
      referenceName = $purviewCollectionName4
    }
  }
}

$body = $body | ConvertTo-Json

$uri = "https://$($accounts_purview_retail_name).purview.azure.com/scan/datasources/PowerBI?api-version=2018-12-01-preview"
RefreshTokens
$result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization="Bearer $purviewToken" } -ContentType "application/json"
