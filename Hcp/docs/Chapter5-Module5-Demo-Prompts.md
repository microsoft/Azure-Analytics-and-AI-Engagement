# Module 5 Demo Prompts

This script is optimized for recording a live Copilot demo where you type a short, generic prompt and Copilot expands it into complete implementation guidance.

## Voice-Over Lock (Do Not Edit)

- All `Voice-over line` sections below are locked and must remain verbatim.
- Do not paraphrase, shorten, or correct grammar/wording in voice-over text.
- You may adjust only prompts and on-screen actions, not narration.

Use each timestamp block as a scene card:
- Type the short prompt first (what Lydia types on screen).
- Then use the expanded prompt (what Copilot should execute in detail).
- Follow the on-screen actions and voice line so the story stays synchronized.

## Demo Goal

Build and ship AI-ready modern databases in one workflow:
- Structured clinical data + vector embeddings in Azure HorizonDB (PostgreSQL compatible)
- Unstructured chat memory + profile data in Azure Cosmos DB
- Foundry SDK + Redis for intelligence and short-term memory
- Infrastructure as code with Bicep
- One PR and one GitHub Actions deployment path to AKS Automatic with governance

## Scene Cards (Timestamped)

## [0:00-0:25] OPEN - One Workspace, One Lifecycle

### Short prompt to type
"Map this flow: clinician-ready data, AI memory, and one workspace pipeline."

### Expanded prompt for Copilot
"Create an execution checklist for this repository that covers: data modeling, database selection, Bicep updates, Foundry + Redis integration, schema validation, commit packaging, and pipeline deployment. Keep all actions inside this workspace and map each action to the files I should open during recording."

### On-screen task
- Open the repository root and show API, web, infra, and workflow folders.
- Keep VS Code explorer, editor, and Source Control visible.

### Voice-over line
"OPEN Caldova's new prescriber portal is built and running - but it's a front door with nothing behind it yet. To answer a clinician, it needs data of its own: structured clinical records, the embeddings the AI reasons over, and the memory to hold a conversation. Working directly in VS Code, Lydia will model the data, write the IaC (infrastructure-as-code) instructions, connect an AI layer, and ship alongside the app. One workspace, one lifecycle, one pipeline."

### Evidence to show
- API projects under HcpPortalApi
- Infrastructure templates in infra/bicep
- Workflow under .github/workflows

---

## [0:25-1:10] CHOOSE THE RIGHT DATABASES

### Short prompt to type
"Recommend database split for clinical records + embeddings vs chat history + agent memory."

### Expanded prompt for Copilot
"Given this healthcare prescriber portal architecture, recommend the best data split between Azure HorizonDB and Azure Cosmos DB. Include which entities go to each database, how vector embeddings are stored with clinical records, and why Cosmos DB is better for chat history, user profiles, and long-term agent memory. Then generate starter schema definitions and validation queries for both stores."

### On-screen task
- Open domain/entity and persistence files.
- Show schema notes or SQL scripts as Copilot proposes them.

### Voice-over line
"The app has two kinds of data with very different requirements. The first is the clinical data, drug information, and AI vector embeddings - structured data that needs to stay together. The second is the chat history, user profiles, and agent memory - unstructured data that is fast-moving and delivered to users in real-time. Lydia asks Copilot for a recommendation. The structured data goes to Azure HorizonDB - a highly-scalable Postgres-compatible database built for mission-critical workloads. It keeps records and vector embeddings in one engine, with nothing to sync. The unstructured data goes to Azure Cosmos DB - built for speed, performance, and scalablityscalability; and the database that powers ChatGPT. Lydia models both databases and validates the schema - all within the editor."

### Must-mention points
- One engine for relational + vector search in HorizonDB
- Cosmos DB for real-time, high-throughput unstructured memory
- Validate schema in editor before deployment

---

## [1:10-1:50] TURN MODEL INTO INFRASTRUCTURE (BICEP)

### Short prompt to type
"Update Bicep for HorizonDB and Cosmos DB with Entra ID, regions, capacity, and network access."

### Expanded prompt for Copilot
"Update the existing Bicep templates in this repo to provision Azure HorizonDB (PostgreSQL compatible) and Azure Cosmos DB. Include region configuration, capacity/performance settings, Entra ID authentication, network access controls, and outputs needed by app services. Keep changes modular and aligned with existing infra/bicep structure and deployment pipeline conventions."

### On-screen task
- Open infra/bicep/main.bicep and related module files.
- Show additions for database resources and parameters.

### Voice-over line
"She turns the local model into cloud infrastructure with a prompt: \"update my Bicep to support the PostgreSQL and Azure Cosmos DB resources this app needs.\" GitHub Copilot extends the existing Bicep - adding Azure HorizonDB and Azure Cosmos DB, configuring regions, provisioning capacity and setting up Entra ID authentication and network access. The data layer is now infrastructure-as-code, and database changes deploy through the same pipeline as the app."

### Must-mention points
- IaC as source of truth
- No portal-only manual setup
- App + data deploy together

---

## [1:50-2:40] WIRE IN INTELLIGENCE (FOUNDRY + REDIS)

### Short prompt to type
"Wire Foundry embeddings, Redis short-term memory, and Cosmos long-term memory into the microservice."

