"""MCP server for running Python source and Jupyter notebooks in ACA sandboxes.

The server process never executes submitted code locally. It uploads a notebook
and a small runner to an ephemeral Azure Container Apps sandbox, then returns
the captured execution result as JSON.
"""

from __future__ import annotations

import json
import logging
import os
import threading
import uuid
from typing import Any

import anyio

from azure.containerapps.sandbox import (
    AutoDeletePolicy,
    AutoSuspendPolicy,
    LifecyclePolicy,
    SandboxGroupClient,
    endpoint_for_region,
)
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from mcp.server.fastmcp import FastMCP
from mcp.server.transport_security import TransportSecuritySettings


logger = logging.getLogger("sandbox_mcp_server")

MAX_INPUT_BYTES = int(os.getenv("SANDBOX_MAX_INPUT_BYTES", str(512 * 1024)))
MAX_OUTPUT_BYTES = int(os.getenv("SANDBOX_MAX_OUTPUT_BYTES", str(2 * 1024 * 1024)))
EXECUTION_TIMEOUT_SECONDS = int(os.getenv("SANDBOX_EXECUTION_TIMEOUT_SECONDS", "120"))
# Upper bounds for waiting on a sandbox to resume or to be created. App Service
# ends any HTTP request after 230 seconds; these limits keep a tool call inside
# that window so the caller receives a clear error instead of a gateway timeout.
RESUME_TIMEOUT_SECONDS = int(os.getenv("SANDBOX_RESUME_TIMEOUT_SECONDS", "60"))
CREATE_TIMEOUT_SECONDS = int(os.getenv("SANDBOX_CREATE_TIMEOUT_SECONDS", "90"))
ALLOWED_EGRESS_HOSTS = (
    "archive.ubuntu.com",
    "security.ubuntu.com",
    "pypi.org",
    "files.pythonhosted.org",
)

REQUIRED_ENV_VARS = (
    "AZURE_REGION",
    "AZURE_SUBSCRIPTION_ID",
    "AZURE_RESOURCE_GROUP",
    "AZURE_SANDBOX_GROUP",
)

# --------------------------------------------------------------------------
# Persistent, reusable sandbox (one agent for now).
#
# Simplification for now: exactly one logical agent ("invoice-agent").
# When you have more than one, replace AGENT_ID with a real argument
# threaded through run_code/run_notebook (e.g. an `agent_id: str` param),
# and everything below already keys off that value, so the rest of this
# design doesn't change.
# --------------------------------------------------------------------------
AGENT_ID = "invoice-agent"
SANDBOX_LABEL_KEY = "agent-id"

# Reuses the existing blob storage account already used elsewhere in this
# project. This blob is just a tiny durable pointer — {"invoice-agent":
# "<sandbox_id>"} — so that whichever Function instance handles the next
# request can find the SAME sandbox, instead of each instance keeping its
# own in-memory guess (which breaks the moment Azure Functions routes you
# to a different instance or cold-starts a new one).
SANDBOX_STATE_BLOB_ACCOUNT_URL = os.getenv("SANDBOX_STATE_BLOB_ACCOUNT_URL", "")
SANDBOX_STATE_BLOB_CONNECTION_STRING = os.getenv("SANDBOX_STATE_BLOB_CONNECTION_STRING", "")
SANDBOX_STATE_BLOB_CONTAINER = os.getenv("SANDBOX_STATE_BLOB_CONTAINER", "agent-sandbox-state")
SANDBOX_STATE_BLOB_NAME = os.getenv("SANDBOX_STATE_BLOB_NAME", "sandbox-map.json")

