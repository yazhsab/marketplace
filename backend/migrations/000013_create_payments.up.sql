-- 000013_create_payments.up.sql
-- Create payments table

CREATE TABLE payments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_type        VARCHAR(20) NOT NULL
                        CHECK (payment_type IN ('order', 'booking')),
    reference_id        UUID NOT NULL,
    customer_id         UUID NOT NULL REFERENCES users(id),
    vendor_id           UUID NOT NULL REFERENCES vendors(id),
    amount              DECIMAL(10,2) NOT NULL,
    currency            VARCHAR(3) DEFAULT 'INR',
    status              VARCHAR(20) DEFAULT 'created'
                        CHECK (status IN ('created', 'authorized', 'captured', 'failed', 'refunded')),
    razorpay_order_id   VARCHAR(255),
    razorpay_payment_id VARCHAR(255),
    razorpay_signature  VARCHAR(255),
    refund_id           VARCHAR(255),
    refund_amount       DECIMAL(10,2),
    method              VARCHAR(30),
    error_code          VARCHAR(100),
    error_description   TEXT,
    paid_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_reference_id ON payments (reference_id);
CREATE INDEX idx_payments_customer_id ON payments (customer_id);
CREATE INDEX idx_payments_vendor_id ON payments (vendor_id);
CREATE INDEX idx_payments_status ON payments (status);
CREATE INDEX idx_payments_razorpay_order_id ON payments (razorpay_order_id);
