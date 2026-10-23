
CREATE TABLE landing_payments (
    order_id VARCHAR2(50),
    payment_sequential VARCHAR2(10),
    payment_type VARCHAR2(30),
    payment_installments VARCHAR2(10),
    payment_value VARCHAR2(30)
);

CREATE TABLE stg_payments (
    staging_id NUMBER
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    batch_id NUMBER NOT NULL,

    order_id VARCHAR2(50) NOT NULL,
    payment_sequential NUMBER NOT NULL,
    payment_type VARCHAR2(30),
    payment_installments NUMBER,
    payment_value NUMBER(15,2),

    loaded_at TIMESTAMP
        DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT fk_stg_payments_batch
        FOREIGN KEY (batch_id)
        REFERENCES etl_batch(batch_id),

    CONSTRAINT uk_stg_payments_order_seq
        UNIQUE (order_id, payment_sequential)
);
