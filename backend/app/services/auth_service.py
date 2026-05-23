from __future__ import annotations

from base64 import urlsafe_b64decode, urlsafe_b64encode

from flask import current_app, request

from ..core.errors import ApiError
from .store_service import JsonStore


def login(email: str, password: str) -> dict:
    normalized_email = email.strip().lower()
    if not normalized_email or not password.strip():
        raise ApiError(400, "invalid_credentials", "Email y password son requeridos.")

    store = JsonStore(current_app.config["DATA_FILE"])
    data = store.read()
    user = next(
        (item for item in data["users"] if item["email"].lower() == normalized_email),
        None,
    )

    if user is None:
        raise ApiError(401, "invalid_credentials", "Credenciales invalidas.")
    if user["password"] != password:
        raise ApiError(401, "invalid_credentials", "Credenciales invalidas.")

    return {"token": _build_token(user["id"]), "user": _sanitize_user(user)}


def register_demo_user(email: str, password: str, name: str | None) -> dict:
    normalized_email = email.strip().lower()
    if not normalized_email or not password.strip():
        raise ApiError(400, "invalid_payload", "Email y password son requeridos.")

    store = JsonStore(current_app.config["DATA_FILE"])

    def updater(data: dict) -> dict:
        existing = next(
            (
                item
                for item in data["users"]
                if item["email"].lower() == normalized_email
            ),
            None,
        )
        if existing is not None:
            raise ApiError(409, "user_exists", "El usuario demo ya existe.")

        user = {
            "id": f'usr_{len(data["users"]) + 1:04d}',
            "email": normalized_email,
            "password": password,
            "name": name.strip() if name else "Usuario Demo",
            "phone": None,
            "address": None,
        }
        data["users"].append(user)
        data["_new_user"] = user
        return data

    updated = store.update(updater)
    user = updated.pop("_new_user")
    return {"token": _build_token(user["id"]), "user": _sanitize_user(user)}


def current_user() -> dict:
    authorization = request.headers.get("Authorization", "").strip()
    if not authorization.startswith("Bearer "):
        raise ApiError(401, "unauthorized", "Falta un token Bearer valido.")

    token = authorization.replace("Bearer ", "", 1).strip()
    user_id = _parse_token(token)

    store = JsonStore(current_app.config["DATA_FILE"])
    data = store.read()
    user = next((item for item in data["users"] if item["id"] == user_id), None)
    if user is None:
        raise ApiError(401, "unauthorized", "La sesion ya no es valida.")
    return user


def update_current_user(payload: dict) -> dict:
    user = current_user()
    store = JsonStore(current_app.config["DATA_FILE"])

    def updater(data: dict) -> dict:
        editable = next(item for item in data["users"] if item["id"] == user["id"])
        editable["name"] = payload.get("name")
        editable["phone"] = payload.get("phone")
        editable["address"] = payload.get("address")
        data["_updated_user"] = editable
        return data

    updated = store.update(updater)
    return _sanitize_user(updated.pop("_updated_user"))


def delete_current_user() -> None:
    user = current_user()
    store = JsonStore(current_app.config["DATA_FILE"])

    def updater(data: dict) -> dict:
        data["users"] = [item for item in data["users"] if item["id"] != user["id"]]
        data["orders"] = [
            item for item in data["orders"] if item["user_id"] != user["id"]
        ]
        return data

    store.update(updater)


def _sanitize_user(user: dict) -> dict:
    return {
        "id": user["id"],
        "email": user["email"],
        "name": user.get("name"),
        "phone": user.get("phone"),
        "address": user.get("address"),
    }


def _build_token(user_id: str) -> str:
    encoded = urlsafe_b64encode(user_id.encode("utf-8")).decode("utf-8")
    return encoded.rstrip("=")


def _parse_token(token: str) -> str:
    padding = "=" * (-len(token) % 4)
    try:
        return urlsafe_b64decode(f"{token}{padding}".encode("utf-8")).decode("utf-8")
    except Exception as error:
        raise ApiError(401, "unauthorized", "El token no es valido.") from error
