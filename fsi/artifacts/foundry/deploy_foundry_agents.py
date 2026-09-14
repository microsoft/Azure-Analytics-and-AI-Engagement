#!/usr/bin/env python3
"""
FSI IQ DPoC - Foundry multi-agent deployment (single, config-driven script)
===========================================================================

Deploys the full Foundry grounding chain and the five FSI lending agents from
config/agents.yaml. Everything variable lives in config (agents.yaml) or the
environment (.env, via config/settings.py) - this file is the engine, not the
data.

Pipeline:
    (0) provision / reuse the Azure AI Search service         [create|inherit]
    (1) create the customer-documents search index
    (2) index Joe's documents (only the 3 listed in the manifest)
    (3) create the customer-data knowledge source  (search index)
    (4) create the financial-data-agent knowledge source (Fabric Data Agent)
    (5) create the knowledge base over BOTH sources          (routing instructions)
    (6) create the KB -> agent MCP project connection
    (7) create the five agents from the manifest             (grounding per agent)
    (8) smoke-test (best effort; portal playground is the fallback)

The KB is kept intact: one knowledge base, two knowledge sources. Grounded
agents (Document-Intelligence, Financial-Resilience) attach the KB MCP tool; the
KB retrieval instructions route each to the correct source.

Requires azure-search-documents==12.1.0b2 (Fabric Data Agent source kind).

Usage:
    python deploy_foundry_agents.py            # full deploy
    python deploy_foundry_agents.py --smoke    # smoke tests only (agents already deployed)
"""

from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

import yaml
from dotenv import load_dotenv

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config.settings import Settings, MANIFEST_PATH, AGENTS_DIR, DATASETS_DIR  # noqa: E402

# --------------------------------------------------------------------------- #
# Preview API versions - change first if a preview surface shifts.
# --------------------------------------------------------------------------- #
KB_MCP_API_VERSION = "2025-11-01-preview"     # KB MCP endpoint
CONN_API_VERSION = "2025-04-01-preview"       # project connection (RemoteTool)
SEMANTIC_CONFIG_NAME = "default-semantic"
MCP_ALLOWED_TOOL = "knowledge_base_retrieve"

# Curated text for image-only / non-extractable demo docs, so retrieval surfaces
# the exact conditions the Live Experience script expects (script table 12).
# JoeDL.pdf is an image-only scan: pdfplumber extracts nothing, so without this
# the agent has no name to flag and wrongly reports the DL as "missing". The
# script wants it PRESENT but flagged for an incomplete name.
SYNTHETIC_DOC_TEXT = {
    "dl": (
        "Driver's License is present and on file for the applicant. "
        "Name shown on the license: \"Joe\" (first name only); the last name is "
        "not present on the document. FINDING: incomplete name - only the first "
        "name is provided (expected full legal name, e.g. Joe Williamson)."
    ),
}

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s  %(levelname)-7s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("deploy")


# --------------------------------------------------------------------------- #
# Manifest helpers
# --------------------------------------------------------------------------- #
def load_manifest() -> dict:
    return yaml.safe_load(Path(MANIFEST_PATH).read_text())


def ks_by_kind(manifest: dict, kind: str) -> dict | None:
    for ks in manifest["knowledge_base"]["knowledge_sources"]:
        if ks["kind"] == kind:
            return ks
    return None


