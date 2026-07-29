# HCP Prescriber Portal - Comprehensive Demo Architecture

Comprehensive reference architecture for the HCP Prescriber Portal.

## Implementation Status

| Component | Status | Details |
|-----------|--------|---------|
| **Frontend (React)** | ✅ Complete | Tailwind CSS, light theme, Caldova branding |
| **API (ASP.NET Core)** | ✅ Complete | .NET 10.0, clean architecture, Service Bus client |
| **AKS Deployment** | ✅ Complete | Kubernetes manifests, rolling updates, HPA |
| **GitHub Actions CI/CD** | ✅ Complete | Build, test, push to ACR, deploy to AKS |
| **Security: CodeQL** | ✅ Complete | Code analysis integrated in pipeline |
| **Security: Defender** | ✅ Complete | Container image scanning in pipeline |
| **Service Bus Queue** | ✅ Complete | `enrollment-events` queue with IaC (Bicep) |
| **Worker Service** | ✅ Complete | New `HcpPortalApi.Worker` project, ServiceBusProcessor |
| **ACA Worker Deployment** | ✅ Complete | K8s manifests + standalone ACA Bicep template |
| **Auto-scaling** | ✅ Complete | HPA for API, Worker scales on queue depth |
| **APIM** | ✅ Complete | Bicep template, rate limiting, JWT auth, policies |
| **Future AI Isolation Runtime** | 📋 Planned | Post-launch capability, details in future section |

---

## Executive Architecture View

```mermaid
flowchart TB
    %% Experience
    U[Physician / HCP User]
    W[HCP Portal\nReact Frontend ✅]
    U --> W

    %% Edge and core runtime
    APIM[Azure API Management ✅\nAuth, throttling, versioning]
    AKS[AKS Automatic ✅\nIngress + ASP.NET Core API]
    W --> APIM --> AKS

    %% Core data and event split
    SQL[(Azure SQL\nEnrollment transactions)]
    SB[Azure Service Bus Queue ✅\nenrollment-events]
    AKS --> SQL
    AKS --> SB

    %% Event-driven processing
    ACA[Azure Container Apps Worker ✅\nScale on queue depth, scale to zero]
    SB --> ACA

    %% Observability
    OTEL[OpenTelemetry\nTraces, metrics, logs]
    AI[Application Insights\nOperational visibility]
    AKS --> OTEL --> AI
    ACA --> OTEL

    %% Security plane
    MI[Managed Identity ✅\nNo secrets in code]
    KV[Azure Key Vault\nConnection secrets/certs]
    MI --> KV
    AKS -. secure secret access .-> KV
    ACA -. secure secret access .-> KV

    %% Delivery and posture
    GH[GitHub Actions CI/CD ✅]
    ACR[Azure Container Registry ✅]
    CODEQL[GitHub CodeQL ✅\nCode security analysis]
    DEF[Defender for Cloud ✅\nImage + config posture]
    CODEQL --> GH --> ACR
    ACR --> AKS
    ACR --> ACA
    DEF --> ACR

    %% Future expansion
    SANDBOX[Future: Isolated AI Runtime 📋\nPer-customer secure execution]
    SANDBOX -. planned extension .-> AKS

    style W fill:#90EE90
    style APIM fill:#90EE90
    style AKS fill:#90EE90
    style SB fill:#90EE90
    style ACA fill:#90EE90
    style GH fill:#90EE90
    style CODEQL fill:#90EE90
    style DEF fill:#90EE90
    style MI fill:#90EE90
```

## Architecture Summary

Caldova has modernized its legacy estate and now needs a launch-ready HCP prescriber portal. In this architecture, AKS Automatic runs the always-on portal and APIs, Azure SQL handles transactional enrollment data, and Azure Service Bus decouples background events processed by Azure Container Apps. Security is built in with managed identity and Key Vault, observability is live from day one with OpenTelemetry and Application Insights, and the same platform is ready for future isolated AI sessions with strict customer boundaries.

## Detailed Architecture — Animated View

This view shows the complete flow from Portal → AKS → SQL → Service Bus → ACA → Future AI:

