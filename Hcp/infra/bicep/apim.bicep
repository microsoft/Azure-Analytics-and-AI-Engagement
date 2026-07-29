param location string = resourceGroup().location
param apimName string = 'hcp-api-${uniqueString(resourceGroup().id)}'
param apimPublisherEmail string
param apimPublisherName string
param apiBackendUrl string = 'http://hcp-portal-api.hcp-portal.svc.cluster.local'
param importOpenApi bool = false
// Swagger endpoint the API serves at /swagger/v1/swagger.json
param openApiSpecUrl string = '${apiBackendUrl}/swagger/v1/swagger.json'
param enableOperationPolicy bool = false

resource apimService 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    virtualNetworkType: 'None'
    notificationSenderEmail: apimPublisherEmail
  }
}

resource apiBackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: 'hcp-api-backend'
  parent: apimService
  properties: {
    url: apiBackendUrl
    protocol: 'http'
    circuitBreaker: {
      rules: [
        {
          name: 'apiCircuitBreakerRule'
          failureCondition: {
            count: 3
            interval: 'PT20S'
            statusCodeRanges: [
              {
                min: 429
                max: 429
              }
              {
                min: 500
                max: 599
              }
            ]
          }
          tripDuration: 'PT1M'
        }
      ]
    }
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = if (!importOpenApi) {
  name: 'hcp-enrollment-api'
  parent: apimService
  properties: {
    displayName: 'HCP Enrollment API'
    description: 'Caldova HCP Portal — physician enrollment, onboarding events, and status tracking.'
    path: 'enrollment'
    protocols: [
      'https'
    ]
    serviceUrl: apiBackendUrl
    subscriptionRequired: false
  }
}

resource importedApi 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = if (importOpenApi) {
  name: 'hcp-enrollment-api'
  parent: apimService
  properties: {
    displayName: 'HCP Enrollment API'
    description: 'Caldova HCP Portal — physician enrollment, onboarding events, and status tracking.'
    path: 'enrollment'
    protocols: [
      'https'
    ]
    serviceUrl: apiBackendUrl
    // Import directly from the live Swagger/OpenAPI spec — shows as Imported API in APIM portal
    format: 'openapi-link'
    value: openApiSpecUrl
    subscriptionRequired: false
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  name: '${apimService.name}/hcp-enrollment-api/policy'
  properties: {
    format: 'rawxml'
    value: '''
<policies>
  <inbound>
    <rate-limit calls="100" renewal-period="60" />
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
  </inbound>
  <backend>
    <forward-request />
  </backend>
  <outbound>
    <set-header name="X-Correlation-ID" exists-action="override">
      <value>@(context.RequestId.ToString())</value>
    </set-header>
  </outbound>
  <on-error>
    <set-status code="500" reason="Internal Server Error" />
  </on-error>
</policies>
    '''
  }
}

resource rateLimitPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-03-01-preview' = if (enableOperationPolicy) {
  name: '${apimService.name}/hcp-enrollment-api/enrollments/policy'
  properties: {
    format: 'rawxml'
    value: '''
<policies>
  <inbound>
    <rate-limit-by-key calls="10" renewal-period="60" counter-key="@(context.Request.Headers.GetValueOrDefault("X-Tenant-ID","default"))" />
  </inbound>
</policies>
    '''
  }
}

resource product 'Microsoft.ApiManagement/service/products@2023-03-01-preview' = {
  name: 'hcp-developer-portal'
  parent: apimService
  properties: {
    displayName: 'HCP Developer Portal'
    description: 'API access for HCP Prescriber Portal partners and internal teams'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}

resource apiProductLink 'Microsoft.ApiManagement/service/products/apis@2023-03-01-preview' = {
  name: 'hcp-enrollment-api'
  parent: product
}

output apimName string = apimService.name
output apimId string = apimService.id
output apiId string = importOpenApi ? importedApi.id : api.id
output productId string = product.id
