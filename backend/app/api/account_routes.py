from flask import Blueprint, jsonify, request

from ..core.errors import ApiError
from ..services.auth_service import (
    current_user,
    delete_current_user,
    update_current_user,
)

account_blueprint = Blueprint("account", __name__, url_prefix="/api/v1/account")


@account_blueprint.get("/profile")
def get_profile_route():
    user = current_user()
    return jsonify(
        {
            "id": user["id"],
            "email": user["email"],
            "name": user.get("name"),
            "phone": user.get("phone"),
            "address": user.get("address"),
        }
    )


@account_blueprint.put("/profile")
def update_profile_route():
    payload = request.get_json(silent=True) or {}
    if not isinstance(payload, dict):
        raise ApiError(400, "invalid_payload", "El body debe ser un JSON valido.")

    updated_user = update_current_user(payload)
    return jsonify(updated_user)


@account_blueprint.delete("/profile")
def delete_profile_route():
    delete_current_user()
    return jsonify({"deleted": True})
