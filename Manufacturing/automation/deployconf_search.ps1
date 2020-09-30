$tenantId = (Get-AzContext).Tenant.Id
$subscriptionId= (Get-AzContext).Subscription.Id
$rgName = "mfg-testing2"
$location = "West US 2"
$storageAccountName = "dreamdemostrggen2pocrs11"
$searchName = "search-4i2auh5ce7xs4-pocrs11"

#####################################

#Coonect to Azure Account Subscription
Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId

# Create Search Service
$sku = "Standard"
New-AzSearchService -Name $searchName -ResourceGroupName $rgName -Sku $sku -Location $location

# Create search query key
$queryKey = "QueryKey"
New-AzSearchQueryKey -Name $queryKey -ServiceName $searchName -ResourceGroupName $rgName

# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $searchName
$primaryAdminKey = $adminKeyPair.Primary

$key=az cognitiveservices account keys list --name $customVisionName -g $rgName|ConvertFrom-json
$destinationKey=$key.key1

# Fetch connection string
$storageKey = (Get-AzStorageAccountKey -Name $storageAccountName -ResourceGroupName $rgName)[0].Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageKey;EndpointSuffix=core.windows.net"

# Create Index
Get-ChildItem "artifacts/search" -Filter osha-final.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw

            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/indexes?api-version=2020-06-30"

            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }

Start-Sleep -s 10

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

Start-Sleep -s 10


#Replace connection string in search_skillset.json
(Get-Content -path artifacts/search/search_skillset.json -Raw) | Foreach-Object { $_ `
                -replace '#subscription_id#', $subscriptionId`
				-replace '#rgName#', $rgName`
                -replace '#key#', $destinationkey`
				-replace '#resourceid#', $resourceid`
				-replace '#storageAccountName#', $storageAccountName`
				-replace '#storageKey#', $storageKey`

			} | Set-Content -Path artifacts/search/skillset.json


# Creat Skillset
Get-ChildItem "artifacts/search" -Filter search_skillset.json |
        ForEach-Object {
            $skillsetDefinition = Get-Content $_.FullName -Raw

            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/skillsets?api-version=2020-06-30"

            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $skillsetDefinition | ConvertTo-Json
        }

Start-Sleep -s 10

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
