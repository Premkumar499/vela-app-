# 2. Backend — App & Configuration

## Files

| File | Purpose |
|------|---------|
| `billing_system/backend/app.py` | Flask application factory, CORS, blueprint registration, error handlers, health check |
| `billing_system/backend/config.py` | Central `Config` class — all settings in one place |
| `billing_system/backend/requirements.txt` | Python dependencies |

## `app.py` — Application entry point

Location: `billing_system/backend/app.py`

`create_app()` is a factory that builds and returns the Flask app.

### Blueprint registration

All routes live in blueprints and are registered here:

| Blueprint | Prefix | Module | Handles |
|-----------|--------|--------|---------|
| `products_bp` | `/products` | `routes.products` | Product catalogue |
| `customers_bp` | `/customers` | `routes.customers` | Customer list & create |
| `billing_bp` | `/bill` | `routes.billing` | Create bill |
| `history_bp` | `/bills` | `routes.history` | List/get/delete bills, summary |
| `translate_bp` | *(root)* | `routes.translate` | Local Tamil/Tanglish translation |
| `bilingual_bp` | `/api/bilingual` | `routes.bilingual_billing` | Simple in-memory bill API |
| `invoice_export_bp` | `/invoice-export` | `routes.invoice_export` | PDF generation & storage upload |

### CORS

```python
CORS(app, origins=Config.CORS_ORIGINS, supports_credentials=False,
     allow_headers=["Content-Type", "Accept", "Authorization"],
     methods=["GET", "POST", "DELETE", "OPTIONS"])
```

Allows the browser-based Flutter web app on `localhost:8080` / `:5000` (plus `*`
fallback) to call the API. Credentials are **not** supported.

### Health check

`GET /health` → `{"status": "ok", "service": "ERP Billing API", "version": "1.0.0 (prototype)"}`

Used by the Flutter splash screen to decide between online and offline mode.

### Global error handlers

| Code | Response |
|------|----------|
| 404 | `{"success": false, "message": "Endpoint not found"}` |
| 405 | `{"success": false, "message": "Method not allowed"}` |
| 500 | `{"success": false, "message": "Internal server error"}` |

### Running directly

```python
if __name__ == "__main__":
    app = create_app()
    app.run(host=Config.HOST, port=Config.PORT, debug=Config.DEBUG)
```

## `config.py` — Configuration

Location: `billing_system/backend/config.py`

All settings are centralised in one `Config` class so the app can be pointed at a
database deployment without touching any other file.

| Setting | Value | Purpose |
|---------|-------|---------|
| `DEBUG` | `True` | Flask debug mode |
| `HOST` | `0.0.0.0` | Bind all interfaces |
| `PORT` | `5000` | Default API port |
| `CORS_ORIGINS` | `["http://localhost:8080", "http://127.0.0.1:8080", "http://localhost:5000", "http://127.0.0.1:5000", "*"]` | Allowed browser origins |
| `INVOICE_CONSTANT` | `"A"` | Constant letter in bill number (`2026AUG08**A**161`) |
| `GST_SLABS` | `[0, 5, 12, 18, 28]` | Supported GST slabs (unused — non-GST system) |
| `DEFAULT_PRICE_LIST` | `"Retail"` | Default price-list label |
| `COMPANY_NAME` | `"My Shop"` | Fallback company name |
| `COMPANY_ADDRESS` | `"123 Main Street, City - 000000"` | Fallback address |
| `COMPANY_PHONE` | `"+91 99999 99999"` | Fallback phone |
| `COMPANY_GSTIN` | `"29XXXXX0000X1ZX"` | Fallback GSTIN |

> Note: the real VELA AGENCY details used on printed invoices live in
> `models/invoice_model.dart` (Flutter) and are duplicated in
> `routes/invoice_export.py` (server-side PDF).

## `requirements.txt` — Dependencies

```
Flask==3.0.3            Web framework
Werkzeug==3.0.3         WSGI utilities
Flask-Cors==4.0.1       CORS support
gunicorn==21.2.0        Production WSGI (Linux)
waitress==3.0.0         Production WSGI (Windows)
pytest==8.3.5           Testing
pytest-cov==4.1.0       Coverage
pytest-flask==1.3.0     Flask test helpers
flake8 / black / pylint Linting & formatting
mypy==1.9.0             Type checking
python-dotenv==1.0.1    .env loading
supabase==2.9.1         Supabase client
click==8.1.7            CLI helpers
Pillow==10.3.0          Image handling
reportlab==4.2.0        PDF generation
```

## Environment variables (`.env`)

Stored at `billing_system/backend/.env` (git-ignored):

```
SUPABASE_URL=https://XXXX.supabase.co
SUPABASE_SERVICE_KEY=sb_secret_xxx   # (or SUPABASE_SECRET_KEY)
```

Loaded lazily by `_get_supabase()` in `services/billing_service.py` and
`routes/invoice_export.py`. The app falls back to bundled `sample_data.py` when the
database is unreachable.

## Related docs

- [03 — Backend API Routes](03_backend_routes.md)
- [04 — Backend Services](04_backend_services.md)
- [14 — Run & Deployment](14_run_deployment.md)
