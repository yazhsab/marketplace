-- 000015_create_wallet_transactions.up.sql
-- Create wallet_transactions table

CREATE TABLE wallet_transactions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id           UUID NOT NULL REFERENCES wallets(id),
    type                VARCHAR(20) NOT NULL
                        CHECK (type IN ('credit', 'debit', 'payout', 'refund_debit', 'commission_debit')),
    amount              DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    balance_after       DECIMAL(12,2) NOT NULL,
    reference_type      VARCHAR(20),
    reference_id        UUID,
    description         TEXT,
    razorpay_payout_id  VARCHAR(100),
    status              VARCHAR(20) DEFAULT 'completed'
                        CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wallet_transactions_wallet_id ON wallet_transactions (wallet_id);
CREATE INDEX idx_wallet_transactions_reference ON wallet_transactions (reference_type, reference_id);
CREATE INDEX idx_wallet_transactions_status ON wallet_transactions (status);
CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions (created_at);
