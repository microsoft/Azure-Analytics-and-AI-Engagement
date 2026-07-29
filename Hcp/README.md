# HCP Portal Solution

This folder contains the HCP prescriber portal application and its deployment assets.

## Structure

- `HcpPortalApi/`: ASP.NET Core API using Clean Architecture, Azure SQL, Service Bus, and OpenTelemetry.
- `HcpPortalWeb/`: React frontend for the HCP portal experience.
- `infra/`: Infrastructure-as-code assets for Azure resources.
- `observability/`: Shared telemetry configuration and operational guidance.
- `Architecture.md`: Reference architecture for the end-to-end solution.

## Intended delivery shape

The final application is organized as two deployable workloads:

1. `HcpPortalWeb`: browser application served as a containerized frontend.
2. `HcpPortalApi`: backend API deployed separately and exposed to the frontend through ingress.

This keeps UI and API release cadence independent while still sharing platform, telemetry, and deployment conventions.