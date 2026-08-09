# 1. Project Overview

## Purpose

The **ERP Billing System** is a point-of-sale (POS) / billing application built for
**VELA AGENCY**, a grocery (groceries & general stores — "மளிகை மொத்த மற்றும் சில்லறை
வியாபாரம்") retailer in Anthiyur, Tamil Nadu. It lets a cashier:

- Browse/search a large product catalogue and add items to a cart.
- Select or create a customer.
- Apply per-line discounts and choose payment type (Cash / Credit / UPI).
- Save the bill, which produces **two artifacts**:
  1. A **bilingual cash receipt** (English + Tamil) styled like a thermal receipt.
  2. A **company GST-style invoice** (VELA AGENCY letterhead) rendered server-side as PDF.
- Browse, search, print and delete past bills.
- View a dashboard summary and manage products/customers.

The system is **non-GST**: sale price is final. GST fields are kept only for UI/API
compatibility and are always zero.

## Architecture

```
┌─────────────────────────────┐        ┌──────────────────────────────┐
│   Flutter POS App (UI)      │  HTTP  │      Flask REST API (Python) │
│  · POS billing screen       │ ─────▶ │  · routes/  (blueprints)     │
│  · Bill history / details   │  JSON  │  · services/BillingService   │
│  · Company invoice preview  │        │  · invoice PDF generation    │
│  · Products / customers     │        └──────────────┬───────────────┘
└─────────────────────────────┘                       │ supabase client
                                             ┌────────▼──────────────┐
                                             │       Supabase        │
                                             │  · PostgreSQL tables  │
                                             │  · Storage buckets    │
                                             └───────────────────────┘
```

- **Flutter** is the single UI client (designed for tablets, landscape-first).
- **Flask** exposes a JSON REST API and owns business logic, invoice numbering,
  stock deduction (in-memory), and server-side PDF generation.
- **Supabase** is the persistence layer: bill headers/items, product catalogue,
  customers, plus Storage buckets for the generated PDFs.

### Connection options (documented in `SUPABASE_DATABASE_ARCHITECTURE.md`)

1. **Option A (current):** Flutter → Flask → Supabase with the **service-role key**.
   RLS is bypassed; all logic stays in Python.
2. **Option B (future):** Flutter → Supabase directly with anon key + RLS. The
   canonical `0001_init.sql` schema and `create_bill()` DB function are designed to
   support this later.

## Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart ≥ 3.0), Provider for state, `http` client, `intl` |
| Backend | Python 3.10/3.12, Flask 3.0, Flask-Cors, Waitress/Gunicorn |
| Database | Supabase / PostgreSQL (service-role key) |
| Storage | Supabase Storage (two buckets: `erp_billing_system`, `erp_billing_system_company`) |
| PDF | ReportLab + Pillow (server-side) |
| Tests | Pytest (backend), Flutter widget test, manual scripts |

## Key Concepts & Terminology

| Term | Meaning |
|------|---------|
| **Bill / Cash bill** | The customer-facing bilingual receipt saved to `erp_billing_system`. |
| **Company invoice** | The VELA AGENCY letterhead invoice saved to `erp_billing_system_company`. |
| **Bill number** | `YYYYMMMDDAHHMM` + hourly sequence, e.g. `2026AUG08A161`. |
| **Walk-in Customer** | Default pseudo-customer (`00000000-0000-0000-0000-000000000000`). |
| **Offline mode** | UI works with bundled `LocalData` when backend is unreachable. |
| **Bilingual** | Receipt prints English + Tamil (`descriptionTamil`) via a transliteration engine. |

## Top-level layout

```
├── billing_system/
│   ├── backend/                     Python Flask API
│   ├── frontend/flutter_application/ Flutter app
│   └── (billing_system.iml, README) IDE/app metadata
├── supabase/migrations/0001_init.sql Canonical schema (target architecture)
├── run.sh                          Start backend + Flutter (Linux/macOS)
├── run.bat                         Start backend + Flutter (Windows)
├── check_db.py                     Verify DB rows + storage PDFs
├── test_company_invoice.py         E2E test: create bill → company PDF
├── AGENTS.md                       Graphify/agent conventions
├── QUICK_TEST.md, TESTING_GUIDE.md,
│   BUGFIX_SUMMARY.md,
│   COMPANY_INVOICE_DEBUG.md        Earlier debugging records
├── SUPABASE_DATABASE_ARCHITECTURE.md Database migration plan
└── doc/                            This documentation set
```

## Related docs

- [02 — Backend App & Config](02_backend_app.md)
- [06 — Supabase Database](06_supabase_database.md)
- [10 — Frontend Screens](10_frontend_screens.md)
- [15 — Known Issues & Roadmap](15_known_issues_roadmap.md)
