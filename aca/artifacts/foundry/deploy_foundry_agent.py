#!/usr/bin/env python3
"""
ACA DPoC - Foundry deployment for the Caldova Invoice Audit Agent
=================================================================

Deploys the Foundry side of the invoice-audit scenario into an existing
Foundry project. The Foundry account, project, gpt-5.5 deployment, Function App,
sandbox group and API Management instance are created by acaSetup.ps1; this
script configures and connects them.

Pipeline:
    [1/6] Function App      read the MCP server host name and function key
    [2/6] Gateway           MCP_GATEWAY_MODE=apim  : publish the MCP endpoint through
                                                  API Management (API, policy,
                                                  subscription key)
                            MCP_GATEWAY_MODE=direct: call the Function App directly
    [3/6] Connections       project connection 'mcp-reconcile-tool' (key-based) and the
                            Application Insights connection used by Foundry Traces
    [4/6] Vector store      upload the 13 executed contracts for File search
    [5/6] Agent             create a new version of 'invoice-audit-agent'
    [6/6] Smoke tests       MCP tools/list through the gateway + one grounded prompt

The script is idempotent: re-running updates the same resources and creates a
new agent version.

Usage:
    python deploy_foundry_agent.py                  # full deployment + smoke tests
    python deploy_foundry_agent.py --skip-smoke     # deployment only
    python deploy_foundry_agent.py --smoke          # smoke tests only
    python deploy_foundry_agent.py --smoke-sandbox  # smoke tests, including one real
                                                    # run_code call in the ACA sandbox
"""

from __future__ import annotations

import json
import logging
import os
import sys
import time
from pathlib import Path

import requests
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config.settings import MANIFEST_PATH, ROOT, Settings  # noqa: E402

# --------------------------------------------------------------------------- #
# API versions
# --------------------------------------------------------------------------- #
ARM = "https://management.azure.com"
WEB_API = "2023-12-01"
APIM_API = "2024-05-01"
INSIGHTS_API = "2020-02-02"
CONN_API = "2025-04-01-preview"

APIM_KEY_HEADER = "Ocp-Apim-Subscription-Key"
FUNCTION_KEY_HEADER = "x-functions-key"
MCP_PROTOCOL_VERSION = "2025-06-18"

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s  %(levelname)-7s  %(message)s",
    datefmt="%H:%M:%S",
)
for noisy in ("azure", "urllib3", "httpx"):
    logging.getLogger(noisy).setLevel(logging.WARNING)
log = logging.getLogger("deploy")


class DeploymentError(RuntimeError):
    pass


# --------------------------------------------------------------------------- #
# Azure Resource Manager helper
# --------------------------------------------------------------------------- #
class ArmClient:
    def __init__(self) -> None:
        from azure.identity import DefaultAzureCredential

        self._credential = DefaultAzureCredential()

    def _headers(self) -> dict[str, str]:
        token = self._credential.get_token(f"{ARM}/.default").token
        return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    def request(self, method: str, resource_id: str, api_version: str,
                body: dict | None = None, allow_404: bool = False) -> requests.Response:
        url = f"{ARM}{resource_id}?api-version={api_version}"
        resp = requests.request(method, url, headers=self._headers(), json=body, timeout=120)
        if resp.status_code == 202:
            self._wait_for_async(resp)
        if allow_404 and resp.status_code == 404:
            return resp
        if resp.status_code >= 400:
            raise DeploymentError(f"{method} {resource_id} -> HTTP {resp.status_code}: {resp.text[:600]}")
        return resp

    def _wait_for_async(self, resp: requests.Response, timeout_s: int = 600) -> None:
        url = resp.headers.get("Azure-AsyncOperation") or resp.headers.get("Location")
        if not url:
            return
        deadline = time.time() + timeout_s
        while time.time() < deadline:
            retry_after = str(resp.headers.get("Retry-After", "5"))
            time.sleep(int(retry_after) if retry_after.isdigit() else 5)
            poll = requests.get(url, headers=self._headers(), timeout=60)
            if poll.status_code == 202:
                continue
            if poll.status_code >= 400:
                raise DeploymentError(f"Async operation failed: HTTP {poll.status_code}: {poll.text[:600]}")
            status = ""
            if poll.content:
                try:
                    status = (poll.json() or {}).get("status", "")
                except ValueError:
                    status = ""
            if status in ("", "Succeeded"):
                return
            if status in ("Failed", "Canceled"):
                raise DeploymentError(f"Async operation {status}: {poll.text[:600]}")
        raise DeploymentError(f"Async operation did not finish within {timeout_s}s")