# How long a sandbox can sit idle before the platform suspends it (memory +
# disk snapshotted, compute billing stops) — matches the "10 idle minutes"
# behavior described for Caldova's Agent Launchpad.
SANDBOX_AUTO_SUSPEND_IDLE_SECONDS = int(os.getenv("SANDBOX_AUTO_SUSPEND_IDLE_SECONDS", str(10 * 60)))
# How long a *suspended* sandbox can sit before it's deleted for good, so
# a genuinely-abandoned agent doesn't accumulate storage cost forever.
# 7 days is a starting point, not a considered policy — tune to taste.
SANDBOX_AUTO_DELETE_AFTER_SECONDS = int(os.getenv("SANDBOX_AUTO_DELETE_AFTER_SECONDS", str(7 * 24 * 60 * 60)))

# FastMCP's DNS-rebinding protection only trusts localhost/127.0.0.1 by
# default, which exists to stop a malicious webpage from reaching a
# server bound to a developer's own machine. It doesn't apply here — this
# is a public HTTPS endpoint terminated by Azure's own edge, with no
# localhost-only trust boundary — so we explicitly allow-list the real
# Function App hostname(s) instead of leaving every production request
# to fail with 421 "Invalid Host header".
#
# WEBSITE_HOSTNAME is set automatically by Azure App Service/Functions to
# the app's own *.azurewebsites.net hostname. If you later attach a custom
# domain, add it via the optional MCP_ADDITIONAL_ALLOWED_HOSTS env var
# (comma-separated, e.g. "mcp.mycompany.com,mcp.mycompany.com:443").
_default_host = os.getenv("WEBSITE_HOSTNAME", "127.0.0.1")
_extra_hosts = [h.strip() for h in os.getenv("MCP_ADDITIONAL_ALLOWED_HOSTS", "").split(",") if h.strip()]
_allowed_hosts = list({
    _default_host,
    f"{_default_host}:443",
    "127.0.0.1",
    "127.0.0.1:*",
    "localhost",
    "localhost:*",
    *_extra_hosts,
})

mcp = FastMCP(
    "sandbox-code-runner",
    instructions=(
        "Run Python code or notebooks in an isolated Azure Container Apps "
        "sandbox. Submitted code is untrusted and must be treated as such."
    ),
    # Azure Functions (Flex Consumption) can route consecutive requests to
    # different instances, or cold-start a fresh one, with no session
    # affinity. FastMCP's default stateful mode keeps session state in that
    # instance's memory, so a later request landing on a different instance
    # gets a 404 "session has expired" for an Mcp-Session-Id it never
    # created. stateless_http=True makes every request self-contained, so
    # there's no server-side session to lose.
    stateless_http=True,
    transport_security=TransportSecuritySettings(
        enable_dns_rebinding_protection=True,
        allowed_hosts=_allowed_hosts,
    ),
)


# --------------------------------------------------------------------------
# Lazy, cached sandbox client.
#
# IMPORTANT: nothing below runs at import time. The Azure Functions host
# imports this module during cold start to discover `mcp` and build the
# ASGI app; if that import touched the network or credential chain (as the
# old module-level `_client = SandboxGroupClient(...)` did), any missing
# app setting, RBAC gap, or slow credential resolution would fail or stall
# the import — which meant ALL tools failed to register, and every request
# came back as a BadGateway from the host runtime.
#
# By deferring this to first tool use, a bad configuration becomes a normal
# tool-call error message instead of taking down the whole function app.
# --------------------------------------------------------------------------

_client: SandboxGroupClient | None = None
_client_lock = threading.Lock()


class SandboxConfigError(RuntimeError):
    """Raised when the sandbox client can't be constructed."""


def _check_required_env_vars() -> None:
    missing = [name for name in REQUIRED_ENV_VARS if not os.getenv(name)]
    if missing:
        raise SandboxConfigError(
            "Missing required app settings: "
            + ", ".join(missing)
            + ". Set these under Configuration \u2192 Environment variables "
            "on the Function App (local.settings.json is NOT deployed)."
        )


