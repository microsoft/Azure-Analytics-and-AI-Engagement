#!/usr/bin/env pwsh
<#
.SYNOPSIS
    One-time bootstrap: creates Azure resources and sets all GitHub Actions secrets automatically.

.DESCRIPTION
    Run this once before your first push. It will:
      1. Create the Azure resource group (if not exists)
      2. Create Azure Container Registry
      3. Create AKS Automatic cluster
      4. Create a service principal with Contributor role
      5. Generate a strong SQL admin password
      6. Set all 8 GitHub secrets via GitHub CLI

.PREREQUISITES
    - Azure CLI   (az)        : https://aka.ms/installazurecliwindows
    - GitHub CLI  (gh)        : https://cli.github.com
    - kubectl                 : az aks install-cli  OR  winget install kubectl
    - Run: az login
    - Run: gh auth login

.EXAMPLE
    .\bootstrap.ps1 `
        -ResourceGroup  "hcp-rg" `
        -Location       "eastus" `
        -AcrName        "hcpacr$(-join ((97..122) | Get-Random -Count 6 | % {[char]$_}))" `
        -AksClusterName "hcp-aks" `
        -GitHubRepo     "microsoftdemos/Modernize-with-Confidence"
#>

param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $GitHubRepo,
    [string] $Location       = "eastus",
    [string] $AcrName        = "",
    [string] $AksClusterName = "hcp-aks",
    [string] $ApimEmail      = "admin@caldova.com",
    [string] $SubscriptionId = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── helpers ──────────────────────────────────────────────────────────────────
function Log-Step ([string]$msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Log-Ok   ([string]$msg) { Write-Host "   OK: $msg" -ForegroundColor Green }
function Log-Info ([string]$msg) { Write-Host "   $msg" -ForegroundColor Gray }

function New-StrongPassword {
    $upper   = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZ'
    $lower   = [char[]]'abcdefghjkmnpqrstuvwxyz'
    $digits  = [char[]]'23456789'
    $special = [char[]]'!@#$%^&*'
    $pool    = $upper + $lower + $digits + $special
    $pwd     = ($upper  | Get-Random) `
             + ($lower  | Get-Random) `
             + ($digits | Get-Random) `
             + ($special| Get-Random) `
             + (-join ($pool | Get-Random -Count 20))
    return -join ($pwd.ToCharArray() | Get-Random -Count $pwd.Length)
}

function Assert-Tool ([string]$name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "'$name' is not installed or not in PATH. See script header for install links."
    }
}

# Auto-generate ACR name if not provided
if ([string]::IsNullOrEmpty($AcrName)) {
    $suffix = -join (1..6 | ForEach-Object { [char](97 + (Get-Random -Maximum 26)) })
    $AcrName = "hcpacr$suffix"
}

# ── pre-flight ────────────────────────────────────────────────────────────────
Log-Step "Checking required tools"
Assert-Tool "az"
Assert-Tool "gh"
Assert-Tool "kubectl"
Log-Ok "All tools found"

# ── Azure subscription ────────────────────────────────────────────────────────
Log-Step "Resolving Azure subscription"
if ($SubscriptionId -ne "") {
    az account set --subscription $SubscriptionId | Out-Null
}
$sub = az account show --query "{id:id,name:name}" -o json | ConvertFrom-Json
Log-Ok "Using subscription: $($sub.name) ($($sub.id))"
$SubscriptionId = $sub.id

# ── Resource group ────────────────────────────────────────────────────────────
Log-Step "Resource group: $ResourceGroup"
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    az group create --name $ResourceGroup --location $Location | Out-Null
    Log-Ok "Created"
} else {
    Log-Ok "Already exists"
}

# ── Azure Container Registry ──────────────────────────────────────────────────
Log-Step "Azure Container Registry: $AcrName"
$acrExists = az acr show --name $AcrName --resource-group $ResourceGroup --query "name" -o tsv 2>$null
if (-not $acrExists) {
    az acr create `
        --resource-group $ResourceGroup `
        --name $AcrName `
        --sku Basic `
        --admin-enabled true | Out-Null
    Log-Ok "Created"
} else {
    Log-Ok "Already exists"
}

$acrLoginServer = az acr show --name $AcrName --query "loginServer" -o tsv
$acrCreds       = az acr credential show --name $AcrName -o json | ConvertFrom-Json
$acrUsername    = $acrCreds.username
$acrPassword    = $acrCreds.passwords[0].value
Log-Info "Login server: $acrLoginServer"

# ── AKS Automatic cluster ─────────────────────────────────────────────────────
Log-Step "AKS Automatic cluster: $AksClusterName"
$aksExists = az aks show --name $AksClusterName --resource-group $ResourceGroup --query "name" -o tsv 2>$null
if (-not $aksExists) {
    Log-Info "Creating AKS Automatic cluster (this takes ~5 minutes)..."
    az aks create `
        --resource-group $ResourceGroup `
        --name $AksClusterName `
        --sku automatic `
        --enable-managed-identity `
        --attach-acr $AcrName `
        --generate-ssh-keys | Out-Null
    Log-Ok "Created"
} else {
    # Ensure ACR pull role is assigned
    az aks update `
        --resource-group $ResourceGroup `
        --name $AksClusterName `
        --attach-acr $AcrName | Out-Null
    Log-Ok "Already exists (ACR attachment verified)"
}

