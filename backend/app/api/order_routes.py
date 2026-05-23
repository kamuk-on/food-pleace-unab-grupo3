from flask import Blueprint, jsonify, request

from ..core.errors import ApiError
from ..services.order_service import (
    cancel_order,
    create_order,
    get_order,
    list_orders,
    update_order,
)

orders_blueprint = Blueprint("orders", __name__, url_prefix="/api/v1/orders")


@orders_blueprint.get("")
def list_orders_route():
    return jsonify({"items": list_orders()})


@orders_blueprint.post("")
def create_order_route():
    payload = request.get_json(silent=True) or {}
    if not isinstance(payload, dict):
        raise ApiError(400, "invalid_payload", "El body debe ser un JSON valido.")

    order = create_order(payload)
    return jsonify(order), 201


@orders_blueprint.get("/<string:order_id>")
def get_order_route(order_id: str):
    return jsonify(get_order(order_id))


@orders_blueprint.put("/<string:order_id>")
def update_order_route(order_id: str):
    payload = request.get_json(silent=True) or {}
    if not isinstance(payload, dict):
        raise ApiError(400, "invalid_payload", "El body debe ser un JSON valido.")

    order = update_order(order_id, payload)
    return jsonify(order)


@orders_blueprint.post("/<string:order_id>/cancel")
def cancel_order_route(order_id: str):
    order = cancel_order(order_id)
    return jsonify(order)
