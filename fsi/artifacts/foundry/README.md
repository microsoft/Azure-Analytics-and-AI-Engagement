# FSI IQ DPoC — Foundry multi-agent deployment

Deploys the five FSI lending agents and their grounding chain into a Microsoft
Foundry project, plus a code-first orchestrator that replaces the retiring
Foundry Workflow. **Everything variable lives in config or `.env` — the two
Python files are the engine, not the data.**

```
foundry/
├── deploy_foundry_agents.py     # ONE deploy script (search → index → 2 KS → KB → MCP → 5 agents)
├── main.py                      # hosted orchestrator (Supervisor → specialist) — workflow substitute
├── agent.yaml                   # hosted-agent manifest for main.py
├── config/
│   ├── agents.yaml              # the manifest: agents, grounding, knowledge sources, routing
│   └── settings.py              # .env resolver/writer + create|inherit mode
├── agents/                      # agent instructions as data (.txt), loaded at runtime
├── datasets/joe/                # Joe's 5 documents (only 3 are indexed — see manifest)
├── .env.sample                  # dev/test profile (this file)
├── .env.adnan.sample            # Adnan integration profile — see README.adnan.md
├── requirements.txt
└── README.md
```

## What gets built

- **One knowledge base** (`fsi-knowledge-base`) with **two sources**:
  - `fsi-customer-data` — Azure AI Search index over Joe's documents.
  - `fsi-financial-data-agent` — the live Fabric Data Agent.
- **Five agents** (from `config/agents.yaml`): Supervisor, Application-Prioritization,
  Document-Intelligence, Financial-Resilience-Insight, Task-Prioritization.
  Only Document-Intelligence and Financial-Resilience get the KB MCP tool; the KB's
  retrieval instructions route each to the correct source.
- **A hosted orchestrator** (`main.py`) that runs the Supervisor to classify each
  request and delegates to the right specialist — the code-first replacement for
  the Foundry Workflow retiring on 2026-12-01.

## Documents indexed (matches the Live Experience script)

All five PDFs are in `datasets/joe/`, but the manifest indexes only three
(`JoeDL.pdf`, `JoePayStub.pdf`, `JoeBankStatement.pdf`). This is deliberate: it
lets Document-Intelligence correctly report **Form 1005** and the **Certificate of
Currency** as *not provided*, and surface the three known issues (DL first-name
only, pay stub older than 60 days, employer mismatch ABC Corp vs Northwest
Creative Media). To index all five, add the two filenames under
`knowledge_sources[customer-data].index_documents` in `config/agents.yaml`.

## Run (dev/test)

```bash
python -m venv .venv && source .venv/bin/activate     # Windows: .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
cp .env.sample .env                                    # optionally paste AI Services key
az login && az account set --subscription <sub-id>

python deploy_foundry_agents.py        # full deploy (persists resolved values to .env)
python deploy_foundry_agents.py --smoke # re-run just the smoke prompts
```

After the search service is (re)created, grant the Foundry project managed
identity **Search Index Data Reader** + **Search Service Contributor** on it
(one-time; propagation 2–5 min), then re-run.

## Run the orchestrator

```bash
python main.py            # hosts on http://localhost:8088
# deploy as a Foundry hosted agent via agent.yaml when ready
```

## Requirements

- Python 3.11, `az login` with Owner (or Contributor + User Access Administrator)
- Foundry project with `gpt-5-4-mini` and `text-embedding-3-large` deployments
- `azure-search-documents==12.1.0b2` (Fabric Data Agent knowledge source kind)

## Runtime notes

- The Fabric Data Agent must be **published** and the KB's identity must have
  access to the Fabric workspace, or the financial-data source returns nothing.
- Task-Prioritization handles calendar intent but real calendar data needs the
  Work IQ / calendar tool wired (separate step).
