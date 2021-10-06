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
    Write-Host "Selecting the $selectedSubName subscription"
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
}

$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"
$searchName = "srch-healthcaredemo-$suffix";
$cognitive_services_name = "cog-healthcare-$init"
$concatString = "$init$random"
$dataLakeAccountName = "sthealthcare"+($concatString.substring(0,12))
$storageAccountName = $dataLakeAccountName

#Search service 
Write-Host "-----------------Search service ---------------"
RefreshTokens
# Create Search Service
#$sku = "Standard"
#New-AzSearchService -Name $searchName -ResourceGroupName $rgName -Sku $sku -Location $location

# Create search query key
Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
$queryKey = "QueryKey"
New-AzSearchQueryKey -Name $queryKey -ServiceName $searchName -ResourceGroupName $rgName

# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $searchName
$primaryAdminKey = $adminKeyPair.Primary

#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cognitive_services_name -g $rgName|ConvertFrom-json
$destinationKey=$key.key1

# Fetch connection string
$storageKey = (Get-AzStorageAccountKey -Name $storageAccountName -ResourceGroupName $rgName)[0].Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($storageAccountName);AccountKey=$($storageKey);EndpointSuffix=core.windows.net"

#resource id of cognitive_services_name
$resource=az resource show -g $rgName -n $cognitive_services_name --resource-type "Microsoft.CognitiveServices/accounts"|ConvertFrom-Json
$resourceId=$resource.id

# Create Index
Get-ChildItem "../artifacts/search" -Filter hospitalincidentsearch-index.json |
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
Get-ChildItem "../artifacts/search" -Filter search_datasource.json |
        ForEach-Object {
            $datasourceDefinition = (Get-Content $_.FullName -Raw).replace("#STORAGE_CONNECTION#", $storageConnectionString)
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

             $url = "https://$searchName.search.windows.net/datasources?api-version=2020-06-30"
             Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $dataSourceDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

#Replace connection string in search_skillset.json
(Get-Content -path ../artifacts/search/search_skillset.json -Raw) | Foreach-Object { $_ `
				-replace '#RESOURCE_ID#', $resourceId`
				-replace '#STORAGEACCOUNTNAME#', $storageAccountName`
				-replace '#STORAGEKEY#', $storageKey`
				-replace '#COGNITIVE_API_KEY#', $destinationKey`
			} | Set-Content -Path ../artifacts/search/search_skillset.json

# Creat Skillset
Get-ChildItem "../artifacts/search" -Filter search_skillset.json |
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
Get-ChildItem "../artifacts/search" -Filter search_indexer.json |
        ForEach-Object {
            $indexerDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$searchName.search.windows.net/indexers?api-version=2020-06-30"
            Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexerDefinition | ConvertTo-Json
        }
		
