-- 000003_create_addresses.up.sql
-- Create addresses table

CREATE TABLE addresses (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id),
    label       VARCHAR(50) DEFAULT 'home',
    full_address TEXT NOT NULL,
    landmark    VARCHAR(255),
    city        VARCHAR(100),
    state       VARCHAR(100),
    pincode     VARCHAR(10),
    location    GEOGRAPHY(Point, 4326) NOT NULL,
    is_default  BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_addresses_user_id ON addresses (user_id);
CREATE INDEX idx_addresses_location ON addresses USING GIST (location);
