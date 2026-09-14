# FSI IQ Function App (`fsi-iq-func`)

Python (v2 model) Azure Functions app that fronts the FSI IQ demo. Two HTTP routes:

- **`fsi_iq_api`** — invokes the Foundry workflow (`FSIIQ-Workflow`) via the
  Responses API on the "missing / validate" branch; every other prompt in the
  guided flow is served from deterministic scripted responses. Off-script prompts
  fall through to the live workflow agent.
- **`fsi_iq_workflow`** — a scripted responder (canned JSON keyed by prompt) for
  the on-rails demo path. Needs no Foundry access.

## Configuration

All configuration comes from App Settings (environment variables). There is no
`.env` file and no `local.settings.json`. The provisioning script sets each value
as an App Setting on the Function App resource; the Functions runtime injects them
as environment variables, and the code reads them via `os.environ`.

| App Setting | Purpose |
| --- | --- |
| `PROJECT_ENDPOINT` | Foundry project that hosts `FSIIQ-Workflow`. No default; the workflow route fails without it. |
| `WORKFLOW_NAME` | Workflow invoked by `call_workflow_agent`. Defaults to `FSIIQ-Workflow`; set explicitly to be safe. |
| `AzureWebJobsStorage` | Functions host storage. Required by the platform. |
| `FUNCTIONS_WORKER_RUNTIME` | Must be `python`. Required by the platform. |

## Prerequisites

- Azure Functions Core Tools v4, Python 3.11.
- A Function App (Flex Consumption or Consumption, Linux).
- The Function App's **managed identity** needs **Azure AI User** (Foundry User)
  on the Foundry project — `call_workflow_agent` uses `DefaultAzureCredential`,
  which resolves to the managed identity in the cloud.
- For grounded retrieval, the Foundry project's managed identity also needs
  **Search Index Data Reader** + **Search Service Contributor** on the search
  service (see the foundry-side manual-setup doc).

## Deploy (outline)

1. Provisioning script sets the App Settings above on the Function App resource.
2. `func azure functionapp publish <your-func-app-name> --python`.

## SDK

- `azure-ai-projects==2.1.0`, invoked by name via
  `extra_body={"agent_reference": {"type": "agent_reference", "name": ...}}`
  (aligned with the foundry deploy script).

## Security

Keep secrets in App Settings / Key Vault only — never in source. Consider moving
route auth off `ANONYMOUS` (Function key or APIM).
