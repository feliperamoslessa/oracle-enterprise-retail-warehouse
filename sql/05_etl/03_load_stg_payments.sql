
CREATE OR REPLACE PROCEDURE load_stg_payments (
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
    -- Lock the batch
    SELECT status, source_name
      INTO v_status, v_source_name
      FROM etl_batch
     WHERE batch_id = p_batch_id
       FOR UPDATE NOWAIT;

    v_batch_found := TRUE;

    IF v_status <> 'STARTED' THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Batch is not in STARTED status'
        );
    END IF;

    IF v_source_name <> 'olist_order_payments_dataset.csv' THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Invalid source for payments ETL'
        );
    END IF;

    -- Validate business keys
    SELECT
        COUNT(*),
        COUNT(DISTINCT
            order_id || ':' || payment_sequential
        )
    INTO
        v_source_count,
        v_unique_count
    FROM landing_payments;

    IF v_source_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Payments landing is empty'
        );
    END IF;

    IF v_source_count <> v_unique_count THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'Null or duplicate payment keys'
        );
    END IF;

    -- Validate numeric conversion and required values
    DECLARE
        v_invalid_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_invalid_count
          FROM landing_payments
         WHERE payment_sequential IS NULL
            OR payment_value IS NULL
            OR VALIDATE_CONVERSION(
                payment_sequential AS NUMBER
            ) = 0
            OR (
                payment_installments IS NOT NULL
                AND VALIDATE_CONVERSION(
                    payment_installments AS NUMBER
                ) = 0
            )
            OR VALIDATE_CONVERSION(
                payment_value AS NUMBER,
                '999999999999D99',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            ) = 0;

        IF v_invalid_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20007,
                'Invalid numeric values in payments landing'
            );
        END IF;
    END;

    -- Incremental insertion
    INSERT INTO stg_payments (
        batch_id,
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    )
    SELECT
        p_batch_id,
        l.order_id,
        TO_NUMBER(l.payment_sequential),
        l.payment_type,
        TO_NUMBER(l.payment_installments),
        TO_NUMBER(
            l.payment_value,
            '999999999999D99',
            'NLS_NUMERIC_CHARACTERS=''.,'''
        )
    FROM landing_payments l
    WHERE NOT EXISTS (
        SELECT 1
          FROM stg_payments s
         WHERE s.order_id = l.order_id
           AND s.payment_sequential =
               TO_NUMBER(l.payment_sequential)
    );

    v_loaded_count := SQL%ROWCOUNT;
    v_skipped_count := v_source_count - v_loaded_count;

    -- Reconciliation
    IF v_loaded_count + v_skipped_count
       <> v_source_count THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Payments reconciliation failed'
        );
    END IF;

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

        IF v_error_code NOT IN (-20001, -20002) THEN
            BEGIN
                log_etl_error(
                    p_batch_id =>
                        CASE
                            WHEN v_batch_found THEN p_batch_id
                            ELSE NULL
                        END,
                    p_procedure_name => 'LOAD_STG_PAYMENTS',
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
