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

#Getting User Inputs
$rgName = read-host "Enter the resource Group Name";
$location = (Get-AzResourceGroup -Name $rgName).Location
$init = (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random = (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]

$cosmosdb_retail2_name = "cosmosdb-retail2-$random$init";
if($cosmosdb_retail2_name.length -gt 43)
{
$cosmosdb_retail2_name = $cosmosdb_retail2_name.substring(0,43)
}
$cosmos_database_name= "retail-foottraffic";
$cosmos_database_name_retailinventorydb = "retailinventorydb";
$cosmos_database_video_indexer = "retail-video-indexer";
$cosmos_database_container_name_videoindexerinsights = "retail-videoindexerinsights";
$cosmos_database_container_name_Transcript = "retail-Transcript"
$suffix = "$random-$init"
$connections_cosmosdb_name =  "conn-documentdb-$suffix"

Write-Host "Creating Cosmmos resource in $rgName resource group..."

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
  -TemplateFile "cosmos_template.json" `
  -Mode Incremental `
  -cosmosdb_retail2_name $cosmosdb_retail2_name `
  -cosmos_database_name $cosmos_database_name `
  -cosmos_database_video_indexer $cosmos_database_video_indexer `
  -cosmos_database_name_retailinventorydb $cosmos_database_name_retailinventorydb `
  -cosmos_database_container_name_videoindexerinsights $cosmos_database_container_name_videoindexerinsights `
  -cosmos_database_container_name_Transcript $cosmos_database_container_name_Transcript `
  -connections_cosmosdb_name $connections_cosmosdb_name `
  -location $location `
  -Force

#COSMOS Section
Write-Host "------COSMOS data Upload -------------"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmosdb_retail2_name
$cosmos = Get-ChildItem "../artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    if($name.BaseName -eq "inventorydb")
	{
     $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmos_database_name_retailinventorydb -ResourceGroup $rgName
	}
	else 
	{
	$cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmos_database_name -ResourceGroup $rgName
	}
    $path="../artifacts/cosmos/"+$name.BaseName+".json"
    $documents=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $documents

    foreach($json in $document)
    {
        if($name.Basename -eq "retaildb") {
            $partitionKey = "beforefoottraffic" + $((Get-Date -Format MM-dd-yyyy).ToString())
            if(![bool]($json.PSobject.Properties.name -match "beforefoottraffic"))
            {$json | Add-Member -MemberType NoteProperty -Name 'beforefoottraffic' -Value $partitionKey }
            $key=$json.beforefoottraffic
        }
        elseif ($name.Basename -eq "retailcosmos") {
            $key = $json.TransactionType
        }
        elseif ($name.Basename -eq "inventorydb") {
            $key = $json.InventoryType
        }
        $body=ConvertTo-Json $json
        $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    }
}
