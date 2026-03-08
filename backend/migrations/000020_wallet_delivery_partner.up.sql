-- Add delivery_partner_id to wallets for delivery partner earnings

ALTER TABLE wallets ADD COLUMN delivery_partner_id UUID REFERENCES delivery_partners(id);

-- Make vendor_id nullable (delivery partner wallets won't have vendor_id)
ALTER TABLE wallets ALTER COLUMN vendor_id DROP NOT NULL;

-- Replace unique index with conditional unique indexes
DROP INDEX IF EXISTS idx_wallets_vendor_id;
ALTER TABLE wallets DROP CONSTRAINT IF EXISTS wallets_vendor_id_key;
CREATE UNIQUE INDEX idx_wallets_vendor_id ON wallets (vendor_id) WHERE vendor_id IS NOT NULL;
CREATE UNIQUE INDEX idx_wallets_delivery_partner_id ON wallets (delivery_partner_id) WHERE delivery_partner_id IS NOT NULL;
