# ACA Sandbox Readiness Checklist

Use this checklist to move from optional sandbox usage to enforced per-session sandbox isolation for clinician assistant requests.

## 1. Platform and feature readiness

- [ ] Subscription has `Microsoft.App` registered.
- [ ] ACA Sandboxes preview is enabled in target subscription/region.
- [ ] A sandbox group resource exists: `Microsoft.App/sandboxGroups`.
- [ ] Sandbox group `managementEndpoint` is discoverable.
- [ ] Target region is in `allowedLocations` for the sandbox group.

Evidence in repo:
- `Hcp/infra/bicep/sandboxgroup.bicep` reads an existing sandbox group and exports `managementEndpoint`.
- `.github/workflows/hcp-portal-api.yml` discovers sandbox group and passes name/endpoint to deployment outputs.

## 2. Runtime configuration wiring

Set these runtime values for the API workload:

- [ ] `SandboxGroup__Name`
- [ ] `SandboxGroup__ManagementEndpoint`
- [ ] `SandboxRuntime__BaseUrlTemplate`
- [ ] `SandboxRuntime__Audience` (if runtime endpoint requires AAD token)
- [ ] `SandboxRuntime__RequireIsolatedSandboxExecution=true` for strict mode

Notes:
- `BaseUrlTemplate` must resolve to a reachable sandbox runtime endpoint and should include placeholders as needed, e.g. `{sandboxId}` and/or `{sandboxGroup}`.
- If strict mode is `false`, the API can fall back to shared runtime on sandbox failures.
- If strict mode is `true`, sandbox failures return HTTP 503 and no fallback is used.

## 3. Identity and access

- [ ] API workload identity can request token for sandbox group audience.
- [ ] API workload identity can call sandbox management endpoint.
- [ ] Sandbox runtime endpoint authorizes the API identity (if protected by AAD).
- [ ] Data-plane access follows tenant boundaries (no broad cross-tenant credentials).

## 4. Session lifecycle behavior

- [ ] `POST /api/SandboxSessions` creates one sandbox session per prescriber flow.
- [ ] `GET /api/SandboxSessions` shows active sessions.
- [ ] `DELETE /api/SandboxSessions/{id}` ends and cleans up sessions.
- [ ] Session timeout/cleanup policy is defined (idle timeout and hard TTL).

## 5. Isolation controls

- [ ] Session-to-tenant mapping is explicit (labels include prescriber/session identity).
- [ ] Sandbox receives only tenant-scoped data access context.
- [ ] No shared secrets for multiple tenants in sandbox runtime.
- [ ] Logs/traces do not leak cross-tenant identifiers or payload data.

## 6. Operational readiness

- [ ] Alerts for sandbox create/list/delete failures.
- [ ] Alerts for strict-mode 503 rate spike.
- [ ] Dashboards include sandbox session counts and duration.
- [ ] Runbook exists for sandbox endpoint outage and identity failures.

## 7. Validation tests before go-live

- [ ] Create session -> query assistant -> end session happy path.
- [ ] Two concurrent prescribers receive different sandbox ids.
- [ ] Strict mode on + missing session returns HTTP 409.
- [ ] Strict mode on + sandbox runtime failure returns HTTP 503 (no fallback).
- [ ] Strict mode off + sandbox runtime failure falls back to shared assistant response.

## 8. Recommended production setting

For regulated production environments that require hard tenant isolation:

- `SandboxRuntime__RequireIsolatedSandboxExecution=true`

This enforces sandbox-only assistant execution and prevents accidental fallback to shared runtime.
