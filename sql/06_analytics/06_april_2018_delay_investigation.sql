
-- =====================================================
-- Enterprise Retail Data Warehouse
-- Investigation: April 2018 Delivery Delay Spike
--
-- Comparison: March 2018 vs April 2018
-- Grain: one delivered order
-- Late definition: delivered after estimated calendar day
--
-- Analytical notes:
-- - Absolute delay changes depend on delivery volume.
-- - Rate changes measure proportional deterioration.
-- - State contributions use the national NET change.
-- - Observational results do not prove causality.
-- =====================================================

WITH entregas AS (
    SELECT
        c.customer_state AS estado,
        TRUNC(
            CAST(f.delivered_customer_at AS DATE),
            'MM'
        ) AS mes_entrega,

        CASE
            WHEN TRUNC(CAST(f.delivered_customer_at AS DATE))
               > TRUNC(CAST(f.estimated_delivery_at AS DATE))
            THEN 1
            ELSE 0
        END AS atrasada

    FROM fact_orders f

    JOIN stg_orders o
        ON f.order_id = o.order_id

    JOIN stg_customers c
        ON o.customer_id = c.customer_id

    WHERE f.order_status = 'delivered'
      AND f.delivered_customer_at IS NOT NULL
      AND f.estimated_delivery_at IS NOT NULL
      AND f.delivered_customer_at >=
          TIMESTAMP '2018-03-01 00:00:00'
      AND f.delivered_customer_at <
          TIMESTAMP '2018-05-01 00:00:00'
),
resumo_estados AS (
    SELECT
        estado,

        SUM(
            CASE
                WHEN mes_entrega = DATE '2018-03-01'
                THEN 1 ELSE 0
            END
        ) AS entregas_marco,

        SUM(
            CASE
                WHEN mes_entrega = DATE '2018-03-01'
                THEN atrasada ELSE 0
            END
        ) AS atrasos_marco,

        SUM(
            CASE
                WHEN mes_entrega = DATE '2018-04-01'
                THEN 1 ELSE 0
            END
        ) AS entregas_abril,

        SUM(
            CASE
                WHEN mes_entrega = DATE '2018-04-01'
                THEN atrasada ELSE 0
            END
        ) AS atrasos_abril

    FROM entregas
    GROUP BY estado
)
SELECT
    estado,
    entregas_marco,
    atrasos_marco,
    entregas_abril,
    atrasos_abril,

    atrasos_abril - atrasos_marco
        AS variacao_atrasos,

    ROUND(
        100 * atrasos_marco
        / NULLIF(entregas_marco, 0),
        2
    ) AS taxa_marco_pct,

    ROUND(
        100 * atrasos_abril
        / NULLIF(entregas_abril, 0),
        2
    ) AS taxa_abril_pct

FROM resumo_estados
ORDER BY variacao_atrasos DESC, estado;

SELECT
    TO_CHAR(
        TRUNC(CAST(delivered_customer_at AS DATE), 'MM'),
        'YYYY-MM'
    ) AS mes,

    COUNT(*) AS total_entregas,

    SUM(
        CASE
            WHEN TRUNC(CAST(delivered_customer_at AS DATE))
               > TRUNC(CAST(estimated_delivery_at AS DATE))
            THEN 1 ELSE 0
        END
    ) AS atrasos

FROM fact_orders

WHERE order_status = 'delivered'
  AND delivered_customer_at IS NOT NULL
  AND estimated_delivery_at IS NOT NULL
  AND delivered_customer_at >=
      TIMESTAMP '2018-03-01 00:00:00'
  AND delivered_customer_at <
      TIMESTAMP '2018-05-01 00:00:00'

GROUP BY
    TRUNC(CAST(delivered_customer_at AS DATE), 'MM')

ORDER BY mes;