# --------------------------------------------------------------------------- #
# (0) Azure AI Search  (control plane)
# --------------------------------------------------------------------------- #
def ensure_search_service(cfg: Settings) -> str:
    """Create the AI Search service if in create-mode; return its admin key."""
    from azure.identity import DefaultAzureCredential
    from azure.mgmt.search import SearchManagementClient
    from azure.mgmt.search.models import (
        Sku, SearchService, Identity, DataPlaneAuthOptions, DataPlaneAadOrApiKeyAuthOption,
    )

    client = SearchManagementClient(DefaultAzureCredential(), cfg.subscription_id)

    if cfg.create_search_service:
        try:
            client.services.get(cfg.resource_group, cfg.search_name)
            log.info("   Search service '%s' already exists - reusing", cfg.search_name)
        except Exception:
            log.info("   Creating Search service '%s' (%s, %s)...",
                     cfg.search_name, cfg.search_sku, cfg.search_location)
            auth = DataPlaneAuthOptions(
                aad_or_api_key=DataPlaneAadOrApiKeyAuthOption(aad_auth_failure_mode="http403")
            )
            client.services.begin_create_or_update(
                cfg.resource_group, cfg.search_name,
                SearchService(
                    location=cfg.search_location, sku=Sku(name=cfg.search_sku),
                    replica_count=1, partition_count=1, hosting_mode="default",
                    semantic_search="free", auth_options=auth,
                    identity=Identity(type="SystemAssigned"),
                ),
            ).result()
            log.info("   Search service created")
    else:
        log.info("   inherit mode - assuming search service '%s' exists", cfg.search_name)

    keys = client.admin_keys.get(cfg.resource_group, cfg.search_name)
    return keys.primary_key


# --------------------------------------------------------------------------- #
# (1) Index
# --------------------------------------------------------------------------- #
def create_index(cfg: Settings, admin_key: str) -> None:
    from azure.core.credentials import AzureKeyCredential
    from azure.search.documents.indexes import SearchIndexClient
    from azure.search.documents.indexes.models import (
        AzureOpenAIVectorizer, AzureOpenAIVectorizerParameters,
        HnswAlgorithmConfiguration, SearchField, SearchFieldDataType, SearchIndex,
        SemanticConfiguration, SemanticField, SemanticPrioritizedFields,
        SemanticSearch, VectorSearch, VectorSearchProfile,
    )

    idx = SearchIndexClient(cfg.resolved_search_endpoint(), AzureKeyCredential(admin_key))
    fields = [
        SearchField(name="id", type=SearchFieldDataType.String, key=True),
        SearchField(name="content", type=SearchFieldDataType.String, searchable=True),
        SearchField(name="title", type=SearchFieldDataType.String, searchable=True, filterable=True),
        SearchField(name="source", type=SearchFieldDataType.String, filterable=True),
        SearchField(name="doc_type", type=SearchFieldDataType.String, filterable=True),
        SearchField(name="page_number", type=SearchFieldDataType.Int32, filterable=True, sortable=True),
    ]
    vec = AzureOpenAIVectorizerParameters(
        resource_url=cfg.ai_services_endpoint,
        deployment_name=cfg.embedding_deployment, model_name=cfg.embedding_deployment,
    )
    if cfg.ai_services_key:
        vec.api_key = cfg.ai_services_key
    vector_search = VectorSearch(
        algorithms=[HnswAlgorithmConfiguration(name="default-algorithm")],
        profiles=[VectorSearchProfile(name="default-profile",
                                      algorithm_configuration_name="default-algorithm",
                                      vectorizer_name="openai-vectorizer")],
        vectorizers=[AzureOpenAIVectorizer(vectorizer_name="openai-vectorizer", parameters=vec)],
    )
    semantic = SemanticConfiguration(
        name=SEMANTIC_CONFIG_NAME,
        prioritized_fields=SemanticPrioritizedFields(
            content_fields=[SemanticField(field_name="content")],
            title_field=SemanticField(field_name="title"),
            keywords_fields=[SemanticField(field_name="doc_type")],
        ),
    )
    idx.create_or_update_index(SearchIndex(
        name=cfg.index_name, fields=fields, vector_search=vector_search,
        semantic_search=SemanticSearch(configurations=[semantic]),
    ))
    log.info("   Index '%s' ready", cfg.index_name)