```mermaid
graph TB
    subgraph "🖥️ Experience Layer"
        USER["👨‍⚕️ Physician User"]
        PORTAL["HCP Portal<br/>React 18 + Tailwind<br/>Responsive, instant"]
    end

    subgraph "🔐 API Management Layer"
        APIM["Azure API Management<br/>✓ Auth + Rate Limiting<br/>✓ Versioning + Developer Portal<br/>✓ Circuit Breaker + Policies"]
    end

    subgraph "☁️ AKS Automatic Cluster"
        direction TB
        INGRESS["Ingress Controller<br/>TLS Termination"]
        API["HCP Portal API<br/>ASP.NET Core 10<br/>Replicas: 2-8<br/>HPA: CPU 70%"]
        HEALTH["Health Checks<br/>/health/live<br/>/health/ready"]
    end

    subgraph "📦 Data & Events"
        SQL["Azure SQL<br/>hcp-enrollments<br/>Serverless (GP_S_Gen5_2)<br/>Auto-pause 60min"]
        SB["Azure Service Bus<br/>enrollment-events queue<br/>Auto-retry + DLQ<br/>Max delivery: 10"]
    end

    subgraph "⚡ Event-Driven Processing"
        ACA["Azure Container Apps<br/>Enrollment Worker<br/>Min: 0 | Max: 10<br/>Scales on queue depth"]
        LOGS["Logs: Enrollment Processed<br/>NPI, Email, Organization"]
    end

    subgraph "🔮 Future Expansion"
        SANDBOX["Isolated AI Runtime<br/>Per-customer boundaries<br/>Secure execution<br/>Clinical assistants"]
    end

    subgraph "🔒 Security Plane"
        MI["Managed Identity<br/>Pod Identity<br/>No secrets in env"]
        KV["Azure Key Vault<br/>Connection strings<br/>Certificates<br/>Encryption keys"]
    end

    subgraph "📊 Observability"
        OTEL["OpenTelemetry<br/>Traces, Metrics, Logs"]
        AppInsights["Application Insights<br/>Dashboards, Alerts<br/>Error tracking<br/>Performance monitoring"]
    end

    subgraph "🛡️ Delivery & Security"
        GitHub["GitHub Actions<br/>Build → Test → Push"]
        ACR["Azure Container<br/>Registry"]
        CodeQL["CodeQL Scan<br/>C# code analysis"]
        Defender["Defender for Cloud<br/>Image scanning<br/>Config compliance"]
    end

    %% User flow
    USER --> PORTAL
    PORTAL --> APIM
    APIM --> INGRESS
    INGRESS --> API

    %% API splits to data and events
    API --> SQL
    API --> SB

    %% Event processing
    SB --> ACA
    ACA --> LOGS

    %% Future expansion
    API -.-> SANDBOX
    SANDBOX -.-> ACA

    %% Security & Observability
    API --> MI
    ACA --> MI
    MI --> KV
    
    API --> OTEL
    ACA --> OTEL
    OTEL --> AppInsights

    %% CI/CD pipeline
    GitHub --> CodeQL
    GitHub --> ACR
    CodeQL --> ACR
    ACR --> API
    ACR --> ACA
    Defender --> ACR

    %% Styling
    classDef experience fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    classDef apigw fill:#f3e5f5,stroke:#512da8,stroke-width:2px
    classDef compute fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef data fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef events fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef future fill:#f1f8e9,stroke:#558b2f,stroke-width:2px,stroke-dasharray: 5 5
    classDef security fill:#ede7f6,stroke:#311b92,stroke-width:2px
    classDef observability fill:#e0f2f1,stroke:#004d40,stroke-width:2px
    classDef cicd fill:#fff8e1,stroke:#f57f17,stroke-width:2px

    class USER,PORTAL experience
    class APIM apigw
    class INGRESS,API,HEALTH compute
    class SQL,SB data
    class ACA,LOGS events
    class SANDBOX future
    class MI,KV security
    class OTEL,AppInsights observability
    class GitHub,ACR,CodeQL,Defender cicd
```

