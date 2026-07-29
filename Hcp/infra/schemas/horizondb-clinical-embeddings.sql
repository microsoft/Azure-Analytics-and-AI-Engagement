-- Starter schema for Azure HorizonDB (PostgreSQL-compatible)
-- Purpose: structured clinical records plus vector embeddings for retrieval.

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS clinical;

CREATE TABLE IF NOT EXISTS clinical.tenants (
    tenant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_code varchar(64) NOT NULL UNIQUE,
    display_name varchar(200) NOT NULL,
    region_code varchar(32) NOT NULL,
    created_utc timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS clinical.patients (
    patient_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES clinical.tenants(tenant_id) ON DELETE CASCADE,
    mrn varchar(64) NOT NULL,
    first_name varchar(100) NOT NULL,
    last_name varchar(100) NOT NULL,
    date_of_birth date,
    sex_at_birth varchar(20),
    primary_language varchar(40),
    created_utc timestamptz NOT NULL DEFAULT now(),
    updated_utc timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_patients_tenant_mrn UNIQUE (tenant_id, mrn)
);

CREATE TABLE IF NOT EXISTS clinical.encounters (
    encounter_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES clinical.tenants(tenant_id) ON DELETE CASCADE,
    patient_id uuid NOT NULL REFERENCES clinical.patients(patient_id) ON DELETE CASCADE,
    encounter_type varchar(50) NOT NULL,
    encounter_status varchar(30) NOT NULL,
    occurred_utc timestamptz NOT NULL,
    clinician_npi varchar(20),
    department_name varchar(120),
    diagnosis_summary text,
    source_system varchar(80),
    created_utc timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS clinical.medications (
    medication_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES clinical.tenants(tenant_id) ON DELETE CASCADE,
    patient_id uuid NOT NULL REFERENCES clinical.patients(patient_id) ON DELETE CASCADE,
    encounter_id uuid REFERENCES clinical.encounters(encounter_id) ON DELETE SET NULL,
    rxnorm_code varchar(40),
    medication_name varchar(200) NOT NULL,
    dose varchar(80),
    route varchar(40),
    frequency varchar(80),
    start_date date,
    end_date date,
    is_active boolean NOT NULL DEFAULT true,
    created_utc timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS clinical.clinical_documents (
    document_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES clinical.tenants(tenant_id) ON DELETE CASCADE,
    patient_id uuid REFERENCES clinical.patients(patient_id) ON DELETE CASCADE,
    encounter_id uuid REFERENCES clinical.encounters(encounter_id) ON DELETE SET NULL,
    document_type varchar(50) NOT NULL,
    title varchar(240) NOT NULL,
    source_system varchar(80) NOT NULL,
    authored_utc timestamptz,
    raw_text text NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_utc timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS clinical.document_chunks (
    chunk_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id uuid NOT NULL REFERENCES clinical.clinical_documents(document_id) ON DELETE CASCADE,
    tenant_id uuid NOT NULL REFERENCES clinical.tenants(tenant_id) ON DELETE CASCADE,
    patient_id uuid REFERENCES clinical.patients(patient_id) ON DELETE CASCADE,
    chunk_ordinal integer NOT NULL,
    content_text text NOT NULL,
    token_count integer NOT NULL,
    embedding vector(1536),
    embedding_model varchar(120),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_utc timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_document_chunk_ordinal UNIQUE (document_id, chunk_ordinal),
    CONSTRAINT ck_document_chunks_token_count CHECK (token_count > 0)
);

CREATE TABLE IF NOT EXISTS clinical.guideline_references (
    guideline_reference_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES clinical.tenants(tenant_id) ON DELETE CASCADE,
    reference_code varchar(64) NOT NULL,
    title varchar(240) NOT NULL,
    specialty varchar(120),
    body_text text NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_utc timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_guideline_references_code UNIQUE (tenant_id, reference_code)
);

CREATE TABLE IF NOT EXISTS clinical.guideline_reference_chunks (
    chunk_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    guideline_reference_id uuid NOT NULL REFERENCES clinical.guideline_references(guideline_reference_id) ON DELETE CASCADE,
    tenant_id uuid NOT NULL REFERENCES clinical.tenants(tenant_id) ON DELETE CASCADE,
    chunk_ordinal integer NOT NULL,
    content_text text NOT NULL,
    token_count integer NOT NULL,
    embedding vector(1536),
    embedding_model varchar(120),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_utc timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_guideline_reference_chunk_ordinal UNIQUE (guideline_reference_id, chunk_ordinal),
    CONSTRAINT ck_guideline_reference_chunks_token_count CHECK (token_count > 0)
);

CREATE INDEX IF NOT EXISTS ix_patients_tenant_id ON clinical.patients (tenant_id);
CREATE INDEX IF NOT EXISTS ix_encounters_tenant_patient_occurred ON clinical.encounters (tenant_id, patient_id, occurred_utc DESC);
CREATE INDEX IF NOT EXISTS ix_medications_tenant_patient_active ON clinical.medications (tenant_id, patient_id, is_active);
CREATE INDEX IF NOT EXISTS ix_documents_tenant_patient_type ON clinical.clinical_documents (tenant_id, patient_id, document_type);
CREATE INDEX IF NOT EXISTS ix_documents_metadata_gin ON clinical.clinical_documents USING gin (metadata);
CREATE INDEX IF NOT EXISTS ix_document_chunks_tenant_document ON clinical.document_chunks (tenant_id, document_id, chunk_ordinal);
CREATE INDEX IF NOT EXISTS ix_document_chunks_metadata_gin ON clinical.document_chunks USING gin (metadata);
CREATE INDEX IF NOT EXISTS ix_guideline_references_tenant_specialty ON clinical.guideline_references (tenant_id, specialty);
CREATE INDEX IF NOT EXISTS ix_guideline_reference_chunks_tenant_reference ON clinical.guideline_reference_chunks (tenant_id, guideline_reference_id, chunk_ordinal);

-- HNSW is preferred when the service tier supports it. If not supported,
-- replace with ivfflat and tune the lists parameter after data load.
CREATE INDEX IF NOT EXISTS ix_document_chunks_embedding_hnsw
    ON clinical.document_chunks USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS ix_guideline_reference_chunks_embedding_hnsw
    ON clinical.guideline_reference_chunks USING hnsw (embedding vector_cosine_ops);

CREATE OR REPLACE VIEW clinical.patient_context AS
SELECT
    p.tenant_id,
    p.patient_id,
    p.mrn,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    e.encounter_id,
    e.encounter_type,
    e.occurred_utc,
    m.medication_id,
    m.medication_name,
    m.dose,
    m.frequency,
    m.is_active
FROM clinical.patients p
LEFT JOIN clinical.encounters e ON e.patient_id = p.patient_id
LEFT JOIN clinical.medications m ON m.patient_id = p.patient_id;

-- Validation queries

-- 1. Verify required relations and counts by tenant.
SELECT
    t.tenant_code,
    count(DISTINCT p.patient_id) AS patient_count,
    count(DISTINCT e.encounter_id) AS encounter_count,
    count(DISTINCT d.document_id) AS document_count,
    count(DISTINCT dc.chunk_id) AS document_chunk_count
FROM clinical.tenants t
LEFT JOIN clinical.patients p ON p.tenant_id = t.tenant_id
LEFT JOIN clinical.encounters e ON e.tenant_id = t.tenant_id
LEFT JOIN clinical.clinical_documents d ON d.tenant_id = t.tenant_id
LEFT JOIN clinical.document_chunks dc ON dc.tenant_id = t.tenant_id
GROUP BY t.tenant_code;

-- 2. Verify documents with missing embeddings.
SELECT document_id, count(*) AS chunks_missing_embeddings
FROM clinical.document_chunks
WHERE embedding IS NULL
GROUP BY document_id
ORDER BY chunks_missing_embeddings DESC;

-- 3. Sample patient timeline query for retrieval orchestration.
SELECT
    p.mrn,
    e.occurred_utc,
    e.encounter_type,
    e.diagnosis_summary,
    m.medication_name,
    m.dose,
    m.frequency
FROM clinical.patients p
LEFT JOIN clinical.encounters e ON e.patient_id = p.patient_id
LEFT JOIN clinical.medications m ON m.encounter_id = e.encounter_id
WHERE p.tenant_id = :tenant_id
  AND p.patient_id = :patient_id
ORDER BY e.occurred_utc DESC NULLS LAST;

-- 4. Sample vector similarity query against document chunks.
SELECT
    dc.chunk_id,
    dc.document_id,
    dc.content_text,
    dc.metadata,
    1 - (dc.embedding <=> :query_embedding) AS similarity
FROM clinical.document_chunks dc
WHERE dc.tenant_id = :tenant_id
  AND dc.embedding IS NOT NULL
ORDER BY dc.embedding <=> :query_embedding
LIMIT 10;

-- 5. Sample vector similarity query against guideline references.
SELECT
    gr.reference_code,
    gr.title,
    gr.specialty,
    grc.content_text,
    1 - (grc.embedding <=> :query_embedding) AS similarity
FROM clinical.guideline_reference_chunks grc
JOIN clinical.guideline_references gr
  ON gr.guideline_reference_id = grc.guideline_reference_id
WHERE grc.tenant_id = :tenant_id
  AND grc.embedding IS NOT NULL
ORDER BY grc.embedding <=> :query_embedding
LIMIT 10;