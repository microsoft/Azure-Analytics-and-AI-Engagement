
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
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$suffix = "$random-$init"
$incident_search_retail_name = "incident-srch-retail-$suffix";
$cog_retail_name = "cogretail-$suffix"
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}

$storageAccountName = $dataLakeAccountName

### Replacing Incident Search Files
# get search query key
Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
$incidentQueryKey = Get-AzSearchQueryKey -ResourceGroupName $rgName -ServiceName $incident_search_retail_name

(Get-Content -path artifacts/storageassets/incident-search/AzSearch_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/formrecognizer/AzSearch.html

(Get-Content -path artifacts/storageassets/incident-search/gistfile1_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/formrecognizer/gistfile1.html

(Get-Content -path artifacts/storageassets/incident-search/search_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/formrecognizer/search.html

(Get-Content -path artifacts/storageassets/incident-search/detail_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
} | Set-Content -Path artifacts/formrecognizer/detail.html

#### Incident Search ####

# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $incident_search_retail_name
$primaryAdminKey = $adminKeyPair.Primary

#get list of keys - cognitiveservices
$key=az cognitiveservices account keys list --name $cog_retail_name -g $rgName|ConvertFrom-json
$destinationKey=$key.key1

# Fetch connection string
$storageKey = (Get-AzStorageAccountKey -Name $storageAccountName -ResourceGroupName $rgName)[0].Value
$storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($storageAccountName);AccountKey=$($storageKey);EndpointSuffix=core.windows.net"

#resource id of cognitive_services_name
$resource=az resource show -g $rgName -n $cog_retail_name --resource-type "Microsoft.CognitiveServices/accounts"|ConvertFrom-Json
$resourceId=$resource.id

# Create Index
Write-Host  "------Index----"
Get-ChildItem "artifacts/search" -Filter incidentsearch-index.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$incident_search_retail_name.search.windows.net/indexes?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

#Replace connection string in retailcogsearchjsondata.json
(Get-Content -path artifacts/search/retailcogsearchjsondata.json -Raw) | Foreach-Object { $_ `
    -replace '#STORAGEACCOUNTNAME#', $storageAccountName`
    -replace '#STORAGEKEY#', $storageKey`
} | Set-Content -Path artifacts/search/retailcogsearchjsondata.json

# Create Datasource endpoint
Write-Host  "------Datasource----"
Get-ChildItem "artifacts/search" -Filter retailcogsearchjsondata.json |
        ForEach-Object {
            $datasourceDefinition = (Get-Content $_.FullName -Raw).replace("#STORAGE_CONNECTION#", $storageConnectionString)
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

             $url = "https://$incident_search_retail_name.search.windows.net/datasources?api-version=2020-06-30"
             $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $dataSourceDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

#Replace connection string in search_skillset.json
(Get-Content -path artifacts/search/retailcog-skillset.json -Raw) | Foreach-Object { $_ `
				-replace '#RESOURCE_ID#', $resourceId`
				-replace '#STORAGEACCOUNTNAME#', $storageAccountName`
                -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
                -replace '#RESOURCE_GROUP#',  $rgName`
				-replace '#STORAGEKEY#', $storageKey`
				-replace '#COGNITIVE_API_KEY#', $destinationKey`
			} | Set-Content -Path artifacts/search/retailcog-skillset.json

# Create Skillset
Write-Host  "------Skillset----"
Get-ChildItem "artifacts/search" -Filter retailcog-skillset.json |
        ForEach-Object {
            $skillsetDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$incident_search_retail_name.search.windows.net/skillsets?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $skillsetDefinition | ConvertTo-Json
        }
Start-Sleep -s 10

# Create Indexers
Write-Host  "------Indexers----"
Get-ChildItem "artifacts/search" -Filter adlsgen2-indexer.json |
        ForEach-Object {
            $indexerDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$incident_search_retail_name.search.windows.net/indexers?api-version=2020-06-30"
           $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexerDefinition | ConvertTo-Json
        }
