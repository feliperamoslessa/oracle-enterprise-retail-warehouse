
CREATE TABLE dim_customer (
    customer_key NUMBER
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    customer_unique_id VARCHAR2(50)
        NOT NULL,

    created_at TIMESTAMP
        DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT uk_dim_customer_unique_id
        UNIQUE (customer_unique_id)
);

INSERT INTO dim_customer (
    customer_unique_id
)
SELECT DISTINCT
    s.customer_unique_id
FROM stg_customers s
WHERE s.customer_unique_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM dim_customer d
      WHERE d.customer_unique_id =
            s.customer_unique_id
  );

COMMIT;
