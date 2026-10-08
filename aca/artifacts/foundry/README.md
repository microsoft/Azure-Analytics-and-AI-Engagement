# ACA DPoC — Foundry: Invoice Audit Agent

This codebase configures a Microsoft Foundry project for the Caldova invoice-audit
scenario. It creates the agent, its knowledge (the executed CMO contracts) and its
connection to the reconciliation tool, and it wires up tracing. One Python script
does the whole deployment, and it is safe to run again.

## 1. What is automated

| # | Asset | Details |
| --- | --- | --- |
| 1 | **MCP gateway (API Management API)** | API `mcp-reconcile-tool` (path `/mcp-reconcile-tool`) in front of the Function App's `/mcp` endpoint. Operations `POST`, `GET`, `DELETE` on `/mcp`. The policy injects the function key from a secret named value, re-sends each POST body with a Content-Length, and streams responses back (`buffer-response="false"`, 300 s backend timeout). |
| 2 | **API Management named value** | `mcp-reconcile-func-key`, secret, holding the Function App's default function key. |
| 3 | **API Management subscription** | `mcp-reconcile-tool-foundry`, scoped to the API above. Its key is what Foundry uses. |
| 4 | **Project connection: MCP tool** | `mcp-reconcile-tool`, category *Remote tool*, key-based (`Ocp-Apim-Subscription-Key`), target `https://<apim>.azure-api.net/mcp-reconcile-tool/mcp`. |
| 5 | **Project connection: Application Insights** | `<appinsights-name>-connection`. It feeds the agent's **Traces** tab. |
| 6 | **Knowledge (File search)** | The 13 PDFs in `datasets/contracts/` are uploaded, and the vector store `vs-cmo-contracts` is created. The store is reused on later runs when it already holds all 13 files. |
| 7 | **Agent** | `invoice-audit-agent` (prompt agent): model from `AZURE_CHAT_DEPLOYMENT`, reasoning effort `low`, instructions from `agents/invoice_audit_agent.txt`, and tools **File search** (`vs-cmo-contracts`) + **MCP** (`mcp-reconcile-tool`). `run_code` is set to *never require approval* in Foundry; the instructions make the agent ask the user for approval in the conversation before running code. |
| 8 | **Smoke tests** | MCP `initialize` + `tools/list` through API Management; optionally one real `run_code`; and one grounded question to the agent (expects `CMO-LAM-2027-014`). |

## 2. Azure resources

### Used (must exist before running)

| Resource | Purpose |
| --- | --- |
| Microsoft Foundry resource (AI Services account) and project | Hosts the agent, files, vector store and connections |
| Model deployment (for example `gpt-5.5`) | The agent's model |
| Function App with the MCP reconcile tool **deployed and running** | The tool the agent calls. The script reads its host name and default function key. |
| API Management instance | The gateway in front of the Function App. If it is still provisioning, the script waits up to `APIM_WAIT_MINUTES`. |
| Application Insights | Destination for agent traces (optional, but needed for the Traces tab) |

### Created or updated by the script

| Where | Created |
| --- | --- |
| API Management | named value `mcp-reconcile-func-key`; API `mcp-reconcile-tool` + 3 operations + policy; subscription `mcp-reconcile-tool-foundry` |
| Foundry project | connections `mcp-reconcile-tool` and `<appinsights-name>-connection`; 13 uploaded files; vector store `vs-cmo-contracts`; agent `invoice-audit-agent` (a new version only when its definition changes) |

No Azure resources (accounts, services, apps) are created. Only the configuration objects above are.

## 3. Codebase

```
deploy_foundry_agent.py        # the script to run
config/agent.yaml              # what is deployed: agent, knowledge, tool, APIM object names, smoke test
config/settings.py             # reads .env / environment variables
agents/invoice_audit_agent.txt # agent instructions
datasets/contracts/*.pdf       # 13 executed CMO contracts
.env                           # configuration (set to the target environment's values)
requirements.txt
```

## 4. Configuration: `.env`

Set every value in `.env` to the target environment's values (the committed file holds the test environment's values). The file contains no secrets:
authentication uses the signed-in Azure identity, and the keys the script needs are
read from Azure at run time.

| Variable | Required | Value | Example |
| --- | --- | --- | --- |
| `AZURE_SUBSCRIPTION_ID` | yes | Subscription ID | `2afb8c66-…` |
| `AZURE_RESOURCE_GROUP` | yes | Resource group holding all resources above | `rg-aca-zj6vud5` |
| `AZURE_AI_SERVICES_NAME` | yes | Foundry resource (AI Services account) name | `hub-aifoundry-aca-zj6vud5` |
| `AZURE_AI_PROJECT_NAME` | yes | Foundry project name | `proj-aifoundry-aca-zj6vud5` |
| `AZURE_AI_PROJECT_ENDPOINT` | yes | `https://<foundry-resource>.services.ai.azure.com/api/projects/<project>` | see below |
| `AZURE_CHAT_DEPLOYMENT` | yes | Model **deployment** name used by the agent | `gpt-5.5` |
| `FUNCTION_APP_NAME` | yes | Function App hosting the MCP reconcile tool | `func-mcp-reconcile-zj6vud5` |
| `MCP_GATEWAY_MODE` | no | `apim` (default). `direct` is for diagnostics only (see §8). | `apim` |
| `APIM_NAME` | yes (in `apim` mode) | API Management instance name | `apim-zj6vud5` |
| `APIM_WAIT_MINUTES` | no | Maximum wait for API Management to finish provisioning (default `60`) | `60` |
| `APPINSIGHTS_NAME` | no | Application Insights name. Leave it empty to skip the Traces connection. | `appi-zj6vud5` |
| `LOG_LEVEL` | no | Script log level (default `INFO`) | `INFO` |

