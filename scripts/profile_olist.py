"""Data profiling reproducível dos nove CSVs Olist.

Execução (na raiz do repositório): python scripts/profile_olist.py
Requer: pandas >= 2.0
Não modifica arquivos de origem.
"""
from pathlib import Path
import json
import sys
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / 'data' / 'raw'
OUT = ROOT / 'data' / 'profiling'
FILES = {
    'orders': 'olist_orders_dataset.csv',
    'order_items': 'olist_order_items_dataset.csv',
    'customers': 'olist_customers_dataset.csv',
    'products': 'olist_products_dataset.csv',
    'sellers': 'olist_sellers_dataset.csv',
    'payments': 'olist_order_payments_dataset.csv',
    'reviews': 'olist_order_reviews_dataset.csv',
    'geolocation': 'olist_geolocation_dataset.csv',
    'categories': 'product_category_name_translation.csv',
}
KEYS = {
    'orders': ['order_id'],
    'order_items': ['order_id', 'order_item_id'],
    'customers': ['customer_id'],
    'products': ['product_id'],
    'sellers': ['seller_id'],
    'payments': ['order_id', 'payment_sequential'],
    'categories': ['product_category_name'],
}
RELATIONS = [
    ('orders', 'customer_id', 'customers', 'customer_id'),
    ('order_items', 'order_id', 'orders', 'order_id'),
    ('order_items', 'product_id', 'products', 'product_id'),
    ('order_items', 'seller_id', 'sellers', 'seller_id'),
    ('payments', 'order_id', 'orders', 'order_id'),
    ('reviews', 'order_id', 'orders', 'order_id'),
]
DATE_FIELDS = {
    'orders': ['order_purchase_timestamp', 'order_approved_at', 'order_delivered_carrier_date', 'order_delivered_customer_date', 'order_estimated_delivery_date'],
    'order_items': ['shipping_limit_date'],
    'reviews': ['review_creation_date', 'review_answer_timestamp'],
}


def main():
    missing = [name for name in FILES.values() if not (RAW / name).is_file()]
    if missing:
        raise FileNotFoundError('Faltam CSVs em data/raw/: ' + ', '.join(missing))
    OUT.mkdir(parents=True, exist_ok=True)
    data = {}
    overview = []
    columns = []
    keys = []
    dates = []
    relations = []
    for alias, filename in FILES.items():
        df = pd.read_csv(RAW / filename, dtype='string', encoding='utf-8', low_memory=False)
        # Normaliza strings vazias e espaços preservando as representações originais não vazias.
        df = df.replace(r'^\s*$', pd.NA, regex=True)
        data[alias] = df
        overview.append({'table': alias, 'file': filename, 'rows': len(df), 'columns': len(df.columns), 'duplicate_full_rows': int(df.duplicated().sum())})
        for col in df.columns:
            columns.append({'table': alias, 'column': col, 'rows': len(df), 'nulls': int(df[col].isna().sum()), 'null_pct': round(100 * df[col].isna().mean(), 2) if len(df) else None, 'distinct_non_null': int(df[col].nunique(dropna=True))})
        if alias in KEYS:
            k = KEYS[alias]
            absent = sorted(set(k) - set(df.columns))
            if absent:
                raise ValueError(f'Colunas de chave ausentes em {alias}: {absent}')
            keys.append({'table': alias, 'candidate_key': ' + '.join(k), 'rows_with_null_key': int(df[k].isna().any(axis=1).sum()), 'duplicate_key_rows': int(df.duplicated(subset=k, keep=False).sum())})
        for col in DATE_FIELDS.get(alias, []):
            if col not in df.columns:
                continue
            parsed = pd.to_datetime(df[col], errors='coerce')
            invalid = int((df[col].notna() & parsed.isna()).sum())
            dates.append({'table': alias, 'column': col, 'invalid_non_null_dates': invalid, 'min_date': str(parsed.min()) if parsed.notna().any() else None, 'max_date': str(parsed.max()) if parsed.notna().any() else None})

    for child, child_col, parent, parent_col in RELATIONS:
        left, right = data[child], data[parent]
        nonnull = left[child_col].dropna()
        unmatched = (~nonnull.isin(right[parent_col].dropna())).sum()
        relations.append({'child': child, 'child_column': child_col, 'parent': parent, 'parent_column': parent_col, 'child_null_values': int(left[child_col].isna().sum()), 'unmatched_non_null_rows': int(unmatched)})

    # Reviews podem ter múltiplos registros por order_id; review_id não é tratado como PK sem validação.
    reviews = data['reviews']
    diagnostics = {
        'orders_with_multiple_reviews': int(reviews.groupby('order_id', dropna=True).size().gt(1).sum()),
        'duplicate_review_ids_rows': int(reviews.duplicated(subset=['review_id'], keep=False).sum()),
        'geolocation_duplicate_zip_prefix_rows': int(data['geolocation'].duplicated(subset=['geolocation_zip_code_prefix'], keep=False).sum()),
    }

    for name, rows in [('table_summary', overview), ('column_profile', columns), ('candidate_keys', keys), ('relationships', relations), ('date_profile', dates)]:
        pd.DataFrame(rows).to_csv(OUT / f'{name}.csv', index=False, encoding='utf-8-sig')
    (OUT / 'diagnostics.json').write_text(json.dumps(diagnostics, indent=2, ensure_ascii=False), encoding='utf-8')
    print('\n=== RESUMO DAS TABELAS ===')
    print(pd.DataFrame(overview).to_string(index=False))
    print('\n=== CHAVES CANDIDATAS ===')
    print(pd.DataFrame(keys).to_string(index=False))
    print('\n=== RELACIONAMENTOS ===')
    print(pd.DataFrame(relations).to_string(index=False))
    print('\n=== DIAGNÓSTICOS ===')
    print(json.dumps(diagnostics, indent=2, ensure_ascii=False))
    print(f'\nRelatórios salvos em {OUT}')


if __name__ == '__main__':
    try:
        main()
    except (FileNotFoundError, ValueError) as exc:
        print(f'ERRO: {exc}', file=sys.stderr)
        sys.exit(1)
