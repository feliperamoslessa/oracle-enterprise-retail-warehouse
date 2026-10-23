
-- =====================================================
-- Enterprise Retail Data Warehouse
-- Delivery Performance by Customer State
--
-- Grain: one order / delivery
-- Metric: late delivery by calendar date
-- Minimum sample: 100 valid deliveries per state
-- =====================================================

-- 1. Delivery performance by state

WITH deliveries AS (
    SELECT
        c.customer_state AS state_code,
        CASE
            WHEN TRUNC(CAST(f.delivered_customer_at AS DATE))
               > TRUNC(CAST(f.estimated_delivery_at AS DATE))
            THEN 1
            ELSE 0
        END AS is_late
    FROM fact_orders f
    JOIN stg_orders o
        ON f.order_id = o.order_id
    JOIN stg_customers c
        ON o.customer_id = c.customer_id
    WHERE f.order_status = 'delivered'
      AND f.delivered_customer_at IS NOT NULL
      AND f.estimated_delivery_at IS NOT NULL
)
SELECT
    state_code,
    COUNT(*) AS total_deliveries,
    SUM(is_late) AS late_deliveries,
    COUNT(*) - SUM(is_late) AS on_time_deliveries,
    ROUND(
        100 * SUM(is_late) / NULLIF(COUNT(*), 0),
        2
    ) AS late_rate_pct
FROM deliveries
GROUP BY state_code
HAVING COUNT(*) >= 100
ORDER BY late_rate_pct DESC;


-- 2. Geographic coverage and join validation

SELECT
    COUNT(*) AS total_deliveries,
    COUNT(DISTINCT c.customer_state) AS states_covered,
    COUNT(*) - COUNT(c.customer_state) AS null_states
FROM fact_orders f
JOIN stg_orders o
    ON f.order_id = o.order_id
JOIN stg_customers c
    ON o.customer_id = c.customer_id
WHERE f.order_status = 'delivered'
  AND f.delivered_customer_at IS NOT NULL
  AND f.estimated_delivery_at IS NOT NULL;
