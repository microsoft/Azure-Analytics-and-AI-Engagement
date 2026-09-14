#!/usr/bin/env python3
"""
FSI IQ - hosted multi-agent orchestrator  (Foundry Workflows substitute)
========================================================================

Foundry's visual Workflows retire on 2026-12-01; Microsoft's guidance is to move
orchestration to the code-first Agent Framework and run it as a hosted agent.
This file is that substitute: a hosted agent that reproduces the FSI IQ workflow
(Start -> Supervisor -> route to the correct specialist) entirely in code.

How it maps to the retiring workflow:
    Start node            -> the incoming request
    Supervisor-Agent      -> classifies the request (returns one agent name)
    If/Else routing        -> ROUTES table below
    Specialist agents      -> Application-Prioritization / Document-Intelligence /
                              Financial-Resilience-Insight / Task-Prioritization

The five agents themselves are deployed by deploy_foundry_agents.py. Here we build
lightweight Agent Framework wrappers over the SAME instructions + model and host
the orchestrator via ResponsesHostServer (identical hosting pattern to the repo's
existing main.py), so it deploys as a Foundry hosted agent via agent.yaml.

NOTE (wiring pass): the routing logic below is complete and uses the validated
Agent Framework 1.17 API. It should get one live run-through against the Foundry
project before demo (the Work IQ / calendar tool for Task-Prioritization is wired
separately). Run locally first:  python main.py  ->  http://localhost:8088
"""

from __future__ import annotations

import os
from pathlib import Path

import yaml
from dotenv import load_dotenv

from agent_framework import Agent
from agent_framework.foundry import FoundryChatClient
from agent_framework_foundry_hosting import ResponsesHostServer
from azure.identity import DefaultAzureCredential

ROOT = Path(__file__).resolve().parent
MANIFEST = yaml.safe_load((ROOT / "config" / "agents.yaml").read_text())


def _instructions(rel_path: str) -> str:
    return (ROOT / rel_path).read_text().strip()


def _build_agents(client: FoundryChatClient) -> dict[str, Agent]:
    """One Agent Framework Agent per manifest entry, grounded from its .txt file."""
    agents: dict[str, Agent] = {}
    for a in MANIFEST["agents"]:
        agents[a["name"]] = Agent(
            client,
            instructions=_instructions(a["instructions_file"]),
            name=a["name"],
        )
    return agents


class SupervisorOrchestrator:
    """Runs the Supervisor to classify, then delegates to the routed specialist.

    Implements the async run() surface expected by ResponsesHostServer so it can
    be hosted as a single Foundry agent that fans out internally.
    """

    def __init__(self, agents: dict[str, Agent], workflow_cfg: dict):
        self.agents = agents
        self.supervisor = agents[workflow_cfg["orchestrator"]]
        self.specialists = set(workflow_cfg["specialists"])
        self.fallback = workflow_cfg["fallback"]
        self.name = "FSI-IQ-Workflow"

    def _resolve_route(self, label: str) -> str:
        label = (label or "").strip().splitlines()[0].strip() if label else ""
        # Supervisor is instructed to return ONLY the agent name; be tolerant anyway.
        for specialist in self.specialists:
            if specialist.lower() in label.lower():
                return specialist
        return self.fallback

    async def run(self, messages, **kwargs):  # SupportsAgentRun surface
        # 1) classify
        decision = await self.supervisor.run(messages, **kwargs)
        route = self._resolve_route(getattr(decision, "text", "") or str(decision))
        # 2) delegate to the chosen specialist and return its response unchanged
        return await self.agents[route].run(messages, **kwargs)


def build_orchestrator() -> SupervisorOrchestrator:
    load_dotenv()
    client = FoundryChatClient(
        project_endpoint=os.environ.get(
            "AZURE_AI_PROJECT_ENDPOINT",
            "https://hub-aifoundry-fsi-inu0zw4.services.ai.azure.com/api/projects/proj-aifoundry-fsi-inu0zw4",
        ),
        model=os.environ.get("AZURE_CHAT_DEPLOYMENT", "gpt-5-4-mini"),
        credential=DefaultAzureCredential(),
    )
    return SupervisorOrchestrator(_build_agents(client), MANIFEST["workflow"])


def main() -> None:
    orchestrator = build_orchestrator()
    server = ResponsesHostServer(orchestrator)
    server.run()  # hosts on http://localhost:8088 locally; served as a hosted agent in Foundry


if __name__ == "__main__":
    main()
