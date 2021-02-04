cd 'MfgAI/Manufacturing/automation'
az login -u "poc-mfg-user@cloudlabsaioutlook.onmicrosoft.com" -p "Vaso82554"
$subscriptionId=az account show|ConvertFrom-Json
$subscriptionId=$subscriptionId.Id
$tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$powerbitoken = $tokenValue;
$synapseWorkspaceName = "manufacturingdemodemosckhhaablgxqsu"
$wsId="0b4541f0-10c2-4d51-a5d1-dac80b5f2bdb"
$sqlPoolName = "ManufacturingDW"

$powerBIDataSetConnectionTemplate = Get-Content -Path "./artifacts/templates/powerbi_dataset_connection.json"

$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets"
$datasets = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" }
$powerBIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#TARGET_SERVER#", "$($synapseWorkspaceName).sql.azuresynapse.net").Replace("#TARGET_DATABASE#", $sqlPoolName) |Out-String

$sourceServers = @("manufacturingdemopoc20tifk7nvs2hhqs.sql.azuresynapse.net")
foreach($dataset in $dataSets.value)
{
foreach($source in $sourceServers)
    {

        #ManufacturingDW
        $powerBIReportDataSetConnectionUpdateRequest = $powerBIDataSetConnectionUpdateRequest.Replace("#SOURCE_SERVER#", $source).Replace("#SOURCE_DATABASE#", "ManufacturingDW") |Out-String
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/datasets/$($dataset.id)/Default.UpdateDatasources";
        try
        {
            $pbiResult = Invoke-RestMethod -Uri $url -Method POST -Body $powerBIReportDataSetConnectionUpdateRequest -ContentType "application/json" -Headers @{ Authorization="Bearer $powerbitoken" } -ea SilentlyContinue;
            Add-Content log.txt $pbiResult  
        }
        catch
        {
        }
    }
}






