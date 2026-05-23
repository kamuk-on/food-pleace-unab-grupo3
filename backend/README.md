# FoodPlease Backend

Backend Flask para la API REST de FoodPlease.

## Estructura

```text
backend/
  app/
    api/
    core/
    services/
  data/
  run.py
  requirements.txt
```

## Requisitos

- Python 3.11 o superior.
- `pip` disponible en el entorno.

## Instalacion

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

## Ejecucion

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python run.py
```

La API queda disponible por defecto en `http://127.0.0.1:5000`.

## Variables de entorno

- `FLASK_ENV`: `development` o `production`.
- `FOODPLEASE_API_HOST`: host del servidor.
- `FOODPLEASE_API_PORT`: puerto HTTP.
- `FOODPLEASE_ALLOWED_ORIGINS`: lista separada por comas para CORS o `*`.
- `FOODPLEASE_DATA_FILE`: ruta del archivo JSON que persiste usuarios, menu y pedidos.

## Endpoints principales

- `GET /api/v1/health`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register-demo`
- `GET /api/v1/account/profile`
- `PUT /api/v1/account/profile`
- `DELETE /api/v1/account/profile`
- `GET /api/v1/menu/categories`
- `GET /api/v1/menu/products`
- `POST /api/v1/orders`
- `GET /api/v1/orders`
- `GET /api/v1/orders/<order_id>`
- `PUT /api/v1/orders/<order_id>`
- `POST /api/v1/orders/<order_id>/cancel`

## Notas de la implementacion

- La persistencia es demo y usa un archivo JSON para poder avanzar sin una base de datos separada.
- El login devuelve un token Bearer derivado del usuario para conectar la tarea 8 sin agregar JWT todavia.
- Los pedidos solo se pueden editar en estado `pending` y cancelar en `pending` o `preparing`.