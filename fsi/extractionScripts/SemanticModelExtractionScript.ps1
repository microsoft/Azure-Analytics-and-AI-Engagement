# Requires token: $global:fabric

$sourceWsId    = ""
$sourceModelId = ""

$headers = @{
    Authorization  = "Bearer $global:fabric"
    "Content-Type" = "application/json"
}

Write-Host "Extracting Semantic Model (this may take a few seconds)..."
$exportUrl = "https://api.fabric.microsoft.com/v1/workspaces/$sourceWsId/items/$sourceModelId/getDefinition"

# 1. Trigger extraction and capture the headers (-ResponseHeadersVariable)
Invoke-RestMethod -Method Post -Uri $exportUrl -Headers $headers -Body "{}" -ResponseHeadersVariable resHeaders | Out-Null

# 2. Extract the polling URL from the Location header
$operationUrl = $resHeaders["Location"]
if ($operationUrl -is [array]) { $operationUrl = $operationUrl[0] }

if (-not $operationUrl) {
    throw "Failed to retrieve the background operation URL."
}

# 3. Poll the server until the file is ready
Write-Host "Operation started. Waiting for completion..."
do {
    Start-Sleep -Seconds 5
    $statusResp = Invoke-RestMethod -Method Get -Uri $operationUrl -Headers $headers
    Write-Host "Status: $($statusResp.status)"
} while ($statusResp.status -eq "Running" -or $statusResp.status -eq "NotStarted")

# 4. Download the final result
if ($statusResp.status -eq "Succeeded") {
    Write-Host "Extraction complete! Downloading the definition..."
    
    # The actual file is located at the /result endpoint
    $resultUrl = "$operationUrl/result"
    $modelDefinition = Invoke-RestMethod -Method Get -Uri $resultUrl -Headers $headers
    
    $modelDefinition | ConvertTo-Json -Depth 10 | Out-File "SemanticModelDefinition.json" -Encoding UTF8
    Write-Host "Model saved successfully to SemanticModelDefinition.json"
} else {
    Write-Host "Extraction Failed!"
    $statusResp | ConvertTo-Json -Depth 5
}
