"""
ACA DPoC - configuration resolution.

Resolution precedence (highest wins):
    1. process environment - values exported before invoking python
    2. .env file           - written by acaSetup.ps1 from .env.sample

There are no built-in environment defaults: a missing required value stops the
run with a clear message instead of silently deploying into the wrong project.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover
    raise SystemExit("python-dotenv is required: pip install -r requirements.txt")

ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = ROOT / "config" / "agent.yaml"

REQUIRED = (
    "AZURE_SUBSCRIPTION_ID",
    "AZURE_RESOURCE_GROUP",
    "AZURE_AI_SERVICES_NAME",
    "AZURE_AI_PROJECT_NAME",
    "AZURE_AI_PROJECT_ENDPOINT",
    "AZURE_CHAT_DEPLOYMENT",
    "FUNCTION_APP_NAME",
)

PLACEHOLDER_MARK = "###"


def _val(key: str, default: str = "") -> str:
    return (os.getenv(key) or default).strip().strip('"')


@dataclass(frozen=True)
class Settings:
    subscription_id: str
    resource_group: str
    ai_services_name: str
    ai_project_name: str
    project_endpoint: str
    chat_deployment: str
    function_app_name: str
    gateway_mode: str          # apim | direct
    apim_name: str
    apim_wait_minutes: int
    appinsights_name: str      # optional; enables Foundry Traces

    @classmethod
    def resolve(cls, env_file: str | os.PathLike = ROOT / ".env") -> "Settings":
        if Path(env_file).exists():
            load_dotenv(env_file, override=False)

        missing = [k for k in REQUIRED if not _val(k)]
        unresolved = [k for k in REQUIRED if PLACEHOLDER_MARK in _val(k)]
        mode = _val("MCP_GATEWAY_MODE", "apim").lower()
        if mode not in ("apim", "direct"):
            raise SystemExit(f"MCP_GATEWAY_MODE must be 'apim' or 'direct', got '{mode}'")
        if mode == "apim":
            if not _val("APIM_NAME"):
                missing.append("APIM_NAME")
            elif PLACEHOLDER_MARK in _val("APIM_NAME"):
                unresolved.append("APIM_NAME")
        if missing or unresolved:
            raise SystemExit(
                "Configuration incomplete.\n"
                f"  Missing: {', '.join(missing) or '-'}\n"
                f"  Unreplaced ###TOKENS###: {', '.join(unresolved) or '-'}\n"
                "Populate .env (copy .env.sample) or export the values before running."
            )

        return cls(
            subscription_id=_val("AZURE_SUBSCRIPTION_ID"),
            resource_group=_val("AZURE_RESOURCE_GROUP"),
            ai_services_name=_val("AZURE_AI_SERVICES_NAME"),
            ai_project_name=_val("AZURE_AI_PROJECT_NAME"),
            project_endpoint=_val("AZURE_AI_PROJECT_ENDPOINT").rstrip("/"),
            chat_deployment=_val("AZURE_CHAT_DEPLOYMENT"),
            function_app_name=_val("FUNCTION_APP_NAME"),
            gateway_mode=mode,
            apim_name=_val("APIM_NAME"),
            apim_wait_minutes=int(_val("APIM_WAIT_MINUTES", "60")),
            appinsights_name="" if PLACEHOLDER_MARK in _val("APPINSIGHTS_NAME") else _val("APPINSIGHTS_NAME"),
        )

    # ARM resource ids ------------------------------------------------------ #
    @property
    def rg_id(self) -> str:
        return f"/subscriptions/{self.subscription_id}/resourceGroups/{self.resource_group}"

    @property
    def function_app_id(self) -> str:
        return f"{self.rg_id}/providers/Microsoft.Web/sites/{self.function_app_name}"

    @property
    def apim_id(self) -> str:
        return f"{self.rg_id}/providers/Microsoft.ApiManagement/service/{self.apim_name}"

    @property
    def appinsights_id(self) -> str:
        return f"{self.rg_id}/providers/Microsoft.Insights/components/{self.appinsights_name}"

    @property
    def project_id(self) -> str:
        return (f"{self.rg_id}/providers/Microsoft.CognitiveServices/accounts/"
                f"{self.ai_services_name}/projects/{self.ai_project_name}")