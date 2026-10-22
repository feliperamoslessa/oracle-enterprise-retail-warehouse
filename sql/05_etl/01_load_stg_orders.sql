
CREATE OR REPLACE PROCEDURE load_stg_orders (
    p_batch_id IN NUMBER
)
AS
    v_status       VARCHAR2(20);
    v_source_count NUMBER;
    v_loaded_count NUMBER;
    v_exists       NUMBER;
BEGIN
    -- Bloqueia o lote durante a execução
    SELECT status
    INTO v_status
    FROM etl_batch
    WHERE batch_id = p_batch_id
    FOR UPDATE NOWAIT;

    IF v_status <> 'STARTED' THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Lote nao esta em STARTED'
        );
    END IF;

    -- Impede a reutilização do lote
    SELECT COUNT(*)
    INTO v_exists
    FROM stg_orders
    WHERE batch_id = p_batch_id;

    IF v_exists > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Lote ja possui registros no staging'
        );
    END IF;

    SELECT COUNT(*)
    INTO v_source_count
    FROM landing_orders;

    IF v_source_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Landing vazia'
        );
    END IF;

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
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    FROM landing_orders;

    v_loaded_count := SQL%ROWCOUNT;

    IF v_loaded_count <> v_source_count THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Falha na reconciliacao'
        );
    END IF;

    UPDATE etl_batch
    SET status = 'SUCCESS',
        rows_loaded = v_loaded_count,
        finished_at = SYSTIMESTAMP,
        error_message = NULL
    WHERE batch_id = p_batch_id;

    COMMIT;
 
EXCEPTION
    WHEN OTHERS THEN
        DECLARE
            v_error_code NUMBER := SQLCODE;
            v_error_message VARCHAR2(4000) := SQLERRM;
        BEGIN
            -- Desfaz alteracoes da carga
            ROLLBACK;

            -- Nao registra reprocessamento bloqueado
            -- como falha operacional
            IF v_error_code NOT IN (-20001, -20002) THEN
                BEGIN
                    log_etl_error(
                        p_batch_id       => p_batch_id,
                        p_procedure_name => 'LOAD_STG_ORDERS',
                        p_error_code     => v_error_code,
                        p_error_message  => v_error_message
                    );
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL; -- Preserva o erro original
                END;
            END IF;

            -- Devolve o erro ao chamador
            RAISE;
        END;
END;
/

