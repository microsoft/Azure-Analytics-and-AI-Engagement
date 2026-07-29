# PharmaBackend Modernized Architecture

This architecture mirrors your current modernization target: AKS-hosted API, workload identity, centralized configuration, and managed data/cache services.

## 1) Runtime Architecture (Target State)

```mermaid
flowchart TB
    U[End User Browser]
    FE[PharmaFrontend React SPA]

    subgraph AZ[Azure Subscription]
        subgraph AKS[AKS Cluster]
            ING[Ingress<br/>webapprouting.kubernetes.azure.com]
            SVC[Service<br/>pharma-backend:80]
            subgraph NS[Namespace: pharma]
                SA[ServiceAccount<br/>pharma-backend]
                POD1[pharma-backend Pod 1<br/>ASP.NET Core API]
                POD2[pharma-backend Pod 2<br/>ASP.NET Core API]
            end
        end

        ACR[Azure Container Registry]
        UAMI[User Assigned Managed Identity]
        FIC[Federated Credential<br/>OIDC trust]
        KV[Azure Key Vault]
        APPCFG[Azure App Configuration<br/>Sentinel refresh]
        REDIS[Azure Cache for Redis]
        PG[Azure Database for PostgreSQL<br/>Flexible Server]
    end

    U --> FE
    FE -->|HTTPS API calls| ING
    ING --> SVC
    SVC --> POD1
    SVC --> POD2

    ACR -->|Image pull via AcrPull role| AKS

    SA -->|annotated with client-id| UAMI
    AKS -->|OIDC issuer enabled| FIC
    FIC --> UAMI

    POD1 -->|DefaultAzureCredential| KV
    POD2 -->|DefaultAzureCredential| KV

    POD1 -->|AddAzureAppConfiguration| APPCFG
    POD2 -->|AddAzureAppConfiguration| APPCFG

    APPCFG -->|Key Vault references resolved| KV

    POD1 -->|EF Core / Npgsql| PG
    POD2 -->|EF Core / Npgsql| PG

    POD1 -->|StackExchange.Redis + MI token| REDIS
    POD2 -->|StackExchange.Redis + MI token| REDIS
```

## 2) Modernization Execution in VS Code (Step by Step)

```mermaid
flowchart LR
    I[Open GitHub Issue in VS Code] --> A[Review assessment report\nDependencies, architecture, intent]
    A --> P[Open generated plan.md + tasks.json]
    P --> T1[Execute task 001\nExternalize non-secret config]
    T1 --> T2[Execute task 002\nMigrate database connection to Azure PostgreSQL + MI]
    T1 --> T3[Execute task 003\nMigrate Redis connection to Azure Cache + MI]
    T2 --> T4[Execute task 004\nFinalize Key Vault secret coverage]
    T3 --> T4
    T4 --> V[Run build + tests + health checks]
    V --> D[Deploy manifests to AKS\nand verify ingress + readiness]
```

## 3) Mapping to Current Repo Assets

- API app startup and cloud wiring: `Program.cs`
- Kubernetes deployment and probes: `k8s/deployment.yaml`
- Kubernetes ingress: `k8s/ingress.yaml`
- Kubernetes service account for workload identity: `k8s/serviceaccount.yaml`
- Kubernetes service: `k8s/service.yaml`
- AKS module (OIDC + workload identity + web app routing): `infra/modules/aks.bicep`
- UAMI + federated credential module: `infra/modules/uami.bicep`
- ACR module: `infra/modules/acr.bicep`

## 4) Notes

- The backend is configured to pull configuration from App Configuration and secrets from Key Vault, then allow environment variables and user secrets to override when needed.
- Readiness and liveness checks are exposed at `/health/ready` and `/health/live` and already wired in deployment probes.
- This diagram is intended for IDE visualization and modernization walkthroughs; keep it updated as you add new services.