# --------------------------------------------------------------------------- #
# [1/6] Function App
# --------------------------------------------------------------------------- #
def get_function_endpoint(arm: ArmClient, cfg: Settings) -> tuple[str, str]:
    """Return (host name, default function key) of the MCP Function App."""
    site = arm.request("GET", cfg.function_app_id, WEB_API).json()
    host = site["properties"]["defaultHostName"]

    # Keys exist only after the Functions host has started once after publish.
    for attempt in range(1, 11):
        try:
            keys = arm.request("POST", f"{cfg.function_app_id}/host/default/listkeys", WEB_API).json()
            key = (keys.get("functionKeys") or {}).get("default") or keys.get("masterKey")
            if key:
                log.info("   Function App '%s' (%s) - function key retrieved", cfg.function_app_name, host)
                return host, key
        except DeploymentError as exc:
            log.info("   waiting for Function App host keys (attempt %d/10): %s", attempt, str(exc)[:160])
        time.sleep(30)
    raise DeploymentError(
        f"Could not read function keys for '{cfg.function_app_name}'. Confirm the app is "
        "published and running (Portal > Function App > App keys)."
    )


# --------------------------------------------------------------------------- #
# [2/6] Gateway
# --------------------------------------------------------------------------- #
def _policy_xml(named_value: str, timeout_s: int) -> str:
    # The function key is injected from a secret named value, so the caller only
    # ever holds the APIM subscription key. buffer-response="false" keeps the
    # streamable-HTTP (text/event-stream) responses of the MCP server flowing.
    # Foundry's agent runtime sends MCP POST bodies with Transfer-Encoding:
    # chunked, which the Azure Functions host delivers to the Python worker as
    # an empty body. set-body buffers the request and forwards it with a
    # Content-Length, so the function receives the full JSON-RPC message.
    return (
        "<policies>"
        "<inbound><base />"
        f'<set-header name="{FUNCTION_KEY_HEADER}" exists-action="override">'
        f"<value>{{{{{named_value}}}}}</value></set-header>"
        "<choose><when condition='@(context.Request.Method == \"POST\")'>"
        "<set-body>@(context.Request.Body.As&lt;string&gt;(preserveContent: true))</set-body>"
        "</when></choose>"
        "</inbound>"
        f'<backend><forward-request timeout="{timeout_s}" buffer-response="false" /></backend>'
        "<outbound><base /></outbound>"
        "<on-error><base /></on-error>"
        "</policies>"
    )


def wait_for_apim(arm: ArmClient, cfg: Settings) -> dict:
    deadline = time.time() + cfg.apim_wait_minutes * 60
    while True:
        svc = arm.request("GET", cfg.apim_id, APIM_API).json()
        state = svc["properties"].get("provisioningState", "")
        if state == "Succeeded":
            return svc
        if state in ("Failed", "Canceled"):
            raise DeploymentError(f"API Management '{cfg.apim_name}' is in state '{state}'")
        if time.time() > deadline:
            raise DeploymentError(
                f"API Management '{cfg.apim_name}' still '{state}' after {cfg.apim_wait_minutes} min. "
                "Re-run once it shows 'Online' in the portal."
            )
        log.info("   API Management '%s' is '%s' - waiting (Developer tier can take 30-45 min)...",
                 cfg.apim_name, state)
        time.sleep(60)


