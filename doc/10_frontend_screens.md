# 10. Frontend — Screens

Location: `billing_system/frontend/flutter_application/lib/screens/`

All screens are wired together in `main.dart` with a navigation rail/sidebar layout:
**Dashboard · POS Billing · Products · Customers · Bill History · Settings**.
Invoice screens are pushed on top when needed.

## 10.1 `SplashScreen` — `splash_screen.dart`
Startup screen. Shows the app logo/title, runs an initial health check against the
backend, then navigates to `DashboardScreen`. Also where the navigation destination is
decided (dashboard vs. POS) based on connectivity.

## 10.2 `DashboardScreen` — `dashboard_screen.dart`
The landing page and business summary.

- Loads bills via `ApiService.getBills()` and computes **today's sales** and **total
  sales** by folding `grandTotal`.
- Displays stat cards: Today's Sales, Total Sales, Total Bills, Products, Customers.
- Resets the active bill (`BillingProvider.resetBill()`) before navigating to POS so a
  fresh cart starts.
- Entry point to Products / Customers / Bill History.

## 10.3 `PosBillingScreen` — `pos_billing_screen.dart`
The main POS (point of sale). Layout:

```
┌──────────────────────────────────────────────┐
│ TopPanel: search · selected customer · total │
├───────────────┬──────────────────────────────┤
│  Product grid │   Cart panel                 │
│  (category    │   PosBillItemRow list        │
│   chips +     │   PosSummarySection totals   │
│   search)     │   PosPaymentSelector         │
│               │   [Complete Sale] button     │
└───────────────┴──────────────────────────────┘
```

Behaviour:
- Loads products/customers from `ApiService` (offline fallback + "Retry" banner).
- `addProduct` → cart via `BillingProvider`; stock-exhausted products are rejected.
- Quantity editing via `QuantityDialog` (tap item).
- **Complete Sale** flow:
  1. `ApiService.saveBill(...)` → returns `bill_number`.
  2. `InvoiceExportService.generateCompanyInvoice(billNumber)` → server builds the
     company PDF.
  3. Builds `receiptData` map (customer, items, totals, bill number) and opens the
     **BilingualBillDashboard** dialog, which translates the bill into Tamil and
     auto-saves both the customer receipt and the company invoice PDF to Storage.

## 10.4 `BillHistoryScreen` — `bill_history_screen.dart`
Lists all saved bills newest-first in a table/card layout (`bill_no`, date, customer,
items, total).

- Tapping a bill → `BillDetailsScreen`.
- Delete button per bill (`ApiService.deleteBill`) with confirmation.
- Also hosts the **Consolidated Invoice** and **Single Invoice** entry points from the
  app bar / action menu.

## 10.5 `BillDetailsScreen` — `bill_details_screen.dart`
Read-only detail view of one saved bill:

- Header: bill number, date/time, customer (name + phone), payment mode.
- Line items table (description, qty, rate, amount).
- Totals: subtotal, discount total, **grand total** (no GST row).
- Actions: view/print the company invoice, delete the bill, share (stub).

## 10.6 `ProductsScreen` — `products_screen.dart`
Catalogue management.

- Loads products from `ApiService.getProducts()`; search + category filter.
- Lists products with price / stock / unit.
- Add / edit / delete product dialogs (`_showProductDialog`) posting to the backend
  (create / update endpoints). Stock and price are editable.

## 10.7 `CustomersScreen` — `customers_screen.dart`
Customer management.

- Loads customers from `ApiService.getCustomers()`; search by name/phone.
- Add customer dialog (`createCustomer`) and edit/delete actions.
- Customer cards show name, phone, area, balance.
- Selecting a customer in POS flow passes it to `BillingProvider.setCustomer`.

## 10.8 `SettingsScreen` — `settings_screen.dart`
App configuration placeholders:

- Backend URL display/override (`AppConstants.baseUrl`).
- Theme toggle (light / dark) via the app theme.
- GST toggle UI — **always reports "No GST"** (system is non-GST).
- Company details display (VELA AGENCY static info).
- Testing/debug switches (e.g. sample data, health check).

## 10.9 `CompanyInvoiceScreen` — `company_invoice_screen.dart`
Shows a single bill rendered as the **company GST invoice** using `InvoicePreview`
(navy/blue scheme). Receives a `Bill` (or bill number to fetch). Used for viewing /
printing the formal invoice; the PDF itself is generated server-side on save.

## 10.10 `SingleInvoiceScreen` — `single_invoice_screen.dart`
Shows one bill in clean invoice format via `InvoicePreview`.

- Converts `Bill` → `Invoice` (`_convertBillToInvoice`): items map to `InvoiceItem`
  with `hsn: '0000'` (HSN not modelled in this system).
- Customer GSTIN/PAN shown as `'N/A'`; UPI shown when payment is UPI.
- Share / Print buttons are **stubs** ("coming soon").

## 10.11 `ConsolidatedInvoiceScreen` — `consolidated_invoice_screen.dart`
Aggregates **all** bills in history into one invoice.

- Loads `ApiService.getBills()`.
- Groups items by `productName_rate`, summing quantity and amount → one `Invoice`.
- Empty state: `'No bills found in history'`.
- Renders the aggregate via `InvoicePreview`.

## Navigation map

| From | Action | Goes to |
|------|--------|---------|
| Splash | after health check | Dashboard |
| Dashboard | card tap | Products / Customers / Bill History |
| Dashboard | "Start Billing" | POS Billing |
| Bill History | tap bill | Bill Details |
| Bill History | menu | Consolidated Invoice |
| Bill Details | "Invoice" | Company Invoice / Single Invoice |

## Related docs

- [09 — Frontend Services](09_frontend_services.md)
- [11 — Frontend Widgets](11_frontend_widgets.md)
- [12 — Frontend Utils](12_frontend_utils.md)
