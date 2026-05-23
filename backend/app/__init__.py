from flask import Flask
from flask_cors import CORS

from .api.account_routes import account_blueprint
from .api.auth_routes import auth_blueprint
from .api.health_routes import health_blueprint
from .api.menu_routes import menu_blueprint
from .api.order_routes import orders_blueprint
from .core.config import Config
from .core.errors import register_error_handlers
from .services.store_service import JsonStore


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config())

    _configure_cors(app)
    _configure_services(app)
    _register_blueprints(app)
    register_error_handlers(app)

    return app


def _configure_cors(app: Flask) -> None:
    CORS(
        app,
        resources={r"/api/*": {"origins": app.config["ALLOWED_ORIGINS"]}},
        supports_credentials=False,
    )


def _configure_services(app: Flask) -> None:
    JsonStore(app.config["DATA_FILE"])


def _register_blueprints(app: Flask) -> None:
    app.register_blueprint(health_blueprint)
    app.register_blueprint(auth_blueprint)
    app.register_blueprint(account_blueprint)
    app.register_blueprint(menu_blueprint)
    app.register_blueprint(orders_blueprint)
