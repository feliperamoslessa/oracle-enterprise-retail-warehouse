
-- ========================================================
-- Enterprise Retail Data Warehouse
-- Delivery Performance Analytics
--
-- Grain: one row per order in FACT_ORDERS
-- Scope: delivered orders with known delivery dates
-- Business rule: late if delivered after estimated
--                calendar date (ignoring time of day)
-- ========================================================

-- 1. ON-TIME DELIVERY KPI

WITH deliveries AS (
    SELECT
        order_id,
        TRUNC(CAST(delivered_customer_at AS DATE))
          - TRUNC(CAST(estimated_delivery_at AS DATE))
          AS days_difference
    FROM fact_orders
    WHERE order_status = 'delivered'
      AND delivered_customer_at IS NOT NULL
      AND estimated_delivery_at IS NOT NULL
)
SELECT
    COUNT(*) AS total_deliveries,
    SUM(CASE WHEN days_difference > 0
        THEN 1 ELSE 0 END) AS late_deliveries,
    SUM(CASE WHEN days_difference <= 0
        THEN 1 ELSE 0 END) AS on_time_deliveries,
    ROUND(
        100 * SUM(CASE WHEN days_difference <= 0
            THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_rate_pct,
    ROUND(
        100 * SUM(CASE WHEN days_difference > 0
            THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_rate_pct
FROM deliveries;


-- 2. DELAY SEVERITY

WITH deliveries AS (
    SELECT
        TRUNC(CAST(delivered_customer_at AS DATE))
          - TRUNC(CAST(estimated_delivery_at AS DATE))
          AS days_late
    FROM fact_orders
    WHERE order_status = 'delivered'
      AND delivered_customer_at IS NOT NULL
      AND estimated_delivery_at IS NOT NULL
)
SELECT
    COUNT(*) AS late_deliveries,
    ROUND(AVG(days_late), 2) AS avg_delay_days,
    MEDIAN(days_late) AS median_delay_days,
    MIN(days_late) AS min_delay_days,
    MAX(days_late) AS max_delay_days
FROM deliveries
WHERE days_late > 0;


-- 3. DELAY DISTRIBUTION

WITH deliveries AS (
    SELECT
        TRUNC(CAST(delivered_customer_at AS DATE))
          - TRUNC(CAST(estimated_delivery_at AS DATE))
          AS days_late
    FROM fact_orders
    WHERE order_status = 'delivered'
      AND delivered_customer_at IS NOT NULL
      AND estimated_delivery_at IS NOT NULL
),
delay_bands AS (
    SELECT
        CASE
            WHEN days_late BETWEEN 1 AND 3 THEN '1-3 days'
            WHEN days_late BETWEEN 4 AND 7 THEN '4-7 days'
            WHEN days_late BETWEEN 8 AND 14 THEN '8-14 days'
            WHEN days_late BETWEEN 15 AND 30 THEN '15-30 days'
            ELSE 'Over 30 days'
        END AS delay_band,
        CASE
            WHEN days_late BETWEEN 1 AND 3 THEN 1
            WHEN days_late BETWEEN 4 AND 7 THEN 2
            WHEN days_late BETWEEN 8 AND 14 THEN 3
            WHEN days_late BETWEEN 15 AND 30 THEN 4
            ELSE 5
        END AS band_order
    FROM deliveries
    WHERE days_late > 0
)
SELECT
    delay_band,
    COUNT(*) AS total_deliveries
FROM delay_bands
GROUP BY delay_band, band_order
ORDER BY band_order;
