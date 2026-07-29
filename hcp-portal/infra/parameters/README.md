# HcpPortal Deployment Parameters

These parameter files provide reproducible inputs for sandbox and production deployments.

## Files

- `sandbox.parameters.json`: Parameters for `infra/sandbox.bicep`
- `production.parameters.json`: Parameters for `infra/production.bicep`

## Runtime Environment Variables (Container App)

Both templates set the runtime environment variables consumed by HcpPortal:

- `AZURE_KEYVAULT_URI` from Bicep parameter `keyVaultUri`
- `AZURE_APPCONFIG_ENDPOINT` from Bicep parameter `appConfigEndpoint`

## APIM OAuth2/JWT Settings (Production)

`production.parameters.json` includes all APIM and JWT validation inputs:

- `apimName`
- `apimPublisherEmail`
- `apimPublisherName`
- `oauth2AuthorizationEndpoint`
- `oauth2TokenEndpoint`
- `openIdConfigUrl`
- `jwtAudience`
- `oauth2ClientId`

## Usage

### Sandbox deployment

```powershell
az deployment group create \
  --resource-group <resource-group> \
  --template-file infra/sandbox.bicep \
  --parameters @infra/parameters/sandbox.parameters.json
```

### Production deployment

```powershell
az deployment group create \
  --resource-group <resource-group> \
  --template-file infra/production.bicep \
  --parameters @infra/parameters/production.parameters.json
```

Or use the helper scripts:

- `deploy-sandbox.ps1`
- `deploy-production.ps1`

## Notes

- Keep real values and secrets out of source control.
- Use per-environment parameter files or a secure pipeline variable source for non-placeholder values.
- Ensure APIM, ACR, and Key Vault names exist in the target resource group before deployment.
