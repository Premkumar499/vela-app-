# 14. Run & Deployment

## 14.1 Prerequisites

| Component | Requirement |
|-----------|-------------|
| Python | 3.10+ |
| Flutter | 3.x (Chrome desktop target for quick testing) |
| Supabase | A project with the migrations applied (see [06 — Database](06_supabase_database.md)) |
| `.env` | `billing_system/backend/.env` with `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` |

Backend deps (`billing_system/backend/requirements.txt`):
```
Flask==3.0.3
flask-cors
supabase==2.9.1
reportlab==4.2.0
Pillow==10.3.0
python-dotenv
gunicorn        # production server
waitress        # windows server
pytest          # tests
```

## 14.2 Quick start (development)

```bash
# 1) Backend
cd billing_system/backend
pip install -r requirements.txt
python app.py          # → http://localhost:5000

# 2) Frontend (separate terminal)
cd billing_system/frontend/flutter_application
flutter run -d chrome
```

Or use the one-shot script (starts both, with `sleep 2` between):
```bash
./run.sh      # macOS / Linux
run.bat       # Windows
```

Health check: `curl http://localhost:5000/health`
```
{"status":"ok","service":"ERP Billing API","version":"1.0.0 (prototype)"}
```

## 14.3 Verifying Supabase connectivity

`BillingService.__init__` loads products + customers from Supabase at startup. If the
DB is unreachable it falls back to bundled sample data and logs a warning — the app
still runs, but bills will **not** persist. Confirm with:

```bash
python3 check_db.py    # reads billing_system/backend/.env
```

## 14.4 Production deployment

### Backend (Flask)

Two configured servers in `config.py`:
- **Gunicorn** (Linux/macOS):
  ```bash
  gunicorn -w 4 -b 0.0.0.0:5000 app:app
  ```
- **Waitress** (Windows):
  ```bash
  waitress-serve --port=5000 app:app
  ```

Expose on port 5000; frontend `baseUrl` must point at the server's IP when Flutter is
run on another device (`lib/utils/constants.dart`).

### Frontend (Flutter)

For a real device/network use:
- `flutter build web` and serve `build/web` behind nginx/static host, or
- `flutter build apk` / `flutter build windows` / `flutter build linux` for native
  installs.

Update `AppConstants.baseUrl` to the deployed backend URL before building.

### Supabase

Ensure the production schema (`supabase/migrations/0001_init.sql`) and the live
billing tables (`billing_system/backend/supabase/migrations/0002_…`, `0003_…`) are
applied, storage buckets exist with the service-role policies, and the service key is
in the server `.env` (never in the Flutter app).

## 14.5 Architecture summary

```
Flutter UI (POS)
   │  http://localhost:5000
   ▼
Flask API (blueprints: /products /customers /bill /bills /translate
   │                /api/bilingual /invoice-export)
   ▼
BillingService ──► Supabase (Postgres tables + Storage buckets)
```

## Related docs

- [02 — Backend App & Config](02_backend_app.md)
- [06 — Supabase Database](06_supabase_database.md)
- [13 — Testing & QA](13_testing_qa.md)
