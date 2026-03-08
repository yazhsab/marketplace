-- 000010_create_orders.up.sql
-- Create orders table

CREATE TABLE orders (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number        VARCHAR(20) NOT NULL UNIQUE,
    customer_id         UUID NOT NULL REFERENCES users(id),
    vendor_id           UUID NOT NULL REFERENCES vendors(id),
    address_id          UUID REFERENCES addresses(id),
    status              VARCHAR(30) DEFAULT 'pending'
                        CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready',
                                          'out_for_delivery', 'delivered', 'cancelled', 'refunded')),
    subtotal            DECIMAL(10,2) NOT NULL DEFAULT 0,
    delivery_fee        DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount            DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax                 DECIMAL(10,2) NOT NULL DEFAULT 0,
    total               DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_status      VARCHAR(20) DEFAULT 'pending'
                        CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    notes               TEXT,
    estimated_delivery_at TIMESTAMPTZ,
    delivered_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_vendor_id ON orders (vendor_id);
CREATE INDEX idx_orders_status ON orders (status);
CREATE INDEX idx_orders_payment_status ON orders (payment_status);
CREATE INDEX idx_orders_created_at ON orders (created_at);
