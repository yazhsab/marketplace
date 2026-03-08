-- Create delivery_partners table and add delivery_partner_id to orders

CREATE TABLE delivery_partners (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL UNIQUE REFERENCES users(id),
    vehicle_type        VARCHAR(20) NOT NULL
                        CHECK (vehicle_type IN ('bike', 'scooter', 'bicycle', 'car')),
    vehicle_number      VARCHAR(20),
    license_number      VARCHAR(50),
    status              VARCHAR(20) DEFAULT 'pending'
                        CHECK (status IN ('pending', 'approved', 'rejected', 'suspended')),
    current_latitude    DOUBLE PRECISION DEFAULT 0,
    current_longitude   DOUBLE PRECISION DEFAULT 0,
    location            GEOGRAPHY(Point, 4326),
    is_available        BOOLEAN DEFAULT false,
    is_on_shift         BOOLEAN DEFAULT false,
    current_order_id    UUID,
    zone_preference     VARCHAR(255),
    avg_rating          DECIMAL(2,1) DEFAULT 0.0,
    total_deliveries    INT DEFAULT 0,
    total_earnings      DECIMAL(12,2) DEFAULT 0,
    commission_pct      DECIMAL(5,2) DEFAULT 15.00,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_delivery_partners_location ON delivery_partners USING GIST (location);
CREATE INDEX idx_delivery_partners_status ON delivery_partners (status);
CREATE INDEX idx_delivery_partners_available ON delivery_partners (is_available, is_on_shift, status)
    WHERE is_available = true AND is_on_shift = true AND status = 'approved';
CREATE INDEX idx_delivery_partners_user_id ON delivery_partners (user_id);

-- Add delivery_partner_id FK to orders
ALTER TABLE orders ADD COLUMN delivery_partner_id UUID REFERENCES delivery_partners(id);
CREATE INDEX idx_orders_delivery_partner_id ON orders (delivery_partner_id);

-- Add 'assigned' to the orders status CHECK constraint
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE orders ADD CONSTRAINT orders_status_check
    CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'assigned',
                      'out_for_delivery', 'delivered', 'cancelled', 'refunded'));
