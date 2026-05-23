from __future__ import annotations

import json
import threading
from copy import deepcopy
from pathlib import Path
from typing import Any, Callable


def _default_data() -> dict[str, Any]:
    return {
        "users": [
            {
                "id": "usr_demo_1",
                "email": "demo@foodplease.app",
                "password": "demo123",
                "name": "Usuario Demo",
                "phone": "+56 9 5555 0000",
                "address": "Av. FoodPlease 123, Santiago",
            }
        ],
        "menu_categories": [
            {"id": "cat_pizzas", "name": "Pizzas", "icon": "local_pizza"},
            {"id": "cat_burgers", "name": "Hamburguesas", "icon": "lunch_dining"},
            {"id": "cat_drinks", "name": "Bebidas", "icon": "local_drink"},
        ],
        "menu_products": [
            {
                "id": "prd_pizza_classic",
                "name": "Pizza clasica",
                "description": "Salsa de tomate, mozzarella y oregano fresco.",
                "price": 9900,
                "category_id": "cat_pizzas",
                "category_name": "Pizzas",
                "image_url": "https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80",
                "available": True,
            },
            {
                "id": "prd_burger_double",
                "name": "Hamburguesa doble",
                "description": "Doble carne, queso cheddar y vegetales frescos.",
                "price": 10900,
                "category_id": "cat_burgers",
                "category_name": "Hamburguesas",
                "image_url": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80",
                "available": True,
            },
            {
                "id": "prd_combo_chef",
                "name": "Combo del chef",
                "description": "Plato principal, acompanamiento y bebida.",
                "price": 11900,
                "category_id": "cat_drinks",
                "category_name": "Bebidas",
                "image_url": "https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=800&q=80",
                "available": True,
            },
        ],
        "orders": [
            {
                "id": "FP-001245",
                "user_id": "usr_demo_1",
                "items": [
                    {
                        "product_id": "prd_pizza_classic",
                        "product_name": "Pizza clasica",
                        "unit_price": 9900,
                        "quantity": 2,
                    }
                ],
                "total": 19800,
                "status": "pending",
                "created_at": "2026-05-22T10:00:00Z",
                "delivery_address": "Av. FoodPlease 123, Santiago",
                "notes": "Sin cebolla",
            }
        ],
    }


class JsonStore:
    _instances: dict[str, "JsonStore"] = {}

    def __new__(cls, file_path: str) -> "JsonStore":
        if file_path not in cls._instances:
            instance = super().__new__(cls)
            instance._initialized = False
            cls._instances[file_path] = instance
        return cls._instances[file_path]

    def __init__(self, file_path: str) -> None:
        if getattr(self, "_initialized", False):
            return

        self._file_path = Path(file_path)
        self._lock = threading.Lock()
        self._file_path.parent.mkdir(parents=True, exist_ok=True)
        if not self._file_path.exists():
            self._write(_default_data())
        self._initialized = True

    def read(self) -> dict[str, Any]:
        with self._lock:
            return deepcopy(self._read())

    def update(
        self, updater: Callable[[dict[str, Any]], dict[str, Any]]
    ) -> dict[str, Any]:
        with self._lock:
            data = self._read()
            updated = updater(deepcopy(data))
            self._write(_strip_private_keys(updated))
            return deepcopy(updated)

    def _read(self) -> dict[str, Any]:
        return json.loads(self._file_path.read_text(encoding="utf-8"))

    def _write(self, data: dict[str, Any]) -> None:
        self._file_path.write_text(
            json.dumps(data, indent=2, ensure_ascii=True),
            encoding="utf-8",
        )


def _strip_private_keys(data: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in data.items() if not key.startswith("_")}
