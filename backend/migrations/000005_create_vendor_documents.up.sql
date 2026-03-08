-- 000005_create_vendor_documents.up.sql
-- Create vendor_documents table

CREATE TABLE vendor_documents (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id       UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    doc_type        VARCHAR(50) NOT NULL
                    CHECK (doc_type IN ('aadhaar', 'pan', 'gst', 'fssai', 'shop_license', 'bank_proof', 'other')),
    doc_url         VARCHAR(500) NOT NULL,
    status          VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_note  TEXT,
    verified_by     UUID REFERENCES users(id),
    verified_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vendor_documents_vendor_id ON vendor_documents (vendor_id);
CREATE INDEX idx_vendor_documents_status ON vendor_documents (status);
