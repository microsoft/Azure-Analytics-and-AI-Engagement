// Defender for Cloud plans — deployed at subscription scope
// Run: az deployment sub create --location eastus --template-file defender.bicep
targetScope = 'subscription'

// Defender for Containers: scans AKS workloads + container images in ACR
resource defenderContainers 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'Containers'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for App Service / Key Vault (optional but recommended)
resource defenderKeyVault 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'KeyVaults'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender CSPM: populates the "Recommendations" blade in Defender for Cloud portal
resource defenderCspm 'Microsoft.Security/pricings@2023-01-01' = {
  name: 'CloudPosture'
  properties: {
    pricingTier: 'Standard'
  }
}

// Auto-provision the Log Analytics agent to AKS nodes
resource autoProvision 'Microsoft.Security/autoProvisioningSettings@2019-01-01' = {
  name: 'mma-agent'
  properties: {
    autoProvision: 'On'
  }
}
