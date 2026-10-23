
CREATE OR REPLACE PROCEDURE load_stg_customers (
    p_batch_id IN NUMBER
)
AS
    v_status        VARCHAR2(20);
    v_source_name   VARCHAR2(100);
    v_source_count  NUMBER;
    v_unique_count  NUMBER;
    v_loaded_count  NUMBER;
    v_skipped_count NUMBER;
    v_batch_found   BOOLEAN := FALSE;
    v_error_code    NUMBER;
    v_error_message VARCHAR2(4000);
BEGIN
    -- 1. Lock the batch
    SELECT status, source_name
      INTO v_status, v_source_name
      FROM etl_batch
     WHERE batch_id = p_batch_id
       FOR UPDATE NOWAIT;

    v_batch_found := TRUE;

    -- 2. Validate batch
    IF v_status <> 'STARTED' THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Batch is not in STARTED status'
        );
    END IF;

    IF v_source_name <> 'olist_customers_dataset.csv' THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Invalid source for customers ETL'
        );
    END IF;

    -- 3. Validate landing
    SELECT COUNT(*),
           COUNT(DISTINCT customer_id)
      INTO v_source_count, v_unique_count
      FROM landing_customers;

    IF v_source_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Customers landing is empty'
        );
    END IF;

    IF v_source_count <> v_unique_count THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'Null or duplicate customer IDs'
        );
    END IF;

    -- 4. Incremental insert
    INSERT INTO stg_customers (
        batch_id,
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    )
    SELECT
        p_batch_id,
        l.customer_id,
        l.customer_unique_id,
        l.customer_zip_code_prefix,
        l.customer_city,
        l.customer_state
    FROM landing_customers l
    WHERE NOT EXISTS (
        SELECT 1
        FROM stg_customers s
        WHERE s.customer_id = l.customer_id
    );

    v_loaded_count := SQL%ROWCOUNT;
    v_skipped_count := v_source_count - v_loaded_count;

    -- 5. Reconciliation
    IF v_loaded_count + v_skipped_count
       <> v_source_count THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Customers reconciliation failed'
        );
    END IF;

    -- 6. Update batch
    UPDATE etl_batch
       SET status = 'SUCCESS',
           rows_loaded = v_loaded_count,
           rows_skipped = v_skipped_count,
           finished_at = SYSTIMESTAMP,
           error_message = NULL
     WHERE batch_id = p_batch_id;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        v_error_code := SQLCODE;
        v_error_message := SQLERRM;

        ROLLBACK;

        IF v_error_code <> -20001 THEN
            BEGIN
                log_etl_error(
                    p_batch_id =>
                        CASE
                            WHEN v_batch_found THEN p_batch_id
                            ELSE NULL
                        END,
                    p_procedure_name => 'LOAD_STG_CUSTOMERS',
                    p_error_code => v_error_code,
                    p_error_message => v_error_message
                );
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;

            IF v_batch_found THEN
                BEGIN
                    UPDATE etl_batch
                       SET status = 'FAILED',
                           finished_at = SYSTIMESTAMP,
                           error_message = v_error_message
                     WHERE batch_id = p_batch_id
                       AND status = 'STARTED';

                    COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK;
                END;
            END IF;
        END IF;

        RAISE;
END;
/
