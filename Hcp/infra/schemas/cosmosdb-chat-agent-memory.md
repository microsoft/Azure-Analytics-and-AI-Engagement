# Azure Cosmos DB Starter Model for Chat History and Agent Memory

Purpose: store high-throughput conversation state, clinician profile context, and long-term agent memory in a document model that can evolve without schema migrations.

## Design principles

- Keep raw PHI in HorizonDB when possible; store conversation artifacts in Cosmos DB with references back to clinical record IDs instead of duplicating full charts.
- Use synthetic partition keys that preserve single-conversation locality and avoid large tenant-only hot partitions.
- Put short-lived chat turns on TTL, and keep durable memory summaries as separate documents.
- Keep agent memory append-oriented; use summarization jobs to roll up older turns.

## Database

- Database name: `hcp-ai-memory`

## Containers

| Container | Purpose | Partition key | Default TTL | Notes |
|---|---|---|---:|---|
| `conversationSessions` | One document per active or completed chat session | `/tenantId` | none | Lightweight session envelope for routing and audit. |
| `conversationMessages` | Individual user/assistant/tool messages | `/conversationKey` | 7776000 | 90-day TTL for raw chat turns. |
| `agentMemories` | Durable summaries, facts, preferences, and unresolved tasks | `/memoryKey` | none | Long-term memory for retrieval at conversation start. |
| `clinicianProfiles` | Non-clinical personalization and UI preferences | `/profileKey` | none | Fast reads for session warm-up and personalization. |

`conversationKey` format:

```text
{tenantId}|{conversationId}
```

`memoryKey` format:

```text
{tenantId}|{principalId}
```

`profileKey` format:

```text
{tenantId}|{principalId}
```

## Container: conversationSessions

Document shape:

```json
{
  "id": "session_01JZ8H3K8VJ6S4YJ6M6YF2AC3P",
  "tenantId": "caldova-demo",
  "conversationId": "01JZ8H3K8VJ6S4YJ6M6YF2AC3P",
  "clinicianId": "npi:1356789012",
  "patientContext": {
    "patientId": "9bb52bf9-2e79-4c31-baf9-e53fb9bc0de8",
    "encounterId": "2b7f2229-cf11-4eb1-a4d9-2358f81f0cc5",
    "chartReference": "MRN-100045"
  },
  "status": "active",
  "channel": "hcp-portal-web",
  "startedUtc": "2026-07-02T18:10:00Z",
  "lastActivityUtc": "2026-07-02T18:13:41Z",
  "summaryMemoryIds": [
    "mem_01JZ8H8S4W8Y27RJ9P2YYQ8Y3D"
  ],
  "labels": ["enrollment", "drug-guidance"],
  "trace": {
    "appVersion": "1.0.0",
    "correlationId": "d2d4a917-f132-4b53-a4fd-14a89d4d4a9e"
  }
}
```

Recommended indexing:

- Include: `/tenantId/?`, `/conversationId/?`, `/clinicianId/?`, `/status/?`, `/lastActivityUtc/?`
- Exclude large nested paths that are not queried heavily.

## Container: conversationMessages

Document shape:

```json
{
  "id": "msg_01JZ8H4E3WG8N2Q62YQXK7QK4P",
  "conversationKey": "caldova-demo|01JZ8H3K8VJ6S4YJ6M6YF2AC3P",
  "tenantId": "caldova-demo",
  "conversationId": "01JZ8H3K8VJ6S4YJ6M6YF2AC3P",
  "sequence": 12,
  "role": "assistant",
  "messageType": "answer",
  "content": {
    "text": "Based on the latest note and current medication profile...",
    "citations": [
      {
        "documentId": "f6feff22-c14e-47b1-8821-e8d8d6d7eb74",
        "chunkId": "f15027c2-d7d6-49f6-af06-8770c44087d2",
        "referenceCode": "ASCO-2026-AML-01"
      }
    ]
  },
  "toolCalls": [
    {
      "toolName": "clinical-retrieval",
      "latencyMs": 142,
      "status": "succeeded"
    }
  ],
  "safety": {
    "phiDetected": true,
    "moderationPolicy": "clinical-safe-response-v1"
  },
  "createdUtc": "2026-07-02T18:12:11Z",
  "ttl": 7776000
}
```

Recommended indexing:

- Include: `/conversationId/?`, `/sequence/?`, `/role/?`, `/createdUtc/?`
- Exclude: `/content/text/?` if full-text search is not required in Cosmos.

