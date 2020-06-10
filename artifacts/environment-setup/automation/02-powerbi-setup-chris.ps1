$templatesPath = ".\artifacts\environment-setup\templates"

$tokenValue = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
$global:powerbiToken = $tokenValue;

$wsid = Get-PowerBIWorkspaceId "asa-exp";

Write-Information "Uploading PowerBI Reports"

Upload-PowerBIReport $wsId "1-CDP Vision Demo" "C:\github\solliancenet\azure-synapse-wwi-lab\artifacts\environment-setup\reports\1. CDP Vision Demo.pbix"
Upload-PowerBIReport $wsId "2-Billion Rows Demo.pbix" "C:\github\solliancenet\azure-synapse-wwi-lab\artifacts\environment-setup\reports\2. Billion Rows Demo.pbix"
Upload-PowerBIReport $wsId "Phase 2 CDP Vision Demo.pbix" "C:\github\solliancenet\azure-synapse-wwi-lab\artifacts\environment-setup\reports\(Phase 2) CDP Vision Demo v1.pbix"

$powerBIName = "asaexppowerbi$($uniqueId)"
$workspaceName = "asaexpworkspace$($uniqueId)"

Write-Information "Create PowerBI linked service $($keyVaultName)"

$result = Create-PowerBILinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $powerBIName -WorkspaceId $newPowerBIWorkSpace.id
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Setting PowerBI Database Connection"

$powerBIReports = [ordered]@{
    "2-Billion Rows Demo" = @{ 
            Category = "reports"
            Valid = $false
    }
    "Phase 2 CDP Vision Demo" = @{ 
            Category = "reports"
            Valid = $false
    }
}

$powerBIDataSetConnectionTemplate = Get-Content -Path "$($templatesPath)/powerbi_dataset_connection.json"

$powerBIDataSetConnectionTemplate = Get-Content -Path "C:\github\solliancenet\azure-synapse-wwi-lab\artifacts\environment-setup\templates\powerbi_dataset_connection.json"

foreach ($powerBIReportName in $powerBIReports.Keys) {

    Write-Information "Setting database connection for $($powerBIReportName)"

    $powerNIDataSetConnectionUpdateRequest = $powerBIDataSetConnectionTemplate.Replace("#SERVER#", "asaexpworkspace$($uniqueId).sql.azuresynapse.net").Replace("#DATABASE#", "SQLPool01") |Out-String

    Update-PowerBIDataset $wsId $powerBIReportName $powerNIDataSetConnectionUpdateRequest;   
}