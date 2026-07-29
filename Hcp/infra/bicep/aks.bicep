// AKS Automatic — production-ready managed Kubernetes for the HCP Portal API tier.
// Automatic SKU handles node provisioning, security defaults, scaling, and workload identity.
param location string = resourceGroup().location
param environmentName string = 'dev'
param aksName string = ''
param clusterExists bool = false
param acrName string = ''
param kubernetesVersion string = ''

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var name = empty(aksName) ? 'hcp-aks-${take(resourceToken, 6)}' : aksName

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = if (!clusterExists) {
  name: name
  location: location
  sku: {
    name: 'Automatic'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: name
    kubernetesVersion: empty(kubernetesVersion) ? null : kubernetesVersion
    disableLocalAccounts: true
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        mode: 'System'
        count: 3
        vmSize: 'Standard_D4pds_v5'
        osType: 'Linux'
        osSKU: 'AzureLinux'
      }
    ]
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
      nodeOSUpgradeChannel: 'NodeImage'
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = if (!empty(acrName)) {
  name: acrName
}

var aksResourceId = resourceId('Microsoft.ContainerService/managedClusters', name)
var kubeletIdentityObjectId = reference(aksResourceId, '2024-09-01').identityProfile.kubeletidentity.objectId
var kubeletIdentityClientId = reference(aksResourceId, '2024-09-01').identityProfile.kubeletidentity.clientId
var aksFqdn = reference(aksResourceId, '2024-09-01').fqdn

// Grant AKS kubelet identity AcrPull on the ACR so image pulls need no admin credentials.
resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(acrName)) {
  name: guid(aksResourceId, 'AcrPull', acrName)
  scope: acr
  properties: {
    principalId: kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

output aksName string = name
output aksId string = aksResourceId
output aksFqdn string = aksFqdn
output kubeletIdentityObjectId string = kubeletIdentityObjectId
output kubeletIdentityClientId string = kubeletIdentityClientId