**Project endpoint.** Use the resource's *AI Foundry API* endpoint
(`*.services.ai.azure.com`), not its general endpoint (`*.cognitiveservices.azure.com`):

```powershell
$acct = az cognitiveservices account show -g <rg> -n <foundry-resource> | ConvertFrom-Json
"$($acct.properties.endpoints.'AI Foundry API'.TrimEnd('/'))/api/projects/<project>"
```

## 5. Run

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
az login --tenant <tenant-id>
az account set --subscription <subscription-id>
python deploy_foundry_agent.py
```

| Command | Effect |
| --- | --- |
| `python deploy_foundry_agent.py` | Full deployment, then smoke tests |
| `python deploy_foundry_agent.py --skip-smoke` | Deployment only |
| `python deploy_foundry_agent.py --smoke` | Smoke tests only (still refreshes the API Management configuration) |
| `python deploy_foundry_agent.py --smoke-sandbox` | Also runs one real `run_code` in the ACA sandbox |

A successful run ends with `DONE. MCP=PASS, agent grounding=PASS`.

## 6. Permissions and role assignments

Assign roles **by role name**. Allow 2–5 minutes for a new assignment to take effect.

| Principal | Role | Scope | Why |
| --- | --- | --- | --- |
| Logged in User Identity that runs the script | **Foundry User** | Foundry project | Create the agent, upload files, create the vector store (data-plane actions, not included in Owner or Contributor) |
| Logged in User Identity that runs the script | **Contributor** (or Owner) | Resource group | Read the Function App's keys, configure API Management, create project connections, read Application Insights |
| Logged in user and any other users exploring Foundry agent in the Foundry playground | **Foundry User** | Foundry **resource** (`Microsoft.CognitiveServices/accounts/<name>`) | Attach an invoice in the playground. With the role on the project only, the portal refuses file uploads. Refresh the portal after assigning. |
| Logged in user and any other users exploring Foundry Traces | **Log Analytics Reader** | Application Insights resource | Query trace data (Owner already includes it) |

The Foundry project's managed identity needs **no** role assignments: File search
uses a Foundry-managed vector store, and the MCP tool authenticates with a key.

## 7. Verify in the Foundry portal

1. **Agents → `invoice-audit-agent`**: the tools list shows *File search*
   (`vs-cmo-contracts`) and *mcp-reconcile-tool*
   (`https://<apim>.azure-api.net/mcp-reconcile-tool/mcp`).
2. Start a new chat, attach an invoice PDF, and send *"Audit this invoice against its
   governing contract."* The agent cites the contract, shows the four-check plan and
   the exact Python code, then asks for approval.
3. Reply *"Approved. Run it."* The agent calls `mcp-reconcile-tool` (`run_code`) and
   returns cited findings with an approve, dispute or reject recommendation.
4. **Traces** tab: the run appears within a few minutes, including
   `execute_tool mcp_mcp-reconcile-tool.run_code`.

## 8. Notes

- **API Management is required between Foundry and the Function App.** Foundry's
  agent runtime sends MCP request bodies with `Transfer-Encoding: chunked`, which the
  Azure Functions host delivers to the Python worker as an empty body. The API policy
  re-sends each body with a Content-Length. `MCP_GATEWAY_MODE=direct` connects the
  agent straight to the Function App and is kept only for diagnostics; it does not
  work with the Foundry agent runtime.
- The Foundry label *"Governed with AI Gateway"* comes from linking API Management to
  the Foundry resource in the portal. The API created here gives the same runtime path
  (agent → API Management → Function App) without that label.

## 9. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `Configuration incomplete` | A required `.env` value is missing or still a `###TOKEN###` |
| `403` on agent creation or file upload | Foundry User is missing on the project, or still propagating |
| Playground: "You don't have permission to upload files" | Foundry User is missing on the Foundry **resource**; assign it and refresh the portal |
| `Could not read function keys` | The Function App is not deployed or not running |
| API Management still `Activating` | Developer-tier provisioning takes 30–45 minutes; run again once it is *Online* |
| Agent reports "Initialization timed out", `405` or `406` from the MCP server | The Function App is not running the current `functionApp` code, or the agent points at the Function App directly; redeploy the function and run this script in `apim` mode |
| Tool call ends with API Management `500` after ~230 s | App Service request limit; the sandbox was slow to start. Retry the request. |
| Playground "Error network error", with a 0-token trace | The browser's connection to Foundry dropped before the run started; resend the message |
| Traces tab empty | `APPINSIGHTS_NAME` was not set when the script ran, or ingestion is still pending (2–5 min) |
| Agent answers without citing a contract | The vector store is still indexing (*Data → Vector stores*) |