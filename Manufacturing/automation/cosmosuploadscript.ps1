param (
    [Parameter(Mandatory = $false)][string]$cosmosDbAccountName,
	[Parameter(Mandatory = $false)][string]$databaseName,
	[Parameter(Mandatory = $false)][string]$rgName
		)

$cosmosDbAccountName = $cosmos_account_name_mfgdemo
$databaseName = $cosmos_database_name_mfgdemo_manufacturing
$cosmos = Get-ChildItem "./artifacts/cosmos" | Select BaseName 

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $rgName
    $path="./artifacts/cosmos/"+$name.BaseName+".json"
    $document=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $document

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
} 