---

## Data Flow — Enrollment Journey

```mermaid
sequenceDiagram
    actor Doc as 👨‍⚕️ Physician
    participant Portal as 🖥️ HCP Portal
    participant APIM as 🔐 APIM
    participant API as 🌐 API (AKS)
    participant SQL as 📦 Azure SQL
    participant SB as 📨 Service Bus
    participant Worker as ⚡ ACA Worker

    Doc->>Portal: 1. Fill enrollment form
    Portal->>APIM: 2. POST /enrollment<br/>(rate limited, auth checked)
    APIM->>API: 3. Forward to backend
    API->>SQL: 4a. Save to DB<br/>(transactional)
    API->>SB: 4b. Publish event<br/>(async, decoupled)
    API-->>APIM: 5. Return enrollment ID
    APIM-->>Portal: 6. Success response<br/>(instant feedback)
    Portal-->>Doc: 7. ✓ Enrollment confirmed
    
    Note over SB,Worker: Meanwhile, asynchronously...
    SB->>Worker: 8. Deliver message<br/>(auto-retry, DLQ)
    Worker->>Worker: 9. Process enrollment<br/>🔍 Verify EHR<br/>📧 Send confirmations<br/>📝 Update status
    Worker->>Worker: 10. Log: Enrollment Processed
```

---

## Zones & Deployment Model

```mermaid
graph LR
    subgraph AzureCloud["Azure (East US / Multi-Region Ready)"]
        subgraph AKSZone["AKS Automatic Cluster"]
            Portal["Portal + API<br/>2-8 replicas"]
            Worker["Worker Job<br/>0-10 replicas"]
        end
        subgraph DataZone["Data & Integration"]
            SQL["Azure SQL<br/>Multi-region backup"]
            SB["Service Bus<br/>Zone-redundant"]
        end
        subgraph InfraZone["Infrastructure Services"]
            APIM["API Management<br/>Public endpoint"]
            KV["Key Vault<br/>RBAC-secured"]
            ACR["Container Registry<br/>Images & metadata"]
        end
        subgraph ObservabilityZone["Observability"]
            AI["Application Insights<br/>Aggregated telemetry"]
            LA["Log Analytics<br/>Audit & diagnostics"]
        end
    end

    AKSZone --> DataZone
    AKSZone --> InfraZone
    AKSZone --> ObservabilityZone
    DataZone --> InfraZone

    style AKSZone fill:#c8e6c9
    style DataZone fill:#ffe0b2
    style InfraZone fill:#f8bbd0
    style ObservabilityZone fill:#b3e5fc
```

---

## Key Architectural Decisions

### 1. **Always-On API (AKS) + Event-Driven Workers (ACA)**
- **API**: 2-8 replicas for consistent uptime and scale-on-CPU
- **Workers**: 0-10 replicas that scale down to **zero cost** when idle
- **Why**: Decouples user experience from background processing; optimizes cloud spend

### 2. **Transactional DB (Azure SQL) + Event Queue (Service Bus)**
- **SQL**: Immediate enrollment record for compliance audit trails
- **Service Bus**: Reliable async message delivery with retry and dead-letter
- **Why**: ACID transactions + guaranteed processing with no data loss

### 3. **Managed Identity (No Connection Strings in Code)**
- Pods authenticate to SQL and Service Bus with AAD tokens
- Secrets live in Key Vault; rotated without redeployment
- **Why**: Zero-trust security; compliant with regulations (HIPAA, SOC 2)

### 4. **API Management Facade**
- Single public entry point with authentication, rate limiting, versioning
- Developer portal for partner API access
- **Why**: Control exposure; enforce SLAs; enable monetization

### 5. **Observable by Default (OpenTelemetry)**
- Distributed traces across API → DB → Queue → Worker
- Metrics and logs flow to Application Insights automatically
- **Why**: Root-cause analysis in < 1 minute; meet uptime SLAs

### 6. **Future Isolated AI Runtime (ACA)**
- Isolated Container Apps per customer session
- Ephemeral (scale to zero)
- Secure data access patterns
- **Why**: Ready to add clinical AI assistants post-launch without rearchitecting

