targetScope = 'resourceGroup'

@description('APIM service name (globally unique within Azure).')
param apimName string

@description('Azure region.')
param location string = resourceGroup().location

@description('Publisher email for APIM.')
param publisherEmail string

@description('Publisher name for APIM.')
param publisherName string

@description('Logical API name in APIM.')
param apiName string = 'hcp-portal'

@description('Display name of the API in APIM.')
param apiDisplayName string = 'HcpPortal API'

@description('Path segment exposed by APIM, for example hcp-portal.')
param apiPath string = 'hcp-portal'

@description('API semantic version.')
param apiVersion string = 'v1'

@description('OAuth2 authorization endpoint URL.')
param oauth2AuthorizationEndpoint string

@description('OAuth2 token endpoint URL.')
param oauth2TokenEndpoint string

@description('OpenID configuration URL for JWT validation.')
param openIdConfigUrl string

@description('Expected JWT audience value.')
param jwtAudience string

@description('OAuth2 client ID used by APIM authorization server metadata.')
param oauth2ClientId string

@description('Backend URL that APIM should forward traffic to (ACA app URL).')
param backendUrl string

resource apim 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: apimName
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

resource versionSet 'Microsoft.ApiManagement/service/apiVersionSets@2022-08-01' = {
  parent: apim
  name: '${apiName}-versionset'
  properties: {
    displayName: apiDisplayName
    versioningScheme: 'Segment'
  }
}

resource oauth2Server 'Microsoft.ApiManagement/service/authorizationServers@2022-08-01' = {
  parent: apim
  name: '${apiName}-oauth2'
  properties: {
    displayName: '${apiDisplayName} OAuth2'
    description: 'OAuth2 configuration for ${apiDisplayName}.'
    authorizationEndpoint: oauth2AuthorizationEndpoint
    tokenEndpoint: oauth2TokenEndpoint
    clientRegistrationEndpoint: oauth2AuthorizationEndpoint
    clientId: oauth2ClientId
    grantTypes: [
      'authorizationCode'
      'clientCredentials'
    ]
    authorizationMethods: [
      'GET'
      'POST'
    ]
    bearerTokenSendingMethods: [
      'authorizationHeader'
    ]
    clientAuthenticationMethod: [
      'Body'
    ]
    supportState: true
  }
}

resource backend 'Microsoft.ApiManagement/service/backends@2022-08-01' = {
  parent: apim
  name: '${apiName}-aca-backend'
  properties: {
    title: '${apiDisplayName} ACA Backend'
    protocol: 'http'
    url: backendUrl
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  parent: apim
  name: '${apiName}-${apiVersion}'
  properties: {
    displayName: apiDisplayName
    description: 'HCP prescriber portal API imported from OpenAPI spec.'
    path: apiPath
    protocols: [
      'https'
    ]
    apiVersion: apiVersion
    apiVersionSetId: versionSet.id
    format: 'openapi+json'
    value: loadTextContent('../../openapi/hcp-portal-v1.json')
    serviceUrl: backendUrl
    subscriptionRequired: true
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '<policies>\n  <inbound>\n    <base />\n    <set-backend-service backend-id="${backend.name}" />\n    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">\n      <openid-config url="${openIdConfigUrl}" />\n      <audiences>\n        <audience>${jwtAudience}</audience>\n      </audiences>\n    </validate-jwt>\n    <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Subscription?.Key ?? context.Request.IpAddress)" />\n  </inbound>\n  <backend>\n    <base />\n  </backend>\n  <outbound>\n    <base />\n  </outbound>\n  <on-error>\n    <base />\n  </on-error>\n</policies>'
  }
}

@description('APIM gateway URL.')
output apimGatewayUrl string = apim.properties.gatewayUrl

@description('Imported API resource ID.')
output apiResourceId string = api.id

@description('OAuth2 authorization server resource ID.')
output oauth2ServerId string = oauth2Server.id
