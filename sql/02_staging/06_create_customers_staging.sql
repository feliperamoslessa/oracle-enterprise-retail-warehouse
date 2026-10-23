
CREATE TABLE landing_customers (
    customer_id VARCHAR2(50),
    customer_unique_id VARCHAR2(50),
    customer_zip_code_prefix VARCHAR2(10),
    customer_city VARCHAR2(100),
    customer_state VARCHAR2(2)
);

CREATE TABLE stg_customers (
    staging_id NUMBER
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    batch_id NUMBER NOT NULL,

    customer_id VARCHAR2(50) NOT NULL,
    customer_unique_id VARCHAR2(50),
    customer_zip_code_prefix VARCHAR2(10),
    customer_city VARCHAR2(100),
    customer_state VARCHAR2(2),

    loaded_at TIMESTAMP
        DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT fk_stg_customers_batch
        FOREIGN KEY (batch_id)
        REFERENCES etl_batch(batch_id),

    CONSTRAINT uk_stg_customers_id
        UNIQUE (customer_id)
);
