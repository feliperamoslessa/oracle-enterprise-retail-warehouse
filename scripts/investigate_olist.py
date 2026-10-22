
from pathlib import Path
import pandas as pd

RAW = Path("data/raw")

def load(filename):
    return pd.read_csv(
        RAW / filename,
        dtype="string"
    )

orders = load("olist_orders_dataset.csv")
items = load("olist_order_items_dataset.csv")
payments = load("olist_order_payments_dataset.csv")
products = load("olist_products_dataset.csv")
categories = load(
    "product_category_name_translation.csv"
)

# 1. Pedidos sem itens e sem pagamentos
no_items = orders[
    ~orders["order_id"].isin(items["order_id"])
]

no_payments = orders[
    ~orders["order_id"].isin(payments["order_id"])
]

print("\nPEDIDOS SEM ITENS")
print(no_items["order_status"].value_counts())

print("\nPEDIDOS SEM PAGAMENTO")
print(no_payments["order_status"].value_counts())

# 2. Categorias sem traducao
missing_translation = (
    set(products["product_category_name"].dropna())
    - set(categories["product_category_name"].dropna())
)

print("\nCATEGORIAS SEM TRADUCAO")
print(sorted(missing_translation))

# 3. Limites de envio fora de 2018
items["shipping_limit_date"] = pd.to_datetime(
    items["shipping_limit_date"],
    errors="coerce"
)

outliers = items[
    items["shipping_limit_date"]
    >= pd.Timestamp("2019-01-01")
]

print("\nLIMITES DE ENVIO A PARTIR DE 2019")
print("Quantidade:", len(outliers))
print(
    outliers[
        ["order_id", "order_item_id", "shipping_limit_date"]
    ].head(10).to_string(index=False)
)
