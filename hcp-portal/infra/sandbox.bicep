targetScope = 'resourceGroup'

@description('Unique suffix for ephemeral sandbox resources.')
param sandboxSuffix string

@description('Azure region for the sandbox resources.')
param location string = resourceGroup().location

@description('Name of an existing Azure Container Registry in this resource group.')
param acrName string

@description('Container image reference, for example myacr.azurecr.io/hcp-portal:sandbox-20260623093000.')
param image string

@description('Azure Key Vault URI injected into the container environment.')
param keyVaultUri string

@description('Azure App Configuration endpoint URI injected into the container environment.')
param appConfigEndpoint string = ''

@description('CPU cores for the container app.')
param cpu string = '0.5'

@description('Memory for the container app.')
param memory string = '1.0Gi'

@description('Minimum replica count for the sandbox app.')
param minReplicas int = 0

@description('Maximum replica count for the sandbox app.')
param maxReplicas int = 2

var appName = 'hcp-portal-sbx-${sandboxSuffix}'
var environmentName = 'acae-hcp-sbx-${sandboxSuffix}'
var workspaceName = 'law-hcp-sbx-${sandboxSuffix}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 7
  }
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
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

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
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
          image: image
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
  name: guid(acr.id, containerApp.id, 'acrpull')
  scope: acr
  properties: {
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

@description('Ephemeral sandbox app name.')
output appName string = containerApp.name

@description('Ephemeral managed environment name.')
output managedEnvironmentName string = managedEnvironment.name

@description('Ephemeral sandbox URL.')
output appUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'

@description('Managed identity principal ID for role assignments.')
output appPrincipalId string = containerApp.identity.principalId
