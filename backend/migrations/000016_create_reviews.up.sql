-- 000016_create_reviews.up.sql
-- Create reviews table

CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id     UUID NOT NULL REFERENCES users(id),
    vendor_id       UUID NOT NULL REFERENCES vendors(id),
    review_type     VARCHAR(20) NOT NULL
                    CHECK (review_type IN ('product', 'service', 'vendor')),
    reference_id    UUID NOT NULL,
    order_id        UUID,
    rating          SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title           VARCHAR(255),
    comment         TEXT,
    images          TEXT[] DEFAULT '{}',
    is_verified     BOOLEAN DEFAULT false,
    vendor_reply    TEXT,
    vendor_replied_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT uq_review_per_order UNIQUE (customer_id, review_type, reference_id, order_id)
);

CREATE INDEX idx_reviews_customer_id ON reviews (customer_id);
CREATE INDEX idx_reviews_vendor_id ON reviews (vendor_id);
CREATE INDEX idx_reviews_reference ON reviews (review_type, reference_id);
CREATE INDEX idx_reviews_rating ON reviews (rating);
