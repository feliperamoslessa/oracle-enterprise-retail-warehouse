
CREATE TABLE map_customer_keys (
    customer_id VARCHAR2(50) NOT NULL,
    customer_key NUMBER NOT NULL,

    mapped_at TIMESTAMP
        DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT pk_map_customer_keys
        PRIMARY KEY (customer_id),

    CONSTRAINT fk_map_customer_dim
        FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key)
);

INSERT INTO map_customer_keys (
    customer_id,
    customer_key
)
SELECT
    s.customer_id,
    d.customer_key
FROM stg_customers s
JOIN dim_customer d
    ON s.customer_unique_id = d.customer_unique_id
WHERE NOT EXISTS (
    SELECT 1
    FROM map_customer_keys m
    WHERE m.customer_id = s.customer_id
);

COMMIT;
