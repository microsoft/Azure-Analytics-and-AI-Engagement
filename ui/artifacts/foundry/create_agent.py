#!/usr/bin/env python3
"""
Foundry deployment for the supply chain intelligence agent.

  [1/4] Upload the knowledge docs (knowledge/*.docx) to blob storage
  [2/4] Foundry IQ: blob knowledge source + knowledge base (Azure AI Search)
  [3/4] Project connection to the knowledge base MCP endpoint
  [4/4] Prompt agent with the Foundry IQ tool + Work IQ tool
  
"""
import logging
import os
import sys
from pathlib import Path

import requests
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / ".env")

logging.basicConfig(level="INFO", format="%(asctime)s  %(levelname)-7s  %(message)s", datefmt="%H:%M:%S")
for n in ("azure", "urllib3", "httpx"):
    logging.getLogger(n).setLevel(logging.WARNING)
log = logging.getLogger("deploy")

E = os.environ
PROJECT_RESOURCE_ID = E["PROJECT_RESOURCE_ID"]
PROJECT_ENDPOINT = E["PROJECT_ENDPOINT"]
SEARCH_ENDPOINT = E["SEARCH_ENDPOINT"].rstrip("/")
KB_NAME = E["KB_NAME"]
KB_CONNECTION_NAME = E["KB_CONNECTION_NAME"]
WORK_IQ_CONNECTION_NAME = E.get("WORK_IQ_CONNECTION_NAME", "").strip()
CHAT_DEPLOYMENT = E["CHAT_DEPLOYMENT"]
AGENT_NAME = E["AGENT_NAME"]
STORAGE_RESOURCE_ID = E["STORAGE_RESOURCE_ID"]
BLOB_CONTAINER = E["BLOB_CONTAINER"]
AOAI_ENDPOINT = E["AOAI_ENDPOINT"]
EMBED_DEPLOYMENT = E["EMBED_DEPLOYMENT"]
KS_NAME = E["KS_NAME"]

# Preview versions change often - check the Foundry IQ connect doc if these fail
KB_MCP_API = "2026-08-01-preview"
CONN_API = "2025-10-01-preview"
MCP_ENDPOINT = f"{SEARCH_ENDPOINT}/knowledgebases/{KB_NAME}/mcp?api-version={KB_MCP_API}"


# [1/4] Upload docs to blob
def upload_docs(credential) -> None:
    from azure.storage.blob import BlobServiceClient

    account = STORAGE_RESOURCE_ID.rstrip("/").split("/")[-1]
    svc = BlobServiceClient(f"https://{account}.blob.core.windows.net", credential=credential)
    container = svc.get_container_client(BLOB_CONTAINER)
    if not container.exists():
        container.create_container()
    files = sorted((ROOT / "knowledge").glob("*.docx"))
    if not files:
        raise RuntimeError("No .docx files found in knowledge/")
    for p in files:
        with open(p, "rb") as fh:
            container.upload_blob(name=p.name, data=fh, overwrite=True)
    log.info("   uploaded %d docs to '%s/%s'", len(files), account, BLOB_CONTAINER)


