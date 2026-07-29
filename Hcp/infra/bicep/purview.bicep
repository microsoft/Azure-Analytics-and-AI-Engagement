param location string = resourceGroup().location
param environmentName string = 'dev'
param purviewAccountName string = ''
param enableManagedEventHub bool = false

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var accountName = empty(purviewAccountName) ? 'hcppv${resourceToken}' : purviewAccountName

resource purviewAccount 'Microsoft.Purview/accounts@2024-04-01-preview' = {
  name: accountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    managedEventHubState: enableManagedEventHub ? 'Enabled' : 'Disabled'
    managedResourcesPublicNetworkAccess: 'Enabled'
    tenantEndpointState: 'Enabled'
  }
}

output purviewAccountName string = purviewAccount.name
output purviewAccountId string = purviewAccount.id