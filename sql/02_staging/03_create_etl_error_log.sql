CREATE TABLE etl_error_log (
    error_id NUMBER
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    batch_id NUMBER,

    procedure_name VARCHAR2(100) NOT NULL,

    error_code NUMBER,

    error_message VARCHAR2(4000),

    error_timestamp TIMESTAMP
        DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT fk_error_batch
        FOREIGN KEY (batch_id)
        REFERENCES etl_batch(batch_id)
);
