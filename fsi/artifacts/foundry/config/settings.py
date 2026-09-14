"""
FSI IQ DPoC - configuration resolution + .env persistence.
====================================================================

This is the single parameterization seam for the whole deployment. It is written
so that when the PowerShell provisioning script (fsi.ps1) begins to feed values,
nothing structural has to change - only *which key is sourced from where*.

Resolution precedence (highest wins):
    1. process environment   - values the PowerShell exports before invoking python
    2. .env file             - values written locally / persisted by a previous run
    3. built-in defaults      - the current shared environment (inu0zw4)

RESOURCE_SOURCE decides what the deploy script does with resources:
    - "create"  (dev/test): the script provisions the AI Search service itself.
    - "inherit" (Adnan)    : the search service + Foundry project already exist
                             (created by the PowerShell) and are only reused.

persist_env() writes the resolved values back to the active .env so that:
    - the run is reproducible, and
    - values the PowerShell exported into the process are captured to disk
      (this is the ".env gets populated" step in the hand-off).
"""

from __future__ import annotations

import os
from dataclasses import dataclass, fields
from pathlib import Path

try:
    from dotenv import load_dotenv, dotenv_values
except ImportError:  # dotenv is a hard dependency; fail clearly if missing
    raise SystemExit("python-dotenv is required: pip install -r requirements.txt")

# Repo-relative anchors so the script runs from any working directory.
ROOT = Path(__file__).resolve().parent.parent          # .../foundry
AGENTS_DIR = ROOT / "agents"
DATASETS_DIR = ROOT / "datasets"
MANIFEST_PATH = ROOT / "config" / "agents.yaml"


# --------------------------------------------------------------------------- #
# Default environment (the current shared inu0zw4 environment). Every one of
# these is overridable via .env or a process env var of the same name.
# --------------------------------------------------------------------------- #
DEFAULTS: dict[str, str] = {
    "RESOURCE_SOURCE": "create",                 # create | inherit
    "AZURE_SUBSCRIPTION_ID": "2afb8c66-936c-466c-8c6d-c69b42ec2e95",
    "AZURE_RESOURCE_GROUP": "rg-fsi-iq-inu0zw4",
    "AZURE_LOCATION": "eastus2",
    "AZURE_SEARCH_LOCATION": "eastus",
    "AZURE_AI_SERVICES_NAME": "hub-aifoundry-fsi-inu0zw4",
    "AZURE_AI_PROJECT_NAME": "proj-aifoundry-fsi-inu0zw4",
    "AZURE_AI_PROJECT_ENDPOINT":
        "https://hub-aifoundry-fsi-inu0zw4.services.ai.azure.com/api/projects/proj-aifoundry-fsi-inu0zw4",
    "AZURE_AI_SERVICES_ENDPOINT":
        "https://hub-aifoundry-fsi-inu0zw4.services.ai.azure.com",
    "AZURE_AI_SERVICES_KEY": "",
    "AZURE_CHAT_DEPLOYMENT": "gpt-5-4-mini",
    "AZURE_CHAT_MODEL": "gpt-5.4-mini",
    "AZURE_KB_MODEL": "gpt-5-4-mini",
    "AZURE_KB_MODEL_NAME": "gpt-5.4-mini",
    "AZURE_EMBEDDING_DEPLOYMENT": "text-embedding-3-large",
    "CREATE_SEARCH_SERVICE": "true",
    "AZURE_SEARCH_NAME": "srch-fsi-iq-01",
    "AZURE_SEARCH_SKU": "basic",
    "AZURE_SEARCH_ENDPOINT": "",
    # Foundry-layer artifact names (KB kept intact; sources renamed meaningfully)
    "INDEX_NAME": "fsi-customer-documents",
    "CUSTOMER_KS_NAME": "fsi-customer-data",
    "FABRIC_KS_NAME": "fsi-financial-data-agent",
    "KB_NAME": "fsi-knowledge-base",
    "KB_MCP_CONNECTION_NAME": "fsi-kb-mcp-connection",
    # Fabric Data Agent (our FDA for dev/test; Adnan tests his own)
    "FABRIC_WORKSPACE_ID": "ded5294c-c3fe-408c-a3c4-99fd93ffb29f",
    "FABRIC_DATA_AGENT_ID": "febef30c-df4f-42e6-a1f5-2350b5635261",
    "LOG_LEVEL": "INFO",
}


def _val(key: str) -> str:
    """process env  >  .env (already loaded by load_dotenv)  >  default."""
    return (os.getenv(key) or DEFAULTS.get(key, "")).strip().strip('"')


