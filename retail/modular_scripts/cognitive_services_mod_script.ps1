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

[string]$random =  -join ((48..57) + (97..122) | Get-Random -Count 7 | % {[char]$_})
#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$location = (Get-AzResourceGroup -Name $rgName).Location
$init = (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random = (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$suffix = "$random-$init"

$search_srch_retail_name = "srch-retail-product-$suffix";
$dataLakeAccountName = "stretail$concatString"
if($dataLakeAccountName.length -gt 24)
{
$dataLakeAccountName = $dataLakeAccountName.substring(0,24)
}
$storageAccountName = $dataLakeAccountName
$incident_search_retail_name = "incident-srch-retail-$suffix";
$cog_retail_name = "cogretail-$suffix"
$subscriptionId = (Get-AzContext).Subscription.Id
$cog_speech_name = "retailspeechapp-$suffix"
$accounts_transqna_retail_name = "transqna-retail-$suffix"
$forms_retail_name = "retail-form-recognizer-$suffix"
$accounts_qnamaker_name= "qnamaker-$suffix"
$search_retail_qna_name = "srch-retail-qna-$suffix"
$app_retail_qna_name = "qnamaker-app-$suffix"
$asp_retail_qna_name = "asp-qnamaker-$suffix"
$accounts_RetailMedia_name = "retailmedia-$suffix"
$mediaservices_name = "mediasvc$random"

Write-Host "Creating Cognitive Services resource in $rgName resource group..."

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
  -TemplateFile "cognitive_services_template.json" `
  -Mode Incremental `
  -accounts_retailspeechapp_name $cog_speech_name `
  -accounts_transqna_retail_name $accounts_transqna_retail_name `
  -forms_retail_name $forms_retail_name `
  -accounts_cogretail_name $cog_retail_name `
  -accounts_qnamaker_name $accounts_qnamaker_name `
  -search_retail_qna_name $search_retail_qna_name `
  -search_srch_retail_name $search_srch_retail_name `
  -app_retail_qna_name $app_retail_qna_name `
  -serverfarms_app_retail_qna_name $asp_retail_qna_name `
  -accounts_RetailMedia_name $accounts_RetailMedia_name `
  -mediaservices_name $mediaservices_name `
  -location $location `
  -Force

RefreshTokens
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key

$StartTime = Get-Date
$EndTime = $StartTime.AddDays(6)
$sasToken = New-AzStorageContainerSASToken -Container "incidentpdftraining" -Context $dataLakeContext -Permission rwdl -StartTime $StartTime -ExpiryTime $EndTime
  
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$forms_cogs_keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $rgName -name $forms_retail_name

#########################

### Replacing Incident Search Files
# get search query key
Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
$incidentQueryKey = Get-AzSearchQueryKey -ResourceGroupName $rgName -ServiceName $incident_search_retail_name
$incidentQueryKey = $incidentQueryKey.Key

(Get-Content -path artifacts/storageassets/incident-search/AzSearch_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/storageassets/incident-search/AzSearch.html

(Get-Content -path artifacts/storageassets/incident-search/gistfile1_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/storageassets/incident-search/gistfile1.html

(Get-Content -path artifacts/storageassets/incident-search/search_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
    -replace '#INCIDENT_QUERY_KEY#', $incidentQueryKey`
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/storageassets/incident-search/search.html

(Get-Content -path artifacts/storageassets/incident-search/detail_withoutreplacement.html -Raw) | Foreach-Object { $_ `
    -replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
} | Set-Content -Path artifacts/storageassets/incident-search/detail.html

#incident-search assests copy
RefreshTokens

$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $dataLakeAccountName)[0].Value
$dataLakeContext = New-AzStorageContext -StorageAccountName $dataLakeAccountName -StorageAccountKey $storage_account_key
$container = "incident-search"

$destinationSasKey = New-AzStorageContainerSASToken -Container $container.BaseName -Context $dataLakeContext -Permission rwdl
$destinationUri="https://$($dataLakeAccountName).blob.core.windows.net/$($container.BaseName)/$($destinationSasKey)"
& $azCopyCommand copy "../artifacts/storageassets/$($container.BaseName)/*" $destinationUri --recursive

#########################

Add-Content log.txt "----Form Recognizer-----"
Write-Host "----Form Recognizer-----"
#form Recognizer
#Replace values in create_model.py
(Get-Content -path artifacts/formrecognizer/create_model.py -Raw) | Foreach-Object { $_ `
                -replace '#LOCATION#', $location`
				-replace '#STORAGE_ACCOUNT_NAME#', $storageAccountName`
				-replace '#CONTAINER_NAME#', "incidentpdftraining"`
				-replace '#SAS_TOKEN#', $sasToken`
				-replace '#APIM_KEY#',  $forms_cogs_keys.Key1`
			} | Set-Content -Path artifacts/formrecognizer/create_model1.py
			
$modelUrl = python "../artifacts/formrecognizer/create_model1.py"
$modelId = $modelUrl.split("/")
$modelId = $modelId[7]

##############################

#Search service 
Write-Host "-----------------Search services---------------"
RefreshTokens

Install-Module -Name Az.Search -RequiredVersion 0.7.4 -f
# Get search primary admin key
$adminKeyPair = Get-AzSearchAdminKeyPair -ResourceGroupName $rgName -ServiceName $search_srch_retail_name
$primaryAdminKey = $adminKeyPair.Primary

# Create Index
Write-Host  "------Index----"
try {
Get-ChildItem "../artifacts/search" -Filter fabrikam-fashion.json |
        ForEach-Object {
            $indexDefinition = Get-Content $_.FullName -Raw
            $headers = @{
                'api-key' = $primaryAdminKey
                'Content-Type' = 'application/json'
                'Accept' = 'application/json' }

            $url = "https://$($search_srch_retail_name).search.windows.net/indexes?api-version=2020-06-30"
            $res = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $indexDefinition | ConvertTo-Json
        }
    } catch {
        Write-Host "Resource already Exists !"
}
Start-Sleep -s 10

$headers = @{
'api-key' = $primaryAdminKey
'Content-Type' = 'application/json' 
'Accept' = 'application/json' }
$url = "https://$search_srch_retail_name.search.windows.net/indexes/fabrikam-fashion/docs/index?api-version=2021-04-30-Preview"
$Data= Get-Content -Raw -Path ../artifacts/search/data.json
$body = $Data.Replace("#STORAGE_ACCOUNT_NAME#",$dataLakeAccountName)
Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body

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
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
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

#Replace connection string in retailcog-skillset.json
(Get-Content -path artifacts/search/retailcog-skillset.json -Raw) | Foreach-Object { $_ `
				-replace '#RESOURCE_ID#', $resourceId`
				-replace '#STORAGEACCOUNTNAME#', $storageAccountName`
                -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
                -replace '#RESOURCE_GROUP#', $rgName`
				-replace '#STORAGEKEY#', $storageKey`
				-replace '#COGNITIVE_API_KEY#', $destinationKey`
                -replace '#COGNITIVE_RETAIL_NAME#', $cog_retail_name`
                -replace '#SUBSCRIPTION_ID#', $subscriptionId`
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

#Replace connection string in adlsgen2-indexer.json
(Get-Content -path artifacts/search/adlsgen2-indexer.json -Raw) | Foreach-Object { $_ `
    -replace '#INCIDENT_SEARCH_SERVICE#', $incident_search_retail_name`
} | Set-Content -Path artifacts/search/adlsgen2-indexer.json

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