def _build_credential() -> DefaultAzureCredential:
    # In Azure, exclude the slow/irrelevant local-dev credential types so a
    # cold start doesn't stall for several seconds walking the full chain
    # (interactive browser, VS Code, Azure CLI, etc.) before falling back
    # to Managed Identity. This directly reduces BadGateway risk from
    # cold-start latency on Flex Consumption.
    running_in_azure = bool(os.getenv("WEBSITE_INSTANCE_ID"))
    if running_in_azure:
        return DefaultAzureCredential(
            exclude_environment_credential=False,
            exclude_managed_identity_credential=False,
            exclude_shared_token_cache_credential=True,
            exclude_visual_studio_code_credential=True,
            exclude_cli_credential=True,
            exclude_powershell_credential=True,
            exclude_interactive_browser_credential=True,
        )
    # Local development: allow the full default chain (e.g. Azure CLI login).
    return DefaultAzureCredential()


def _get_client() -> SandboxGroupClient:
    global _client
    if _client is not None:
        return _client

    with _client_lock:
        if _client is not None:
            return _client

        _check_required_env_vars()

        try:
            _client = SandboxGroupClient(
                endpoint_for_region(os.environ["AZURE_REGION"]),
                _build_credential(),
                subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],
                resource_group=os.environ["AZURE_RESOURCE_GROUP"],
                sandbox_group=os.environ["AZURE_SANDBOX_GROUP"],
            )
        except Exception as error:  # noqa: BLE001 - surface as a clear tool error
            logger.exception("Failed to construct SandboxGroupClient")
            raise SandboxConfigError(
                f"Could not connect to the sandbox control plane: {error}"
            ) from error

        return _client


# --------------------------------------------------------------------------
# Durable agent -> sandbox_id pointer, stored in blob storage.
#
# Same lazy/cached/error-safe pattern as the sandbox client above, and for
# the same reason: this must never run at import time.
# --------------------------------------------------------------------------

_blob_service_client: BlobServiceClient | None = None
_blob_lock = threading.Lock()


class SandboxStateError(RuntimeError):
    """Raised when the sandbox-id pointer can't be read or written."""


def _get_blob_service_client() -> BlobServiceClient:
    global _blob_service_client
    if _blob_service_client is not None:
        return _blob_service_client

    with _blob_lock:
        if _blob_service_client is not None:
            return _blob_service_client

        if not SANDBOX_STATE_BLOB_ACCOUNT_URL and not SANDBOX_STATE_BLOB_CONNECTION_STRING:
            raise SandboxStateError(
                "Set SANDBOX_STATE_BLOB_ACCOUNT_URL or "
                "SANDBOX_STATE_BLOB_CONNECTION_STRING under Configuration "
                "\u2192 Environment variables."
            )

        try:
            if SANDBOX_STATE_BLOB_CONNECTION_STRING:
                _blob_service_client = BlobServiceClient.from_connection_string(
                    SANDBOX_STATE_BLOB_CONNECTION_STRING
                )
            else:
                _blob_service_client = BlobServiceClient(
                    account_url=SANDBOX_STATE_BLOB_ACCOUNT_URL,
                    credential=_build_credential(),
                )
        except Exception as error:  # noqa: BLE001
            logger.exception("Failed to construct BlobServiceClient")
            raise SandboxStateError(f"Could not connect to blob storage: {error}") from error

        return _blob_service_client


def _load_sandbox_map() -> dict[str, str]:
    """Best-effort read of the {agent_id: sandbox_id} pointer file.

    Returns an empty dict on any problem (container/blob doesn't exist yet,
    transient error, bad JSON) rather than raising \u2014 an unreadable pointer
    should fall back to "create/find a sandbox", not crash the tool call.
    """
    try:
        container = _get_blob_service_client().get_container_client(SANDBOX_STATE_BLOB_CONTAINER)
        blob = container.get_blob_client(SANDBOX_STATE_BLOB_NAME)
        data = blob.download_blob().readall()
        parsed = json.loads(data)
        return parsed if isinstance(parsed, dict) else {}
    except Exception as error:  # noqa: BLE001 - missing blob/container is expected on first run
        logger.info("No existing sandbox-state blob (or failed to read it): %s", error)
        return {}


