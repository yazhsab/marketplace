-- 000006_create_categories.up.sql
-- Create categories table (self-referencing for hierarchy)

CREATE TABLE categories (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    image_url       VARCHAR(500),
    parent_id       UUID REFERENCES categories(id),
    sort_order      INT DEFAULT 0,
    is_active       BOOLEAN DEFAULT true,
    category_type   VARCHAR(20) DEFAULT 'product'
                    CHECK (category_type IN ('product', 'service')),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_categories_parent_id ON categories (parent_id);
CREATE INDEX idx_categories_category_type ON categories (category_type);
CREATE INDEX idx_categories_slug ON categories (slug);
