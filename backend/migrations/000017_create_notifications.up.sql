-- 000017_create_notifications.up.sql
-- Create notifications table

CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       VARCHAR(255) NOT NULL,
    body        TEXT,
    type        VARCHAR(30) NOT NULL
                CHECK (type IN ('order_update', 'booking_update', 'payment',
                                'promotion', 'vendor_approval', 'system', 'review')),
    data        JSONB DEFAULT '{}',
    is_read     BOOLEAN DEFAULT false,
    sent_via    VARCHAR(20)[] DEFAULT '{push}',
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications (user_id);
CREATE INDEX idx_notifications_type ON notifications (type);
CREATE INDEX idx_notifications_is_read ON notifications (user_id, is_read);
CREATE INDEX idx_notifications_created_at ON notifications (created_at);