def _save_sandbox_map(mapping: dict[str, str]) -> None:
    """Overwrite the pointer file with the full current mapping.

    NOTE: this is a plain read-modify-write, not a compare-and-swap. That's
    fine while AGENT_ID is a single hardcoded value with essentially no
    write concurrency. Once there's more than one agent (or more than one
    writer), switch to an ETag-conditional upload so two concurrent
    requests can't clobber each other's sandbox_id.
    """
    service = _get_blob_service_client()
    container = service.get_container_client(SANDBOX_STATE_BLOB_CONTAINER)
    try:
        container.create_container()
    except Exception:  # noqa: BLE001 - already exists is the common case
        pass
    blob = container.get_blob_client(SANDBOX_STATE_BLOB_NAME)
    blob.upload_blob(json.dumps(mapping).encode("utf-8"), overwrite=True)


def _attach(client: SandboxGroupClient, sandbox_id: str):
    """Return a running, sandbox-scoped client for an existing sandbox.

    ``SandboxGroupClient.get_sandbox`` returns a read-only ``Sandbox`` record,
    which has no file or exec operations. File writes and command execution
    are performed through the ``SandboxClient`` returned by
    ``get_sandbox_client``. ``ensure_running`` resumes a sandbox that the
    lifecycle policy has auto-suspended and raises if the sandbox is in a
    state that cannot be resumed.
    """
    client.get_sandbox(sandbox_id)  # raises if the sandbox no longer exists
    sandbox = client.get_sandbox_client(sandbox_id)
    sandbox.ensure_running(timeout=RESUME_TIMEOUT_SECONDS)
    return sandbox


def _get_or_create_sandbox(client: SandboxGroupClient, agent_id: str):
    """Return a running ``SandboxClient`` for this agent's persistent sandbox.

    Order of attempts:
    1. Reattach to the sandbox id cached in blob storage.
    2. Recover the sandbox by its agent label, in case the pointer blob was
       lost while the sandbox still exists.
    3. Create a new sandbox, label it, set its lifecycle policy, and persist
       its id.
    """
    mapping = _load_sandbox_map()
    cached_id = mapping.get(agent_id)

    if cached_id:
        try:
            return _attach(client, cached_id)
        except Exception as error:  # noqa: BLE001
            logger.warning(
                "Cached sandbox %s for agent %s could not be reattached (%s).",
                cached_id, agent_id, error,
            )

    try:
        for existing in client.list_sandboxes(labels={SANDBOX_LABEL_KEY: agent_id}):
            if not existing.id or existing.id == cached_id:
                continue
            try:
                sandbox = _attach(client, existing.id)
            except Exception as error:  # noqa: BLE001
                logger.warning("Labelled sandbox %s could not be reattached (%s).", existing.id, error)
                continue
            mapping[agent_id] = existing.id
            try:
                _save_sandbox_map(mapping)
            except SandboxStateError:
                logger.exception("Failed to persist recovered sandbox id for agent %s", agent_id)
            return sandbox
    except Exception as error:  # noqa: BLE001
        logger.info("Label-based sandbox lookup failed for agent %s: %s", agent_id, error)

    # begin_create_sandbox(...).result() returns a SandboxClient in Running state.
    sandbox = client.begin_create_sandbox(
        disk="ubuntu",
        labels={SANDBOX_LABEL_KEY: agent_id},
        polling_timeout=CREATE_TIMEOUT_SECONDS,
    ).result()

    try:
        sandbox.set_lifecycle_policy(
            LifecyclePolicy(
                auto_suspend=AutoSuspendPolicy(
                    enabled=True,
                    interval=SANDBOX_AUTO_SUSPEND_IDLE_SECONDS,
                    mode="Memory",
                ),
                auto_delete=AutoDeletePolicy(
                    enabled=True,
                    delete_interval_seconds=SANDBOX_AUTO_DELETE_AFTER_SECONDS,
                ),
            )
        )
    except Exception:  # noqa: BLE001 - a lifecycle-policy failure must not block execution
        logger.exception("Failed to set lifecycle policy on new sandbox for agent %s", agent_id)

    mapping[agent_id] = sandbox.sandbox_id
    try:
        _save_sandbox_map(mapping)
    except SandboxStateError:
        logger.exception("Failed to persist sandbox id for agent %s", agent_id)

    return sandbox


