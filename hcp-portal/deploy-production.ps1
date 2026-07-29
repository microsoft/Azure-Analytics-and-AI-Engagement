[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$SandboxAppName,

    [Parameter(Mandatory = $true)]
    [string]$ProdAppName,

    [Parameter(Mandatory = $true)]
    [string]$AcrName,

    [Parameter(Mandatory = $true)]
    [string]$KeyVaultName,

    [Parameter(Mandatory = $true)]
    [string]$KeyVaultUri,

    [Parameter(Mandatory = $true)]
    [string]$ApimName,

    [Parameter(Mandatory = $true)]
    [string]$ApimPublisherEmail,

    [Parameter(Mandatory = $true)]
    [string]$ApimPublisherName,

    [Parameter(Mandatory = $true)]
    [string]$OAuth2AuthorizationEndpoint,

    [Parameter(Mandatory = $true)]
    [string]$OAuth2TokenEndpoint,

    [Parameter(Mandatory = $true)]
    [string]$OpenIdConfigUrl,

    [Parameter(Mandatory = $true)]
    [string]$JwtAudience,

    [Parameter(Mandatory = $true)]
    [string]$OAuthClientId,

    [Parameter(Mandatory = $false)]
    [string]$AppConfigEndpoint = '',

    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = 'prod',

    [Parameter(Mandatory = $false)]
    [string]$DeploymentName,

    [Parameter(Mandatory = $false)]
    [string]$Cpu = '0.5',

    [Parameter(Mandatory = $false)]
    [string]$Memory = '1.0Gi',

    [Parameter(Mandatory = $false)]
    [int]$MinReplicas = 2,

    [Parameter(Mandatory = $false)]
    [int]$MaxReplicas = 6
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptRoot

if (-not $DeploymentName) {
    $DeploymentName = "hcp-portal-prod-$((Get-Date).ToString('yyyyMMddHHmmss'))"
}

Write-Host "[1/4] Setting Azure subscription to '$SubscriptionId'..."
az account set --subscription $SubscriptionId | Out-Null

Write-Host "[2/4] Ensuring resource group '$ResourceGroup' exists in '$Location'..."
az group create --name $ResourceGroup --location $Location --output none

Write-Host "[3/4] Deploying infra/production.bicep (deployment: $DeploymentName)..."
$deploymentResultJson = az deployment group create `
    --name $DeploymentName `
    --resource-group $ResourceGroup `
    --template-file "infra/production.bicep" `
    --parameters location=$Location `
                 environmentName=$EnvironmentName `
                 sandboxContainerAppName=$SandboxAppName `
                 productionAppName=$ProdAppName `
                 acrName=$AcrName `
                 keyVaultName=$KeyVaultName `
                 keyVaultUri=$KeyVaultUri `
                 appConfigEndpoint=$AppConfigEndpoint `
                 cpu=$Cpu `
                 memory=$Memory `
                 minReplicas=$MinReplicas `
                 maxReplicas=$MaxReplicas `
                 apimName=$ApimName `
                 apimPublisherEmail=$ApimPublisherEmail `
                 apimPublisherName=$ApimPublisherName `
                 oauth2AuthorizationEndpoint=$OAuth2AuthorizationEndpoint `
                 oauth2TokenEndpoint=$OAuth2TokenEndpoint `
                 openIdConfigUrl=$OpenIdConfigUrl `
                 jwtAudience=$JwtAudience `
                 oauth2ClientId=$OAuthClientId `
    --output json

$deploymentResult = $deploymentResultJson | ConvertFrom-Json

$productionAppUrl = $deploymentResult.properties.outputs.productionAppUrl.value
$apimGatewayUrl = $deploymentResult.properties.outputs.apimGatewayUrl.value

Write-Host "[4/4] Deployment complete."
Write-Host "Production ACA URL: $productionAppUrl"
Write-Host "APIM Gateway URL: $apimGatewayUrl"
