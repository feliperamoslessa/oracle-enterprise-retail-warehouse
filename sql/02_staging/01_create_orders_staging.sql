
CREATE TABLE etl_batch (
    batch_id NUMBER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    source_name VARCHAR2(100) NOT NULL,
    status VARCHAR2(20) DEFAULT 'STARTED' NOT NULL,
    started_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    finished_at TIMESTAMP,
    rows_loaded NUMBER DEFAULT 0 NOT NULL,
    error_message VARCHAR2(4000),

    CONSTRAINT chk_batch_status
    CHECK (status IN ('STARTED', 'SUCCESS', 'FAILED'))
);

CREATE TABLE landing_orders (
    order_id VARCHAR2(50),
    customer_id VARCHAR2(50),
    order_status VARCHAR2(30),
    order_purchase_timestamp VARCHAR2(30),
    order_approved_at VARCHAR2(30),
    order_delivered_carrier_date VARCHAR2(30),
    order_delivered_customer_date VARCHAR2(30),
    order_estimated_delivery_date VARCHAR2(30)
);

CREATE TABLE stg_orders (
    staging_id NUMBER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    batch_id NUMBER NOT NULL,
    order_id VARCHAR2(50),
    customer_id VARCHAR2(50),
    order_status VARCHAR2(30),
    order_purchase_timestamp VARCHAR2(30),
    order_approved_at VARCHAR2(30),
    order_delivered_carrier_date VARCHAR2(30),
    order_delivered_customer_date VARCHAR2(30),
    order_estimated_delivery_date VARCHAR2(30),
    loaded_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT fk_stg_orders_batch
    FOREIGN KEY (batch_id)
    REFERENCES etl_batch(batch_id)
);
