param location string = resourceGroup().location
param serviceBusNamespace string = 'hcp-${uniqueString(resourceGroup().id)}'
param queueName string = 'enrollment-events'

resource serviceBusNamespaceResource 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusNamespace
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    zoneRedundant: false
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  name: queueName
  parent: serviceBusNamespaceResource
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    deadLetteringOnMessageExpiration: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    enableBatchedOperations: true
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
  }
}

resource manageAuthRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' = {
  name: 'Manage'
  parent: serviceBusNamespaceResource
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource listenAuthRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' = {
  name: 'Listen'
  parent: serviceBusNamespaceResource
  properties: {
    rights: [
      'Listen'
    ]
  }
}

output serviceBusNamespaceName string = serviceBusNamespaceResource.name
output queueName string = queueName
