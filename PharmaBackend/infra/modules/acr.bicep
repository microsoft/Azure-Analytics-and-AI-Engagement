// ─── Azure Container Registry ─────────────────────────────────────────────────
// Standard SKU; admin user disabled; AcrPull role granted to the AKS kubelet
// identity is handled in main.bicep after the AKS cluster is created.

@description('Prefix for resource names (alphanumeric, no hyphens).')
param prefix string

@description('Environment name (e.g. prod, staging, dev).')
param env string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

// ACR name: globally unique, 5–50 alphanumeric chars.
// Strip hyphens from prefix/env before concatenation.
var cleanPrefix = replace(toLower(prefix), '-', '')
var cleanEnv    = replace(toLower(env), '-', '')
var acrName     = '${cleanPrefix}pharma${cleanEnv}${uniqueString(resourceGroup().id)}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

@description('Resource ID of the ACR.')
output acrId string = acr.id

@description('Globally unique ACR name.')
output acrName string = acr.name

@description('ACR login server (e.g. myacr.azurecr.io).')
output acrLoginServer string = acr.properties.loginServer
