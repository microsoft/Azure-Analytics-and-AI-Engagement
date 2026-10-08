# ACA DPoC — Function App: MCP reconcile tool

A Python (v2 model) Azure Function that hosts a stateless **MCP server**
(`sandbox-code-runner`, streamable HTTP at `/mcp`). The Invoice Audit Agent calls it
to run approved reconciliation code in an isolated **Azure Container Apps sandbox**.
The Function App never executes submitted code itself.

## 1. What is automated

| Asset | Details |
| --- | --- |
| **HTTP function `http_app_func`** | One ASGI function, route `/{*route}`, auth level **Function** (callers send `x-functions-key`). Serves the MCP endpoint at `https://<function-app>.azurewebsites.net/mcp`. |
| **MCP tool `run_code`** | Input `code` (Python source). Runs it in the sandbox and returns JSON: `ok`, `notebook_id`, `notebook.cells[].outputs` (or `error`). |
| **MCP tool `run_notebook`** | Input `notebook` (Jupyter notebook object). Same result shape. |
| **Persistent sandbox** | One sandbox per agent (label `agent-id=invoice-agent`), created on first use, resumed when auto-suspended, and found again by its label if its pointer is lost. Lifecycle: auto-suspend after 10 idle minutes, auto-delete 7 days after suspension. Egress allowed only to `archive.ubuntu.com`, `security.ubuntu.com`, `pypi.org`, `files.pythonhosted.org`. |
| **Sandbox pointer** | Blob `agent-sandbox-state/sandbox-map.json` records the sandbox ID, so any Function instance reuses the same sandbox. The container is created if missing. |

The Azure Functions host adaptations are in `function_app.py`:
- `GET /mcp` returns an empty, closed event stream. MCP clients open this stream,
  and on Azure Functions an open stream would never return.
- POST `Accept` headers are normalized to the single value the MCP library expects.

Tool work runs on a worker thread, so a slow sandbox call does not block other MCP
requests.

## 2. Azure resources

### Used (must exist)

| Resource | Purpose |
| --- | --- |
| Function App (Linux, Python 3.11) with a **system-assigned managed identity** | Hosts the MCP server |
| Storage account | Functions host storage (`AzureWebJobsStorage`) and the `agent-sandbox-state` container |
| Container Apps **sandbox group** | Where the code runs |

### Created at run time by the code

| Resource | When |
| --- | --- |
| ACA sandbox (label `agent-id=invoice-agent`) | First tool call, or when the previous sandbox no longer exists |
| Blob container `agent-sandbox-state` and blob `sandbox-map.json` | First tool call |

## 3. Codebase

```
function_app.py         # Functions entry point (AsgiFunctionApp) + host adaptations
sandbox_mcp_server.py   # MCP server: tools, sandbox and blob-state logic
host.json               # routePrefix "" so the endpoint is /mcp
requirements.txt        # azure-functions, azure-identity, azure-containerapps-sandbox==0.1.0b3,
                        # azure-storage-blob, mcp (<2)
.funcignore / .gitignore
```

## 4. Configuration

### 4.1 App Settings (Azure)

All configuration is read from environment variables. In Azure, set these as
**App Settings** on the Function App.

| Setting | Required | Value |
| --- | --- | --- |
| `FUNCTIONS_WORKER_RUNTIME` | yes | `python` |
| `FUNCTIONS_EXTENSION_VERSION` | yes | `~4` |
| `AzureWebJobsStorage` | yes | Storage account connection string |
| `AZURE_REGION` | yes | Region of the sandbox group, for example `westus3` |
| `AZURE_SUBSCRIPTION_ID` | yes | Subscription ID of the sandbox group |
| `AZURE_RESOURCE_GROUP` | yes | Resource group of the sandbox group |
| `AZURE_SANDBOX_GROUP` | yes | Sandbox group name |
| `SANDBOX_STATE_BLOB_ACCOUNT_URL` | yes* | `https://<storage-account>.blob.core.windows.net` (accessed with the managed identity) |
| `SANDBOX_STATE_BLOB_CONNECTION_STRING` | alternative* | Use instead of the account URL to authenticate with a key |
| `SANDBOX_STATE_BLOB_CONTAINER` | no | Default `agent-sandbox-state` |
| `SANDBOX_STATE_BLOB_NAME` | no | Default `sandbox-map.json` |
| `AZURE_CLIENT_ID` | only with a user-assigned identity | Client ID of that identity (not needed with the system-assigned identity) |
| `SANDBOX_EXECUTION_TIMEOUT_SECONDS` | no | Default `120`. Maximum run time of submitted code. |
| `SANDBOX_RESUME_TIMEOUT_SECONDS` | no | Default `60`. Maximum wait for a suspended sandbox to resume. |
| `SANDBOX_CREATE_TIMEOUT_SECONDS` | no | Default `90`. Maximum wait for a new sandbox to start. |
| `SANDBOX_AUTO_SUSPEND_IDLE_SECONDS` | no | Default `600` |
| `SANDBOX_AUTO_DELETE_AFTER_SECONDS` | no | Default `604800` (7 days) |
| `SANDBOX_MAX_INPUT_BYTES` | no | Default `524288` |
| `SANDBOX_MAX_OUTPUT_BYTES` | no | Default `2097152` |
| `MCP_ADDITIONAL_ALLOWED_HOSTS` | no | Extra host names, comma-separated (for a custom domain) |