def configure_apim(arm: ArmClient, cfg: Settings, manifest: dict,
                   func_host: str, func_key: str) -> tuple[str, str, str]:
    """Publish the MCP endpoint through APIM. Returns (server_url, header, key)."""
    a = manifest["apim"]
    mcp_path = manifest["mcp_tool"]["function_mcp_path"]
    svc = wait_for_apim(arm, cfg)
    gateway_url = svc["properties"]["gatewayUrl"].rstrip("/")

    api_id = f"{cfg.apim_id}/apis/{a['api_name']}"

    arm.request("PUT", f"{cfg.apim_id}/namedValues/{a['named_value']}", APIM_API, {
        "properties": {"displayName": a["named_value"], "value": func_key, "secret": True},
    })
    log.info("   named value '%s' (secret function key) ready", a["named_value"])

    arm.request("PUT", api_id, APIM_API, {
        "properties": {
            "displayName": a["api_name"],
            "description": "Caldova invoice reconciliation MCP server (Azure Functions, ACA sandbox).",
            "path": a["api_path"],
            "protocols": ["https"],
            "serviceUrl": f"https://{func_host}",
            "type": "http",
            "subscriptionRequired": True,
            "subscriptionKeyParameterNames": {"header": APIM_KEY_HEADER, "query": "subscription-key"},
        },
    })
    for method in ("POST", "GET", "DELETE"):
        arm.request("PUT", f"{api_id}/operations/mcp-{method.lower()}", APIM_API, {
            "properties": {
                "displayName": f"MCP {method}",
                "method": method,
                "urlTemplate": mcp_path,
                "templateParameters": [],
                "responses": [],
            },
        })
    arm.request("PUT", f"{api_id}/policies/policy", APIM_API, {
        "properties": {"format": "rawxml",
                       "value": _policy_xml(a["named_value"], int(a["backend_timeout_seconds"]))},
    })
    log.info("   API '%s' -> https://%s%s (POST/GET/DELETE, streaming policy) ready",
             a["api_name"], func_host, mcp_path)

    sub_id = f"{cfg.apim_id}/subscriptions/{a['subscription_name']}"
    arm.request("PUT", sub_id, APIM_API, {
        "properties": {"displayName": a["subscription_name"],
                       "scope": f"/apis/{a['api_name']}", "state": "active"},
    })
    secrets = arm.request("POST", f"{sub_id}/listSecrets", APIM_API).json()
    server_url = f"{gateway_url}/{a['api_path']}{mcp_path}"
    log.info("   subscription '%s' ready; MCP server URL: %s", a["subscription_name"], server_url)
    return server_url, APIM_KEY_HEADER, secrets["primaryKey"]


def resolve_gateway(arm: ArmClient, cfg: Settings, manifest: dict,
                    func_host: str, func_key: str) -> tuple[str, str, str]:
    if cfg.gateway_mode == "apim":
        return configure_apim(arm, cfg, manifest, func_host, func_key)
    server_url = f"https://{func_host}{manifest['mcp_tool']['function_mcp_path']}"
    log.info("   direct mode - MCP server URL: %s", server_url)
    return server_url, FUNCTION_KEY_HEADER, func_key


# --------------------------------------------------------------------------- #
# [3/6] Project connection (key-based RemoteTool)
# --------------------------------------------------------------------------- #
def create_connection(arm: ArmClient, cfg: Settings, manifest: dict,
                      server_url: str, header: str, key: str) -> str:
    name = manifest["mcp_tool"]["connection_name"]
    arm.request("PUT", f"{cfg.project_id}/connections/{name}", CONN_API, {
        "properties": {
            "authType": "CustomKeys",
            "category": "RemoteTool",
            "target": server_url,
            "isSharedToAll": True,
            "credentials": {"keys": {header: key}},
            "metadata": {"ApiType": "Azure"},
        },
    })
    log.info("   connection '%s' ready (key header: %s)", name, header)
    return name


def create_appinsights_connection(arm: ArmClient, cfg: Settings) -> None:
    """Connect the project to Application Insights so agent runs appear in Traces."""
    if not cfg.appinsights_name:
        log.warning("   APPINSIGHTS_NAME not set - skipping the Application Insights connection "
                    "(Foundry Traces will stay empty)")
        return
    component = arm.request("GET", cfg.appinsights_id, INSIGHTS_API).json()
    conn_string = component["properties"]["ConnectionString"]
    name = f"{cfg.appinsights_name}-connection"
    arm.request("PUT", f"{cfg.project_id}/connections/{name}", CONN_API, {
        "properties": {
            "category": "AppInsights",
            "target": cfg.appinsights_id,
            "authType": "ApiKey",
            "isSharedToAll": True,
            "credentials": {"key": conn_string},
            "metadata": {"ApiType": "Azure", "ResourceId": cfg.appinsights_id},
        },
    })
    log.info("   connection '%s' ready (Application Insights '%s' for Traces)", name, cfg.appinsights_name)