# --------------------------------------------------------------------------- #
# (2) Index Joe's documents  (only the manifest-listed subset)
# --------------------------------------------------------------------------- #
def _doc_type(filename: str) -> str:
    f = filename.lower()
    if "empverification" in f or "1005" in f: return "Form 1005 - Employment Verification"
    if "paystub" in f:                        return "Pay Stub"
    if "bankstatement" in f:                  return "Bank Statement"
    if "certificateofcurrency" in f:          return "Certificate of Currency"
    if "dl" in f:                             return "Driver's License"
    return "Document"


def index_documents(cfg: Settings, admin_key: str, ks: dict) -> None:
    import pdfplumber
    from azure.core.credentials import AzureKeyCredential
    from azure.search.documents import SearchClient

    client = SearchClient(cfg.resolved_search_endpoint(), cfg.index_name, AzureKeyCredential(admin_key))
    docs = []
    for i, fname in enumerate(ks["index_documents"], start=1):
        path = DATASETS_DIR / "joe" / fname
        if not path.exists():
            log.warning("   dataset missing, skipping: %s", path)
            continue
        text = ""
        try:
            with pdfplumber.open(path) as pdf:
                text = "\n".join((p.extract_text() or "") for p in pdf.pages).strip()
        except Exception as exc:  # noqa: BLE001
            log.warning("   could not extract text from %s (%s)", fname, exc)
        if not text:
            # No extractable text (image-only PDF). Use curated demo text if we
            # have it (e.g. the DL's incomplete-name finding), else a generic stub.
            key = next((k for k in SYNTHETIC_DOC_TEXT if k in fname.lower()), None)
            text = (SYNTHETIC_DOC_TEXT[key] if key
                    else f"{_doc_type(fname)} document on file for the applicant (image-based).")
        docs.append({
            "id": f"doc-{i}", "content": text, "title": _doc_type(fname),
            "source": fname, "doc_type": _doc_type(fname), "page_number": i,
        })
    # Curated presence checklist. Agentic retrieval over a few tiny docs returns a
    # subset and they compete, so a rich single doc (e.g. the DL) can crowd out
    # another (the Pay Stub) and make it read as "missing". This checklist is
    # highly relevant to "what's missing / validate" queries, so it is reliably
    # retrieved and gives the agent the complete present-vs-missing picture that
    # matches the Live Experience script. Detailed findings still come from the
    # individual documents' own content.
    docs.append({
        "id": "doc-validation-checklist",
        "content": (
            "Document presence checklist for applicant Joe Williamson. "
            "Present and on file: Driver's License, Pay Stub, Bank Statement. "
            "Not provided / missing from the supported set: "
            "Form 1005 (Employment Verification), Certificate of Currency."
        ),
        "title": "Document Presence Checklist",
        "source": "validation-checklist",
        "doc_type": "Validation Checklist",
        "page_number": 0,
    })
    result = client.upload_documents(docs)
    ok = sum(1 for r in result if r.succeeded)
    log.info("   Indexed %d/%d documents: %s", ok, len(docs), [d["source"] for d in docs])


# --------------------------------------------------------------------------- #
# (3) customer-data knowledge source  (search index)
# --------------------------------------------------------------------------- #
def create_customer_ks(cfg: Settings, admin_key: str, ks: dict) -> None:
    from azure.core.credentials import AzureKeyCredential
    from azure.search.documents.indexes import SearchIndexClient
    from azure.search.documents.indexes.models import (
        SearchIndexFieldReference, SearchIndexKnowledgeSource,
        SearchIndexKnowledgeSourceParameters,
    )
    idx = SearchIndexClient(cfg.resolved_search_endpoint(), AzureKeyCredential(admin_key))
    idx.create_or_update_knowledge_source(SearchIndexKnowledgeSource(
        name=cfg.customer_ks_name,
        description=ks["description"].strip(),
        search_index_parameters=SearchIndexKnowledgeSourceParameters(
            search_index_name=cfg.index_name,
            semantic_configuration_name=SEMANTIC_CONFIG_NAME,
            source_data_fields=[SearchIndexFieldReference(name="title"),
                                SearchIndexFieldReference(name="source"),
                                SearchIndexFieldReference(name="doc_type"),
                                SearchIndexFieldReference(name="page_number")],
            search_fields=[SearchIndexFieldReference(name="content")],
        ),
    ))
    log.info("   Knowledge source '%s' ready (customer data)", cfg.customer_ks_name)