---

## Future: AI Sandbox Architecture & Tenant Isolation

### Concept

The clinical team is preparing for an AI assistant experience in the portal where physicians can ask about drug interactions, dosing guidelines, and formulary status. In a regulated healthcare setting, every response must be grounded in that customer's own approved data and protected by hard tenant boundaries.

ACA Sandboxes are ephemeral, lightweight Container Apps that enable secure AI-powered clinical assistants while maintaining strict customer isolation:

- **Customer-Grounded Responses**: AI retrieval is limited to customer-approved sources (formulary, policy, and clinical reference data)
- **Per-Tenant Isolation**: One sandbox per physician session with tenant-scoped identity and runtime context
- **No Cross-Contamination**: Data access policies and row-level controls ensure a sandbox can read only its assigned tenant data
- **Ephemeral Execution**: Sandboxes scale to 0 when idle and terminate at session end, leaving no residual runtime state
- **Regulated Auditability**: Every prompt, retrieval operation, and response trace is correlated to tenant and session IDs for audit
- **Instant Burst Capacity**: Scale 0 -> N in seconds for peak demand

### Deployment Model — Sandboxes per Session

```mermaid
graph TB
    API["HCP Portal API<br/>(Main AKS Service)"]
    
    API -->|"Session 1<br/>Dr. Smith<br/>UUID: smith-123"| SANDBOX1["ACA Sandbox 1<br/>Clinical AI Assistant<br/>Ephemeral"]
    API -->|"Session 2<br/>Dr. Jones<br/>UUID: jones-456"| SANDBOX2["ACA Sandbox 2<br/>Clinical AI Assistant<br/>Ephemeral"]
    API -->|"Session 3<br/>Dr. Lee<br/>UUID: lee-789"| SANDBOX3["ACA Sandbox 3<br/>Clinical AI Assistant<br/>Ephemeral"]
    
    SANDBOX1 -->|"SELECT * FROM Patients<br/>WHERE TenantId = 'smith-123'"| SQL["Azure SQL<br/>Shared Multi-Tenant DB<br/>Row-level security enforced"]
    SANDBOX2 -->|"SELECT * FROM Patients<br/>WHERE TenantId = 'jones-456'"| SQL
    SANDBOX3 -->|"SELECT * FROM Patients<br/>WHERE TenantId = 'lee-789'"| SQL
    
    SANDBOX1 -.->|"Read-only tenant context<br/>from Key Vault"| KV["Azure Key Vault<br/>Tenant config<br/>Model secrets"]
    SANDBOX2 -.-> KV
    SANDBOX3 -.-> KV
    
    style SANDBOX1 fill:#f1f8e9,stroke:#558b2f,stroke-width:3px
    style SANDBOX2 fill:#f1f8e9,stroke:#558b2f,stroke-width:3px
    style SANDBOX3 fill:#f1f8e9,stroke:#558b2f,stroke-width:3px
    style SQL fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style API fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    style KV fill:#ede7f6,stroke:#311b92,stroke-width:2px
```

### Key Characteristics

| Aspect | Benefit | Implementation |
|--------|---------|-----------------|
| **Ephemeral** | No long-running state; lightweight; cost-efficient | 30-min auto-delete; scale to zero |
| **Per-Tenant** | Each session isolated; zero cross-contamination risk | One ACA instance per session UUID |
| **Row-Level Security** | TenantId enforcement at database query level | Azure SQL RLS policies + managed identity |
| **Burst Capacity** | Scale 0 → 100 replicas in seconds for peak demand | ACA autoscaling on CPU/memory |
| **Developer-Familiar** | Same .NET/Docker/K8s skills; no new paradigm | C# Minimal API; standard Dockerfile |
| **Audit-Ready** | Full trace of AI operations per tenant | Application Insights + CosmosDB audit trail |

### Data Access Control Flow

