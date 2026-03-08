-- 000012_create_bookings.up.sql
-- Create bookings table

CREATE TABLE bookings (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_number      VARCHAR(20) NOT NULL UNIQUE,
    customer_id         UUID NOT NULL REFERENCES users(id),
    vendor_id           UUID NOT NULL REFERENCES vendors(id),
    service_id          UUID NOT NULL REFERENCES services(id),
    slot_id             UUID REFERENCES service_slots(id),
    address_id          UUID REFERENCES addresses(id),
    status              VARCHAR(30) DEFAULT 'pending'
                        CHECK (status IN ('pending', 'confirmed', 'in_progress',
                                          'completed', 'cancelled', 'no_show')),
    scheduled_date      DATE NOT NULL,
    scheduled_start     TIME NOT NULL,
    scheduled_end       TIME NOT NULL,
    service_name        VARCHAR(255) NOT NULL,
    price               DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax                 DECIMAL(10,2) NOT NULL DEFAULT 0,
    total               DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_status      VARCHAR(20) DEFAULT 'pending'
                        CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    notes               TEXT,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_bookings_customer_id ON bookings (customer_id);
CREATE INDEX idx_bookings_vendor_id ON bookings (vendor_id);
CREATE INDEX idx_bookings_service_id ON bookings (service_id);
CREATE INDEX idx_bookings_status ON bookings (status);
CREATE INDEX idx_bookings_scheduled_date ON bookings (scheduled_date);