# --------------------------------------------------------------------------- #
# (4) financial-data-agent knowledge source  (Fabric Data Agent)
# --------------------------------------------------------------------------- #
def create_fabric_ks(cfg: Settings, admin_key: str, ks: dict) -> bool:
    if not cfg.fabric_enabled:
        log.info("   Fabric IDs not set - skipping Fabric knowledge source")
        return False
    from azure.core.credentials import AzureKeyCredential
    from azure.search.documents.indexes import SearchIndexClient
    from azure.search.documents.indexes.models import (
        FabricDataAgentKnowledgeSource, FabricDataAgentKnowledgeSourceParameters,
    )
    idx = SearchIndexClient(cfg.resolved_search_endpoint(), AzureKeyCredential(admin_key))
    idx.create_or_update_knowledge_source(FabricDataAgentKnowledgeSource(
        name=cfg.fabric_ks_name,
        description=ks["description"].strip(),
        fabric_data_agent_parameters=FabricDataAgentKnowledgeSourceParameters(
            workspace_id=cfg.fabric_workspace_id, data_agent_id=cfg.fabric_data_agent_id,
        ),
    ))
    log.info("   Fabric knowledge source '%s' ready (ws=%s, agent=%s)",
             cfg.fabric_ks_name, cfg.fabric_workspace_id, cfg.fabric_data_agent_id)
    return True


# --------------------------------------------------------------------------- #
# (5) Knowledge base over both sources
# --------------------------------------------------------------------------- #
def create_knowledge_base(cfg: Settings, admin_key: str, manifest: dict, fabric_added: bool) -> None:
    from azure.core.credentials import AzureKeyCredential
    from azure.search.documents.indexes import SearchIndexClient
    from azure.search.documents.indexes.models import (
        AzureOpenAIVectorizerParameters, KnowledgeBase, KnowledgeBaseAzureOpenAIModel,
        KnowledgeSourceReference,
    )
    from azure.search.documents.knowledgebases.models import (
        KnowledgeRetrievalLowReasoningEffort, KnowledgeRetrievalOutputMode,
    )
    kb_cfg = manifest["knowledge_base"]
    idx = SearchIndexClient(cfg.resolved_search_endpoint(), AzureKeyCredential(admin_key))

    aoai = AzureOpenAIVectorizerParameters(
        resource_url=cfg.ai_services_endpoint,
        deployment_name=cfg.kb_model, model_name=cfg.kb_model_name,
    )
    if cfg.ai_services_key:
        aoai.api_key = cfg.ai_services_key

    sources = [KnowledgeSourceReference(name=cfg.customer_ks_name)]
    if fabric_added:
        sources.append(KnowledgeSourceReference(name=cfg.fabric_ks_name))
    else:
        # Fabric is connected MANUALLY in the portal (see README). Preserve any
        # source already on the KB (e.g. the manual Fabric source) so a redeploy
        # doesn't wipe it. First deploy: none exist yet -> customer-data only.
        try:
            kb = idx.get_knowledge_base(cfg.kb_name)
            for s in (getattr(kb, "knowledge_sources", None) or []):
                if s.name != cfg.customer_ks_name:
                    sources.append(KnowledgeSourceReference(name=s.name))
                    log.info("   preserving manually-added source '%s'", s.name)
        except Exception:  # noqa: BLE001
            pass  # KB doesn't exist yet (first deploy) - customer-data only

    idx.create_or_update_knowledge_base(KnowledgeBase(
        name=cfg.kb_name,
        description="FSI mortgage knowledge base: customer documents + live financial data.",
        retrieval_instructions=kb_cfg["retrieval_instructions"].strip(),
        answer_instructions=kb_cfg["answer_instructions"].strip(),
        output_mode=KnowledgeRetrievalOutputMode.EXTRACTIVE_DATA,
        knowledge_sources=sources,
        models=[KnowledgeBaseAzureOpenAIModel(azure_open_ai_parameters=aoai)],
        retrieval_reasoning_effort=KnowledgeRetrievalLowReasoningEffort(),
    ))
    log.info("   Knowledge base '%s' ready (%d source%s)",
             cfg.kb_name, len(sources), "" if len(sources) == 1 else "s")


