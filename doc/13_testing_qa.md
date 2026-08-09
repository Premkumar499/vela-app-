# 13. Testing & QA

The project uses lightweight, manual/scripted QA (no CI). Everything documented in the
root-level markdown guides is summarised here.

## 13.1 Backend unit tests

Location: `billing_system/backend/tests/test_billing.py` (pytest).

Covers billing logic (bill creation, numbering, product/customer queries). Note:
`test_billing.py` still expects the **545-product sample catalogue** — those tests
assume DB availability or older behaviour. The current `SAMPLE_PRODUCTS` is empty
(DB-driven), so these tests may fail until the test fixtures are updated to mock
Supabase. See [15 — Known Issues](15_known_issues_roadmap.md).

Run:
```bash
cd billing_system/backend
pip install -r requirements.txt
pytest
```

## 13.2 Root-level QA scripts

| File | Purpose | Run |
|------|---------|-----|
| `QUICK_TEST.md` | Manual test for the **company-invoice storage fix**; documents the two-terminal `run.sh` flow and expected log lines | follow steps in doc |
| `TESTING_GUIDE.md` | Full UI test: start app, create bill, verify both PDFs land in the correct buckets | follow steps in doc |
| `BUGFIX_SUMMARY.md` | Records root cause + fix for the company-invoice-not-uploaded bug (`_autoSaveBoth()` was **not awaited** → now awaited + error handling) | read-only |
| `COMPANY_INVOICE_DEBUG.md` | Debug guide with step-by-step logging added to `BilingualBillDashboard` to trace PDF uploads | read-only |
| `test_company_invoice.py` | **Automated** end-to-end test: creates a bill against the running backend and verifies the company invoice was generated | `python3 test_company_invoice.py` (backend must be running) |
| `check_db.py` | DB verification: confirms a bill exists in BOTH `erp_billing_system` AND `erp_billing_system_company`, compares rows, lists PDFs in both buckets | `python3 check_db.py` |

### `test_company_invoice.py` expected output
```
✓ ALL TESTS PASSED
  Bill 2026AUG09AXXX was created and company invoice was generated
```

## 13.3 Manual UI test checklist (from TESTING_GUIDE)

1. `./run.sh` — expect two terminals: **Backend (Flask, port 5000)** and **Flutter
   (Chrome)**.
2. POS Billing → add 2–3 products → select or create a customer → **Complete**.
3. Verify in Flutter console:
   ```
   _autoSaveBoth START …
   Step 1: Capturing customer receipt…
   Customer bill result: true …
   Waiting 500ms for DB commit…
   Step 2: Calling generateCompanyInvoice …
   ✅ SUCCESS: Company invoice uploaded to bucket
   ```
4. Confirm both buckets in Supabase Storage:
   - `erp_billing_system` → customer receipt PDF
   - `erp_billing_system_company` → company invoice PDF
5. Bill History → open the bill → both artifacts viewable/printable.

## 13.4 What gets verified end-to-end

- **Numbering**: bills follow `YYYYMMMDDAHHMM` sequence and continue after delete.
- **Persistence**: header + items land in both table pairs.
- **Storage**: customer receipt + company invoice PDFs upload to their buckets.
- **Offline fallback**: UI still usable with `LocalData` when backend is down (offline
  banner + Retry).
- **No GST**: all tax rows render ₹0.00.

## Related docs

- [14 — Run & Deployment](14_run_deployment.md)
- [15 — Known Issues & Roadmap](15_known_issues_roadmap.md)
