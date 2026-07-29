# HCP Portal API

Cloud-native ASP.NET Core Web API for physician enrollment using Clean Architecture.

## Implemented capabilities

- Clean Architecture split across Domain, Application, Infrastructure, and Api projects
- Physician enrollment API endpoints
- Azure SQL persistence with EF Core
- Azure Service Bus event publishing for enrollment-created events
- Dependency injection across layers
- OpenTelemetry tracing and metrics via OTLP exporter
- Docker multi-stage build
- Kubernetes manifests (namespace, deployment, service, ingress, HPA, secret template)
- GitHub Actions CI/CD pipeline with image build and deployment flow
- No hardcoded secrets (runtime configuration through environment variables and Kubernetes secrets)

## Solution layout

- HcpPortalApi.Domain: Core entities and enums
- HcpPortalApi.Application: Use cases, DTOs, and abstraction interfaces
- HcpPortalApi.Infrastructure: EF Core persistence and Service Bus publisher
- HcpPortalApi.Api: HTTP host, controllers, health checks, and OpenTelemetry wiring

## Required configuration

Set these through environment variables, secret manager, or Kubernetes secrets:

- ConnectionStrings__HcpSql
- ServiceBus__FullyQualifiedNamespace (recommended with managed identity)
- ServiceBus__QueueName
- Foundry__Endpoint
- Foundry__EmbeddingModelDeployment
- Foundry__ChatModelDeployment
- HorizonDb__ConnectionString
- Cosmos__AccountEndpoint
- ConnectionStrings__Redis
- SandboxGroup__Name
- SandboxGroup__ManagementEndpoint
- SandboxRuntime__BaseUrlTemplate
- SandboxRuntime__RequireIsolatedSandboxExecution (set to true to disable shared-runtime fallback)
- OpenTelemetry__Otlp__Endpoint

## Local run

1. Restore and build:

```bash
dotnet restore HcpPortalApi.slnx
dotnet build HcpPortalApi.slnx
```

2. Run API:

```bash
dotnet run --project HcpPortalApi.Api/HcpPortalApi.Api.csproj
```

3. Test endpoints with HcpPortalApi.Api/HcpPortalApi.Api.http.

## Container build

```bash
docker build -t hcp-portal-api:local .
```

## Kubernetes apply order

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret-template.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml
```
