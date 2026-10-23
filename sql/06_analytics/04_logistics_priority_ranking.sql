
-- =====================================================
-- Enterprise Retail Data Warehouse
-- Logistics Priority Ranking
--
-- Grain: one delivered order
-- Late delivery: delivery calendar date exceeds
--                estimated calendar date
-- Coverage: all 27 Brazilian states
-- =====================================================

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
),
state_metrics AS (
    SELECT
        state_code,
        COUNT(*) AS total_deliveries,
        SUM(is_late) AS late_deliveries,
        ROUND(
            100 * SUM(is_late) / NULLIF(COUNT(*), 0),
            2
        ) AS late_rate_pct
    FROM deliveries
    GROUP BY state_code
)
SELECT
    state_code,
    total_deliveries,
    late_deliveries,
    late_rate_pct,

    ROUND(
        100 * late_deliveries
        / NULLIF(SUM(late_deliveries) OVER (), 0),
        2
    ) AS share_of_late_pct,

    ROUND(
        100 * SUM(late_deliveries) OVER (
            ORDER BY late_deliveries DESC, state_code
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        )
        / NULLIF(SUM(late_deliveries) OVER (), 0),
        2
    ) AS cumulative_share_pct

FROM state_metrics
ORDER BY late_deliveries DESC, state_code;