```mermaid
sequenceDiagram
    participant Doc as 👨‍⚕️ Physician<br/>(Dr. Smith)
    participant Portal as HCP Portal
    participant API as Portal API<br/>(AKS)
    participant SB as Service Bus
    participant SANDBOX as AI Sandbox<br/>(Ephemeral)
    participant SQL as Azure SQL<br/>(Multi-Tenant)
    participant KV as Key Vault

    Doc->>Portal: 1. Request clinical AI insight<br/>(e.g., "Check drug interactions")
    Portal->>API: 2. POST /clinical-ai/start<br/>{ sessionId, tenantId, query }
    API->>KV: 3. Get sandbox config<br/>(model API key, tenant rules)
    API->>SB: 4. Publish StartAISandbox event
    SB->>SANDBOX: 5. Spin up ephemeral container<br/>Env: TENANT_ID=smith-123<br/>Env: SESSION_ID=uuid-xxx
    
    Note over SANDBOX: 🔐 SANDBOX EXECUTION
    SANDBOX->>SANDBOX: 6. Initialize with tenant context
    SANDBOX->>SQL: 7. Query patient data<br/>WHERE TenantId = 'smith-123'<br/>(RLS enforced in DB)
    SQL-->>SANDBOX: 8. Return only smith-123 rows
    SANDBOX->>SANDBOX: 9. Call AI model<br/>(fine-tuned on pharma data)
    SANDBOX->>SANDBOX: 10. Generate response<br/>w/ clinical references
    
    SANDBOX-->>API: 11. Return insight + trace ID
    API-->>Portal: 12. Success response
    Portal-->>Doc: 13. Display AI insight
    
    Note over SANDBOX: ⏱️ SESSION ENDS
    SANDBOX->>SANDBOX: 14. Auto-delete after 30min idle<br/>OR on session.close()
    Note over SANDBOX: Zero residual state
```

  ### Demo Visual Script (40s) — Part 2 (Screen 4 to 6)

  Use this sequence for the second half of the story so viewers see readiness without opening implementation details.

  #### Screen 4 (20s-28s) — Future Isolated AI Runtime Highlight

  - Show the architecture view with only the future AI zone highlighted.
  - Keep labels high-level: "Future Isolated AI Runtime", "Per-customer boundaries", "On-demand sessions".
  - Narration goal: architecture is ready now, assistant can be activated later.

  #### Screen 5 (28s-36s) — Session Lifecycle Animation

  Show this simple lifecycle animation:

  ```mermaid
  flowchart LR
    A[Session Start] --> B[Isolated Sandbox Spin-Up]
    B --> C[Customer-Scoped Execution]
    C --> D[Session End]
    D --> E[Sandbox Teardown]

    style B fill:#f1f8e9,stroke:#558b2f,stroke-width:2px
    style C fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    style E fill:#fff3e0,stroke:#e65100,stroke-width:2px
  ```

  - On-screen callouts during animation:
  - "No shared kernel"
  - "No shared state"
  - "Tenant boundary enforced end-to-end"

  #### Screen 6 (36s-40s) — Closing Assurance Slide

  Display three visual badges only:

  - **Per-session isolation**
  - **No shared state**
  - **No cross-customer leakage**

  Narration goal: safe AI enablement is built into the platform design, not bolted on later.

### Post-Launch Roadmap

#### **Phase 1 — Foundation** (Weeks 1–4 post-MVP)
- ✅ AI Sandbox Bicep template (containerAppEnv + ephemeral policies)
- ✅ Clinical assistant model (fine-tuned Phi-4 on pharma dataset)
- ✅ Per-tenant prompt isolation (system prompt includes TenantId)
- ✅ Basic observability (logs to Application Insights)

#### **Phase 2 — Scale & Compliance** (Weeks 5–12)
- 📋 Model serving via Azure OpenAI (fine-tuned models per tenant)
- 📋 Cost attribution (usage/token count per physician per day)
- 📋 Audit logging (what data AI accessed, AI response times)
- 📋 Compliance mode (HIPAA audit trail, consent workflows)

