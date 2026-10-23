
CREATE OR REPLACE VIEW vw_delivery_monthly_kpis AS
SELECT
    delivery_month,

    COUNT(*) AS total_deliveries,

    SUM(is_late) AS late_deliveries,

    COUNT(*) - SUM(is_late) AS on_time_deliveries,

    ROUND(
        100 * SUM(is_late)
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_rate_pct,

    ROUND(
        100 * (COUNT(*) - SUM(is_late))
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_rate_pct

FROM vw_delivery_performance

GROUP BY delivery_month;
