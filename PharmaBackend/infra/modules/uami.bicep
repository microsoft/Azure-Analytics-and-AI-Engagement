// ─── User-Assigned Managed Identity + Federated Credential ───────────────────
// The UAMI is annotated on the pharma-backend Kubernetes ServiceAccount so the
// pod can authenticate to Azure services without storing credentials.
// The federated credential binds:
//   issuer  = AKS OIDC issuer URL
//   subject = system:serviceaccount:pharma:pharma-backend

@description('UAMI resource name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('AKS OIDC issuer URL (from aks module output).')
param aksOidcIssuerUrl string

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: uami
  name: 'pharma-backend-fedcred'
  properties: {
    issuer: aksOidcIssuerUrl
    subject: 'system:serviceaccount:pharma:pharma-backend'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

@description('Resource ID of the UAMI.')
output uamiId string = uami.id

@description('Client ID of the UAMI — annotate the K8s ServiceAccount with this value.')
output clientId string = uami.properties.clientId

@description('Principal (object) ID of the UAMI — used for RBAC role assignments.')
output principalId string = uami.properties.principalId