# --------------------------------------------------------------------------- #
# [4/6] Vector store with the executed contracts
# --------------------------------------------------------------------------- #
def ensure_vector_store(oai, manifest: dict) -> str:
    k = manifest["knowledge"]
    name = k["vector_store_name"]
    pdfs = sorted((ROOT / k["documents_dir"]).glob("*.pdf"))
    if not pdfs:
        raise DeploymentError(f"No PDF contracts found in {ROOT / k['documents_dir']}")

    existing = [vs for vs in oai.vector_stores.list(limit=100) if vs.name == name]
    for vs in existing:
        counts = vs.file_counts
        if counts.completed == len(pdfs) and counts.failed == 0 and counts.in_progress == 0:
            log.info("   vector store '%s' (%s) already holds %d contracts - reusing", name, vs.id, len(pdfs))
            return vs.id
    for vs in existing:
        log.info("   vector store '%s' (%s) is incomplete - replacing", name, vs.id)
        oai.vector_stores.delete(vs.id)

    vs = oai.vector_stores.create(name=name)
    handles = [open(p, "rb") for p in pdfs]
    try:
        batch = oai.vector_stores.file_batches.upload_and_poll(vector_store_id=vs.id, files=handles)
    finally:
        for h in handles:
            h.close()
    counts = batch.file_counts
    if counts.completed != len(pdfs):
        raise DeploymentError(
            f"Vector store '{name}': {counts.completed}/{len(pdfs)} files indexed "
            f"(failed={counts.failed}, in_progress={counts.in_progress})"
        )
    log.info("   vector store '%s' (%s) created with %d contracts", name, vs.id, counts.completed)
    return vs.id


# --------------------------------------------------------------------------- #
# [5/6] Agent
# --------------------------------------------------------------------------- #
def build_agent_definition(cfg: Settings, manifest: dict, vector_store_id: str,
                           server_url: str, connection_name: str):
    from azure.ai.projects.models import (
        FileSearchTool, MCPTool, MCPToolFilter, MCPToolRequireApproval,
        PromptAgentDefinition, PromptAgentDefinitionTextOptions, Reasoning,
        TextResponseFormatText,
    )
    a, t = manifest["agent"], manifest["mcp_tool"]
    instructions = (ROOT / a["instructions_file"]).read_text(encoding="utf-8").strip()
    return PromptAgentDefinition(
        model=cfg.chat_deployment,
        instructions=instructions,
        reasoning=Reasoning(effort=a["reasoning_effort"]),
        text=PromptAgentDefinitionTextOptions(format=TextResponseFormatText()),
        tools=[
            FileSearchTool(vector_store_ids=[vector_store_id]),
            MCPTool(
                server_label=t["server_label"],
                server_url=server_url,
                require_approval=MCPToolRequireApproval(
                    never=MCPToolFilter(tool_names=list(t["never_require_approval"]))),
                project_connection_id=connection_name,
            ),
        ],
    )


def create_agent(project, cfg: Settings, manifest: dict, vector_store_id: str,
                 server_url: str, connection_name: str) -> None:
    definition = build_agent_definition(cfg, manifest, vector_store_id, server_url, connection_name)
    agent = project.agents.create_version(agent_name=manifest["agent"]["name"], definition=definition)
    log.info("   agent '%s' version %s ready (model=%s)",
             manifest["agent"]["name"], getattr(agent, "version", "?"), cfg.chat_deployment)


# --------------------------------------------------------------------------- #
# [6/6] Smoke tests
# --------------------------------------------------------------------------- #
def _mcp_call(server_url: str, header: str, key: str, method: str, params: dict, rid: int) -> dict:
    resp = requests.post(
        server_url,
        headers={header: key, "Content-Type": "application/json",
                 "Accept": "application/json, text/event-stream",
                 "MCP-Protocol-Version": MCP_PROTOCOL_VERSION},
        json={"jsonrpc": "2.0", "id": rid, "method": method, "params": params},
        timeout=400,
    )
    if resp.status_code >= 400:
        raise DeploymentError(f"MCP {method} -> HTTP {resp.status_code}: {resp.text[:300]}")
    body = resp.text
    if "text/event-stream" in resp.headers.get("Content-Type", ""):
        data = [line[5:].strip() for line in body.splitlines() if line.startswith("data:")]
        body = data[-1] if data else "{}"
    msg = json.loads(body)
    if "error" in msg:
        raise DeploymentError(f"MCP {method} error: {msg['error']}")
    return msg.get("result", {})


