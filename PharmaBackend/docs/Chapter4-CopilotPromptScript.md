# Chapter 4: Build New Cloud-Native Applications — Copilot Prompt Script

**Pillar:** INNOVATION — Innovate with a modern, AI-ready platform  
**Persona:** Developer (new build, not migration)  
**Story:** Developer builds ABC Pharma's HCP prescriber portal as a cloud-native microservice using GitHub Copilot, from scaffold to production deployment.

---

## Recording Order: Run prompts 1 → 2 → 3 → 4 → 5 in a new Copilot chat

Optional but recommended close-out: run prompts 6 → 7 → 8 to make the chapter fully executable for demo and handoff.

---

## Beat 1 · SCAFFOLD WITH GITHUB COPILOT

> Scaffold `HcpPortal/` — ASP.NET Core microservice for ABC Pharma's HCP prescriber portal. Include controllers/models/services, Dockerfile (aspnet:10.0), and Bicep for Azure Container Apps. Wire secrets via Key Vault + DefaultAzureCredential, same pattern as PharmaBackend.

---

## Beat 2 · PROTOTYPE IN ACA SANDBOX

> Add `infra/sandbox.bicep` for an ephemeral ACA Consumption environment and `deploy-sandbox.ps1` to build, push to ACR, and deploy HcpPortal to it. Inject `AZURE_KEYVAULT_URI` and `AZURE_APPCONFIG_ENDPOINT` as container env vars.

---

## Beat 3 · BUILD & TEST WITH AGENTIC AI + OPENAPI

> Add xUnit unit and integration tests for HcpPortal covering prescriber lookup, prescription submission, and Key Vault config. Configure Swashbuckle to export a versioned OpenAPI spec to `openapi/hcp-portal-v1.json` on build. Run tests and fix any failures.

---

## Beat 4 · SECURITY GATE — CODEQL + DEFENDER FOR CLOUD

> Add `.github/workflows/hcp-portal-security.yml` — on PR to main: run dotnet test, CodeQL C# scan (security-extended), and Defender for Cloud container image scan. Fail PR on any high/critical finding.

---

## Beat 5 · EXPOSE VIA APIM + SHIP TO PRODUCTION ACA

> Add `infra/modules/apim.bicep` (Consumption tier) importing `openapi/hcp-portal-v1.json` with OAuth2/JWT, rate limiting (100/min), and versioning. Add `infra/production.bicep` to promote the sandbox Container App to production ACA and wire APIM backend to it.

---

## Beat 6 · PRODUCTION DEPLOY AUTOMATION

> Add `deploy-production.ps1` to deploy `infra/production.bicep` end-to-end. Inputs: subscription, resource group, location, sandbox app name, prod app name, ACR, Key Vault, APIM name/publisher details, OAuth2 endpoints, OpenID config URL, JWT audience, and OAuth client ID. Output production ACA URL and APIM gateway URL.

---

## Beat 7 · PARAMETERIZE FOR REPEATABLE ENVIRONMENTS

> Add `infra/parameters/sandbox.parameters.json` and `infra/parameters/production.parameters.json` with placeholders and usage notes. Include all required APIM OAuth2/JWT settings and runtime env vars (`AZURE_KEYVAULT_URI`, `AZURE_APPCONFIG_ENDPOINT`) so deployments are reproducible.

---

## Beat 8 · CHAPTER 5 HANDOFF ARTIFACT (DATA LAYER)

> Create `docs/chapter5-data-handoff.md` with the HCP portal data requirements discovered in Chapter 4: entities, access patterns, expected scale, retention/compliance constraints, and recommended Azure data service options for IT Operations to implement in Chapter 5.

---

## Hero Products Referenced

| Beat | Products |
|------|----------|
| 1 – Scaffold | GitHub Copilot, Azure Container Apps, Azure Key Vault |
| 2 – Sandbox | Azure Container Apps Sandboxes, Azure Container Registry |
| 3 – Build & Test | GitHub Copilot (agentic), Swashbuckle (OpenAPI) |
| 4 – Security Gate | GitHub Advanced Security (CodeQL), Microsoft Defender for Cloud (DevOps Security) |
| 5 – Ship | Azure API Management, Azure Container Apps (production) |
| 6 – Prod Deploy Automation | Azure Bicep, Azure Container Apps, Azure API Management |
| 7 – Environment Parameterization | Azure Bicep, GitHub Copilot |
| 8 – Chapter 5 Handoff | GitHub Copilot, Azure architecture/governance practices |
