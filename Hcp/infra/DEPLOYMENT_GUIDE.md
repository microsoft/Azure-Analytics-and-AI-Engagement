# Infrastructure as Code Deployment Guide

## Quick Start

### 1. Deploy Infrastructure with Bicep

```bash
# Prerequisites
export RESOURCE_GROUP="hcp-rg"
export LOCATION="eastus"
export ACR_LOGIN_SERVER="hcpacr.azurecr.io"
export ACR_USERNAME="hcpadmin"
export ACR_PASSWORD="<your-acr-password>"

# Create resource group (if not exists)
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy Bicep template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file Hcp/infra/bicep/main.bicep \
  --parameters \
    location=$LOCATION \
    acrLoginServer=$ACR_LOGIN_SERVER \
    acrUsername=$ACR_USERNAME \
    acrPassword=$ACR_PASSWORD \
    apimPublisherEmail="admin@caldova.com" \
    apimPublisherName="Caldova"
```

### 2. Get Outputs

```bash
# Retrieve deployment outputs
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query properties.outputs
```

**Expected outputs:**
- `serviceBusNamespace`: Name of Service Bus namespace
- `containerAppId`: ID of Azure Container Apps instance
- `apimName`: Name of API Management instance

## Infrastructure Components

### Service Bus Queue

**Created by:** `bicep/servicebus.bicep`

**Details:**
- Namespace: `hcp-<uniqueId>`
- Queue: `enrollment-events`
- Tier: Standard (High availability)
- Message TTL: 14 days
- Max delivery count: 10
- Dead-letter on expiration: Enabled

**Authorization:**
- `Manage` rule (for publisher)
- `Listen` rule (for consumer)

### Container App (Alternative to Kubernetes)

**Created by:** `bicep/containerapp.bicep`

**Details:**
- Environment: `hcp-env` with Log Analytics
- Container: `hcp-enrollment-worker`
- Image: `<acr>/hcp-enrollment-worker:latest`
- Min replicas: 0 (scale to zero)
- Max replicas: 10
- CPU: 0.5 core
- Memory: 1 GB
- Auto-scale rule: Service Bus queue depth

**Alternative deployment option:**
If you prefer standalone ACA (not in AKS):

```bash
# Deploy Container App
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file Hcp/infra/bicep/containerapp.bicep \
  --parameters \
    acrLoginServer=$ACR_LOGIN_SERVER \
    acrUsername=$ACR_USERNAME \
    acrPassword=$ACR_PASSWORD \
    serviceBusConnectionString=$SERVICE_BUS_CONN
```

### API Management

**Created by:** `bicep/apim.bicep`

**Details:**
- Name: `hcp-api-<uniqueId>`
- Tier: Developer (suitable for non-production)
- Backend: hcp-api-backend (circuit breaker enabled)
- API: hcp-enrollment-api
- Authentication: JWT (Entra ID)
- Rate limiting: 100 calls/min

**Features:**
- Developer Portal for self-service
- OpenAPI specification publishing
- API versioning support
- Automatic retry policies

**Policies applied:**
```xml
<!-- Rate limiting (global) -->
<rate-limit calls="100" renewal-period="60" />

<!-- JWT validation -->
<validate-jwt header-name="Authorization" 
  failed-validation-httpcode="401" />

<!-- CORS -->
<cors allowed-origins="*" />
```

---

## Deployment Flow

```
[Push to main]
    ↓
[GitHub Actions Triggers]
    ↓
[CodeQL Scan + Build]
    ↓
[Docker build: API + Worker]
    ↓
[Defender Image Scan]
    ↓
[Push to ACR]
    ↓
[Deploy to AKS]
    ├── Deploy Kubernetes manifests
    ├── Update image references
    ├── Rollout status check
    └── Verify pods running
```

---

## Manual Troubleshooting

### Restart Worker

```bash
kubectl rollout restart deployment/hcp-enrollment-worker -n hcp-portal-worker
```

### View Worker Logs

```bash
# Real-time logs
kubectl logs -f deployment/hcp-enrollment-worker -n hcp-portal-worker

# Last 100 lines
kubectl logs -n hcp-portal-worker deployment/hcp-enrollment-worker --tail=100
```

### Test Service Bus Connection

```bash
# Port forward to worker pod
kubectl port-forward -n hcp-portal-worker svc/hcp-enrollment-worker 8080:8080

# Call health endpoint
curl http://localhost:8080/health/ready
```

### Check HPA Status

```bash
kubectl get hpa -n hcp-portal-worker
kubectl describe hpa hcp-enrollment-worker-hpa -n hcp-portal-worker
```

---

## Cost Estimation (Monthly)

| Component | SKU | Cost |
|-----------|-----|------|
| AKS Automatic | 1 cluster | ~$90 |
| Service Bus | Standard (1GB/day) | ~$25 |
| APIM | Developer tier | ~$40 |
| Container App | ~2 replicas avg | ~$50 |
| Application Insights | 100 GB ingestion | ~$30 |
| **Total** | | **~$235/month** |

*Note: Production deployments (Standard APIM, Premium SKUs) would cost 2-3x more*

---

## Security Checklist

- [ ] Enable managed identity on AKS pods
- [ ] Configure Key Vault access policies
- [ ] Enable network policies (zero-trust networking)
- [ ] Set up Pod Security Standards
- [ ] Enable audit logging in AKS
- [ ] Scan images regularly with Defender
- [ ] Review APIM authentication policies
- [ ] Rotate credentials monthly

---

## Next: Wire to Existing Infrastructure

If you have existing Azure resources, update `parameters.json`:

```json
{
  "parameters": {
    "acrLoginServer": {
      "value": "your-existing-acr.azurecr.io"
    },
    "location": {
      "value": "your-region"
    }
  }
}
```

Then redeploy to integrate with your existing setup.
