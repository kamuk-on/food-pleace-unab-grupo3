from flask import Blueprint, jsonify

health_blueprint = Blueprint("health", __name__, url_prefix="/api/v1")


@health_blueprint.get("/health")
def health_check():
    return jsonify({"status": "ok", "service": "foodplease-backend"})
