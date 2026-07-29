targetScope = 'resourceGroup'

@description('Azure region.')
param location string = resourceGroup().location

@description('Production environment name suffix.')
param environmentName string = 'prod'

@description('Name of existing sandbox Container App to promote from.')
param sandboxContainerAppName string

@description('Production Container App name.')
param productionAppName string = 'hcp-portal-prod'

@description('Name of existing Azure Container Registry in this resource group.')
param acrName string

@description('Name of existing Azure Key Vault in this resource group.')
param keyVaultName string

@description('Full Key Vault URI for app runtime.')
param keyVaultUri string

@description('Optional Azure App Configuration endpoint URI.')
param appConfigEndpoint string = ''

@description('CPU cores for production app.')
param cpu string = '0.5'

@description('Memory for production app.')
param memory string = '1.0Gi'

@description('Minimum replica count for production app.')
param minReplicas int = 2

@description('Maximum replica count for production app.')
param maxReplicas int = 6

@description('APIM service name.')
param apimName string

@description('APIM publisher email.')
param apimPublisherEmail string

@description('APIM publisher name.')
param apimPublisherName string

@description('OAuth2 authorization endpoint URL.')
param oauth2AuthorizationEndpoint string

@description('OAuth2 token endpoint URL.')
param oauth2TokenEndpoint string

@description('OpenID configuration URL for JWT validation.')
param openIdConfigUrl string

@description('Expected JWT audience value.')
param jwtAudience string

@description('OAuth2 client ID for APIM authorization server metadata.')
param oauth2ClientId string

var logAnalyticsName = 'law-hcp-portal-${environmentName}'
var containerEnvironmentName = 'acae-hcp-portal-${environmentName}'

resource sandboxApp 'Microsoft.App/containerApps@2024-03-01' existing = {
  name: sandboxContainerAppName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource productionApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: productionAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: managedEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: 'system'
        }
      ]
      activeRevisionsMode: 'Single'
    }
    template: {
      containers: [
        {
          name: 'hcp-portal'
          image: sandboxApp.properties.template.containers[0].image
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
            {
              name: 'AZURE_KEYVAULT_URI'
              value: keyVaultUri
            }
            {
              name: 'AZURE_APPCONFIG_ENDPOINT'
              value: appConfigEndpoint
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, productionApp.id, 'acrpull')
  scope: acr
  properties: {
    principalId: productionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, productionApp.id, 'kv-secrets-user')
  scope: keyVault
  properties: {
    principalId: productionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  }
}

module apim './modules/apim.bicep' = {
  name: 'apim-hcp-portal-prod'
  params: {
    apimName: apimName
    location: location
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    apiName: 'hcp-portal'
    apiDisplayName: 'HcpPortal API'
    apiPath: 'hcp-portal'
    apiVersion: 'v1'
    oauth2AuthorizationEndpoint: oauth2AuthorizationEndpoint
    oauth2TokenEndpoint: oauth2TokenEndpoint
    openIdConfigUrl: openIdConfigUrl
    jwtAudience: jwtAudience
    oauth2ClientId: oauth2ClientId
    backendUrl: 'https://${productionApp.properties.configuration.ingress.fqdn}'
  }
}

@description('Promoted production image reference copied from sandbox app.')
output promotedImage string = sandboxApp.properties.template.containers[0].image

@description('Production Container App URL.')
output productionAppUrl string = 'https://${productionApp.properties.configuration.ingress.fqdn}'

@description('Production APIM gateway URL.')
output apimGatewayUrl string = apim.outputs.apimGatewayUrl

@description('Production APIM API resource ID.')
output apimApiResourceId string = apim.outputs.apiResourceId
