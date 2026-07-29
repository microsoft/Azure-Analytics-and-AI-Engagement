-- Governance hardening for HorizonDB clinical data.
-- Applies row-level security and Purview-ready classification metadata.

CREATE OR REPLACE FUNCTION clinical.current_tenant_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid;
$$;

ALTER TABLE clinical.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.patients FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.encounters ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.encounters FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.medications FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.clinical_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.clinical_documents FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.document_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.document_chunks FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.guideline_references ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.guideline_references FORCE ROW LEVEL SECURITY;
ALTER TABLE clinical.guideline_reference_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinical.guideline_reference_chunks FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS patients_tenant_isolation ON clinical.patients;
CREATE POLICY patients_tenant_isolation ON clinical.patients
    USING (tenant_id = clinical.current_tenant_id())
    WITH CHECK (tenant_id = clinical.current_tenant_id());

DROP POLICY IF EXISTS encounters_tenant_isolation ON clinical.encounters;
CREATE POLICY encounters_tenant_isolation ON clinical.encounters
    USING (tenant_id = clinical.current_tenant_id())
    WITH CHECK (tenant_id = clinical.current_tenant_id());

DROP POLICY IF EXISTS medications_tenant_isolation ON clinical.medications;
CREATE POLICY medications_tenant_isolation ON clinical.medications
    USING (tenant_id = clinical.current_tenant_id())
    WITH CHECK (tenant_id = clinical.current_tenant_id());

DROP POLICY IF EXISTS clinical_documents_tenant_isolation ON clinical.clinical_documents;
CREATE POLICY clinical_documents_tenant_isolation ON clinical.clinical_documents
    USING (tenant_id = clinical.current_tenant_id())
    WITH CHECK (tenant_id = clinical.current_tenant_id());

DROP POLICY IF EXISTS document_chunks_tenant_isolation ON clinical.document_chunks;
CREATE POLICY document_chunks_tenant_isolation ON clinical.document_chunks
    USING (tenant_id = clinical.current_tenant_id())
    WITH CHECK (tenant_id = clinical.current_tenant_id());

DROP POLICY IF EXISTS guideline_references_tenant_isolation ON clinical.guideline_references;
CREATE POLICY guideline_references_tenant_isolation ON clinical.guideline_references
    USING (tenant_id = clinical.current_tenant_id())
    WITH CHECK (tenant_id = clinical.current_tenant_id());

DROP POLICY IF EXISTS guideline_reference_chunks_tenant_isolation ON clinical.guideline_reference_chunks;
CREATE POLICY guideline_reference_chunks_tenant_isolation ON clinical.guideline_reference_chunks
    USING (tenant_id = clinical.current_tenant_id())
    WITH CHECK (tenant_id = clinical.current_tenant_id());

COMMENT ON TABLE clinical.tenants IS 'Internal tenant registry used to map the current session to a clinical boundary.';
COMMENT ON TABLE clinical.patients IS 'Purview classification: Confidential - PHI';
COMMENT ON COLUMN clinical.patients.mrn IS 'Purview classification: Confidential - PHI';
COMMENT ON COLUMN clinical.patients.first_name IS 'Purview classification: Confidential - PHI';
COMMENT ON COLUMN clinical.patients.last_name IS 'Purview classification: Confidential - PHI';
COMMENT ON COLUMN clinical.patients.date_of_birth IS 'Purview classification: Confidential - PHI';
COMMENT ON TABLE clinical.encounters IS 'Purview classification: Confidential - clinical encounter data';
COMMENT ON COLUMN clinical.encounters.diagnosis_summary IS 'Purview classification: Restricted - clinical narrative';
COMMENT ON TABLE clinical.medications IS 'Purview classification: Confidential - medication profile';
COMMENT ON TABLE clinical.clinical_documents IS 'Purview classification: Restricted - source clinical document text';
COMMENT ON COLUMN clinical.clinical_documents.raw_text IS 'Purview classification: Restricted - source clinical document text';
COMMENT ON TABLE clinical.document_chunks IS 'Purview classification: Restricted - vectorized clinical content';
COMMENT ON COLUMN clinical.document_chunks.embedding IS 'Purview classification: Restricted - AI embedding derived from clinical text';
COMMENT ON TABLE clinical.guideline_references IS 'Purview classification: Internal - drug and guideline reference content';
COMMENT ON TABLE clinical.guideline_reference_chunks IS 'Purview classification: Internal - guideline retrieval chunks';