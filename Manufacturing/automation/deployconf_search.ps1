$tenantId = "f94768c8-8714-4abe-8e2d-37a64b18216a" 
$subscriptionId = "6f6a71d2-83bb-42b0-9912-2e243ef214c4" 
$resourceGroup = "mfg-testing2"
$location = "West US 2" 
$storageAccountName = "dreamdemostrggen2pocrs8l" 
$searchName = "search-luypgpxtpghpo-pocrs8"

#Coonect to Azure Account Subscription
Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId

# Create Search Service
$sku = "Standard"
New-AzSearchService -Name $searchName -ResourceGroupName $resourceGroup -Sku $sku -Location $location

# Create search query key
$queryKey = "QueryKey"
New-AzSearchQueryKey -Name $queryKey -ServiceName $searchName -ResourceGroupName $resourceGroup
 

# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $resourceGroup -ServiceName $searchName
$primaryAdminKey = $adminKeyPair.Primary


# Fetch connection string
$storageKey = (Get-AzStorageAccountKey -Name $storageAccountName -ResourceGroupName $resourceGroup)[0].Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageKey;EndpointSuffix=core.windows.net"

# Create Index
Get-ChildItem "artifacts/search/" -Filter osha-final.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw

            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json' 
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/indexes?api-version=2020-06-30"

            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }


# Create Datasource endpoint
Get-ChildItem "artifacts/search" -Filter search_datasource.json |
        ForEach-Object {
            $datasourceDefinition = (Get-Content $_.FullName -Raw).replace("[STORAGECONNECTION]", $storageConnectionString)

            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json' 
                'Accept' = 'application/json' }

             $url = "https://$searchName.search.windows.net/datasources?api-version=2020-06-30"

             Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $dataSourceDefinition | ConvertTo-Json
        }
		
# Create Indexers		
Get-ChildItem "artifacts/search" -Filter search_indexer.json |
        ForEach-Object {
            $indexerDefinition = Get-Content $_.FullName -Raw

            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json' 
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/indexers?api-version=2020-06-30"

            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexerDefinition | ConvertTo-Json
        }
