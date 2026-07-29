// Reference the existing ACA Sandbox Group (pre-provisioned by the sandbox environment).
// Sandboxes are created on-demand per prescriber session via the group's data-plane API.
param sandboxGroupName string
param sandboxGroupResourceGroup string = resourceGroup().name

resource sandboxGroup 'Microsoft.App/sandboxGroups@2026-02-01-preview' existing = {
  name: sandboxGroupName
  scope: resourceGroup(sandboxGroupResourceGroup)
}

output sandboxGroupName string = sandboxGroup.name
output sandboxGroupId string = sandboxGroup.id
output managementEndpoint string = sandboxGroup.properties.managementEndpoint
output allowedLocations array = sandboxGroup.properties.allowedLocations