# [2/4] Foundry IQ: knowledge source + knowledge base
def create_knowledge_base(credential) -> None:
    from azure.search.documents.indexes import SearchIndexClient
    from azure.search.documents.indexes.models import (
        AzureBlobKnowledgeSource, AzureBlobKnowledgeSourceParameters,
        AzureOpenAIVectorizerParameters, KnowledgeBase,
        KnowledgeBaseAzureOpenAIModel, KnowledgeSourceContentExtractionMode,
        KnowledgeSourceReference,
    )
    from azure.search.documents.knowledgebases.models import (
        KnowledgeSourceAzureOpenAIVectorizer, KnowledgeSourceIngestionParameters,
    )

    client = SearchIndexClient(endpoint=SEARCH_ENDPOINT, credential=credential)

    def aoai(dep):
        return AzureOpenAIVectorizerParameters(resource_url=AOAI_ENDPOINT, deployment_name=dep, model_name=dep)

    ks = AzureBlobKnowledgeSource(
        name=KS_NAME,
        description="Supply chain SOPs and guidance docs",
        azure_blob_parameters=AzureBlobKnowledgeSourceParameters(
            connection_string=f"ResourceId={STORAGE_RESOURCE_ID};",  # identity-based, no key
            container_name=BLOB_CONTAINER,
            ingestion_parameters=KnowledgeSourceIngestionParameters(
                embedding_model=KnowledgeSourceAzureOpenAIVectorizer(
                    azure_open_ai_parameters=aoai(EMBED_DEPLOYMENT)),
                chat_completion_model=KnowledgeBaseAzureOpenAIModel(
                    azure_open_ai_parameters=aoai(CHAT_DEPLOYMENT)),
                content_extraction_mode=KnowledgeSourceContentExtractionMode.MINIMAL,
            ),
        ),
    )
    client.create_or_update_knowledge_source(knowledge_source=ks)
    log.info("   knowledge source '%s' ready (indexing continues in the background)", KS_NAME)

    kb = KnowledgeBase(
        name=KB_NAME,
        knowledge_sources=[KnowledgeSourceReference(name=KS_NAME)],
        models=[KnowledgeBaseAzureOpenAIModel(azure_open_ai_parameters=aoai(CHAT_DEPLOYMENT))],
    )
    client.create_or_update_knowledge_base(kb)
    log.info("   knowledge base '%s' ready", KB_NAME)


# [3/4] Project connection (RemoteTool, project managed identity)
def create_kb_connection(credential) -> None:
    token = get_bearer_token_provider(credential, "https://management.azure.com/.default")()
    resp = requests.put(
        f"https://management.azure.com{PROJECT_RESOURCE_ID}/connections/{KB_CONNECTION_NAME}"
        f"?api-version={CONN_API}",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "name": KB_CONNECTION_NAME,
            "type": "Microsoft.MachineLearningServices/workspaces/connections",
            "properties": {
                "authType": "ProjectManagedIdentity",
                "category": "RemoteTool",
                "target": MCP_ENDPOINT,
                "isSharedToAll": True,
                "audience": "https://search.azure.com/",
                "metadata": {"ApiType": "Azure"},
            },
        },
        timeout=120,
    )
    resp.raise_for_status()
    log.info("   connection '%s' ready", KB_CONNECTION_NAME)


# [4/4] Agent
def create_agent(project) -> None:
    from azure.ai.projects.models import MCPTool, PromptAgentDefinition, WorkIQPreviewTool

    instructions = (ROOT / "instructions" / "supply_chain_agent.md").read_text(encoding="utf-8").strip()
    kb_tool = MCPTool(
        server_label="knowledge-base",
        server_url=MCP_ENDPOINT,
        require_approval="never",
        allowed_tools=["knowledge_base_retrieve"],
        project_connection_id=KB_CONNECTION_NAME,
    )
    tools = [kb_tool]
    if WORK_IQ_CONNECTION_NAME:
        tools.append(WorkIQPreviewTool(project_connection_id=WORK_IQ_CONNECTION_NAME))
    else:
        log.info("   WORK_IQ_CONNECTION_NAME not set - creating the agent without Work IQ")
    agent = project.agents.create_version(
        agent_name=AGENT_NAME,
        definition=PromptAgentDefinition(model=CHAT_DEPLOYMENT, instructions=instructions, tools=tools),
    )
    log.info("   agent '%s' version %s ready", agent.name, agent.version)


def main() -> int:
    from azure.ai.projects import AIProjectClient

    credential = DefaultAzureCredential()
    log.info("[1/4] Upload docs...")
    upload_docs(credential)
    log.info("[2/4] Foundry IQ knowledge base...")
    create_knowledge_base(credential)
    log.info("[3/4] Foundry IQ connection...")
    create_kb_connection(credential)
    with AIProjectClient(endpoint=PROJECT_ENDPOINT, credential=credential) as project:
        log.info("[4/4] Agent...")
        create_agent(project)
    log.info("DONE. Verify in the Foundry portal (Agents > %s).", AGENT_NAME)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as err:  # noqa: BLE001
        log.error("%s", err)
        sys.exit(1)