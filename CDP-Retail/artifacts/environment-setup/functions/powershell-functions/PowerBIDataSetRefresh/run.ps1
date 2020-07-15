using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$datasetId = $Request.Query.DataSetId

$powerBIRefreshToken = $env:powerBIRefreshToken
$tenantId = $env:tenantId
$ropcBodyPowerBI = "refresh_token=$($powerBIRefreshToken)&client_id=04b07795-8ddb-461a-bbee-02f9e1bf7b46&scope=https://analysis.windows.net/powerbi/api/.default&grant_type=refresh_token"
$result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/$($tenantId)/oauth2/v2.0/token" `
                -Method POST -Body $ropcBodyPowerBI -ContentType "application/x-www-form-urlencoded"
$access_token = $result.access_token

$result = Invoke-RestMethod  -Uri "https://api.powerbi.com/v1.0/myorg/datasets/$($datasetId)/refreshes" `
                -Method POST -Body "{""notifyOption"":""MailOnCompletion""}" -ContentType "application/json" -Headers @{ Authorization="Bearer $access_token" }

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = ""
}) 