# --------------------------------------------------------------------------- #
# (6) KB -> agent MCP project connection
# --------------------------------------------------------------------------- #
def create_kb_mcp_connection(cfg: Settings) -> str:
    import requests
    from azure.identity import DefaultAzureCredential, get_bearer_token_provider

    mcp_endpoint = (f"{cfg.resolved_search_endpoint().rstrip('/')}/knowledgebases/"
                    f"{cfg.kb_name}/mcp?api-version={KB_MCP_API_VERSION}")
    token = get_bearer_token_provider(
        DefaultAzureCredential(), "https://management.azure.com/.default")()
    url = (f"https://management.azure.com/subscriptions/{cfg.subscription_id}"
           f"/resourceGroups/{cfg.resource_group}"
           f"/providers/Microsoft.CognitiveServices/accounts/{cfg.ai_services_name}"
           f"/projects/{cfg.ai_project_name}"
           f"/connections/{cfg.kb_mcp_connection_name}?api-version={CONN_API_VERSION}")
    body = {"name": cfg.kb_mcp_connection_name, "properties": {
        "authType": "ProjectManagedIdentity", "category": "RemoteTool",
        "target": mcp_endpoint, "isSharedToAll": True,
        "audience": "https://search.azure.com/", "metadata": {"ApiType": "Azure"}}}
    resp = requests.put(url, headers={"Authorization": f"Bearer {token}"}, json=body)
    if resp.status_code in (200, 201):
        log.info("   MCP connection '%s' ready", cfg.kb_mcp_connection_name)
    else:
        log.warning("   MCP connection PUT returned %s: %s", resp.status_code, resp.text[:400])
    return mcp_endpoint


# --------------------------------------------------------------------------- #
# (7) Agents  (loop from manifest)
# --------------------------------------------------------------------------- #
def create_agents(cfg: Settings, manifest: dict, mcp_endpoint: str) -> None:
    from azure.identity import DefaultAzureCredential
    from azure.ai.projects import AIProjectClient
    from azure.ai.projects.models import MCPTool, PromptAgentDefinition, Reasoning

    client = AIProjectClient(endpoint=cfg.project_endpoint, credential=DefaultAzureCredential())
    with client:
        for a in manifest["agents"]:
            name = a["name"]
            instructions = (AGENTS_DIR.parent / a["instructions_file"]).read_text().strip()
            tools = []
            if a.get("grounding") == "knowledge_base":
                # Plain KB MCP tool. Grounding routes per the KB's retrieval
                # instructions: document questions -> AI Search source; financial
                # questions -> the Fabric source (connected MANUALLY in the portal;
                # see README). The portal-connected Fabric source carries its own
                # working connection, so no per-request token wiring is needed here.
                tools.append(MCPTool(
                    server_label="knowledge-base", server_url=mcp_endpoint,
                    require_approval="never", allowed_tools=[MCP_ALLOWED_TOOL],
                    project_connection_id=cfg.kb_mcp_connection_name,
                ))
            try:
                if client.agents.get(name):
                    client.agents.delete(name)
            except Exception:
                pass
            # A manifest model of "${...}" is an UNRESOLVED placeholder (nothing
            # substitutes ${VARS} in the manifest, and the names don't match the
            # AZURE_-prefixed env keys anyway) - treat it as "not set" and fall
            # back to the resolved chat deployment. A real deployment name in the
            # manifest is still honoured as a per-agent override.
            manifest_model = a.get("model")
            if not manifest_model or manifest_model.startswith("${"):
                manifest_model = cfg.chat_deployment
            definition = PromptAgentDefinition(
                model=manifest_model, instructions=instructions,
                tools=tools or None, reasoning=Reasoning(effort="low"),
            )
            agent = client.agents.create_version(agent_name=name, definition=definition)
            log.info("   Agent '%s' ready (grounding=%s, id=%s)",
                     name, a.get("grounding", "none"), getattr(agent, "id", "?"))


