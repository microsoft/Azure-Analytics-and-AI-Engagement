# Architecture Documentation

## Architecture source artifact
- Generated architecture file: `.azure/architecture.copilotmd`

## Overview
This solution is composed of a frontend and a backend service with Azure-managed dependencies:
- Frontend (`PharmaFrontend`): TypeScript web app hosted on Azure App Service.
- Backend (`PharmaBackend`): .NET API container hosted on Azure Kubernetes Service (AKS), listening on port `8080`.

## Compute topology
- `pharma-frontend` -> Azure App Service
- `pharma-backend` -> Azure Kubernetes Service (AKS)

## Backend dependencies
The backend uses system-managed identity to access:
- Azure Key Vault (`pharma-keyvault`)
- Azure App Configuration (`pharma-appconfig`)
- Azure SQL Database (`pharma-sql`)
- Azure Cache for Redis (`pharma-redis`)
- Azure Container Registry (`pharma-acr`)

## Data flow
1. The frontend calls backend APIs over HTTP.
2. The backend reads runtime configuration from Azure App Configuration.
3. App Configuration resolves secret references from Azure Key Vault.
4. The backend persists relational data in Azure SQL Database.
5. The backend uses Azure Cache for Redis for caching.
6. The backend pulls container images from Azure Container Registry.

## Mermaid diagram
The diagram below mirrors the generated architecture topology.

```mermaid
graph TD
svcazurekubernetesservice_pharmabackend["`Name: pharma-backend
Path: PharmaBackend
Language: dotnet
Port: 8080`"]
svcazureappservice_pharmafrontend["`Name: pharma-frontend
Path: PharmaFrontend
Language: ts
Port: 80`"]

subgraph "Compute Resources"
subgraph akscluster["Azure Kubernetes Service (AKS) Cluster"]
azurekubernetesservice_pharmabackend("`pharma-backend (Containerized Service)`")
end
azureappservice_pharmafrontend("`pharma-frontend (Azure App Service)`")
end

subgraph "Dependency Resources"
azurekeyvault_pharmakeyvault["`pharma-keyvault (Azure Key Vault)`"]
azureappconfiguration_pharmaappconfig["`pharma-appconfig (Azure App Configuration)`"]
azuresqldatabase_pharmasql["`pharma-sql (Azure SQL Database)`"]
azurecacheforredis_pharmaredis["`pharma-redis (Azure Cache for Redis)`"]
azurecontainerregistry_pharmaacr["`pharma-acr (Azure Container Registry)`"]
end

svcazurekubernetesservice_pharmabackend -->|hosted on| azurekubernetesservice_pharmabackend
svcazureappservice_pharmafrontend -->|hosted on| azureappservice_pharmafrontend
azureappservice_pharmafrontend -.->|http| azurekubernetesservice_pharmabackend

azurekubernetesservice_pharmabackend -.->|system-identity| azurekeyvault_pharmakeyvault
azurekubernetesservice_pharmabackend -.->|system-identity| azureappconfiguration_pharmaappconfig
azurekubernetesservice_pharmabackend -.->|system-identity| azuresqldatabase_pharmasql
azurekubernetesservice_pharmabackend -.->|system-identity| azurecacheforredis_pharmaredis
azurekubernetesservice_pharmabackend -.->|system-identity| azurecontainerregistry_pharmaacr
azureappconfiguration_pharmaappconfig -.->|Key Vault references| azurekeyvault_pharmakeyvault
```
