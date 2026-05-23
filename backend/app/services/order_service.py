from __future__ import annotations

from datetime import datetime, timezone

from flask import current_app

from ..core.errors import ApiError
from .auth_service import current_user
from .menu_service import get_product_map
from .store_service import JsonStore

EDITABLE_STATUSES = {"pending"}
CANCELLABLE_STATUSES = {"pending", "preparing"}
VALID_STATUSES = {"pending", "preparing", "ready", "delivered", "cancelled"}


def list_orders() -> list[dict]:
    user = current_user()
    store = JsonStore(current_app.config["DATA_FILE"])
    data = store.read()
    orders = [item for item in data["orders"] if item["user_id"] == user["id"]]
    return sorted(orders, key=lambda item: item["created_at"], reverse=True)


def get_order(order_id: str) -> dict:
    user = current_user()
    store = JsonStore(current_app.config["DATA_FILE"])
    data = store.read()
    order = next(
        (
            item
            for item in data["orders"]
            if item["id"] == order_id and item["user_id"] == user["id"]
        ),
        None,
    )
    if order is None:
        raise ApiError(404, "order_not_found", "Pedido no encontrado.")
    return order


def create_order(payload: dict) -> dict:
    user = current_user()
    items = _normalize_items(payload.get("items"))
    notes = payload.get("notes")
    delivery_address = payload.get("delivery_address") or user.get("address")

    if not delivery_address:
        raise ApiError(
            400,
            "invalid_payload",
            "delivery_address es requerido si el usuario no tiene direccion.",
        )

    store = JsonStore(current_app.config["DATA_FILE"])

    def updater(data: dict) -> dict:
        product_map = {item["id"]: item for item in data["menu_products"]}
        order_items, total = _build_order_items(items, product_map)
        order = {
            "id": _next_order_id(data["orders"]),
            "user_id": user["id"],
            "items": order_items,
            "total": total,
            "status": "pending",
            "created_at": _now_iso(),
            "delivery_address": delivery_address,
            "notes": notes,
        }
        data["orders"].append(order)
        data["_new_order"] = order
        return data

    updated = store.update(updater)
    return updated.pop("_new_order")


def update_order(order_id: str, payload: dict) -> dict:
    user = current_user()
    items = _normalize_items(payload.get("items"))
    delivery_address = payload.get("delivery_address")
    notes = payload.get("notes")

    store = JsonStore(current_app.config["DATA_FILE"])

    def updater(data: dict) -> dict:
        order = next(
            (
                item
                for item in data["orders"]
                if item["id"] == order_id and item["user_id"] == user["id"]
            ),
            None,
        )
        if order is None:
            raise ApiError(404, "order_not_found", "Pedido no encontrado.")
        if order["status"] not in EDITABLE_STATUSES:
            raise ApiError(
                409, "order_not_editable", "El pedido ya no se puede editar."
            )

        product_map = {item["id"]: item for item in data["menu_products"]}
        order_items, total = _build_order_items(items, product_map)

        order["items"] = order_items
        order["total"] = total
        order["delivery_address"] = delivery_address or order.get("delivery_address")
        order["notes"] = notes
        data["_updated_order"] = order
        return data

    updated = store.update(updater)
    return updated.pop("_updated_order")


def cancel_order(order_id: str) -> dict:
    user = current_user()
    store = JsonStore(current_app.config["DATA_FILE"])

    def updater(data: dict) -> dict:
        order = next(
            (
                item
                for item in data["orders"]
                if item["id"] == order_id and item["user_id"] == user["id"]
            ),
            None,
        )
        if order is None:
            raise ApiError(404, "order_not_found", "Pedido no encontrado.")
        if order["status"] not in CANCELLABLE_STATUSES:
            raise ApiError(
                409, "order_not_cancellable", "El pedido no se puede cancelar."
            )

        order["status"] = "cancelled"
        data["_cancelled_order"] = order
        return data

    updated = store.update(updater)
    return updated.pop("_cancelled_order")


def _normalize_items(items: object) -> list[dict]:
    if not isinstance(items, list) or not items:
        raise ApiError(
            400, "invalid_payload", "items debe contener al menos un producto."
        )

    normalized: list[dict] = []
    for item in items:
        if not isinstance(item, dict):
            raise ApiError(400, "invalid_payload", "Cada item debe ser un objeto.")
        product_id = str(item.get("product_id", "")).strip()
        quantity = item.get("quantity")
        if not product_id:
            raise ApiError(400, "invalid_payload", "Cada item requiere product_id.")
        if not isinstance(quantity, int) or quantity <= 0:
            raise ApiError(400, "invalid_payload", "Cada item requiere quantity > 0.")
        normalized.append({"product_id": product_id, "quantity": quantity})
    return normalized


def _build_order_items(
    items: list[dict], product_map: dict[str, dict]
) -> tuple[list[dict], float]:
    order_items: list[dict] = []
    total = 0.0
    for item in items:
        product = product_map.get(item["product_id"])
        if product is None:
            raise ApiError(
                400, "invalid_payload", f"Producto {item['product_id']} no existe."
            )
        if not product.get("available", True):
            raise ApiError(
                409,
                "product_unavailable",
                f"Producto {item['product_id']} no disponible.",
            )

        unit_price = float(product["price"])
        quantity = item["quantity"]
        order_items.append(
            {
                "product_id": product["id"],
                "product_name": product["name"],
                "unit_price": unit_price,
                "quantity": quantity,
            }
        )
        total += unit_price * quantity

    return order_items, round(total, 2)


def _next_order_id(orders: list[dict]) -> str:
    if not orders:
        return "FP-000001"

    numbers: list[int] = []
    for order in orders:
        try:
            numbers.append(int(order["id"].split("-")[-1]))
        except Exception:
            continue
    next_number = (max(numbers) if numbers else 0) + 1
    return f"FP-{next_number:06d}"


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
