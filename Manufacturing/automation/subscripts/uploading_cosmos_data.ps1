function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
az login

#for powershell...
Connect-AzAccount -DeviceCode

#will be done as part of the cloud shell start - README

#remove-item MfgAI -recurse -force
#git clone -b real-time https://github.com/microsoft/Azure-Analytics-and-AI-Engagement.git MfgAI

#cd 'MfgAI/Manufacturing/automation'

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

#TODO pick the resource group...
$rgName = read-host "Enter the resource Group Name";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$cosmos_account_name_mfgdemo = "cosmosdb-mfgdemo-$random$init"
$cosmos_database_name_mfgdemo_manufacturing = "manufacturing"

Write-Host  "-----------------Uploading Cosmos Data Started--------------"
#uploading Cosmos data
Add-Content log.txt "-----------------uploading Cosmos data--------------"
RefreshTokens
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmos_account_name_mfgdemo
$databaseName = $cosmos_database_name_mfgdemo_manufacturing
$cosmos = Get-ChildItem "../artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $rgName
    $path="../artifacts/cosmos/"+$name.BaseName+".json"
    $document=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $document
	#$newRU=4000
	#az cosmosdb sql container throughput update -a $cosmosDbAccountName -g $rgName -d $databaseName -n $collection --throughput $newRU
	
    foreach($json in $document)
    {
        $key=$json.SyntheticPartitionKey
        $id = New-Guid
       if(![bool]($json.PSobject.Properties.name -match "id"))
       {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
       if(![bool]($json.PSobject.Properties.name -match "SyntheticPartitionKey"))
       {$json | Add-Member -MemberType NoteProperty -Name 'SyntheticPartitionKey' -Value $id}
        $body=ConvertTo-Json $json
        New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    }
	
	#$newRU=400
	#az cosmosdb sql container throughput update -a $cosmosDbAccountName -g $rgName -d $databaseName -n $collection --throughput $newRU
} 

Write-Host  "-----------------Uploading Cosmos Data Complete--------------"