## Container: agentMemories

Document shape:

```json
{
  "id": "mem_01JZ8H8S4W8Y27RJ9P2YYQ8Y3D",
  "memoryKey": "caldova-demo|npi:1356789012",
  "tenantId": "caldova-demo",
  "principalId": "npi:1356789012",
  "scope": "clinician",
  "memoryType": "summary",
  "sourceConversationId": "01JZ8H3K8VJ6S4YJ6M6YF2AC3P",
  "importance": 0.91,
  "tags": ["aml", "prior-authorization", "preferred-tone"],
  "content": {
    "summary": "Clinician prefers concise formulary answers with source citations.",
    "facts": [
      "Frequently asks about prior authorization pathways.",
      "Wants oncology guidance with current line-of-therapy context."
    ]
  },
  "clinicalRefs": [
    {
      "patientId": "9bb52bf9-2e79-4c31-baf9-e53fb9bc0de8",
      "documentId": "f6feff22-c14e-47b1-8821-e8d8d6d7eb74"
    }
  ],
  "validFromUtc": "2026-07-02T18:13:00Z",
  "expiresUtc": null,
  "createdUtc": "2026-07-02T18:13:00Z",
  "updatedUtc": "2026-07-02T18:13:00Z"
}
```

Recommended indexing:

- Include: `/principalId/?`, `/memoryType/?`, `/importance/?`, `/updatedUtc/?`, `/tags/*`
- Keep memory summaries compact; store large transcripts only in `conversationMessages`.

## Container: clinicianProfiles

Document shape:

```json
{
  "id": "profile_caldova-demo_npi-1356789012",
  "profileKey": "caldova-demo|npi:1356789012",
  "tenantId": "caldova-demo",
  "principalId": "npi:1356789012",
  "displayName": "Dr. Maya Chen",
  "specialty": "Oncology",
  "organizationName": "Caldova Cancer Center",
  "uiPreferences": {
    "responseStyle": "concise",
    "showCitations": true,
    "defaultView": "chat"
  },
  "notificationPreferences": {
    "email": true,
    "inApp": true
  },
  "lastActiveUtc": "2026-07-02T18:13:41Z",
  "createdUtc": "2026-07-02T18:10:00Z",
  "updatedUtc": "2026-07-02T18:13:41Z"
}
```

Recommended indexing:

- Include: `/principalId/?`, `/specialty/?`, `/lastActiveUtc/?`

## Validation queries

Get an active session for a clinician:

```sql
SELECT TOP 1 *
FROM conversationSessions c
WHERE c.tenantId = "caldova-demo"
  AND c.clinicianId = "npi:1356789012"
  AND c.status = "active"
ORDER BY c.lastActivityUtc DESC
```

Get the last 20 messages for one conversation:

```sql
SELECT TOP 20 c.id, c.sequence, c.role, c.content.text, c.createdUtc
FROM conversationMessages c
WHERE c.conversationKey = @conversationKey
ORDER BY c.sequence DESC
```

`@conversationKey` format: `{tenantId}|{conversationId}` (example: `caldova-demo|<conversation-id>`).

Get the highest-value memories to hydrate an agent at session start:

```sql
SELECT TOP 10 c.id, c.memoryType, c.importance, c.content, c.tags
FROM agentMemories c
WHERE c.memoryKey = "caldova-demo|npi:1356789012"
  AND (IS_NULL(c.expiresUtc) OR c.expiresUtc > GetCurrentDateTime())
ORDER BY c.importance DESC, c.updatedUtc DESC
```

Find profiles that have not been active recently:

```sql
SELECT c.id, c.displayName, c.lastActiveUtc
FROM clinicianProfiles c
WHERE c.tenantId = "caldova-demo"
  AND c.lastActiveUtc < "2026-06-01T00:00:00Z"
```

Count message volume by role within a single conversation partition:

```sql
SELECT c.role, COUNT(1) AS messageCount
FROM conversationMessages c
WHERE c.conversationKey = @conversationKey
GROUP BY c.role
```

## Operational notes

- Prefer session summaries in `agentMemories` over replaying entire transcripts into the model context window.
- Consider a change-feed processor that rolls up older `conversationMessages` into new `agentMemories` summary documents.
- For tenant-level audit, mirror required immutable audit events into a dedicated compliance container or operational log sink.
- If vector search is later needed for memory retrieval, add a separate memory-vector container instead of mixing embeddings into the high-churn message container.