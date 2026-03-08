-- 000014_create_wallets.up.sql
-- Create wallets table

CREATE TABLE wallets (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id       UUID NOT NULL UNIQUE REFERENCES vendors(id),
    balance         DECIMAL(12,2) DEFAULT 0 CHECK (balance >= 0),
    total_earned    DECIMAL(12,2) DEFAULT 0,
    total_withdrawn DECIMAL(12,2) DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);
