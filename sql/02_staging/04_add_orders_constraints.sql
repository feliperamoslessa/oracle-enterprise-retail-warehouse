
-- =====================================================
-- Enterprise Retail Data Warehouse
-- Enforce order integrity in staging
-- =====================================================

ALTER TABLE stg_orders
MODIFY (order_id NOT NULL);

ALTER TABLE stg_orders
ADD CONSTRAINT uk_stg_orders_order_id
UNIQUE (order_id);
