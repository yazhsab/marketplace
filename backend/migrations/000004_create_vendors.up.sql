-- 000004_create_vendors.up.sql
-- Create vendors table

CREATE TABLE vendors (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL UNIQUE REFERENCES users(id),
    business_name   VARCHAR(255),
    description     TEXT,
    logo_url        VARCHAR(500),
    banner_url      VARCHAR(500),
    vendor_type     VARCHAR(20)
                    CHECK (vendor_type IN ('product', 'service', 'both')),
    status          VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected', 'suspended')),
    location        GEOGRAPHY(Point, 4326),
    address         TEXT,
    city            VARCHAR(100),
    state           VARCHAR(100),
    pincode         VARCHAR(10),
    service_radius_km DECIMAL(5,2) DEFAULT 10.0,
    avg_rating      DECIMAL(2,1) DEFAULT 0.0,
    total_reviews   INT DEFAULT 0,
    commission_pct  DECIMAL(5,2) DEFAULT 10.00,
    is_online       BOOLEAN DEFAULT false,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_vendors_location ON vendors USING GIST (location);
CREATE INDEX idx_vendors_status ON vendors (status);
CREATE INDEX idx_vendors_city ON vendors (city);
CREATE INDEX idx_vendors_vendor_type ON vendors (vendor_type);
