// ─── AKS Cluster ─────────────────────────────────────────────────────────────
// - System-assigned managed identity (control-plane)
// - OIDC issuer + Workload Identity enabled
// - Azure CNI Overlay (no pre-existing VNet required)
// - Web Application Routing addon (ingress class: webapprouting.kubernetes.azure.com)
// - Default system node pool: Standard_DS2_v2, 2 nodes

@description('AKS cluster name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: name
    // OIDC issuer — required for Workload Identity
    oidcIssuerProfile: {
      enabled: true
    }
    // Workload Identity
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    // Azure CNI Overlay — no pre-existing VNet required
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'Overlay'
      podCidr: '10.244.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      loadBalancerSku: 'standard'
    }
    // Web App Routing (nginx-based managed ingress controller)
    ingressProfile: {
      webAppRouting: {
        enabled: true
      }
    }
    agentPoolProfiles: [
      {
        name: 'system'
        count: 2
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        osDiskSizeGB: 128
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
      }
    ]
  }
}

@description('AKS cluster name.')
output aksName string = aks.name

@description('OIDC issuer URL — used to create UAMI federated credentials.')
output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL

@description('Object ID of the AKS kubelet managed identity — used for AcrPull role assignment.')
output kubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
