
-- =====================================================
-- Project: Enterprise Retail Data Warehouse
-- File: 02_validate_orders_landing.sql
-- Purpose: Validate Olist orders landing ingestion
-- =====================================================

-- 1. Total rows and unique orders
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT order_id) AS pedidos_unicos,
    COUNT(*) - COUNT(order_id) AS ids_nulos
FROM landing_orders;

-- 2. Order status distribution
SELECT
    order_status,
    COUNT(*) AS quantidade
FROM landing_orders
GROUP BY order_status
ORDER BY quantidade DESC;

-- 3. Batch execution history
SELECT
    batch_id,
    source_name,
    status,
    rows_loaded,
    started_at,
    finished_at
FROM etl_batch
ORDER BY batch_id DESC;

-- 4. Check staging row count
SELECT
    COUNT(*) AS total_staging
FROM stg_orders;
