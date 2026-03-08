-- 000002_create_users.up.sql
-- Create users table

CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone       VARCHAR(15) UNIQUE,
    email       VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    full_name   VARCHAR(255) NOT NULL,
    avatar_url  VARCHAR(500),
    role        VARCHAR(20) NOT NULL DEFAULT 'customer'
                CHECK (role IN ('customer', 'vendor', 'admin')),
    is_active   BOOLEAN DEFAULT true,
    fcm_token   VARCHAR(500),
    last_login_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

-- Partial unique indexes to allow soft-deleted duplicates
CREATE UNIQUE INDEX idx_users_phone_active ON users (phone)
    WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX idx_users_email_active ON users (email)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_users_role ON users (role);
