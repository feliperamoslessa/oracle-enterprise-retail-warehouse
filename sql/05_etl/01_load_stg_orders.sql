
CREATE OR REPLACE PROCEDURE load_stg_orders (
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
    -- 1. Lock the batch to prevent concurrent runs
    SELECT status, source_name
      INTO v_status, v_source_name
      FROM etl_batch
     WHERE batch_id = p_batch_id
       FOR UPDATE NOWAIT;

    v_batch_found := TRUE;

    -- 2. Validate batch state and source
    IF v_status <> 'STARTED' THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Batch is not in STARTED status'
        );
    END IF;

    IF v_source_name <> 'olist_orders_dataset.csv' THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Invalid source for orders ETL'
        );
    END IF;

    -- 3. Count source records
    SELECT COUNT(*),
           COUNT(DISTINCT order_id)
      INTO v_source_count, v_unique_count
      FROM landing_orders;

    IF v_source_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Landing table is empty'
        );
    END IF;

    -- Prevent duplicate or null source keys
    IF v_source_count <> v_unique_count THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'Landing contains null or duplicate order IDs'
        );
    END IF;

    -- 4. Insert new orders only
    INSERT INTO stg_orders (
        batch_id,
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    )
    SELECT
        p_batch_id,
        l.order_id,
        l.customer_id,
        l.order_status,
        l.order_purchase_timestamp,
        l.order_approved_at,
        l.order_delivered_carrier_date,
        l.order_delivered_customer_date,
        l.order_estimated_delivery_date
    FROM landing_orders l
    WHERE NOT EXISTS (
        SELECT 1
        FROM stg_orders s
        WHERE s.order_id = l.order_id
    );

    v_loaded_count := SQL%ROWCOUNT;

    -- 5. Calculate skipped rows
    v_skipped_count := v_source_count - v_loaded_count;

    IF v_loaded_count + v_skipped_count
       <> v_source_count THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Batch reconciliation failed'
        );
    END IF;

    -- 6. Mark batch as successful
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

        -- Already completed batches are not operational errors
        IF v_error_code <> -20001 THEN

            BEGIN
                log_etl_error(
                    p_batch_id =>
                        CASE
                            WHEN v_batch_found THEN p_batch_id
                            ELSE NULL
                        END,
                    p_procedure_name => 'LOAD_STG_ORDERS',
                    p_error_code => v_error_code,
                    p_error_message => v_error_message
                );
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;

            -- Mark an existing STARTED batch as FAILED
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
