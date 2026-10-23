
CREATE TABLE fact_orders (
    order_key NUMBER
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    order_id VARCHAR2(50) NOT NULL,
    customer_key NUMBER NOT NULL,
    order_status VARCHAR2(30),

    purchase_at TIMESTAMP NOT NULL,
    approved_at TIMESTAMP,
    delivered_carrier_at TIMESTAMP,
    delivered_customer_at TIMESTAMP,
    estimated_delivery_at TIMESTAMP,

    created_at TIMESTAMP
        DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT uk_fact_orders_order_id
        UNIQUE (order_id),

    CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key)
);

INSERT INTO fact_orders (
    order_id,
    customer_key,
    order_status,
    purchase_at,
    approved_at,
    delivered_carrier_at,
    delivered_customer_at,
    estimated_delivery_at
)
SELECT
    o.order_id,
    m.customer_key,
    o.order_status,

    TO_TIMESTAMP(
        o.order_purchase_timestamp,
        'YYYY-MM-DD HH24:MI:SS'
    ),

    TO_TIMESTAMP(
        o.order_approved_at,
        'YYYY-MM-DD HH24:MI:SS'
    ),

    TO_TIMESTAMP(
        o.order_delivered_carrier_date,
        'YYYY-MM-DD HH24:MI:SS'
    ),

    TO_TIMESTAMP(
        o.order_delivered_customer_date,
        'YYYY-MM-DD HH24:MI:SS'
    ),

    TO_TIMESTAMP(
        o.order_estimated_delivery_date,
        'YYYY-MM-DD HH24:MI:SS'
    )

FROM stg_orders o
JOIN map_customer_keys m
    ON o.customer_id = m.customer_id

WHERE NOT EXISTS (
    SELECT 1
    FROM fact_orders f
    WHERE f.order_id = o.order_id
);

COMMIT;
