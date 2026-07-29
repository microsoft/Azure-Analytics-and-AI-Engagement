# Execution Checklist: Clinician-Ready Data + AI Memory + One Workspace Pipeline

Purpose: implement the full flow in one repository path so app, data, AI memory, and deployment stay in a single PR and a single GitHub Actions pipeline.

## 1) Baseline and branch hygiene

Open these files first:
- Hcp/Architecture.md
- Hcp/docs/Chapter5-Module5-Demo-Prompts.md
- .github/workflows/hcp-portal-api.yml

Run:
```powershell
git status
git branch --show-current
```

Expected outcome:
- You are on a feature branch.
- Working tree is clean or only contains intended edits.

## 2) Data split design (clinical vs memory)

Target split:
- Clinical + vector data: PostgreSQL compatible store (HorizonDB-ready shape).
- Conversation and profile memory: Cosmos DB.
- Short-term response cache: Redis.

Create or update these API contracts:
- Hcp/HcpPortalApi/HcpPortalApi.Application/Abstractions
- Hcp/HcpPortalApi/HcpPortalApi.Application/DTOs

Suggested interfaces:
- IClinicalKnowledgeRepository (clinical records + embeddings)
- IConversationMemoryRepository (long-term memory)
- IResponseCache (short-term cache)

Verification:
```powershell
cd Hcp/HcpPortalApi
dotnet build HcpPortalApi.slnx
```

Expected outcome:
- New abstractions compile with no API break in existing enrollment flow.

## 3) Infrastructure modules for AI-ready data layer

Current main orchestration exists at:
- Hcp/infra/bicep/main.bicep

Current Service Bus module exists at:
- Hcp/infra/bicep/servicebus.bicep

Add new Bicep modules:
- Hcp/infra/bicep/postgresql.bicep
- Hcp/infra/bicep/cosmos.bicep
- Hcp/infra/bicep/redis.bicep

Then wire in Hcp/infra/bicep/main.bicep:
- New params for region/capacity/network toggles.
- Module calls for PostgreSQL, Cosmos, Redis.
- Outputs for endpoints, database names, and connection references.

Verification:
```powershell
az bicep build --file Hcp/infra/bicep/main.bicep
```

Expected outcome:
- Bicep compiles.
- New outputs available for deployment and app settings.

## 4) App configuration and DI wiring

Open and update:
- Hcp/HcpPortalApi/HcpPortalApi.Infrastructure/DependencyInjection.cs
- Hcp/HcpPortalApi/HcpPortalApi.Api/Program.cs
- Hcp/HcpPortalApi/HcpPortalApi.Api/appsettings.json
- Hcp/HcpPortalApi/HcpPortalApi.Api/appsettings.Development.json

Add configuration sections:
- PostgreSql
- Cosmos
- Redis
- Foundry

Register services:
- Clinical knowledge repository implementation.
- Conversation memory repository implementation.
- Redis cache implementation.
- Foundry client wrapper for embeddings and retrieval orchestration.

Verification:
```powershell
cd Hcp/HcpPortalApi
dotnet build HcpPortalApi.slnx
dotnet test HcpPortalApi.slnx --configuration Release
```

Expected outcome:
- API and worker resolve DI successfully.
- Tests pass.

## 5) Worker and event enrichment path

Open and update:
- Hcp/HcpPortalApi/HcpPortalApi.Worker/Program.cs
- Hcp/HcpPortalApi/HcpPortalApi.Worker/EnrollmentEventWorker.cs

Actions:
- On enrollment event, enrich with clinical context retrieval.
- Persist long-term conversation/memory updates to Cosmos.
- Use Redis for repeated response memoization when applicable.

Verification:
```powershell
cd Hcp/HcpPortalApi
dotnet build HcpPortalApi.slnx
```

Expected outcome:
- Worker remains event-driven and backward compatible with existing queue shape.

## 6) Pipeline: one workflow for app + infra + data

Open and update:
- .github/workflows/hcp-portal-api.yml

Ensure workflow includes:
- Build and test.
- Security scan (CodeQL, container scan already present).
- Infra deploy from Hcp/infra/bicep/main.bicep including PostgreSQL/Cosmos/Redis.
- App deploy to AKS using newly produced outputs.
- Post-deploy verification checks.

Current deploy gates already used in this workflow:
- vars.ENABLE_INFRA_DEPLOYMENT
- vars.ENABLE_DEFENDER_DEPLOYMENT

Add required secrets/vars as needed:
- AZURE_CREDENTIALS
- AZURE_RESOURCE_GROUP
- AZURE_APIM_PUBLISHER_EMAIL
- Any new deployment parameters for data services

Verification:
```powershell
# Local lint/validation pass
# 1) Validate yaml syntax in editor
# 2) Push branch and confirm workflow run in GitHub Actions UI
```

Expected outcome:
- One workflow run provisions data resources and deploys app updates.

## 7) Kubernetes runtime configuration updates

Open and update as needed:
- Hcp/HcpPortalApi/k8s/deployment.yaml
- Hcp/HcpPortalApi/k8s/worker-deployment.yaml
- Hcp/HcpPortalApi/k8s/secret-template.yaml

Actions:
- Add env var wiring for PostgreSQL/Cosmos/Redis/Foundry endpoints.
- Keep secret values externalized (no plaintext secrets in manifests).
- Keep existing namespace split and rollout behavior.

Verification:
```powershell
kubectl apply --dry-run=client -f Hcp/HcpPortalApi/k8s/deployment.yaml
kubectl apply --dry-run=client -f Hcp/HcpPortalApi/k8s/worker-deployment.yaml
```

Expected outcome:
- Manifests remain valid and deployable.

## 8) PR packaging and evidence

Stage all related changes in one PR scope:
- API/Application/Infrastructure code
- Worker updates
- Bicep modules and main orchestration
- Workflow updates
- K8s manifest updates
- Supporting docs

Suggested commit sequence:
1. feat(infra): add postgresql/cosmos/redis bicep modules and outputs
2. feat(api): wire foundry, memory repositories, and redis cache
3. feat(worker): enrich event processing with memory updates
4. ci: extend workflow for data layer provisioning and deploy checks
5. docs: execution notes and architecture update

Verification:
```powershell
git status
git diff --name-only
```

Expected outcome:
- Reviewers can trace design to implementation in one cohesive PR.

## 9) Minimal acceptance test script

After deployment, verify:
1. Enrollment API returns success and writes transactional record.
2. Service Bus queue receives and drains enrollment event.
3. Worker processes event without crash loop.
4. AI retrieval path resolves clinical context.
5. Multi-turn memory persists and reloads context.
6. Repeat prompt path shows cache benefit.

Operational checks:
```powershell
kubectl get pods -n hcp-portal
kubectl get pods -n hcp-portal-worker
kubectl logs -n hcp-portal-worker -l app=hcp-enrollment-worker --tail=200
```

Expected outcome:
- End-to-end path works with no manual portal-only steps.

## 10) Definition of done

Done means all of the following are true:
- Data model split is implemented (clinical/vector vs memory/cache).
- Infrastructure is source-controlled and deployed through Bicep.
- API + worker are wired with managed config and pass build/tests.
- One GitHub Actions workflow deploys app + data layer.
- Evidence exists in logs and deployment outputs.
- Single PR documents business impact and operational verification.
