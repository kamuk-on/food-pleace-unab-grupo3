# FoodPlease Flutter

Aplicacion movil de delivery construida con Flutter y respaldada por una API REST en Flask. El proyecto ya incluye autenticacion, menu, carrito, pedidos, cuenta, persistencia local y mejoras base de UX y accesibilidad.

## Que incluye el proyecto

- App Flutter con arquitectura modular por features y capas.
- Navegacion con `go_router` para login, menu, carrito, pedidos, detalle y cuenta.
- Estado global con controladores observables para sesion, carrito, pedidos y perfil.
- Persistencia local con SQLite para sesion, catalogo cacheado, carrito e historial.
- Backend Flask en `backend/` con API REST versionada en `/api/v1`.
- Reglas de negocio compartidas para cantidades minimas, totales, edicion y cancelacion de pedidos.
- Feedback visual consistente con loaders, snackbars, confirmaciones y semantica basica de accesibilidad.

## Stack tecnico

### Frontend

- Flutter
- Dart SDK `^3.12.0`
- `go_router`
- `http`
- `sqflite`
- `shared_preferences`

### Backend

- Python 3.11 o superior
- Flask
- Persistencia demo en archivo JSON

## Estructura principal

```text
lib/
	app/
		router/
	core/
		config/
		di/
		theme/
		widgets/
	features/
		auth/
		menu/
		cart/
		orders/
		account/
		shared/
backend/
	app/
		api/
		core/
		services/
	data/
	run.py
```

## Requisitos

Antes de iniciar, asegurate de tener instalado:

- Flutter SDK
- Dart SDK compatible con Flutter actual
- Python 3.11 o superior
- `pip`

Puedes validar el entorno con:

```powershell
flutter doctor
python --version
```

## Como iniciar el proyecto

### 1. Instalar dependencias de Flutter

Desde la raiz del proyecto:

```powershell
flutter pub get
```

### 2. Levantar el backend Flask

En una terminal nueva:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
Copy-Item .env.example .env
.\.venv\Scripts\python run.py
```

Si PowerShell bloquea `Activate.ps1`, no necesitas activar el entorno virtual para ejecutar el backend. Los comandos anteriores usan directamente el Python de `.venv`.

Si igual quieres activarlo de forma temporal en la sesion actual, puedes usar:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

Tambien puedes evitar PowerShell y usar `cmd` con:

```bat
.venv\Scripts\activate.bat
```

La API queda disponible por defecto en `http://127.0.0.1:5000`.

El backend expone, entre otros, estos endpoints:

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

### 3. Ejecutar la app Flutter

En otra terminal, desde la raiz del proyecto:

```powershell
flutter run -d windows --dart-define=FOODPLEASE_API_BASE_URL=http://127.0.0.1:5000/api/v1 --dart-define=APP_ENV=development
```

Tambien puedes ejecutarla en un emulador Android con:

```powershell
flutter run -d android --dart-define=FOODPLEASE_API_BASE_URL=http://10.0.2.2:5000/api/v1 --dart-define=APP_ENV=development
```

En Chrome tambien deberia funcionar con:

```powershell
flutter run -d chrome --dart-define=FOODPLEASE_API_BASE_URL=http://127.0.0.1:5000/api/v1 --dart-define=APP_ENV=development
```

Si Chrome muestra un error relacionado con `sqflite_sw.js` o `sqlite3.wasm`, regenera los binarios web con:

```powershell
dart run sqflite_common_ffi_web:setup . --dir web --force
```

Si quieres usar la URL por defecto configurada en el proyecto y dejar que Flutter elija un dispositivo soportado, tambien puedes ejecutar:

```powershell
flutter run
```

## Credenciales para ingresar

El proyecto incluye una cuenta demo precargada en el backend y visible tambien en la pantalla de login.

### Usuario demo

- Email: `demo@foodplease.app`
- Contrasena: `demo123`
- Nombre: `Usuario Demo`

La informacion seed se encuentra en `backend/data/store.json`.

En la pantalla de login existe ademas la accion `Usar cuenta demo`, que completa automaticamente esas credenciales.

## Comandos utiles

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Para el backend:

```powershell
cd backend
.\.venv\Scripts\python run.py
```

## Persistencia local

La app mantiene una base SQLite versionada para:

- sesion activa;
- usuarios y perfil;
- categorias y productos cacheados;
- carrito persistido;
- pedidos y detalle de `order_items`.

### Estrategia de datos

- Sesion, carrito y pedidos usan soporte local para recuperar estado.
- El catalogo puede cachearse localmente y refrescarse desde API.
- Los pedidos se conservan como snapshot historico.
- El carrito mantiene el ultimo estado confirmado localmente.

## Flujo funcional disponible

Actualmente puedes probar este recorrido completo:

1. Iniciar sesion con la cuenta demo.
2. Explorar el menu y agregar productos al carrito.
3. Ajustar cantidades o vaciar el carrito con confirmacion.
4. Confirmar un pedido.
5. Revisar pedidos creados, ver su detalle y editar o cancelar si el estado lo permite.
6. Consultar y actualizar los datos de la cuenta.

## Documentacion adicional

- `backend/README.md`: detalle del backend, variables de entorno y endpoints.
