
-- =====================================================
-- Enterprise Retail Data Warehouse
-- Monthly Delivery Trends
--
-- Grain: one delivered order
-- Time dimension: actual delivery month
-- KPI: late delivery rate by calendar date
-- Rolling metric: weighted 3-month late delivery rate
--
-- Data quality considerations:
-- 1. Keep all observed months for reconciliation.
-- 2. Months with fewer than 100 deliveries should
--    not be used in primary monthly comparisons.
-- 3. Rolling windows may contain low-volume months.
-- 4. Observed trends do not establish causality.
-- =====================================================

WITH monthly_metrics AS (
    SELECT
        TRUNC(
            CAST(delivered_customer_at AS DATE),
            'MM'
        ) AS delivery_month,

        COUNT(*) AS total_deliveries,

        SUM(
            CASE
                WHEN TRUNC(
                    CAST(delivered_customer_at AS DATE)
                ) > TRUNC(
                    CAST(estimated_delivery_at AS DATE)
                )
                THEN 1
                ELSE 0
            END
        ) AS late_deliveries

    FROM fact_orders

    WHERE order_status = 'delivered'
      AND delivered_customer_at IS NOT NULL
      AND estimated_delivery_at IS NOT NULL

    GROUP BY
        TRUNC(
            CAST(delivered_customer_at AS DATE),
            'MM'
        )
),
rolling_metrics AS (
    SELECT
        delivery_month,
        total_deliveries,
        late_deliveries,

        ROUND(
            100 * late_deliveries
            / NULLIF(total_deliveries, 0),
            2
        ) AS monthly_late_rate_pct,

        SUM(late_deliveries) OVER (
            ORDER BY delivery_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_late,

        SUM(total_deliveries) OVER (
            ORDER BY delivery_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_total,

        COUNT(*) OVER (
            ORDER BY delivery_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS months_in_window

    FROM monthly_metrics
)
SELECT
    TO_CHAR(delivery_month, 'YYYY-MM') AS month,
    total_deliveries,
    late_deliveries,
    monthly_late_rate_pct,

    CASE
        WHEN months_in_window = 3 THEN
            ROUND(
                100 * rolling_late
                / NULLIF(rolling_total, 0),
                2
            )
    END AS rolling_3m_late_rate_pct

FROM rolling_metrics
ORDER BY delivery_month;
