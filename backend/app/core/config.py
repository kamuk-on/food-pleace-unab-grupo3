import os
from pathlib import Path


class Config:
    def __init__(self) -> None:
        backend_root = Path(__file__).resolve().parents[2]
        data_file = os.getenv(
            "FOODPLEASE_DATA_FILE",
            str(backend_root / "data" / "store.json"),
        )

        self.DEBUG = os.getenv("FLASK_ENV", "development") == "development"
        self.API_HOST = os.getenv("FOODPLEASE_API_HOST", "127.0.0.1")
        self.API_PORT = int(os.getenv("FOODPLEASE_API_PORT", "5000"))
        allowed_origins = os.getenv("FOODPLEASE_ALLOWED_ORIGINS", "*")
        self.ALLOWED_ORIGINS = (
            "*"
            if allowed_origins.strip() == "*"
            else [
                origin.strip()
                for origin in allowed_origins.split(",")
                if origin.strip()
            ]
        )
        self.DATA_FILE = data_file
