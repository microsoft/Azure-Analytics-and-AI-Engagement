az login
Install-Module -Name MicrosoftPowerBIMgmt
Login-PowerBI
$subscription=Read-Host "Enter subscription name from above list"

$wsId=Read-Host "Enter your powerBi workspace Id"
$TwitterAccessToken=Read-Host "Enter your twitter access token"
$TwitterAccessTokenSecret=Read-Host "Enter your twitter access token secret"
$TwitterConsumerKey=Read-Host "Enter your twitter consumer key"
$TwitterConsumerKeySecret=Read-Host "Enter your twitter consumer key secret"
$TwitterKeywords=Read-Host "Enter keywords in hashtags to be monitored with ,(comma) seperation"
az account set --subscription $subscription
$subscriptionId=az account show|ConvertFrom-Json


$resourceGroup=Read-Host "Please enter resource group name"
$uniqueCode=Read-Host "Please enter a unique code for environment(lowercase)"

$streamingDatasetUrl= Read-Host "Please enter streaming dataset url for Location analytics"

(Get-Content -path TwitterARM.json -Raw) | Foreach-Object { $_ `
                -replace '#streamingDatasetUrl#', $streamingDatasetUrl`
				-replace '#uniqueCode#', $uniqueCode`
				-replace '#wsId#', $wsId`
				-replace '#resourceGroup#', $resourceGroup`
				-replace '#TwitterAccessToken#', $TwitterAccessToken`
				-replace '#TwitterAccessTokenSecret#', $TwitterAccessTokenSecret`
				-replace '#TwitterConsumerKey#', $TwitterConsumerKey`
				-replace '#TwitterConsumerKeySecret#', $TwitterConsumerKeySecret`
				-replace '#TwitterKeywords#', $TwitterKeywords`
        } | Set-Content -Path TwitterARM.json
	
az group deployment create --resource-group $resourceGroup --template-file ./TwitterARM.json >> output.txt #deploys azure function at specified resource-group	
$output_json = Get-Content "output.txt" | Out-String | ConvertFrom-Json
$twitterFunction=$output_json.properties.outputs.twitter_azure_function_functions_app_name.value
$locationFunction=$output_json.properties.outputs.location_azure_function_functions_app_name.value
$asaName=$output_json.properties.outputs.asaName.value

az functionapp deployment source config-zip `
        --resource-group $resourceGroup `
        --name $twitterFunction `
        --src "../functions/powershell-functions/Twitter_Function_Publish_Package.zip"
		
az functionapp deployment source config-zip `
        --resource-group $resourceGroup `
        --name $locationFunction `
        --src "../functions/powershell-functions/LocationAnalytics_Publish_Package.zip"

# $principal=az resource show --ids /subscriptions/$subscriptionId.id/resourceGroups/$resourceGroup/providers/Microsoft.StreamAnalytics/StreamingJobs/$asaName |ConvertFrom-Json
$principal=az resource show -g $resourceGroup -n $asaName --resource-type "Microsoft.StreamAnalytics/streamingjobs"|ConvertFrom-Json
$principalId=$principal.identity.principalId
Add-PowerBIWorkspaceUser -WorkspaceId $wsId -PrincipalId $principalId -PrincipalType App -AccessRight Contributor


