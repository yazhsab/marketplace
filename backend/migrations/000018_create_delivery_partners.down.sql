ALTER TABLE orders DROP COLUMN IF EXISTS delivery_partner_id;
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE orders ADD CONSTRAINT orders_status_check
    CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready',
                      'out_for_delivery', 'delivered', 'cancelled', 'refunded'));
DROP TABLE IF EXISTS delivery_partners CASCADE;
