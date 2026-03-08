-- 000007_create_products.up.sql
-- Create products table

CREATE TABLE products (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id           UUID NOT NULL REFERENCES vendors(id),
    category_id         UUID REFERENCES categories(id),
    name                VARCHAR(255) NOT NULL,
    slug                VARCHAR(255) NOT NULL,
    description         TEXT,
    price               DECIMAL(10,2) NOT NULL,
    compare_price       DECIMAL(10,2),
    unit                VARCHAR(20) DEFAULT 'piece',
    sku                 VARCHAR(100),
    images              TEXT[] DEFAULT '{}',
    is_active           BOOLEAN DEFAULT true,
    avg_rating          DECIMAL(2,1) DEFAULT 0.0,
    total_reviews       INT DEFAULT 0,
    stock_quantity      INT DEFAULT 0,
    low_stock_threshold INT DEFAULT 5,
    weight_grams        INT,
    tags                TEXT[] DEFAULT '{}',
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,

    CONSTRAINT uq_products_vendor_slug UNIQUE (vendor_id, slug)
);

CREATE INDEX idx_products_vendor_id ON products (vendor_id);
CREATE INDEX idx_products_category_id ON products (category_id);
CREATE INDEX idx_products_is_active ON products (is_active);
