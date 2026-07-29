param location string = resourceGroup().location
param environmentName string = 'dev'
// Suffix appended to nested module deployment names so re-runs never collide with a still-Running deployment.
param deploymentSuffix string = utcNow('yyMMddHHmmss')
param deployContainerApp bool = false
param deployApim bool = false
param deployPostgreSql bool = true
param deployPurview bool = true
param purviewEnableManagedEventHub bool = false
param deployCosmos bool = true
param deployRedis bool = true
param deployAks bool = false
param aksName string = ''
param aksClusterExists bool = false
// ACA Sandbox Group (new preview product). Provide the pre-existing group name; individual sandboxes
// are created on-demand per prescriber session via the group's data-plane API.
param sandboxGroupName string = ''
param sandboxGroupResourceGroup string = ''
param postgreSqlLocation string = 'centralus'
param cosmosLocation string = 'centralus'
param redisLocation string = ''
param cosmosPublicNetworkAccess string = 'Enabled'
param cosmosNetworkAclBypass string = 'AzureServices'
param cosmosDisableLocalAuth bool = false
param cosmosEnableAutomaticFailover bool = false
param cosmosEnableFreeTier bool = false
param cosmosConsistencyLevel string = 'Session'
param cosmosBoundedStalenessMaxIntervalInSeconds int = 300
param cosmosBoundedStalenessMaxStalenessPrefix int = 100000
param cosmosIpRules array = []
param cosmosAdditionalWriteRegions array = []
param cosmosSqlRolePrincipalId string = ''
param acrLoginServer string
param acrUsername string
@secure()
param acrPassword string
param apimPublisherEmail string
param apimPublisherName string
param sqlAdminLogin string = 'hcpadmin'
@secure()
param sqlAdminPassword string
param postgreSqlAdminLogin string = 'hcpadmin'
@secure()
param postgreSqlAdminPassword string
param postgreSqlDatabaseName string = 'hcpclinical'
param postgreSqlClusterExists bool = false
param postgreSqlClusterName string = ''
param purviewAccountName string = ''
param cosmosDatabaseName string = 'hcp-ai-memory'
param cosmosDatabaseThroughput int = 400
param enableSqlServerDiagnostics bool = false

module sql 'sql.bicep' = {
  name: 'sqlDeployment-${deploymentSuffix}'
  params: {
    location: location
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    enableSqlServerDiagnostics: enableSqlServerDiagnostics
  }
}

module postgreSql 'postgresql.bicep' = if (deployPostgreSql) {
  name: 'postgreSqlDeployment-${deploymentSuffix}'
  params: {
    location: postgreSqlLocation
    environmentName: environmentName
    administratorLogin: postgreSqlAdminLogin
    administratorPassword: postgreSqlAdminPassword
    databaseName: postgreSqlDatabaseName
    clusterExists: postgreSqlClusterExists
    clusterName: postgreSqlClusterName
  }
}

module cosmos 'cosmos.bicep' = if (deployCosmos) {
  name: 'cosmosDeployment-${deploymentSuffix}'
  params: {
    location: cosmosLocation
    environmentName: environmentName
    databaseName: cosmosDatabaseName
    databaseThroughput: cosmosDatabaseThroughput
    publicNetworkAccess: cosmosPublicNetworkAccess
    networkAclBypass: cosmosNetworkAclBypass
    disableLocalAuth: cosmosDisableLocalAuth
    enableAutomaticFailover: cosmosEnableAutomaticFailover
    enableFreeTier: cosmosEnableFreeTier
    consistencyLevel: cosmosConsistencyLevel
    boundedStalenessMaxIntervalInSeconds: cosmosBoundedStalenessMaxIntervalInSeconds
    boundedStalenessMaxStalenessPrefix: cosmosBoundedStalenessMaxStalenessPrefix
    ipRules: cosmosIpRules
    additionalWriteRegions: cosmosAdditionalWriteRegions
    sqlRolePrincipalId: cosmosSqlRolePrincipalId
  }
}

module aks 'aks.bicep' = if (deployAks) {
  name: 'aksDeployment-${deploymentSuffix}'
  params: {
    location: location
    environmentName: environmentName
    aksName: aksName
    clusterExists: aksClusterExists
    acrName: split(acrLoginServer, '.')[0]
  }
}

module purview 'purview.bicep' = if (deployPurview) {
  name: 'purviewDeployment-${deploymentSuffix}'
  params: {
    location: location
    environmentName: environmentName
    purviewAccountName: purviewAccountName
    enableManagedEventHub: purviewEnableManagedEventHub
  }
}

module keyVault 'keyvault.bicep' = if (deployPostgreSql || deployCosmos) {
  name: 'keyVaultDeployment-${deploymentSuffix}'
  params: {
    location: location
    environmentName: environmentName
    sqlServerFqdn: sql.outputs.sqlServerFqdn
    sqlDatabaseName: sql.outputs.sqlDatabaseName
    sqlAdministratorLogin: sqlAdminLogin
    sqlAdministratorPassword: sqlAdminPassword
    postgreSqlHost: deployPostgreSql ? postgreSql!.outputs.fqdn : ''
    postgreSqlDatabaseName: deployPostgreSql ? postgreSql!.outputs.databaseName : ''
    postgreSqlAdministratorLogin: deployPostgreSql ? postgreSql!.outputs.administratorLogin : ''
    postgreSqlAdministratorPassword: deployPostgreSql && !postgreSqlClusterExists ? postgreSqlAdminPassword : ''
    cosmosAccountName: deployCosmos ? cosmos!.outputs.accountName : ''
    redisResourceName: deployRedis ? redis!.outputs.redisName : ''
    aksKubeletIdentityObjectId: deployAks ? aks!.outputs.kubeletIdentityObjectId : ''
  }
}

