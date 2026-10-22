CREATE OR REPLACE PROCEDURE log_etl_error (
    p_batch_id       IN NUMBER,
    p_procedure_name IN VARCHAR2,
    p_error_code     IN NUMBER,
    p_error_message  IN VARCHAR2
)
AS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO etl_error_log (
        batch_id,
        procedure_name,
        error_code,
        error_message
    )
    VALUES (
        p_batch_id,
        p_procedure_name,
        p_error_code,
        SUBSTR(p_error_message, 1, 4000)
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
