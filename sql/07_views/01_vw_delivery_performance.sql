
CREATE OR REPLACE VIEW vw_delivery_performance AS
SELECT
    f.order_id,
    f.customer_key,
    c.customer_state AS state_code,

    f.purchase_at,
    f.delivered_customer_at,
    f.estimated_delivery_at,

    TRUNC(CAST(f.delivered_customer_at AS DATE))
      - TRUNC(CAST(f.estimated_delivery_at AS DATE))
      AS delivery_days_difference,

    CASE
        WHEN TRUNC(CAST(f.delivered_customer_at AS DATE))
           > TRUNC(CAST(f.estimated_delivery_at AS DATE))
        THEN 1
        ELSE 0
    END AS is_late,

    TRUNC(
        CAST(f.delivered_customer_at AS DATE),
        'MM'
    ) AS delivery_month

FROM fact_orders f

JOIN stg_orders o
    ON f.order_id = o.order_id

JOIN stg_customers c
    ON o.customer_id = c.customer_id

WHERE f.order_status = 'delivered'
  AND f.delivered_customer_at IS NOT NULL
  AND f.estimated_delivery_at IS NOT NULL;
