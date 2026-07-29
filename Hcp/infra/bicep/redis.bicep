param location string
param environmentName string = 'dev'
param redisName string = ''
param skuName string = 'Basic'
param skuFamily string = 'C'
param skuCapacity int = 0

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var name = empty(redisName) ? 'azredis${resourceToken}' : redisName

resource redis 'Microsoft.Cache/Redis@2024-03-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
}

output redisName string = redis.name
output redisHostName string = redis.properties.hostName
