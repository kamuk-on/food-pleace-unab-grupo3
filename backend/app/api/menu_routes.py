from flask import Blueprint, jsonify, request

from ..services.menu_service import get_categories, get_products

menu_blueprint = Blueprint("menu", __name__, url_prefix="/api/v1/menu")


@menu_blueprint.get("/categories")
def categories_route():
    return jsonify({"items": get_categories()})


@menu_blueprint.get("/products")
def products_route():
    category_id = request.args.get("category_id")
    return jsonify({"items": get_products(category_id=category_id)})
