from __future__ import annotations

from flask import current_app

from .store_service import JsonStore


def get_categories() -> list[dict]:
    store = JsonStore(current_app.config["DATA_FILE"])
    data = store.read()
    return sorted(data["menu_categories"], key=lambda item: item["name"])


def get_products(category_id: str | None = None) -> list[dict]:
    store = JsonStore(current_app.config["DATA_FILE"])
    data = store.read()
    products = data["menu_products"]
    if category_id:
        products = [item for item in products if item["category_id"] == category_id]
    return sorted(products, key=lambda item: item["name"])


def get_product_map() -> dict[str, dict]:
    store = JsonStore(current_app.config["DATA_FILE"])
    data = store.read()
    return {item["id"]: item for item in data["menu_products"]}