#### **Phase 3 — Competitive Advantage** (Months 3–6)
- 🚀 Competitive market plugins (competitor intelligence, pricing)
- 🚀 Generative drug interaction checking (real-time)
- 🚀 Patient cohort analysis (who benefits from new therapies?)
- 🚀 Reimbursement optimization (code suggestions, appeal templates)

### Security & Isolation Guarantees

```mermaid
graph TB
    subgraph Trust["🔒 Security Boundaries"]
        direction TB
        T1["Boundary 1: Network<br/>Each sandbox in private VNET<br/>No inter-sandbox traffic"]
        T2["Boundary 2: Storage<br/>Ephemeral /tmp only<br/>No persistent disk shared"]
        T3["Boundary 3: Database<br/>SQL RLS enforces TenantId<br/>Query-level filtering"]
        T4["Boundary 4: Authentication<br/>Managed Identity per sandbox<br/>AAD tokens scoped to tenant"]
        T5["Boundary 5: Observability<br/>Traces tagged with TenantId<br/>Logs segregated by session"]
    end
    
    Attack["🎯 Attack Scenarios Mitigated"]
    
    T1 --> Attack
    T2 --> Attack
    T3 --> Attack
    T4 --> Attack
    T5 --> Attack
    
    Attack --> Mit1["❌ Cannot read other tenant's<br/>patient records"]
    Attack --> Mit2["❌ Cannot persist malicious<br/>code between sessions"]
    Attack --> Mit3["❌ Cannot escalate to API<br/>or bypass AAD auth"]
    Attack --> Mit4["❌ Cannot forge tokens<br/>for other tenants"]
    Attack --> Mit5["❌ Cannot hide activity<br/>in audit logs"]
    
    style Trust fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    style Attack fill:#ffebee,stroke:#b71c1c,stroke-width:2px
    style Mit1 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style Mit2 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style Mit3 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style Mit4 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
    style Mit5 fill:#c8e6c9,stroke:#558b2f,stroke-width:2px
```

### Example: Bicep Template for AI Sandbox

```bicep
param aiSandboxImage string = 'acr.azurecr.io/caldova/ai-clinical-assistant:latest'
param tenantId string = 'smith-123'
param sessionId string // UUID
param containerAppEnvId string
param sqlConnectionString string

// Ephemeral Container App — one per physician session
resource aiSandbox 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'ai-sandbox-${tenantId}-${take(sessionId, 8)}'
  location: resourceGroup().location
  properties: {
    environmentId: containerAppEnvId
    template: {
      containers: [
        {
          name: 'clinical-ai'
          image: aiSandboxImage
          env: [
            { name: 'TENANT_ID', value: tenantId }
            { name: 'SESSION_ID', value: sessionId }
            { name: 'ENVIRONMENT', value: 'Production' }
            { name: 'CONNECTION_STRING', secretRef: 'sql-connection' }
            { name: 'OPENAI_API_KEY', secretRef: 'openai-key' }
          ]
          resources: {
            cpu: '1.0'
            memory: '2Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0      // Scale to zero when idle
        maxReplicas: 1      // One replica per session
        rules: [
          {
            name: 'cpu-based'
            custom: {
              query: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
            loggingLevel: 'Information'
          }
        ]
      }
      revisionSuffix: sessionId
    }
    configuration: {
      secrets: [
        { name: 'sql-connection', value: sqlConnectionString }
        { name: 'openai-key', value: '@Microsoft.KeyVault(SecretUri=https://keyvault.vault.azure.net/secrets/openai-api-key/)', }
      ]
      ingress: {
        external: false  // Internal to API only
        targetPort: 5000
      }
    }
  }
}

// Auto-delete policy — sandbox terminates after 30 min idle
resource deletePolicy 'Microsoft.App/containerApps/deletePolicy@2023-05-01' = {
  parent: aiSandbox
  name: 'auto-cleanup'
  properties: {
    idleTimeoutMinutes: 30
    deleteAfterSessionEnd: true
  }
}

output sandboxUrl string = aiSandbox.properties.configuration.ingress.fqdn
output sandboxName string = aiSandbox.name
```

### AI Sandbox Vs. Always-On API — When to Use Each

