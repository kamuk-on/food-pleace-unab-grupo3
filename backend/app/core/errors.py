from __future__ import annotations

from dataclasses import dataclass

from flask import Flask, jsonify


@dataclass(slots=True)
class ApiError(Exception):
    status_code: int
    code: str
    message: str
    details: dict | None = None


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(ApiError)
    def handle_api_error(error: ApiError):
        payload = {
            "error": {
                "code": error.code,
                "message": error.message,
                "details": error.details or {},
            }
        }
        return jsonify(payload), error.status_code

    @app.errorhandler(404)
    def handle_not_found(_error):
        return (
            jsonify(
                {
                    "error": {
                        "code": "not_found",
                        "message": "Recurso no encontrado.",
                        "details": {},
                    }
                }
            ),
            404,
        )

    @app.errorhandler(405)
    def handle_method_not_allowed(_error):
        return (
            jsonify(
                {
                    "error": {
                        "code": "method_not_allowed",
                        "message": "Metodo HTTP no permitido.",
                        "details": {},
                    }
                }
            ),
            405,
        )

    @app.errorhandler(Exception)
    def handle_unexpected_error(_error):
        return (
            jsonify(
                {
                    "error": {
                        "code": "internal_error",
                        "message": "Ocurrio un error interno.",
                        "details": {},
                    }
                }
            ),
            500,
        )
