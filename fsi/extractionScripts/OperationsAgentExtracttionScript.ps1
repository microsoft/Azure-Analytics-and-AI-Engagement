# =====================================================================
# Standalone Extraction Script for 'Operations agent'
# =====================================================================

$sourceWorkspaceName = "DPoC_Development"
$agentName           = "FSI_Operations_Agent_z7qc04s"
$outputDir           = "./"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$fabricToken = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$headers = @{
    "Authorization" = "Bearer $fabricToken"
    "Content-Type"  = "application/json"
}

Write-Host "Resolving source workspace ID..."
$workspaces = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces" -Headers $headers
$sourceWs = $workspaces.value | Where-Object { $_.displayName -eq $sourceWorkspaceName }
if (-not $sourceWs) { throw "Source workspace '$sourceWorkspaceName' not found." }
$sourceWsId = $sourceWs.id

Write-Host "Locating Operations agent in source workspace..."
$agents = Invoke-RestMethod -Method Get -Uri "https://api.fabric.microsoft.com/v1/workspaces/$sourceWsId/operationsAgents" -Headers $headers
$sourceAgent = $agents.value | Where-Object { $_.displayName -eq $agentName }
if (-not $sourceAgent) { throw "Operations agent '$agentName' not found in source workspace." }
$agentId = $sourceAgent.id

Write-Host "Triggering getDefinition for Operations agent ID: $agentId..."
$getDefUri = "https://api.fabric.microsoft.com/v1/workspaces/$sourceWsId/operationsAgents/$agentId/getDefinition?format=OperationsAgentV1"
$response = Invoke-RestMethod -Method Post -Uri $getDefUri -Headers $headers -ResponseHeadersVariable getDefHeaders

if ($getDefHeaders["Location"]) {
    $opUrl = @($getDefHeaders["Location"])[0]
    do {
        Start-Sleep -Seconds 3
        $opStatus = Invoke-RestMethod -Method Get -Uri $opUrl -Headers $headers
    } while ($opStatus.status -eq "Running")
    $definitionData = $opStatus.result
} else {
    $definitionData = $response
}

$outputPath = Join-Path (Get-Location) "$outputDir/OperationsAgentDefinition.json"
$definitionData | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8

Write-Host "Operations agent definition successfully extracted and saved to: $outputPath"