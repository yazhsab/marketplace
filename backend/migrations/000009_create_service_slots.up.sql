-- 000009_create_service_slots.up.sql
-- Create service_slots table

CREATE TABLE service_slots (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id      UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    vendor_id       UUID NOT NULL REFERENCES vendors(id),
    slot_date       DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    max_bookings    INT DEFAULT 1,
    booked_count    INT DEFAULT 0,
    is_available    BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT chk_slot_time CHECK (end_time > start_time),
    CONSTRAINT chk_booked_count CHECK (booked_count <= max_bookings),
    CONSTRAINT uq_service_slot UNIQUE (service_id, slot_date, start_time)
);

CREATE INDEX idx_service_slots_service_id ON service_slots (service_id);
CREATE INDEX idx_service_slots_vendor_id ON service_slots (vendor_id);
CREATE INDEX idx_service_slots_slot_date ON service_slots (slot_date);