@dataclass
class Settings:
    resource_source: str
    subscription_id: str
    resource_group: str
    location: str
    search_location: str
    ai_services_name: str
    ai_project_name: str
    project_endpoint: str
    ai_services_endpoint: str
    ai_services_key: str | None
    chat_deployment: str
    chat_model: str
    kb_model: str
    kb_model_name: str
    embedding_deployment: str
    create_search_service: bool
    search_name: str
    search_sku: str
    search_endpoint: str | None
    index_name: str
    customer_ks_name: str
    fabric_ks_name: str
    kb_name: str
    kb_mcp_connection_name: str
    fabric_workspace_id: str | None
    fabric_data_agent_id: str | None

    @classmethod
    def resolve(cls, env_file: str | os.PathLike = ROOT / ".env") -> "Settings":
        # Load .env if present (process env still wins - override=False).
        if Path(env_file).exists():
            load_dotenv(env_file, override=False)

        source = _val("RESOURCE_SOURCE").lower() or "create"
        # In inherit mode we never provision the search service ourselves.
        create_search = (
            _val("CREATE_SEARCH_SERVICE").lower() == "true" and source == "create"
        )
        return cls(
            resource_source=source,
            subscription_id=_val("AZURE_SUBSCRIPTION_ID"),
            resource_group=_val("AZURE_RESOURCE_GROUP"),
            location=_val("AZURE_LOCATION"),
            search_location=_val("AZURE_SEARCH_LOCATION") or _val("AZURE_LOCATION"),
            ai_services_name=_val("AZURE_AI_SERVICES_NAME"),
            ai_project_name=_val("AZURE_AI_PROJECT_NAME"),
            project_endpoint=_val("AZURE_AI_PROJECT_ENDPOINT"),
            ai_services_endpoint=_val("AZURE_AI_SERVICES_ENDPOINT"),
            ai_services_key=_val("AZURE_AI_SERVICES_KEY") or None,
            chat_deployment=_val("AZURE_CHAT_DEPLOYMENT"),
            chat_model=_val("AZURE_CHAT_MODEL"),
            kb_model=_val("AZURE_KB_MODEL"),
            kb_model_name=_val("AZURE_KB_MODEL_NAME"),
            embedding_deployment=_val("AZURE_EMBEDDING_DEPLOYMENT"),
            create_search_service=create_search,
            search_name=_val("AZURE_SEARCH_NAME"),
            search_sku=_val("AZURE_SEARCH_SKU"),
            search_endpoint=_val("AZURE_SEARCH_ENDPOINT") or None,
            index_name=_val("INDEX_NAME"),
            customer_ks_name=_val("CUSTOMER_KS_NAME"),
            fabric_ks_name=_val("FABRIC_KS_NAME"),
            kb_name=_val("KB_NAME"),
            kb_mcp_connection_name=_val("KB_MCP_CONNECTION_NAME"),
            fabric_workspace_id=_val("FABRIC_WORKSPACE_ID") or None,
            fabric_data_agent_id=_val("FABRIC_DATA_AGENT_ID") or None,
        )

    # Derived --------------------------------------------------------------- #
    def resolved_search_endpoint(self) -> str:
        return self.search_endpoint or f"https://{self.search_name}.search.windows.net"

    @property
    def fabric_enabled(self) -> bool:
        return bool(self.fabric_workspace_id and self.fabric_data_agent_id)

    # Persistence ----------------------------------------------------------- #
    def persist_env(self, env_file: str | os.PathLike = ROOT / ".env") -> None:
        """Write resolved values back to .env (captures PS-exported values)."""
        # Map dataclass fields back to their env-var keys via DEFAULTS ordering.
        out = {
            "RESOURCE_SOURCE": self.resource_source,
            "AZURE_SUBSCRIPTION_ID": self.subscription_id,
            "AZURE_RESOURCE_GROUP": self.resource_group,
            "AZURE_LOCATION": self.location,
            "AZURE_SEARCH_LOCATION": self.search_location,
            "AZURE_AI_SERVICES_NAME": self.ai_services_name,
            "AZURE_AI_PROJECT_NAME": self.ai_project_name,
            "AZURE_AI_PROJECT_ENDPOINT": self.project_endpoint,
            "AZURE_AI_SERVICES_ENDPOINT": self.ai_services_endpoint,
            "AZURE_AI_SERVICES_KEY": self.ai_services_key or "",
            "AZURE_CHAT_DEPLOYMENT": self.chat_deployment,
            "AZURE_CHAT_MODEL": self.chat_model,
            "AZURE_KB_MODEL": self.kb_model,
            "AZURE_KB_MODEL_NAME": self.kb_model_name,
            "AZURE_EMBEDDING_DEPLOYMENT": self.embedding_deployment,
            "CREATE_SEARCH_SERVICE": str(self.create_search_service).lower(),
            "AZURE_SEARCH_NAME": self.search_name,
            "AZURE_SEARCH_SKU": self.search_sku,
            "AZURE_SEARCH_ENDPOINT": self.resolved_search_endpoint(),
            "INDEX_NAME": self.index_name,
            "CUSTOMER_KS_NAME": self.customer_ks_name,
            "FABRIC_KS_NAME": self.fabric_ks_name,
            "KB_NAME": self.kb_name,
            "KB_MCP_CONNECTION_NAME": self.kb_mcp_connection_name,
            "FABRIC_WORKSPACE_ID": self.fabric_workspace_id or "",
            "FABRIC_DATA_AGENT_ID": self.fabric_data_agent_id or "",
            "LOG_LEVEL": _val("LOG_LEVEL") or "INFO",
        }
        lines = ["# Auto-written by settings.persist_env() - resolved deployment config.\n"]
        for k, v in out.items():
            lines.append(f"{k}={v}\n")
        Path(env_file).write_text("".join(lines))