def smoke_mcp(server_url: str, header: str, key: str, run_sandbox: bool) -> bool:
    try:
        _mcp_call(server_url, header, key, "initialize", {
            "protocolVersion": MCP_PROTOCOL_VERSION, "capabilities": {},
            "clientInfo": {"name": "aca-dpoc-smoke", "version": "1.0"}}, 1)
        tools = [t["name"] for t in _mcp_call(server_url, header, key, "tools/list", {}, 2).get("tools", [])]
        log.info("   MCP tools/list via %s -> %s", "gateway" if header == APIM_KEY_HEADER else "function", tools)
        if "run_code" not in tools:
            log.warning("   MCP server does not expose run_code")
            return False
        if run_sandbox:
            log.info("   run_code in the ACA sandbox (first call can take a few minutes)...")
            res = _mcp_call(server_url, header, key, "tools/call",
                            {"name": "run_code", "arguments": {"code": "print('sandbox ok')"}}, 3)
            payload = json.loads(res["content"][0]["text"])
            log.info("   run_code -> ok=%s %s", payload.get("ok"),
                     payload.get("error") or payload.get("notebook", {}).get("cells", [{}])[0].get("outputs"))
            return bool(payload.get("ok"))
        return True
    except Exception as exc:  # noqa: BLE001
        log.warning("   MCP smoke test failed: %s", exc)
        return False


def smoke_agent(project, manifest: dict) -> bool:
    s = manifest["smoke_test"]
    try:
        oai = project.get_openai_client()
        resp = oai.responses.create(
            input=s["agent_prompt"],
            extra_body={"agent_reference": {"type": "agent_reference", "name": manifest["agent"]["name"]}},
        )
        text = getattr(resp, "output_text", "") or ""
        log.info("   agent -> %s", text.strip().replace("\n", " ")[:300])
        if s["expected_text"] in text:
            return True
        log.warning("   expected '%s' in the answer (File search grounding)", s["expected_text"])
        return False
    except Exception as exc:  # noqa: BLE001
        log.warning("   agent smoke test failed: %s", exc)
        return False


# --------------------------------------------------------------------------- #
# Orchestrator
# --------------------------------------------------------------------------- #
def main() -> int:
    from azure.ai.projects import AIProjectClient
    from azure.identity import DefaultAzureCredential

    cfg = Settings.resolve()
    manifest = yaml.safe_load(Path(MANIFEST_PATH).read_text(encoding="utf-8"))
    smoke_only = "--smoke" in sys.argv
    skip_smoke = "--skip-smoke" in sys.argv
    run_sandbox = "--smoke-sandbox" in sys.argv
    log.info("ACA invoice-audit deploy - project=%s, gateway=%s", cfg.ai_project_name, cfg.gateway_mode)

    arm = ArmClient()
    log.info("[1/6] Function App...")
    func_host, func_key = get_function_endpoint(arm, cfg)
    log.info("[2/6] Gateway (%s)...", cfg.gateway_mode)
    server_url, header, key = resolve_gateway(arm, cfg, manifest, func_host, func_key)

    project = AIProjectClient(endpoint=cfg.project_endpoint, credential=DefaultAzureCredential())
    with project:
        if not smoke_only:
            log.info("[3/6] Project connections...")
            connection = create_connection(arm, cfg, manifest, server_url, header, key)
            create_appinsights_connection(arm, cfg)
            log.info("[4/6] Vector store...")
            vs_id = ensure_vector_store(project.get_openai_client(), manifest)
            log.info("[5/6] Agent...")
            create_agent(project, cfg, manifest, vs_id, server_url, connection)

        if skip_smoke:
            log.info("DONE (smoke tests skipped).")
            return 0
        log.info("[6/6] Smoke tests...")
        mcp_ok = smoke_mcp(server_url, header, key, run_sandbox)
        agent_ok = smoke_agent(project, manifest)
    log.info("DONE. MCP=%s, agent grounding=%s. Verify in the Foundry portal (Agents > %s).",
             "PASS" if mcp_ok else "CHECK", "PASS" if agent_ok else "CHECK", manifest["agent"]["name"])
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except DeploymentError as err:
        log.error("%s", err)
        sys.exit(1)
    except KeyboardInterrupt:
        log.error("Interrupted.")
        sys.exit(130)