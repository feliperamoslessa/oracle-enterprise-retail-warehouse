
WITH compras_por_cliente AS (
    SELECT
        customer_key,
        COUNT(*) AS total_pedidos
    FROM fact_orders
    GROUP BY customer_key
)
SELECT
    CASE
        WHEN total_pedidos = 1 THEN '1 compra'
        WHEN total_pedidos = 2 THEN '2 compras'
        WHEN total_pedidos = 3 THEN '3 compras'
        WHEN total_pedidos = 4 THEN '4 compras'
        ELSE '5 ou mais compras'
    END AS faixa_compras,
    COUNT(*) AS total_consumidores
FROM compras_por_cliente
GROUP BY
    CASE
        WHEN total_pedidos = 1 THEN '1 compra'
        WHEN total_pedidos = 2 THEN '2 compras'
        WHEN total_pedidos = 3 THEN '3 compras'
        WHEN total_pedidos = 4 THEN '4 compras'
        ELSE '5 ou mais compras'
    END
ORDER BY MIN(total_pedidos);

WITH compras_por_cliente AS (
    SELECT
        customer_key,
        COUNT(*) AS total_pedidos
    FROM fact_orders
    GROUP BY customer_key
)
SELECT
    COUNT(*) AS total_consumidores,

    SUM(
        CASE WHEN total_pedidos = 1
        THEN 1 ELSE 0 END
    ) AS consumidores_uma_compra,

    SUM(
        CASE WHEN total_pedidos > 1
        THEN 1 ELSE 0 END
    ) AS consumidores_recorrentes,

    ROUND(
        100 * SUM(
            CASE WHEN total_pedidos > 1
            THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS taxa_recompra_pct

FROM compras_por_cliente;
