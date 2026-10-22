
-- Enterprise Retail Data Warehouse
-- Add incremental load metrics

ALTER TABLE etl_batch
ADD (
    rows_skipped NUMBER DEFAULT 0 NOT NULL
);