### Expanded prompt for Copilot
"Add Microsoft Foundry SDK integration and Azure Managed Redis caching to the microservice codebase. Implement embedding generation and persistence to HorizonDB vectors, retrieval flow that combines vector + relational query, short-term response cache in Redis, and long-term conversation memory in Cosmos DB. Use managed identity and app configuration patterns already present in the repo."

### On-screen task
- Open service layer and dependency injection code.
- Show where Foundry client, Redis cache, and Cosmos memory providers are registered.

### Voice-over line
"With the databases defined as code, Lydia is ready to add intelligence in. She prompts Copilot to wire the Microsoft Foundry SDK and an Azure Managed Redis cache into the microservice, and the integration code drops into the project. Foundry's models generate the embeddings and write them into HorizonDB, so vector search runs alongside relational queries - one engine, one query, nothing moving between systems. Redis serves as short-term memory, caching recent model responses so repeated questions don't re-run the model - keeping responses fast and token cost down. Azure Cosmos DB holds the agent memory long-term; carrying chat history and context across every interaction. The app has gone from storing data to reasoning over it, with every answer grounded in ABC PharmaCaldova's own records."

### Must-mention points
- Ground answers on organizational data
- Reduce repeat model cost with Redis
- Preserve multi-turn continuity in Cosmos

---

## [2:40-3:05] COMMIT - ONE PULL REQUEST

### Short prompt to type
"Prepare one PR for schema migrations, Bicep updates, Foundry + Redis wiring, and app code."

### Expanded prompt for Copilot
"Review all staged changes and produce a single cohesive commit plan that includes schema updates, Bicep resource changes, Foundry integration, Redis integration, and app configuration updates. Provide a concise commit message and PR description that explains business impact and deployment flow."

### On-screen task
- Open Source Control and scroll changed files.
- Show one unified diff scope.

### Voice-over line
"Lydia reviews the whole change in VS Code's Source Control: the schema migrations, the Bicep updates, the Foundry and Redis wiring, and the app code - all in one workspace, one diff. She commits and pushes. One pull request ships the entire data layer with the application."

### Must-mention points
- Unified change package
- App + infra + data in same PR
- Reviewer-friendly scope and message

---

## [3:05-3:40] PIPELINE DOES THE REST

### Short prompt to type
"Deploy app, HorizonDB, Cosmos DB, and Redis from the same GitHub Action to AKS Automatic."

### Expanded prompt for Copilot
"Update or validate the GitHub Actions workflow so the same pipeline provisions HorizonDB, Cosmos DB, and Redis from Bicep, applies schema migrations, and deploys app updates to AKS Automatic. Include environment gating and post-deploy verification checks."

### On-screen task
- Open .github/workflows workflow file.
- Show deploy stages and success run.

### Voice-over line
"The push triggers the same GitHub Action that deploys the app. It provisions Azure HorizonDB, Azure Cosmos DB, and Redis from the Bicep, applies the schema migrations, and deploys the updated app to AKS Automatic - onto the landing zone the architect stood up, reusing the same Key Vault pattern from the app modernization and the build. The governance a regulated environment demands is applied at deploy time: row-level security, encryption, Microsoft Purview classification, audit logs flowing to Log Analytics, and managed-identity binding through Key Vault - with no secrets in the code. Lydia never opened the Azure portal. The databases shipped as code, exactly like the app."

### Must-mention points
- AKS Automatic target
- Governance controls applied in pipeline
- Key Vault + managed identity pattern

---

## [3:40-3:55] ENDING

### Short prompt to type
"Write a one-line close: modeled locally, declared as code, governed at deploy, shipped in one PR."

### Expanded prompt for Copilot
"Generate a closing summary that emphasizes: modeled locally, declared as code, governed at deploy, and shipped in one PR; plus AI answers grounded in Caldova data through Foundry, HorizonDB vectors, and Cosmos memory."

### Voice-over line
"Modeled locally, declared as code, governed at deploy, shipped in one pull request. Through the Foundry layer, the portal reasons over ABC PharmaCaldova's own data and gives a prescriber a sourced answer in the moment."

---

## BRIDGE (Use only if transitioning to next module)

### Short prompt to type
"Create a bridge to operations: security, resilience, and run-state."

### Voice-over line
"Now everything is running - the modernized apps, the migrated data, the new portal, the new databases. The build is done. What's left is the job that never ends: keeping all of it running, secure, and resilient, through the most important launch window of the year."

---

## Fast Recording Checklist

- Keep one VS Code window only; avoid context switching to portal tabs unless needed.
- Show actual files before narration references them.
- Keep Copilot chat history visible when feasible to reinforce one lifecycle flow.
- Pause 1-2 seconds between scenes to make cuts easy.
- Keep naming consistent: Caldova, HorizonDB, Cosmos DB, Foundry, Redis, AKS Automatic.

## Optional: Ultra-Short Prompt Set (for live pace)

1. "Recommend database split for portal data and memory."
2. "Generate starter schema for HorizonDB and Cosmos DB."
3. "Update Bicep for HorizonDB, Cosmos, Entra ID, networking."
4. "Wire Foundry embeddings + Redis cache + Cosmos long-term memory."
5. "Prepare one commit and PR message for full stack change."
6. "Validate GitHub Action deploy path to AKS Automatic with governance controls."
