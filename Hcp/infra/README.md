# HCP Infrastructure

This folder is reserved for Azure infrastructure definitions for the HCP portal.

Planned assets:

- Azure SQL logical server and database
- Azure Service Bus namespace and queue
- Container registry and managed identity wiring
- Kubernetes environment configuration and secret references

Application code can now depend on this path existing without mixing IaC into the API or web projects.

Schema assets:

- `schemas/horizondb-clinical-embeddings.sql` - starter PostgreSQL-compatible schema for clinical records, chunked documents, and pgvector embeddings.
- `schemas/cosmosdb-chat-agent-memory.md` - starter Cosmos DB container model for chat history, clinician profiles, and long-term agent memory.