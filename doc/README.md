# ERP Billing System — Technical Documentation

> Complete module-by-module documentation for the **VELA AGENCY** ERP billing system
> (Flutter POS frontend + Flask REST API + Supabase database & storage).

This folder documents every module of the project. Each markdown file covers one
module: purpose, files, key classes/functions, data flows, and how it connects to
the rest of the system.

## Documentation Index

| # | Module | File | Covers |
|---|--------|------|--------|
| 1 | Project Overview | [`01_project_overview.md`](01_project_overview.md) | System purpose, architecture, stack, top-level layout |
| 2 | Backend — App & Config | [`02_backend_app.md`](02_backend_app.md) | `app.py`, `config.py`, CORS, error handlers |
| 3 | Backend — API Routes | [`03_backend_routes.md`](03_backend_routes.md) | All Flask blueprints & endpoints |
| 4 | Backend — Services | [`04_backend_services.md`](04_backend_services.md) | `BillingService`, `language_utils`, `sample_data` |
| 5 | Backend — Models | [`05_backend_models.md`](05_backend_models.md) | `Product`, `Customer`, `Bill`, `BillItem` |
| 6 | Supabase Database | [`06_supabase_database.md`](06_supabase_database.md) | Tables, migrations, DB functions, RLS, storage |
| 7 | Frontend — Models | [`07_frontend_models.md`](07_frontend_models.md) | Dart data models & JSON mapping |
| 8 | Frontend — State (Provider) | [`08_frontend_state_provider.md`](08_frontend_state_provider.md) | `BillingProvider` state management |
| 9 | Frontend — Services | [`09_frontend_services.md`](09_frontend_services.md) | `ApiService`, export services, offline data |
| 10 | Frontend — Screens | [`10_frontend_screens.md`](10_frontend_screens.md) | All Flutter screens & navigation |
| 11 | Frontend — Widgets | [`11_frontend_widgets.md`](11_frontend_widgets.md) | Reusable widgets (POS, invoice, receipt) |
| 12 | Frontend — Utils & Theming | [`12_frontend_utils.md`](12_frontend_utils.md) | Constants, themes, formatters |
| 13 | Testing & QA | [`13_testing_qa.md`](13_testing_qa.md) | Pytest suite, manual test scripts, debug guides |
| 14 | Run & Deployment | [`14_run_deployment.md`](14_run_deployment.md) | Start scripts, dependencies, env setup |
| 15 | Known Issues & Roadmap | [`15_known_issues_roadmap.md`](15_known_issues_roadmap.md) | Bugs, limitations, production migration plan |

## Quick Orientation

```
ERP Billing System
├── billing_system/
│   ├── backend/               Flask REST API (Python)
│   │   ├── app.py             Entry point — creates the Flask app
│   │   ├── config.py          Central configuration
│   │   ├── routes/            Blueprints (billing, products, customers, …)
│   │   ├── services/          Business logic (BillingService, language, sample data)
│   │   ├── models/            Dataclass models (Product, Customer, Bill)
│   │   ├── supabase/migrations/  SQL migrations for Supabase
│   │   └── tests/             Pytest suite
│   └── frontend/
│       └── flutter_application/  Flutter POS app
│           └── lib/
│               ├── main.dart      App entry — routes & providers
│               ├── models/        Dart models
│               ├── providers/     BillingProvider (state)
│               ├── services/      API / export / offline services
│               ├── screens/       One file per screen
│               ├── widgets/       Reusable UI widgets
│               └── utils/         Constants, themes, formatters
├── supabase/migrations/0001_init.sql   Canonical production schema
├── run.sh / run.bat           Start both servers
├── check_db.py                DB + storage verification utility
├── test_company_invoice.py    End-to-end invoice test script
└── doc/                       ← this documentation
```

## Cross-cutting notes

- **No GST** — the system is a non-GST (L/Exempt) retailer biller. GST fields exist
  only for UI compatibility and are always `0`.
- **Invoice numbering** — backend generates `YYYYMMMDDAHHMM…` style numbers
  (e.g. `2026AUG08A161`) using an hourly in-memory sequence seeded from the DB.
- **Two bill artifacts per sale** — a simple bilingual cash receipt
  (`erp_billing_system`) and a company GST-style invoice (`erp_billing_system_company`).
- **Offline resilience** — the Flutter app falls back to bundled sample data when the
  Flask backend is unreachable.
