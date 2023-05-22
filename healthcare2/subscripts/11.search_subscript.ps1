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
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$suffix = "$random-$init"
$searchName = "srch-healthcare2-$suffix"
$dataLakeAccountName = "sthealthcare2$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$cognitive_service_name = "cog-healthcare2-$suffix"



##Search service 
Write-Host "-----------------Search service ---------------"
Add-Content log.txt "-----------------Search service ---------------"
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
$key=az cognitiveservices account keys list --name $cognitive_service_name -g $rgName|ConvertFrom-json
$destinationKey=$key.key1

# Fetch connection string
$storageKey = (Get-AzStorageAccountKey -Name $dataLakeAccountName -ResourceGroupName $rgName)[0].Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($dataLakeAccountName);AccountKey=$($storageKey);EndpointSuffix=core.windows.net"

#resource id of cognitive_service_name
$resource=az resource show -g $rgName -n $cognitive_service_name --resource-type "Microsoft.CognitiveServices/accounts"|ConvertFrom-Json
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
                -replace '#STORAGEACCOUNTNAME#', $dataLakeAccountName`
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
