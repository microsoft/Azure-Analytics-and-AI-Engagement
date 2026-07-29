# Modernization Plan: PharmaBackend Azure Modernization

**Project**: PharmacyBackend (PharmaBackend)
**Source Assessment**: `.github/modernize/assessment/reports/report-20260619162917/report.json`
**Generated**: 2026-06-19
**Plan folder**: `.github/modernize/pharmabackend-azure-modernization/`

---

## Technical Framework

- **Language**: C# on .NET 10 (`net10.0`)
- **Framework**: ASP.NET Core Web API (`Microsoft.NET.Sdk.Web`)
- **Build Tool**: MSBuild (`PharmacyBackend.csproj`, SDK-style)
- **Database**: PostgreSQL via `Npgsql.EntityFrameworkCore.PostgreSQL` (Entity Framework Core)
- **Cache**: Redis via `Microsoft.Extensions.Caching.StackExchangeRedis`
- **Key Dependencies**: `Azure.Identity`, `Azure.Extensions.AspNetCore.Configuration.Secrets`, `Microsoft.Extensions.Configuration.AzureAppConfiguration`, `HealthChecks.UI`, EF Core, Swashbuckle
- **Existing cloud wiring**: `Program.cs` already registers Azure Key Vault, Azure App Configuration, and `DefaultAzureCredential`; secrets and config endpoints are resolved at startup via `AZURE_KEYVAULT_URI` and `AZURE_APPCONFIG_ENDPOINT`
- **Existing container/k8s assets**: `Dockerfile` and `k8s/` manifests are already present in the repo

---

## Overview

This plan modernizes PharmaBackend so it runs cleanly on Azure as a managed, identity-authenticated service. The application is already substantially cloud-ready — the configuration pipeline in `Program.cs` resolves Azure Key Vault, Azure App Configuration, environment variables, and user-secrets in the correct precedence — but four AppCAT findings still need to be closed out:

- Move the remaining non-secret app settings out of `appsettings.json` / `appsettings.Development.json` into a central Azure App Configuration store, so configuration is environment-aware and dynamically refreshable.
- Re-target the application's data and cache connections at Azure Database for PostgreSQL Flexible Server and Azure Cache for Redis, authenticating with Managed Identity instead of any password or access key.
- Confirm every secret-bearing value lives in Azure Key Vault (reviewing the two Security.0003 hits in `Program.cs`, which are exception-message false positives), and that no plaintext credential survives in source or configuration.
- Verify the seed-time image base URL in `Data/DbSeeder.cs` is reachable from Azure and is always sourced from configuration in production.

A standard CVE remediation task runs last to ensure every newly introduced Azure SDK package, together with the existing dependency graph, is free of known high or critical vulnerabilities before deployment.

The migration follows a phased flow: first centralize configuration (so later tasks can publish endpoint values into a single source of truth), then migrate data and cache in parallel, then close the Key Vault / hardcoded-URL gaps, and finally run security validation.

---

## Migration Impact Summary

| Application   | Original Service                          | New Azure Service                                | Authentication      | Comments                                                                              |
|---------------|--------------------------------------------|--------------------------------------------------|---------------------|----------------------------------------------------------------------------------------|
| PharmaBackend | Local `appsettings.json` configuration     | Azure App Configuration                          | Managed Identity    | Non-secret keys (Logging, AllowedHosts, Seeding:ImageBaseUrl) only; secrets via KV refs |
| PharmaBackend | Local PostgreSQL (Npgsql connection string)| Azure Database for PostgreSQL Flexible Server    | Managed Identity    | EF Core; Npgsql token provider acquires access tokens via DefaultAzureCredential       |
| PharmaBackend | Local Redis (StackExchange.Redis)          | Azure Cache for Redis                            | Managed Identity    | `AddStackExchangeRedisCache` re-wired to use Microsoft.Azure.StackExchangeRedis token   |
| PharmaBackend | Any in-source / in-config secret values    | Azure Key Vault                                   | Managed Identity    | Program.cs already wires `AddAzureKeyVault`; audit + finalize secret inventory          |
| PharmaBackend | Hardcoded fallback URL in `DbSeeder.cs`    | (none — verification only)                       | n/a                 | Public Pexels CDN, reachable from Azure; harden so prod cannot use the fallback        |

