# 15. Known Issues & Roadmap

## 15.1 Known issues (as of last QA pass)

### 1. Stock is in-memory only, not persisted
`BillingService` deducts stock in memory (`_deduct_stock`); it resets on every server
restart and is not written back to Supabase. Overselling and restart drift are possible.

> **Fix path**: the production schema's `create_bill()` DB function already does atomic
> stock deduction (`WHERE stock >= qty`) — switch to generation-1 schema to fix.

### 2. `tests/test_billing.py` expects 545 products
The sample catalogue (`services/sample_data.py`) was emptied (products are now
DB-driven; old list kept in `_REMOVED_PRODUCTS`). Tests that count 545 products fail
against the DB-less environment. Update fixtures to mock Supabase.

### 3. Company invoice PDF flakiness via Flutter UI (FIXED, keep watch)
`BilingualBillDashboard._autoSaveBoth()` was not awaited → company PDF sometimes
missed the bucket. Fixed by awaiting + error handling + 500 ms commit delay. Regression
risk remains — re-run `test_company_invoice.py` after any save-flow change.

### 4. Timing dependence on DB commit
The 500 ms delay between customer-receipt upload and company-invoice generation is a
heuristic for the DB commit; on slow networks it can still race. The backend
`generate-company/<n>` endpoint fetches from the DB, so a retry button mitigates.

### 5. Single point of failure: `localhost:5000` base URL
`AppConstants.baseUrl` is hardcoded to `localhost`. Any device/network deployment needs
the IP changed; no runtime config.

### 6. Stub UI actions
- Share / Print buttons on `SingleInvoiceScreen` are placeholders.
- Settings GST toggle always reports "No GST" (by design — non-GST system).

### 7. HSN codes not modelled
Invoice items use `hsn: '0000'` placeholder. No HSN/GST data exists in the catalogue.

## 15.2 Security notes

- `SUPABASE_SERVICE_KEY` lives in `billing_system/backend/.env` — **never** commit it or
  ship it in the Flutter client.
- Storage buckets are non-public with service-role-only policies; keep them that way
  unless a public view URL is explicitly required.
- RLS is enabled on the generation-1 schema (permissive policy for `authenticated`);
  the backend bypasses it via the service key. Tighten the policy if clients ever talk
  to Supabase directly.

## 15.3 Roadmap

| Priority | Item | Notes |
|----------|------|-------|
| P0 | Migrate to production schema (`0001_init.sql`) | `create_bill()` gives atomic numbering + persisted stock + audit log |
| P0 | Re-sync product catalogue into `products` table | Loader in `SUPABASE_DATABASE_ARCHITECTURE.md` §7; preserve ids |
| P1 | Move bill numbering to `invoice_series` | Concurrency-safe, replaces in-memory hour counter |
| P1 | Replace 500 ms delay with proper save-ordering | Generate company PDF from the already-returned payload, or retry loop |
| P1 | Fix `tests/test_billing.py` fixtures | Mock Supabase; remove 545-product assumption |
| P2 | Configurable backend URL at runtime | Settings screen field → persisted value instead of constant |
| P2 | Real HSN/GSTIN catalogue fields | Enables future GST compliance if needed |
| P2 | Implement Share / Print | Uses the existing `RepaintBoundary` + PDF export |
| P3 | Direct Flutter → Supabase | Only after RLS policy review; uses anon/user key |
| P3 | CI pipeline | Run pytest + `flutter test` + `test_company_invoice.py` on push |

## Related docs

- [01 — Project Overview](01_project_overview.md)
- [06 — Supabase Database](06_supabase_database.md)
- [13 — Testing & QA](13_testing_qa.md)
- Root: `SUPABASE_DATABASE_ARCHITECTURE.md`, `BUGFIX_SUMMARY.md`