| Use Case | Always-On (AKS) | AI Sandbox (ACA) |
|----------|---|---|
| Enrollment form submission | ✅ | ❌ |
| Drug interaction lookup | ✅ | ✅ Better (bursty, isolated) |
| Physician search/filter | ✅ | ❌ |
| Clinical AI assistant | ❌ | ✅ Better (ephemeral, per-tenant) |
| Report generation | ✅ | ✅ Either, but sandbox cheaper if bursty |
| Compliance audit trail | ✅ | ✅ Both log to Application Insights |

---

## Production Readiness Checklist

- ✅ **Multi-replicas**: No single points of failure
- ✅ **Auto-scaling**: CPU-based for API; queue-depth for Worker
- ✅ **Health probes**: Liveness + readiness for pod eviction
- ✅ **Resource limits**: Prevents noisy-neighbor issues
- ✅ **Security**: Managed identity, RBAC, network policies (roadmap)
- ✅ **Observability**: Traces, metrics, logs aggregated to Application Insights
- ✅ **CI/CD**: Automated build → test → scan → push → deploy
- ✅ **Cost optimization**: Auto-pause SQL, Worker scales to zero
- ✅ **Compliance**: Encryption at rest and in transit; audit logging
- ✅ **Disaster recovery**: SQL multi-region backup; Service Bus zone-redundancy

---

## Deployment Sequence (Automated by CI/CD)

| Step | Component | Trigger | Time |
|------|-----------|---------|------|
| 1 | CodeQL Scan | Commit push | 2 min |
| 2 | Build API + Worker | Tests pass | 3 min |
| 3 | Defender Image Scan | Build complete | 2 min |
| 4 | Deploy Azure Infra (Bicep) | Push to main | 5 min |
| 5 | Deploy AKS Manifests | Infra ready | 3 min |
| 6 | Deploy ACA Worker | Infra ready | 2 min |
| 7 | Verify Rollouts | Deployment done | 2 min |
| **Total** | **End-to-End** | **One Push** | **~19 min** |

---

## Cost Breakdown (Monthly Estimate)

| Service | Size | Cost | Notes |
|---------|------|------|-------|
| **AKS Automatic** | 1 cluster | $90 | Managed compute |
| **Azure SQL** | GP_S_Gen5_2 serverless | $40 | Pauses when idle |
| **Service Bus** | Standard tier, 1GB/day | $25 | Reliable messaging |
| **Azure Container Apps** | 2 replicas avg | $50 | Scales 0-10 |
| **APIM** | Developer tier | $40 | API gateway + portal |
| **Application Insights** | 100 GB ingestion | $30 | Telemetry aggregation |
| **Key Vault** | Standard | $1 | Secret storage |
| **Container Registry** | Basic | $5 | Image storage |
| **Data egress** | 10 GB/mo | $1 | Typical for launch |
| | | | |
| **Total Monthly** | | **~$282** | Production-ready |

*Post-launch optimizations: move APIM to Standard tier ($400/mo) for higher throughput and SLA; add Premium AKS for Kubernetes network policies ($100/mo). Costs scale linearly with traffic.*

---

## Success Metrics (Day 1 Launch)

- **API Latency**: p95 < 200ms (mostly network transit)
- **Enrollment Success Rate**: 99.9%+ (no data loss via Service Bus)
- **Worker Processing**: < 1 min from event to "Enrollment Processed" log
- **Code Coverage**: > 80% (automated by unit tests)
- **Security Scan**: 0 critical vulnerabilities (CodeQL + Defender)
- **Uptime**: 99.5%+ (multi-replicas + health probes + auto-failover)
2. Core app layer: reliable always-on business logic on AKS Automatic.
3. Data layer: transactional consistency in Azure SQL.
4. Event layer: loose coupling through Service Bus.
5. Worker layer: elastic background execution with ACA.
6. Security layer: identity-based secret access, no embedded credentials.
7. Operations layer: telemetry, traces, and production diagnostics from first deployment.
8. Platform engineering layer: CI/CD, image registry, and continuous security posture.
9. Future AI layer: per-customer isolated execution with ACA Sandboxes.