def _source_text(source: Any) -> str:
    if isinstance(source, list):
        if not all(isinstance(line, str) for line in source):
            raise ValueError("Notebook source lists must contain only strings")
        return "".join(source)
    if not isinstance(source, str):
        raise ValueError("Notebook cell source must be a string or list of strings")
    return source


def _notebook_from_input(code: str | None, notebook: dict[str, Any] | None) -> dict[str, Any]:
    if (code is None) == (notebook is None):
        raise ValueError("Provide exactly one of 'code' or 'notebook'")

    if code is not None:
        if not isinstance(code, str) or not code.strip():
            raise ValueError("'code' must be a non-empty Python string")
        cells = [{"cell_type": "code", "source": code, "metadata": {}, "outputs": []}]
    else:
        if not isinstance(notebook, dict) or not isinstance(notebook.get("cells"), list):
            raise ValueError("'notebook' must be a Jupyter notebook object with a cells list")
        cells = []
        for cell in notebook["cells"]:
            if not isinstance(cell, dict) or cell.get("cell_type") not in {"code", "markdown", "raw"}:
                raise ValueError("Each notebook cell must be an object with a valid cell_type")
            normalized = dict(cell)
            normalized["source"] = _source_text(normalized.get("source", ""))
            normalized.setdefault("metadata", {})
            normalized.setdefault("outputs", [])
            cells.append(normalized)

    return {
        "cells": cells,
        "metadata": (notebook or {}).get("metadata", {}) if notebook else {},
        "nbformat": (notebook or {}).get("nbformat", 4) if notebook else 4,
        "nbformat_minor": (notebook or {}).get("nbformat_minor", 5) if notebook else 5,
    }


_RUNNER = r'''
import contextlib
import io
import json
import traceback

with open("/workspace/input.ipynb", encoding="utf-8") as handle:
    notebook = json.load(handle)

namespace = {"__name__": "__sandbox__"}
failed = False
for index, cell in enumerate(notebook.get("cells", [])):
    if cell.get("cell_type") != "code":
        continue
    source = cell.get("source", "")
    if isinstance(source, list):
        source = "".join(source)
    stdout = io.StringIO()
    stderr = io.StringIO()
    outputs = []
    try:
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exec(compile(source, f"<cell {index}>", "exec"), namespace)
    except BaseException as error:
        failed = True
        outputs.append({
            "output_type": "error",
            "ename": type(error).__name__,
            "evalue": str(error),
            "traceback": traceback.format_exc().splitlines(),
        })
    if stdout.getvalue():
        outputs.append({"output_type": "stream", "name": "stdout", "text": stdout.getvalue()})
    if stderr.getvalue():
        outputs.append({"output_type": "stream", "name": "stderr", "text": stderr.getvalue()})
    cell["execution_count"] = index + 1
    cell["outputs"] = outputs

with open("/workspace/result.json", "w", encoding="utf-8") as handle:
    json.dump({"notebook": notebook, "failed": failed}, handle)
'''


def _validate_size(value: Any, label: str) -> None:
    encoded = json.dumps(value, ensure_ascii=False).encode("utf-8")
    if len(encoded) > MAX_INPUT_BYTES:
        raise ValueError(f"{label} exceeds the {MAX_INPUT_BYTES}-byte input limit")


