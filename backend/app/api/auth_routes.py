from flask import Blueprint, jsonify, request

from ..core.errors import ApiError
from ..services.auth_service import login, register_demo_user

auth_blueprint = Blueprint("auth", __name__, url_prefix="/api/v1/auth")


@auth_blueprint.post("/login")
def login_route():
    payload = request.get_json(silent=True) or {}
    if not isinstance(payload, dict):
        raise ApiError(400, "invalid_payload", "El body debe ser un JSON valido.")

    response = login(
        email=str(payload.get("email", "")),
        password=str(payload.get("password", "")),
    )
    return jsonify(response)


@auth_blueprint.post("/register-demo")
def register_demo_route():
    payload = request.get_json(silent=True) or {}
    if not isinstance(payload, dict):
        raise ApiError(400, "invalid_payload", "El body debe ser un JSON valido.")

    response = register_demo_user(
        email=str(payload.get("email", "")),
        password=str(payload.get("password", "")),
        name=payload.get("name"),
    )
    return jsonify(response), 201
