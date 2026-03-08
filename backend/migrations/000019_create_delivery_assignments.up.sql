-- Create delivery_assignments table

CREATE TABLE delivery_assignments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id            UUID NOT NULL REFERENCES orders(id),
    delivery_partner_id UUID NOT NULL REFERENCES delivery_partners(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'assigned'
                        CHECK (status IN ('assigned', 'accepted', 'rejected', 'picked_up',
                                          'delivered', 'cancelled')),
    assigned_at         TIMESTAMPTZ DEFAULT NOW(),
    accepted_at         TIMESTAMPTZ,
    picked_up_at        TIMESTAMPTZ,
    delivered_at        TIMESTAMPTZ,
    delivery_proof_url  VARCHAR(500),
    delivery_otp        VARCHAR(6),
    distance_km         DECIMAL(8,2),
    earnings            DECIMAL(10,2),
    rejection_reason    TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_delivery_assignments_order_id ON delivery_assignments (order_id);
CREATE INDEX idx_delivery_assignments_partner_id ON delivery_assignments (delivery_partner_id);
CREATE INDEX idx_delivery_assignments_status ON delivery_assignments (status);
CREATE INDEX idx_delivery_assignments_created_at ON delivery_assignments (created_at);