def _run(notebook: dict[str, Any]) -> dict[str, Any]:
    notebook_id = uuid.uuid4().hex

    try:
        client = _get_client()
        sandbox = _get_or_create_sandbox(client, AGENT_ID)
    except (SandboxConfigError, SandboxStateError) as error:
        # Configuration/connectivity problem: fail this call cleanly instead
        # of letting an exception escape and take the worker down with it.
        return {"ok": False, "notebook_id": notebook_id, "error": str(error)}

    # No `finally: sandbox.delete()` here anymore \u2014 this sandbox is the
    # agent's persistent workspace. The lifecycle policy set in
    # _get_or_create_sandbox handles suspending it after idle time and
    # deleting it after a much longer abandonment window; we don't tear it
    # down ourselves after every call.
    try:
        # Re-applying egress rules on a reused sandbox is a no-op in effect
        # (same host, same "Allow" action) even though it repeats work on
        # every call. Wrapped defensively in case the SDK rejects a
        # duplicate rule on a sandbox that already has it.
        for host in ALLOWED_EGRESS_HOSTS:
            try:
                sandbox.add_egress_host_rule(host, action="Allow")
            except Exception:  # noqa: BLE001
                pass
        sandbox.write_file("/workspace/input.ipynb", json.dumps(notebook).encode("utf-8"))
        sandbox.write_file("/workspace/runner.py", _RUNNER.encode("utf-8"))
        command = (
            f"timeout --signal=TERM {EXECUTION_TIMEOUT_SECONDS}s "
            "python3 /workspace/runner.py"
        )
        process = sandbox.exec(command, working_directory="/workspace")
        if process.exit_code != 0:
            return {
                "ok": False,
                "notebook_id": notebook_id,
                "exit_code": process.exit_code,
                "stdout": process.stdout[-MAX_OUTPUT_BYTES:],
                "stderr": process.stderr[-MAX_OUTPUT_BYTES:],
            }
        result = json.loads(sandbox.read_file("/workspace/result.json").decode("utf-8"))
        result["ok"] = not result.pop("failed", False)
        result["notebook_id"] = notebook_id
        encoded = json.dumps(result, ensure_ascii=False)
        if len(encoded.encode("utf-8")) > MAX_OUTPUT_BYTES:
            return {"ok": False, "notebook_id": notebook_id, "error": "Execution output exceeded the output limit"}
        return result
    except Exception as error:  # noqa: BLE001 - surface as a tool error, sandbox stays alive for retry
        logger.exception("Execution failed for agent %s", AGENT_ID)
        return {"ok": False, "notebook_id": notebook_id, "error": str(error)}


@mcp.tool()
async def run_code(code: str) -> str:
    """Run a Python source string in an isolated ACA sandbox."""
    notebook = _notebook_from_input(code, None)
    _validate_size(notebook, "Code")
    # Sandbox calls are blocking; running them on a worker thread keeps the
    # server responsive to other MCP requests while a call is in progress.
    result = await anyio.to_thread.run_sync(_run, notebook)
    return json.dumps(result, ensure_ascii=False)


@mcp.tool()
async def run_notebook(notebook: dict[str, Any]) -> str:
    """Run a Jupyter notebook object in an isolated ACA sandbox."""
    normalized = _notebook_from_input(None, notebook)
    _validate_size(normalized, "Notebook")
    result = await anyio.to_thread.run_sync(_run, normalized)
    return json.dumps(result, ensure_ascii=False)


# Azure Functions Python v2 can expose this ASGI application through a single
# HTTP-triggered function. Keep the import optional so the MCP server remains
# runnable with `python sandbox_mcp_server.py` outside Azure Functions.
try:
    from azure.functions import AsgiMiddleware

    main = AsgiMiddleware(mcp.streamable_http_app()).handle
except ImportError:
    main = None


if __name__ == "__main__":
    mcp.run(transport="streamable-http")