\* Set one of the two.

The resume, create and execution limits keep a tool call within App Service's
230-second request limit.

### 4.2 Site configuration (Azure)

| Setting | Value |
| --- | --- |
| Stack (`linuxFxVersion`) | `PYTHON|3.11` |
| Always On | `On` (App Service / dedicated plans), so the MCP endpoint stays warm |

On Windows, set `linuxFxVersion` through a JSON body, because `az.cmd` splits the `|` on the command line:

```powershell
@{ properties = @{ linuxFxVersion = "PYTHON|3.11"; alwaysOn = $true } } | ConvertTo-Json | Set-Content webconfig.json
az rest --method patch --url "https://management.azure.com/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/sites/<function-app>/config/web?api-version=2023-12-01" --body "@webconfig.json"
```

### 4.3 `local.settings.json` (local runs only)

`func start` reads settings from `local.settings.json`. It is excluded from
deployment (`.funcignore`) and from source control (`.gitignore`). It holds the same
values as the App Settings:

```json
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AzureWebJobsStorage": "<storage-account-connection-string>",
    "AZURE_REGION": "<sandbox-group-region>",
    "AZURE_SUBSCRIPTION_ID": "<subscription-id>",
    "AZURE_RESOURCE_GROUP": "<resource-group>",
    "AZURE_SANDBOX_GROUP": "<sandbox-group-name>",
    "SANDBOX_STATE_BLOB_ACCOUNT_URL": "https://<storage-account>.blob.core.windows.net",
    "SANDBOX_STATE_BLOB_CONTAINER": "agent-sandbox-state",
    "SANDBOX_STATE_BLOB_NAME": "sandbox-map.json"
  }
}
```

Locally the code authenticates as the signed-in Azure CLI user (`az login`). That
user needs the same two data roles as the Function App identity (§5).

## 5. Permissions and role assignments

Assign **by role name**. Allow 2–5 minutes for a new assignment to take effect.

| Principal | Role | Scope | Why |
| --- | --- | --- | --- |
| Function App system-assigned identity | **Container Apps SandboxGroup Data Owner** | Sandbox group | Create, resume and execute in sandboxes |
| Function App system-assigned identity | **Storage Blob Data Contributor** | Storage account | Read and write the `sandbox-map.json` pointer |
| Developer running `func start` locally | Same two roles | Same scopes | The local run uses the developer's identity |
| Identity deploying the code | **Contributor** (or Website Contributor) | Function App / resource group | Publish the code and set App Settings |

## 6. Deploy

Requires Azure Functions Core Tools v4 and Python 3.11. From this folder:

```powershell
func azure functionapp publish <function-app-name> --python --build remote
```

Dependencies install on Azure during the remote build. Publish after the App
Settings are in place.

## 7. Test

### Local

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
func start
```

The endpoint is `http://localhost:7071/mcp`. Send
`{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}` as a POST with the headers
`Content-Type: application/json` and `Accept: application/json, text/event-stream`.
The response is an event stream whose `data:` line lists `run_code` and `run_notebook`.

### Azure

```powershell
$key = (az functionapp keys list -g <rg> -n <function-app> --query "functionKeys.default" -o tsv).Trim()
$body = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"run_code","arguments":{"code":"print(\"ok\")"}}}'
$r = Invoke-WebRequest -Uri "https://<function-app>.azurewebsites.net/mcp" -Method Post -Body $body `
      -ContentType "application/json" -UseBasicParsing `
      -Headers @{ Accept = "application/json, text/event-stream"; "x-functions-key" = $key }
$r.Content   # the data: line contains "ok": true
```

## 8. Callers

- The Foundry agent must call this function **through the API Management API
  created by the Foundry deployment**, not directly. Foundry's agent runtime sends
  request bodies with `Transfer-Encoding: chunked`, which the Functions host delivers
  to the Python worker as empty. The API Management policy re-sends each body with a
  Content-Length.
- Calls that send a normal `Content-Length` (the tests above, scripts) can call
  `/mcp` directly with the function key.
