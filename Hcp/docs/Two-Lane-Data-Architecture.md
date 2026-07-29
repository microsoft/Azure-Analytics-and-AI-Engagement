# Data Architecture

## One-Line Story
We run two data lanes in parallel: a trusted clinical intelligence lane for high-integrity decisions, and a real-time experience lane for fast, conversational user interactions.

## Architecture Snapshot

```mermaid
flowchart LR
    U[HCP User] --> APP[HCP Portal + AI Assistant]

    APP --> ORCH[Application Orchestrator]

    ORCH --> CLIN[Lane 1: Clinical Intelligence Data]
    ORCH --> CHAT[Lane 2: Conversational Experience Data]

    CLIN --> C1[Clinical Records + Drug Catalog]
    CLIN --> C2[Vector Embeddings]
    CLIN --> C3[Unified Governance + Traceability]

    CHAT --> U1[Chat History]
    CHAT --> U2[User Profile + Preferences]
    CHAT --> U3[Agent Memory + Session Context]

    C3 --> RESP[Grounded, Compliant Clinical Response]
    U3 --> RESP
    RESP --> U

    classDef lane1 fill:#e9f5ff,stroke:#0f4c81,stroke-width:2px;
    classDef lane2 fill:#fff4e8,stroke:#9a4d00,stroke-width:2px;
    classDef core fill:#eef7ee,stroke:#2f6b2f,stroke-width:2px;

    class CLIN,C1,C2,C3 lane1;
    class CHAT,U1,U2,U3 lane2;
    class ORCH,APP,RESP core;
```

## Why This Split Works

### Lane 1: Clinical Intelligence (Structured, Trusted)
- Keeps clinical data, medication knowledge, and embeddings together.
- Preserves context integrity for retrieval and decision support.
- Optimized for consistency, governance, and auditability.

### Lane 2: Conversational Experience (Unstructured, Fast)
- Handles chat turns, profile context, and short/long-term agent memory.
- Optimized for low latency and high update frequency.
- Delivers real-time user experience without slowing clinical workflows.

## Business Outcome
- Faster user interactions without compromising clinical reliability.
- Better grounding quality because trusted medical context stays coherent.
- Cleaner compliance posture through clear separation of responsibilities.

## 20-Second Voiceover Script
We separate data into two purpose-built lanes. Lane one keeps clinical records, drug knowledge, and AI embeddings together, so responses are trustworthy and traceable. Lane two handles chat history, user preferences, and agent memory for real-time speed. The orchestrator combines both at response time, giving clinicians fast interactions and high-confidence clinical answers.
