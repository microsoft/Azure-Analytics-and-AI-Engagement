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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$sqlPoolName = "MediaDW"
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$init$random"
$location = (Get-AzResourceGroup -Name $rgName).Location
$synapseWorkspaceName = "synapsemedia$init$random"
if($concatString.length -gt 16)
{
$dataLakeAccountName = "stmedia"+($concatString.substring(0,17))
}
else
{
	$dataLakeAccountName = "stmedia"+ $concatString
}

$cosmos_account_name = "cosmosdb-media-$concatString"
if($cosmos_account_name.length -gt 43 )
{
$cosmos_account_name = $cosmos_account_name.substring(0,43)
}

#Cosmos keys
$cosmos_account_key=az cosmosdb keys list -n $cosmos_account_name -g $rgName |ConvertFrom-Json
$cosmos_account_key=$cosmos_account_key.primarymasterkey

#uploading Sql Scripts
Add-Content log.txt "-----------uploading Sql Scripts-----------------"
Write-Host "----uploading Sql Scripts------"
RefreshTokens
$scripts=Get-ChildItem "../artifacts/sqlscripts" | Select BaseName
$TemplatesPath="../artifacts/templates";	

foreach ($name in $scripts) 
{
    if ($name.BaseName -eq "schema" -or $name.BaseName -eq "sqluser" -or $name.BaseName -eq "sqlOnDemandSchema" )
    {
        continue;
    }

    $item = Get-Content -Raw -Path "$($TemplatesPath)/sql_script.json"
    $item = $item.Replace("#SQL_SCRIPT_NAME#", $name.BaseName)
    $item = $item.Replace("#SQL_POOL_NAME#", $sqlPoolName)
    $jsonItem = ConvertFrom-Json $item 
    $ScriptFileName="../artifacts/sqlscripts/"+$name.BaseName+".sql"
    
    $query = Get-Content -Raw -Path $ScriptFileName -Encoding utf8
    $query = $query.Replace("#STORAGE_ACCOUNT#", $dataLakeAccountName)
     $query = $query.Replace("#STORAGE_ACCOUNT_NAME#", $dataLakeAccountName)
    $query = $query.Replace("#COSMOS_ACCOUNT#", $cosmos_account_name)
    $query = $query.Replace("#COSMOS_KEY#", $cosmos_account_key)

    $query = $query.Replace("#LOCATION#", $location)
	
    if ($Parameters -ne $null) 
    {
        foreach ($key in $Parameters.Keys) 
        {
            $query = $query.Replace("#$($key)#", $Parameters[$key])
        }
    }

    $query = ConvertFrom-Json (ConvertTo-Json $query)
    $jsonItem.properties.content.query = $query
    $item = ConvertTo-Json $jsonItem -Depth 100
    $uri = "https://$($synapseWorkspaceName).dev.azuresynapse.net/sqlscripts/$($name.BaseName)?api-version=2019-06-01-preview"
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"
}
