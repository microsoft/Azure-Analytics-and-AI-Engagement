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
$cosmos_database_name = "sample-database"
$cosmos_database_name_SampleDB = "SampleDB"
$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
$concatString = "$random$init"
$db_graph_fintax_name = "db-acc-graph-fintax-$concatString"


#COSMOS Section
Write-Host  "-----------------Uploading Cosmos Data --------------"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $db_graph_fintax_name
$cosmos = Get-ChildItem "../artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    if($name.Basename -eq "import2" -or $name.Basename -eq "import3" -or $name.Basename -eq "Persons") {
        $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmos_database_name_SampleDB -ResourceGroup $rgName   
    } 
    elseif($name.Basename -eq "bookCollection" -or $name.Basename -eq "graph2" -or $name.Basename -eq "sample-graph") {
        $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $cosmos_database_name -ResourceGroup $rgName
    }
    $path="../artifacts/cosmos/"+$name.BaseName+".json"
    $document=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $document

    foreach($json in $document)
    {
        if($name.Basename -eq "import2" -or $name.Basename -eq "import3") {
            $id = New-Guid
            $partitionKey = "partitionKey" + $((Get-Date -Format MM-dd-yyyy).ToString())
            if(![bool]($json.PSobject.Properties.name -match "id"))
            {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
            if(![bool]($json.PSobject.Properties.name -match "partitionKey"))
            {$json | Add-Member -MemberType NoteProperty -Name 'partitionKey' -Value $partitionKey }
            $key=$json.partitionKey
        }
        if($name.Basename -eq "Persons" -or $name.Basename -eq "bookCollection") {
            $id = New-Guid
            $key=$json.name
            if(![bool]($json.PSobject.Properties.name -match "id"))
            {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
            if(![bool]($json.PSobject.Properties.name -match "name"))
            {$json | Add-Member -MemberType NoteProperty -Name 'name' -Value $id}
        }
        if($name.Basename -eq "graph2" -or $name.Basename -eq "sample-graph") {
            $id = New-Guid
            $key=$json.pk
            if(![bool]($json.PSobject.Properties.name -match "id"))
            {$json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id}
            if(![bool]($json.PSobject.Properties.name -match "pk"))
            {$json | Add-Member -MemberType NoteProperty -Name 'pk' -Value 'pk'}
        }
        $body=ConvertTo-Json $json
        $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    }
} 
