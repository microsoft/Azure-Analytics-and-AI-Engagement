param location string
param environmentName string = 'dev'
param administratorLogin string = 'hcpadmin'
@secure()
param administratorPassword string
param databaseName string = 'hcpclinical'
param serverVersion string = '17'
param clusterExists bool = false
param clusterName string = ''

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var generatedClusterName = 'azhdb${resourceToken}'
var effectiveClusterName = empty(clusterName) ? generatedClusterName : clusterName

resource horizonDbCluster 'Microsoft.HorizonDb/clusters@2026-01-20-preview' = if (!clusterExists) {
  name: effectiveClusterName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    network: {}
    replicaCount: 1
    vCores: 2
    version: serverVersion
  }
}

resource existingHorizonDbCluster 'Microsoft.HorizonDb/clusters@2026-01-20-preview' existing = if (clusterExists) {
  name: effectiveClusterName
}

output serverName string = clusterExists ? existingHorizonDbCluster!.name : horizonDbCluster!.name
output fqdn string = clusterExists ? existingHorizonDbCluster!.properties.fullyQualifiedDomainName : horizonDbCluster!.properties.fullyQualifiedDomainName
output databaseName string = databaseName
output administratorLogin string = administratorLogin
output publicNetworkAccess string = ''
output readOnlyEndpoint string = clusterExists ? existingHorizonDbCluster!.properties.readonlyEndpoint : horizonDbCluster!.properties.readonlyEndpoint