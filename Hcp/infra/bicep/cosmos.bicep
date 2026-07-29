param location string
param environmentName string = 'dev'
param accountName string = ''
param databaseName string = 'hcp-ai-memory'
param databaseThroughput int = 400
param publicNetworkAccess string = 'Enabled'
param networkAclBypass string = 'AzureServices'
param disableLocalAuth bool = false
param enableAutomaticFailover bool = false
param enableFreeTier bool = false
param consistencyLevel string = 'Session'
param boundedStalenessMaxIntervalInSeconds int = 300
param boundedStalenessMaxStalenessPrefix int = 100000
param ipRules array = []
param additionalWriteRegions array = []
param sqlRolePrincipalId string = ''

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var cosmosAccountName = empty(accountName) ? 'azcos${resourceToken}' : accountName
var secondaryCosmosLocations = [for region in additionalWriteRegions: {
  locationName: region.name
  failoverPriority: region.failoverPriority
  isZoneRedundant: region.?isZoneRedundant ?? false
}]
var cosmosLocations = concat([
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
], secondaryCosmosLocations)
var defaultSqlDataContributorRoleDefinitionId = '${cosmosAccount.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    publicNetworkAccess: publicNetworkAccess
    networkAclBypass: networkAclBypass
    disableKeyBasedMetadataWriteAccess: disableLocalAuth
    disableLocalAuth: disableLocalAuth
    isVirtualNetworkFilterEnabled: length(ipRules) > 0
    minimalTlsVersion: 'Tls12'
    locations: cosmosLocations
    consistencyPolicy: consistencyLevel == 'BoundedStaleness' ? {
      defaultConsistencyLevel: consistencyLevel
      maxIntervalInSeconds: boundedStalenessMaxIntervalInSeconds
      maxStalenessPrefix: boundedStalenessMaxStalenessPrefix
    } : {
      defaultConsistencyLevel: consistencyLevel
    }
    enableAutomaticFailover: enableAutomaticFailover
    enableFreeTier: enableFreeTier
    ipRules: [for rule in ipRules: {
      ipAddressOrRange: rule
    }]
  }
}

resource sqlDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  name: databaseName
  parent: cosmosAccount
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: databaseThroughput
    }
  }
}

resource conversationSessions 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: 'conversationSessions'
  parent: sqlDatabase
  properties: {
    resource: {
      id: 'conversationSessions'
      partitionKey: {
        paths: [
          '/tenantId'
        ]
        kind: 'Hash'
        version: 2
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}

resource conversationMessages 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: 'conversationMessages'
  parent: sqlDatabase
  properties: {
    resource: {
      id: 'conversationMessages'
      partitionKey: {
        paths: [
          '/conversationKey'
        ]
        kind: 'Hash'
        version: 2
      }
      defaultTtl: 7776000
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}

resource agentMemories 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: 'agentMemories'
  parent: sqlDatabase
  properties: {
    resource: {
      id: 'agentMemories'
      partitionKey: {
        paths: [
          '/memoryKey'
        ]
        kind: 'Hash'
        version: 2
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}

resource clinicianProfiles 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: 'clinicianProfiles'
  parent: sqlDatabase
  properties: {
    resource: {
      id: 'clinicianProfiles'
      partitionKey: {
        paths: [
          '/profileKey'
        ]
        kind: 'Hash'
        version: 2
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
    }
  }
}

resource sqlDataContributorAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = if (!empty(sqlRolePrincipalId)) {
  name: guid(cosmosAccount.id, sqlRolePrincipalId, 'SqlDataContributor')
  parent: cosmosAccount
  properties: {
    principalId: sqlRolePrincipalId
    roleDefinitionId: defaultSqlDataContributorRoleDefinitionId
    scope: '/'
  }
}

output accountName string = cosmosAccount.name
output endpoint string = cosmosAccount.properties.documentEndpoint
output databaseName string = databaseName
output publicNetworkAccess string = publicNetworkAccess