Log-Step "Fetching kubeconfig"
az aks get-credentials `
    --resource-group $ResourceGroup `
    --name $AksClusterName `
    --overwrite-existing | Out-Null
$kubeConfigData = [Convert]::ToBase64String(
    [System.IO.File]::ReadAllBytes("$env:USERPROFILE\.kube\config")
)
Log-Ok "kubeconfig encoded (length: $($kubeConfigData.Length))"

# ── Service principal for GitHub Actions ─────────────────────────────────────
Log-Step "Service principal for GitHub Actions"
$spName = "github-actions-hcp-$ResourceGroup"
$scope  = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup"

$spClientId     = ""
$spClientSecret = ""
$spTenantId     = ""

# Check if SP already exists
$existingSp = az ad sp list --display-name $spName --query "[0].appId" -o tsv 2>$null
if ($existingSp) {
    Log-Info "SP exists ($existingSp) — resetting credentials"
    $resetResult    = az ad sp credential reset --id $existingSp --years 1 -o json | ConvertFrom-Json
    $spClientId     = $resetResult.appId
    $spClientSecret = $resetResult.password
    $spTenantId     = $resetResult.tenant

    az role assignment create `
        --assignee $spClientId `
        --role "Contributor" `
        --scope $scope 2>$null | Out-Null
} else {
    Log-Info "Creating new SP..."
    $rawSdkAuth     = az ad sp create-for-rbac --name $spName --role "Contributor" --scopes $scope --sdk-auth -o json | ConvertFrom-Json
    $spClientId     = $rawSdkAuth.clientId
    $spClientSecret = $rawSdkAuth.clientSecret
    $spTenantId     = $rawSdkAuth.tenantId
    Log-Ok "Created SP: $spClientId"
}

# Build full SDK auth JSON (format required by azure/login@v2)
$azCredentialsJson = [pscustomobject]@{
    clientId                       = $spClientId
    clientSecret                   = $spClientSecret
    subscriptionId                 = $SubscriptionId
    tenantId                       = $spTenantId
    activeDirectoryEndpointUrl     = 'https://login.microsoftonline.com'
    resourceManagerEndpointUrl     = 'https://management.azure.com/'
    activeDirectoryGraphResourceId = 'https://graph.windows.net/'
    sqlManagementEndpointUrl       = 'https://management.core.windows.net:8443/'
    galleryEndpointUrl             = 'https://gallery.azure.com/'
    managementEndpointUrl          = 'https://management.core.windows.net/'
} | ConvertTo-Json -Compress
Log-Ok "Service principal ready"

# ── Generate SQL password ─────────────────────────────────────────────────────
Log-Step "Generating SQL admin password"
$sqlPassword = New-StrongPassword
Log-Ok "Generated (length: $($sqlPassword.Length))"

# ── Set GitHub secrets ────────────────────────────────────────────────────────
Log-Step "Setting GitHub Actions secrets on: $GitHubRepo"

$secrets = @{
    "AZURE_CONTAINER_REGISTRY"  = $acrLoginServer
    "AZURE_REGISTRY_USERNAME"   = $acrUsername
    "AZURE_REGISTRY_PASSWORD"   = $acrPassword
    "KUBE_CONFIG_DATA"          = $kubeConfigData
    "AZURE_CREDENTIALS"         = $azCredentialsJson
    "AZURE_RESOURCE_GROUP"      = $ResourceGroup
    "AZURE_SQL_ADMIN_PASSWORD"  = $sqlPassword
    "AZURE_APIM_PUBLISHER_EMAIL"= $ApimEmail
}

foreach ($kv in $secrets.GetEnumerator()) {
    $kv.Value | gh secret set $kv.Key --repo $GitHubRepo
    Log-Ok "Set: $($kv.Key)"
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " Bootstrap complete. All 8 secrets set on $GitHubRepo" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host " Azure resources in resource group: $ResourceGroup" -ForegroundColor White
Write-Host "   ACR:  $acrLoginServer"                          -ForegroundColor Gray
Write-Host "   AKS:  $AksClusterName"                         -ForegroundColor Gray
Write-Host ""
Write-Host " Next step: push to main branch to trigger the pipeline" -ForegroundColor Yellow
Write-Host "   git push origin main"                                  -ForegroundColor Yellow
Write-Host ""