module serviceBus 'servicebus.bicep' = {
  name: 'serviceBusDeployment-${deploymentSuffix}'
  params: {
    location: location
  }
}

module redis 'redis.bicep' = if (deployRedis) {
  name: 'redisDeployment-${deploymentSuffix}'
  params: {
    location: empty(redisLocation) ? location : redisLocation
    environmentName: environmentName
  }
}

module sandboxGroup 'sandboxgroup.bicep' = if (!empty(sandboxGroupName)) {
  name: 'sandboxGroupDeployment-${deploymentSuffix}'
  params: {
    sandboxGroupName: sandboxGroupName
    sandboxGroupResourceGroup: empty(sandboxGroupResourceGroup) ? resourceGroup().name : sandboxGroupResourceGroup
  }
}

module containerApp 'containerapp.bicep' = if (deployContainerApp) {
  name: 'containerAppDeployment-${deploymentSuffix}'
  params: {
    location: location
    acrLoginServer: acrLoginServer
    acrUsername: acrUsername
    acrPassword: acrPassword
    serviceBusFullyQualifiedNamespace: '${serviceBus.outputs.serviceBusNamespaceName}.servicebus.windows.net'
  }
}

module apim 'apim.bicep' = if (deployApim) {
  name: 'apimDeployment-${deploymentSuffix}'
  params: {
    location: location
    apimPublisherEmail: apimPublisherEmail
    apimPublisherName: apimPublisherName
    apiBackendUrl: 'https://hcp-api.example.com'
    openApiSpecUrl: 'https://hcp-api.example.com/swagger/v1/swagger.json'
  }
}

output serviceBusNamespace string = serviceBus.outputs.serviceBusNamespaceName
output containerAppId string = deployContainerApp ? containerApp!.outputs.containerAppId : ''
output apimName string = deployApim ? apim!.outputs.apimName : ''
output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output sqlDatabaseName string = sql.outputs.sqlDatabaseName
output postgreSqlServerName string = deployPostgreSql ? postgreSql!.outputs.serverName : ''
output postgreSqlServerFqdn string = deployPostgreSql ? postgreSql!.outputs.fqdn : ''
output postgreSqlDatabaseName string = deployPostgreSql ? postgreSql!.outputs.databaseName : ''
output postgreSqlAdministratorLogin string = deployPostgreSql ? postgreSql!.outputs.administratorLogin : ''
output postgreSqlPublicNetworkAccess string = deployPostgreSql ? postgreSql!.outputs.publicNetworkAccess : ''
output horizonDbReadOnlyEndpoint string = deployPostgreSql ? postgreSql!.outputs.readOnlyEndpoint : ''
output cosmosAccountName string = deployCosmos ? cosmos!.outputs.accountName : ''
output cosmosEndpoint string = deployCosmos ? cosmos!.outputs.endpoint : ''
output cosmosDatabaseName string = deployCosmos ? cosmos!.outputs.databaseName : ''
output cosmosPublicNetworkAccess string = deployCosmos ? cosmos!.outputs.publicNetworkAccess : ''
output purviewAccountName string = deployPurview ? purview!.outputs.purviewAccountName : ''
output purviewAccountId string = deployPurview ? purview!.outputs.purviewAccountId : ''
output aksKubeletIdentityObjectId string = deployAks ? aks!.outputs.kubeletIdentityObjectId : ''
output aksKubeletIdentityClientId string = deployAks ? aks!.outputs.kubeletIdentityClientId : ''
output keyVaultName string = (deployPostgreSql || deployCosmos) ? keyVault!.outputs.keyVaultName : ''
output keyVaultUri string = (deployPostgreSql || deployCosmos) ? keyVault!.outputs.keyVaultUri : ''
output keyVaultSecretsOfficerClientId string = (deployPostgreSql || deployCosmos) ? keyVault!.outputs.secretsOfficerClientId : ''
output sqlSecretName string = (deployPostgreSql || deployCosmos) ? keyVault!.outputs.sqlSecretName : ''
output postgreSqlSecretName string = (deployPostgreSql || deployCosmos) ? keyVault!.outputs.postgreSqlSecretName : ''
output cosmosSecretName string = (deployPostgreSql || deployCosmos) ? keyVault!.outputs.cosmosSecretName : ''
output redisSecretName string = (deployPostgreSql || deployCosmos) ? keyVault!.outputs.redisSecretName : ''
output redisHostName string = deployRedis ? redis!.outputs.redisHostName : ''
output sandboxGroupName string = !empty(sandboxGroupName) ? sandboxGroup!.outputs.sandboxGroupName : ''
output sandboxGroupManagementEndpoint string = !empty(sandboxGroupName) ? sandboxGroup!.outputs.managementEndpoint : ''
output aksClusterName string = deployAks ? aks!.outputs.aksName : ''