---

## Assessment Findings Mapped to Tasks

| AppCAT Rule         | Incidents | Locations                                                                    | Addressed by                                                              |
|---------------------|-----------|------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| Configuration.0003  | 3         | `appsettings.json` (Logging, ConnectionStrings, Seeding), `appsettings.Development.json` (Logging, ConnectionStrings) | Task 001 — Externalize to Azure App Configuration                          |
| Connection.0001     | 4         | `appsettings.json` (DefaultConnection, RedisConnection), `appsettings.Development.json` (DefaultConnection, RedisConnection) | Task 002 — Azure Database for PostgreSQL; Task 003 — Azure Cache for Redis |
| Security.0003       | 2         | `Program.cs` lines 80, 85 (exception-message false positives)                | Task 004 — Audit & finalize Key Vault secret coverage                      |
| Local.0006          | 1         | `Data/DbSeeder.cs` line 33 (`https://images.pexels.com/photos` fallback)     | Task 005 — Verify URL reachability and harden fallback                     |

---

## Task Summary

All implementation detail (SDKs, package names, code patterns, authentication wiring) is owned by the referenced skills. The plan only states what each task achieves; the tasks themselves live in `.metadata/tasks.json`.

| # | ID                                                          | Type      | Skill / Pattern                                              | Depends on            |
|---|-------------------------------------------------------------|-----------|--------------------------------------------------------------|-----------------------|
| 1 | `001-transform-migration-local-appsettings-azure-app-configuration` | transform | `migration-local-appsettings-azure-app-configuration`        | —                     |
| 2 | `002-transform-migration-azure-database-postgresql`         | transform | `migration-azure-database-postgresql`                        | 001                   |
| 3 | `003-transform-migration-azure-redis-cache`                 | transform | `migration-azure-redis-cache`                                | 001                   |
| 4 | `004-transform-migration-azure-keyvault-secret`             | transform | `migration-azure-keyvault-secret`                            | 002, 003              |
| 5 | `005-transform-verify-hardcoded-url-reachability`           | transform | _(no matched skill — pattern only: verify hardcoded URL)_    | 001                   |
| 6 | `006-security-cve-validation-and-remediation`               | security  | `validate-cves-and-fix` (default for security tasks)         | 001–005               |

**Suggested phases**:

1. **Configuration foundation** — Task 001 lands first so the App Configuration store exists and downstream tasks can publish endpoints there.
2. **Data & cache (parallel)** — Tasks 002 and 003 can execute in parallel; both consume the App Configuration store from phase 1.
3. **Secret consolidation & URL hardening** — Task 004 audits the final secret surface (now that all Azure SDK dependencies are present) and is sequenced after data/cache. Task 005 can run in parallel with 004 since it only touches `DbSeeder.cs`.
4. **Security validation** — Task 006 runs last so it can scan every newly introduced Azure SDK package alongside the existing dependency graph.

---

## Open Questions & Questionnaire

_No clarification questions were raised. The user invoked planning with `Scope: ALL categories from the assessment (no category filter)` and provided one recommended Azure target per category, so every assessment finding maps to exactly one generated task and no per-category solution disambiguation was needed._

---

## Notes on False Positives Detected During Plan Generation

- **Security.0003 (Program.cs lines 80, 85)** — The flagged literal `"secret"` appears inside exception messages (`"Supply it via user-secrets, environment variables, Azure Key Vault, or Azure App Configuration."`). These are not hardcoded credentials. Task 004 keeps the finding in scope (it is `mandatory` severity for `AppServiceManagedInstance.Windows`) but its primary job is to audit the wider secret surface rather than to rewrite these specific lines.
- **Existing cloud wiring** — `Program.cs` already registers `AddAzureKeyVault` and `AddAzureAppConfiguration` with `DefaultAzureCredential` and a Sentinel-based refresh trigger. Tasks 001–004 build on top of this; no rework of the configuration pipeline itself is required.
- **Database flavor** — The user prompt referred to "Azure SQL", but the project uses `Npgsql` / PostgreSQL. The plan therefore selects `migration-azure-database-postgresql` (Azure Database for PostgreSQL Flexible Server) to match the actual codebase.
