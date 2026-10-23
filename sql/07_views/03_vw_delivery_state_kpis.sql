
CREATE OR REPLACE VIEW vw_delivery_state_kpis AS
WITH state_metrics AS (
    SELECT
        state_code,
        COUNT(*) AS total_deliveries,
        SUM(is_late) AS late_deliveries,
        COUNT(*) - SUM(is_late) AS on_time_deliveries
    FROM vw_delivery_performance
    GROUP BY state_code
)
SELECT
    state_code,
    total_deliveries,
    late_deliveries,
    on_time_deliveries,

    ROUND(
        100 * late_deliveries
        / NULLIF(total_deliveries, 0),
        2
    ) AS late_rate_pct,

    ROUND(
        100 * on_time_deliveries
        / NULLIF(total_deliveries, 0),
        2
    ) AS on_time_rate_pct,

    ROUND(
        100 * late_deliveries
        / NULLIF(SUM(late_deliveries) OVER (), 0),
        2
    ) AS share_of_national_late_pct

FROM state_metrics;
