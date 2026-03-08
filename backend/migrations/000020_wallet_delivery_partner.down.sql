DROP INDEX IF EXISTS idx_wallets_delivery_partner_id;
DROP INDEX IF EXISTS idx_wallets_vendor_id;
ALTER TABLE wallets DROP COLUMN IF EXISTS delivery_partner_id;
ALTER TABLE wallets ALTER COLUMN vendor_id SET NOT NULL;
CREATE UNIQUE INDEX idx_wallets_vendor_id ON wallets (vendor_id);
