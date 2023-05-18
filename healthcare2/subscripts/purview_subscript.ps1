function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
    $global:purviewToken = ((az account get-access-token --resource https://purview.azure.net) | ConvertFrom-Json).accessToken
}

az login

#for powershell...
Connect-AzAccount -DeviceCode

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
if ($subs.GetType().IsArray -and $subs.length -gt 1) {
    $subOptions = [System.Collections.ArrayList]::new()
    for ($subIdx = 0; $subIdx -lt $subs.length; $subIdx++) {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    $title = 'Subscription selection'
    $question = 'Are you sure you want to select this subscription for this lab?'
    $choices = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
    else {
        $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
        $selectedSubName = $subs[$selectedSubIdx]
        Write-Host "Selecting the subscription : $selectedSubName "
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
}

$rgName = read-host "Enter the resource Group Name";
$Region = (Get-AzResourceGroup -Name $rgName).Location
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$concatString = "$init$random"
$accounts_purviewhealthcare2_name = "purviewhc2$suffix"
$purviewCollectionName1 = "ADLS"
$purviewCollectionName2 = "AzureSynapseAnalytics"
$purviewCollectionName3 = "AzureCosmosDB"
$purviewCollectionName4 = "PowerBI"
$dataLakeAccountName = "sthealthcare2$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$subscriptionId = (Get-AzContext).Subscription.Id
$synapseWorkspaceName = "synhealthcare2$concatString"
$cosmos_healthcare2_name = "cosmos-healthcare2-$random$init"
if ($cosmos_healthcare2_name.length -gt 43) {
    $cosmos_healthcare2_name = $cosmos_healthcare2_name.substring(0, 43)
}
$tenantId = (Get-AzContext).Tenant.Id
    
#Azure Purview
    Write-Host "-----------------Azure Purview---------------"
    RefreshTokens

    #create collections
    $body = @{
        parentCollection = @{
            referenceName = $accounts_purviewhealthcare2_name
        }
    }
  
    $body = $body | ConvertTo-Json
  
    RefreshTokens
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/account/collections/$($purviewCollectionName1)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/account/collections/$($purviewCollectionName2)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/account/collections/$($purviewCollectionName3)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    RefreshTokens
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/account/collections/$($purviewCollectionName4)?api-version=2019-11-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    #create sources
    $body = @{
        kind       = "AdlsGen2"
        properties = @{
            collection     = @{
                referenceName = $purviewCollectionName1
                type          = 'CollectionReference'
            }
            location       = $Region
            endpoint       = "https://${dataLakeAccountName}.dfs.core.windows.net/"
            resourceGroup  = $rgName
            resourceName   = $dataLakeAccountName
            subscriptionId = $subscriptionId
        }
    }
  
    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/scan/datasources/AzureDataLakeStorage?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    $body = @{
        kind       = "AzureSynapseWorkspace"
        properties = @{
            dedicatedSqlEndpoint  = "$($synapseWorkspaceName).sql.azuresynapse.net"
            serverlessSqlEndpoint = "$($synapseWorkspaceName)-ondemand.sql.azuresynapse.net"
            subscriptionId        = $subscriptionId
            resourceGroup         = $rgName
            location              = $Region
            resourceName          = $synapseWorkspaceName
            collection            = @{
                type          = "CollectionReference"
                referenceName = $purviewCollectionName2
            }
        }
    }
  
    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/scan/datasources/AzureSynapseAnalytics?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    #Create a Source (Azure Cosmos DB)
    $body = @{
        kind       = "AzureCosmosDb"
        properties = @{
            collection     = @{
                referenceName = $purviewCollectionName3
                type          = 'CollectionReference'
            }
            location       = $Region
            resourceGroup  = $rgName
            resourceName   = $cosmos_healthcare2_name
            accountUri = "${cosmos_healthcare2_name}.documents.azure.com:443/"
            subscriptionId = $subscriptionId
        }
    }

    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/scan/datasources/CosmosDB?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"
  
    $body = @{
        kind       = "PowerBI"
        properties = @{
            tenant     = $tenantId
            collection = @{
                type          = "CollectionReference"
                referenceName = $purviewCollectionName4
            }
        }
    }
  
    $body = $body | ConvertTo-Json
  
    $uri = "https://$($accounts_purviewhealthcare2_name).purview.azure.com/scan/datasources/PowerBI?api-version=2018-12-01-preview"
    RefreshTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $body -Headers @{ Authorization = "Bearer $purviewToken" } -ContentType "application/json"  
