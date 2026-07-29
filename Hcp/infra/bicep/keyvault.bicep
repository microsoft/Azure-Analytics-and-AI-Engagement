param location string
param environmentName string = 'dev'
param sqlServerFqdn string = ''
param sqlDatabaseName string = ''
param sqlAdministratorLogin string = ''
@secure()
param sqlAdministratorPassword string = ''
param serviceBusNamespace string = ''
param postgreSqlHost string = ''
param postgreSqlDatabaseName string = ''
param postgreSqlAdministratorLogin string = ''
@secure()
param postgreSqlAdministratorPassword string = ''
param cosmosAccountName string = ''
param redisResourceName string = ''
param keyVaultName string = ''
param postgreSqlSecretName string = 'postgres-connection-string'
param cosmosSecretName string = 'cosmos-connection-string'
param sqlSecretName string = 'sql-connection-string'
param redisSecretName string = 'redis-connection-string'
param serviceBusNamespaceSecretName string = 'servicebus-namespace'
param aksKubeletIdentityObjectId string = ''

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var vaultName = empty(keyVaultName) ? 'azkv${resourceToken}' : keyVaultName
var identityName = 'azid${resourceToken}'
var sqlConnectionString = !empty(sqlServerFqdn) && !empty(sqlDatabaseName) && !empty(sqlAdministratorLogin) && !empty(sqlAdministratorPassword)
  ? 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  : ''
var postgreSqlConnectionString = !empty(postgreSqlHost) && !empty(postgreSqlDatabaseName) && !empty(postgreSqlAdministratorLogin) && !empty(postgreSqlAdministratorPassword)
  ? 'Host=${postgreSqlHost};Port=5432;Database=${postgreSqlDatabaseName};Username=${postgreSqlAdministratorLogin};Password=${postgreSqlAdministratorPassword};Ssl Mode=Require;Trust Server Certificate=false'
  : ''
var cosmosConnectionString = !empty(cosmosAccountName)
  ? listConnectionStrings(resourceId('Microsoft.DocumentDB/databaseAccounts', cosmosAccountName), '2024-05-15').connectionStrings[0].connectionString
  : ''
var redisConnectionString = !empty(redisResourceName)
  ? '${reference(resourceId('Microsoft.Cache/Redis', redisResourceName), '2024-03-01').hostName}:${reference(resourceId('Microsoft.Cache/Redis', redisResourceName), '2024-03-01').sslPort},password=${listKeys(resourceId('Microsoft.Cache/Redis', redisResourceName), '2024-03-01').primaryKey},ssl=True,abortConnect=False'
  : ''

resource secretsOfficerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
  }
}

resource keyVaultSecretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, identityName, 'KeyVaultSecretsOfficer')
  scope: keyVault
  properties: {
    principalId: secretsOfficerIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  }
}

resource aksKeyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(aksKubeletIdentityObjectId)) {
  name: guid(keyVault.id, aksKubeletIdentityObjectId, 'KeyVaultSecretsUser')
  scope: keyVault
  properties: {
    principalId: aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  }
}

resource sqlConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(sqlConnectionString)) {
  name: sqlSecretName
  parent: keyVault
  properties: {
    value: sqlConnectionString
  }
  dependsOn: [
    keyVaultSecretsOfficerRoleAssignment
  ]
}

resource serviceBusNamespaceSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(serviceBusNamespace)) {
  name: serviceBusNamespaceSecretName
  parent: keyVault
  properties: {
    value: serviceBusNamespace
  }
  dependsOn: [
    keyVaultSecretsOfficerRoleAssignment
  ]
}

resource postgreSqlSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(postgreSqlConnectionString)) {
  name: postgreSqlSecretName
  parent: keyVault
  properties: {
    value: postgreSqlConnectionString
  }
  dependsOn: [
    keyVaultSecretsOfficerRoleAssignment
  ]
}

resource cosmosSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(cosmosAccountName)) {
  name: cosmosSecretName
  parent: keyVault
  properties: {
    value: cosmosConnectionString
  }
  dependsOn: [
    keyVaultSecretsOfficerRoleAssignment
  ]
}

resource redisSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(redisResourceName)) {
  name: redisSecretName
  parent: keyVault
  properties: {
    value: redisConnectionString
  }
  dependsOn: [
    keyVaultSecretsOfficerRoleAssignment
  ]
}

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output secretsOfficerClientId string = secretsOfficerIdentity.properties.clientId
output aksKeyVaultSecretsUserRoleAssigned bool = !empty(aksKubeletIdentityObjectId)
output sqlSecretName string = sqlSecretName
output postgreSqlSecretName string = postgreSqlSecretName
output cosmosSecretName string = cosmosSecretName
output redisSecretName string = redisSecretName