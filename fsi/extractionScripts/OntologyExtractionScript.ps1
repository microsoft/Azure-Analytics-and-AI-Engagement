# Requires token: $global:fabric

$sourceWsId       = ""
$sourceOntologyId = ""

$headers = @{
    Authorization  = "Bearer $global:fabric"
    "Content-Type" = "application/json"
}

Write-Host "Extracting Ontology definition..."
$exportUrl = "https://api.fabric.microsoft.com/v1/workspaces/$sourceWsId/ontologies/$sourceOntologyId/getDefinition"

# Use Invoke-WebRequest to capture status codes and headers reliably
$response = Invoke-WebRequest -Method Post -Uri $exportUrl -Headers $headers -Body "{}" -ErrorAction Stop

if ($response.StatusCode -eq 200) {
    Write-Host "Extraction completed instantly (200 OK)."
    $ontologyDefinition = $response.Content | ConvertFrom-Json
    
    $ontologyDefinition | ConvertTo-Json -Depth 10 | Out-File "OntologyDefinition.json" -Encoding UTF8
    Write-Host "Ontology successfully saved to OntologyDefinition.json"
} elseif ($response.StatusCode -eq 202) {
    # Extract the background operation polling URL from the headers
    $operationUrl = $response.Headers["Location"]
    if ($operationUrl -is [array]) { $operationUrl = $operationUrl[0] }

    if (-not $operationUrl) {
        throw "Failed to retrieve the background operation URL from Location header."
    }

    Write-Host "Operation started asynchronously. Waiting for completion..."
    do {
        Start-Sleep -Seconds 5
        $statusResp = Invoke-RestMethod -Method Get -Uri $operationUrl -Headers $headers
        Write-Host "Status: $($statusResp.status)"
    } while ($statusResp.status -eq "Running" -or $statusResp.status -eq "NotStarted")

    if ($statusResp.status -eq "Succeeded") {
        Write-Host "Extraction complete! Downloading definition parts..."
        $resultUrl = "$operationUrl/result"
        $ontologyDefinition = Invoke-RestMethod -Method Get -Uri $resultUrl -Headers $headers
        
        $ontologyDefinition | ConvertTo-Json -Depth 10 | Out-File "OntologyDefinition.json" -Encoding UTF8
        Write-Host "Ontology successfully saved to OntologyDefinition.json"
    } else {
        Write-Host "Extraction Failed!"
        $statusResp | ConvertTo-Json -Depth 5
    }
}
