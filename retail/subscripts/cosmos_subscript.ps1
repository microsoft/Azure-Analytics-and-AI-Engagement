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
$cosmos_database_name = "retail-foottraffic";
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$random$init";
$cosmosdb_retail2_name = "cosmosdb-retail2-$random$init";
if($cosmosdb_retail2_name.length -gt 43)
{
$cosmosdb_retail2_name = $cosmosdb_retail2_name.substring(0,43)
}


#COSMOS Section
Write-Host  "-----------------Uploading Cosmos Data --------------"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmosdb_retail2_name
$cosmos = Get-ChildItem "../artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmos_database_name -ResourceGroup $rgName
    $path="../artifacts/cosmos/"+$name.BaseName+".json"
    $documents=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $documents

    foreach($json in $document)
    {
		$key=$json.TransactionType
        if($name.Basename -eq "retaildb") {
            $id = New-Guid
            $partitionKey = "beforefoottraffic" + $((Get-Date -Format MM-dd-yyyy).ToString())
            if(![bool]($json.PSobject.Properties.name -match "id"))
            {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
            if(![bool]($json.PSobject.Properties.name -match "beforefoottraffic"))
            {$json | Add-Member -MemberType NoteProperty -Name 'beforefoottraffic' -Value $partitionKey }
            $key=$json.beforefoottraffic
        }

        $body=ConvertTo-Json $json
        $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    }
} 
