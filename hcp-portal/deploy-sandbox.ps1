[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$AcrName,

    [Parameter(Mandatory = $true)]
    [string]$AzureKeyVaultUri,

    [Parameter(Mandatory = $true)]
    [string]$AzureAppConfigEndpoint,

    [Parameter(Mandatory = $false)]
    [string]$Tag,

    [Parameter(Mandatory = $false)]
    [string]$Suffix,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptRoot

if (-not $Tag) {
    $Tag = "sandbox-$((Get-Date).ToString('yyyyMMddHHmmss'))"
}

if (-not $Suffix) {
    $Suffix = (Get-Date).ToString('yyyyMMddHHmmss')
}

if ($SubscriptionId) {
    az account set --subscription $SubscriptionId | Out-Null
}

Write-Host "[1/4] Ensuring resource group '$ResourceGroup' exists in '$Location'..."
az group create --name $ResourceGroup --location $Location --output none

Write-Host "[2/4] Resolving ACR login server for '$AcrName'..."
$loginServer = az acr show --name $AcrName --resource-group $ResourceGroup --query loginServer --output tsv
if (-not $loginServer) {
    throw "Unable to resolve login server for ACR '$AcrName' in resource group '$ResourceGroup'."
}

$image = "$loginServer/hcp-portal:$Tag"

Write-Host "[3/4] Building and pushing image '$image' with ACR Tasks..."
az acr build --registry $AcrName --image "hcp-portal:$Tag" --file Dockerfile .

Write-Host "[4/4] Deploying ephemeral ACA sandbox via Bicep..."
$deploymentName = "hcp-portal-sbx-$Suffix"
az deployment group create `
  --name $deploymentName `
  --resource-group $ResourceGroup `
  --template-file "infra/sandbox.bicep" `
  --parameters sandboxSuffix=$Suffix `
              location=$Location `
              acrName=$AcrName `
              image=$image `
              keyVaultUri=$AzureKeyVaultUri `
              appConfigEndpoint=$AzureAppConfigEndpoint

$appUrl = az deployment group show --resource-group $ResourceGroup --name $deploymentName --query "properties.outputs.appUrl.value" --output tsv
$appName = az deployment group show --resource-group $ResourceGroup --name $deploymentName --query "properties.outputs.appName.value" --output tsv

Write-Host "Sandbox deployment complete."
Write-Host "Container App: $appName"
Write-Host "URL: $appUrl"
