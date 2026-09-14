# =====================================================================
# Configuration & Token Initialization
# =====================================================================
$sourceWsId        = "ded5294c-c3fe-408c-a3c4-99fd93ffb29f"
$semanticModelId   = "8ee5d860-40c0-484c-a382-5bc5ee3f7f43"
$reportId          = "d8f615fa-ed2f-4931-b36b-aee9226fc591"

# Generate fresh access token
$global:fabric = az account get-access-token --resource "https://api.fabric.microsoft.com" --query accessToken -o tsv
$headers = @{
    Authorization  = "Bearer $global:fabric"
    "Content-Type" = "application/json"
}

# =====================================================================
# Universal Extraction Function (Handles 200 OK & 202 Accepted LROs)
# =====================================================================
function Export-FabricItem($workspaceId, $itemId, $outputFileName, $itemType) {
    Write-Host "Extracting $itemType definition..."
    $exportUrl = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/items/$itemId/getDefinition"
    
    # Use Invoke-WebRequest to capture the raw status code
    $response = Invoke-WebRequest -Method Post -Uri $exportUrl -Headers $headers -Body "{}" -ErrorAction Stop

    if ($response.StatusCode -eq 200) {
        Write-Host "Extraction completed instantly."
        $definition = $response.Content | ConvertFrom-Json
        $definition | ConvertTo-Json -Depth 10 | Out-File $outputFileName -Encoding UTF8
        Write-Host "Successfully saved to $outputFileName`n"
    }
    elseif ($response.StatusCode -eq 202) {
        $operationUrl = $response.Headers["Location"]
        if ($operationUrl -is [array]) { $operationUrl = $operationUrl[0] }

        Write-Host "Waiting for background extraction to package the $itemType..."
        do {
            Start-Sleep -Seconds 5
            $statusResp = Invoke-RestMethod -Method Get -Uri $operationUrl -Headers $headers
        } while ($statusResp.status -in @("Running", "NotStarted"))

        if ($statusResp.status -eq "Succeeded") {
            $definition = Invoke-RestMethod -Method Get -Uri "$operationUrl/result" -Headers $headers
            $definition | ConvertTo-Json -Depth 10 | Out-File $outputFileName -Encoding UTF8
            Write-Host "Successfully saved to $outputFileName`n"
        } else {
            Write-Host "Extraction Failed for $itemType!"
            $statusResp | ConvertTo-Json -Depth 5
        }
    }
}

# =====================================================================
# Extract Assets
# =====================================================================
Export-FabricItem -workspaceId $sourceWsId -itemId $semanticModelId -outputFileName "DashboardSemanticModel.json" -itemType "Semantic Model"
Export-FabricItem -workspaceId $sourceWsId -itemId $reportId -outputFileName "DashboardReport.json" -itemType "Report"
