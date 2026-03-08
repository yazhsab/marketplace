-- 000008_create_services.up.sql
-- Create services table

CREATE TABLE services (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id       UUID NOT NULL REFERENCES vendors(id),
    category_id     UUID REFERENCES categories(id),
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) NOT NULL,
    description     TEXT,
    price           DECIMAL(10,2) NOT NULL,
    duration_mins   INT DEFAULT 60,
    images          TEXT[] DEFAULT '{}',
    is_active       BOOLEAN DEFAULT true,
    avg_rating      DECIMAL(2,1) DEFAULT 0.0,
    total_reviews   INT DEFAULT 0,
    tags            TEXT[] DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT uq_services_vendor_slug UNIQUE (vendor_id, slug)
);

CREATE INDEX idx_services_vendor_id ON services (vendor_id);
CREATE INDEX idx_services_category_id ON services (category_id);
CREATE INDEX idx_services_is_active ON services (is_active);