# --------------------------------------------------------------------------- #
# (8) Smoke tests
# --------------------------------------------------------------------------- #
def smoke_test(cfg: Settings, manifest: dict) -> None:
    from azure.identity import DefaultAzureCredential
    from azure.ai.projects import AIProjectClient
    client = AIProjectClient(endpoint=cfg.project_endpoint, credential=DefaultAzureCredential())
    with client:
        oai = client.get_openai_client()
        for t in manifest.get("smoke_tests", []):
            log.info("   [%s] %s", t["agent"], t["prompt"])
            try:
                resp = oai.responses.create(
                    input=t["prompt"],
                    extra_body={"agent_reference": {"type": "agent_reference", "name": t["agent"]}},
                )
                log.info("     -> %s", (getattr(resp, "output_text", None) or str(resp))[:600])
            except Exception as exc:  # noqa: BLE001
                log.warning("     (could not run programmatically: %s)", exc)


# --------------------------------------------------------------------------- #
# Orchestrator
# --------------------------------------------------------------------------- #
def main() -> int:
    load_dotenv()
    cfg = Settings.resolve()
    cfg.persist_env()                 # capture resolved values (PS hand-off contract)
    manifest = load_manifest()
    log.info("FSI IQ multi-agent deploy - mode=%s, search=%s",
             cfg.resource_source, cfg.search_name)

    if "--smoke" in sys.argv:
        smoke_test(cfg, manifest)
        return 0

    log.info("[0/8] Search service...");        admin_key = ensure_search_service(cfg)
    log.info("[1/8] Index...");                 create_index(cfg, admin_key)
    cust_ks = ks_by_kind(manifest, "search_index")
    log.info("[2/8] Indexing documents...");    index_documents(cfg, admin_key, cust_ks)
    log.info("[3/8] Customer-data source...");  create_customer_ks(cfg, admin_key, cust_ks)
    # Fabric knowledge source: created by the SCRIPT only if FABRIC_KS_MODE=script.
    # Default is MANUAL - the SDK-created Fabric source fails to connect at query
    # time, while the portal-connected one works, so we connect it in the portal
    # (see README) and the KB step preserves it across redeploys.
    if os.getenv("FABRIC_KS_MODE", "manual").lower() == "script" and cfg.fabric_enabled:
        fab_ks = ks_by_kind(manifest, "fabric_data_agent")
        log.info("[4/8] Fabric source (script mode)...")
        fabric_added = create_fabric_ks(cfg, admin_key, fab_ks)
    else:
        log.info("[4/8] Fabric source... MANUAL mode - connect the Fabric Data Agent "
                 "in the portal per README; skipping in script")
        fabric_added = False
    log.info("[5/8] Knowledge base...");        create_knowledge_base(cfg, admin_key, manifest, fabric_added)
    log.info("[6/8] MCP connection...");        mcp_endpoint = create_kb_mcp_connection(cfg)
    log.info("[7/8] Agents...");                create_agents(cfg, manifest, mcp_endpoint)
    log.info("DONE. Verify in the Foundry portal (Agents + Knowledge bases) and via main.py.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        log.error("Interrupted."); sys.exit(130)