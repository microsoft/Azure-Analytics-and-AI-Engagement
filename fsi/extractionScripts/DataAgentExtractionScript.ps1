# =====================================================================
# Extract Data Agent (Handles 200 OK & 202 Accepted)
# =====================================================================
$sourceWsId    = ""
$sourceAgentId = ""

RefreshTokens
$headers = @{
    Authorization  = "Bearer $global:fabric"
    "Content-Type" = "application/json"
}

Write-Host "Extracting Data Agent definition..."
$exportUrl = "https://api.fabric.microsoft.com/v1/workspaces/$sourceWsId/items/$sourceAgentId/getDefinition"

$response = Invoke-WebRequest -Method Post -Uri $exportUrl -Headers $headers -Body "{}" -ErrorAction Stop

    if ($response.StatusCode -eq 200) {
        Write-Host "Extraction completed instantly."
        $agentDefinition = $response.Content | ConvertFrom-Json
        $agentDefinition | ConvertTo-Json -Depth 10 | Out-File "AgentDefinition.json" -Encoding UTF8
        Write-Host "Agent successfully saved to AgentDefinition.json"
    } elseif ($response.StatusCode -eq 202) {
        $operationUrl = $response.Headers["Location"]
        if ($operationUrl -is [array]) { $operationUrl = $operationUrl[0] }

        Write-Host "Waiting for background extraction..."
        do {
            Start-Sleep -Seconds 5
            $statusResp = Invoke-RestMethod -Method Get -Uri $operationUrl -Headers $headers
        } while ($statusResp.status -eq "Running" -or $statusResp.status -eq "NotStarted")

        if ($statusResp.status -eq "Succeeded") {
            $agentDefinition = Invoke-RestMethod -Method Get -Uri "$operationUrl/result" -Headers $headers
            $agentDefinition | ConvertTo-Json -Depth 10 | Out-File "AgentDefinition.json" -Encoding UTF8
            Write-Host "Agent successfully saved to AgentDefinition.json"
        } else {
            Write-Host "Extraction Failed!"
        }
    }
