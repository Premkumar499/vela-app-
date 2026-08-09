# 9. Frontend — Services

Location: `billing_system/frontend/flutter_application/lib/services/`

Services wrap HTTP calls and offline data for the UI. They never throw — every call
returns a result object or an error message so widgets stay simple.

## 9.1 `ApiService` — `services/api_service.dart`

Central HTTP client for the Flask backend. Base URL: `http://localhost:5000`
(configurable via `utils/constants.dart` `AppConstants.baseUrl`).

### `ApiResult<T>`
```dart
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool success;
  final bool isOffline;   // true when data came from the local dummy dataset
}
```
Constructors: `ApiResult.ok(data, {isOffline})` and `ApiResult.err(error)`.

### Methods

| Method | Endpoint | Notes |
|--------|----------|-------|
| `checkHealth()` | `GET /health` | Returns `true` when backend is reachable |
| `getProducts({search, category})` | `GET /products/` | Falls back to `LocalData.products` (with filters) when offline |
| `getCustomers({search})` | `GET /customers/` | Falls back to `LocalData.customers` when offline |
| `saveBill({customer, items, paymentType, …})` | `POST /bill/` | Returns the created bill map (`bill_number`, `bill`) |
| `getBills()` | `GET /bills/` | Returns `List<Bill>`; empty list when offline |
| `getBillDetails(billNumber)` | `GET /bills/<n>` | Single bill |
| `deleteBill(billNumber)` | `DELETE /bills/<n>` | Returns server message |
| `createCustomer({name, phone, email, address})` | `POST /customers/` | Saves to Supabase via backend |
| `translateToTamil(texts, {target='ta'})` | `POST /translate/` | Returns translated list; falls back to originals on failure |

Internals:
- `_parseList<T>` — generic JSON list parser.
- `_extractError(response)` — pulls `message` from the JSON error envelope.
- 15 s `requestTimeout`; 5 s `connectionTimeout`.

## 9.2 `InvoiceExportService` — `services/invoice_export_service.dart`

Handles exporting invoice widgets to images and uploading PDFs to Supabase Storage.

| Method | Purpose |
|--------|---------|
| `saveInvoiceAsImage({widgetKey, invoiceNumber, isCompanyInvoice})` | Captures a `RepaintBoundary` at pixel-ratio 2.0, base64-encodes the PNG, POSTs to `/invoice-export/save`. Returns `{success, message, fileName, bucket, url, size}`. |
| `generateCompanyInvoice(invoiceNumber, {fallbackData})` | POSTs to `/invoice-export/generate-company/<n>`. Backend builds the PDF from the DB (or fallback payload) and uploads it. Returns `{success, message, fileName, url}`. |

Base URL is hardcoded to `http://localhost:5000`.

## 9.3 `BilingualApiService` — `services/bilingual_api_service.dart`

Thin client for the **simplified** bilingual API (`/api/bilingual`).

| Method | Endpoint |
|--------|----------|
| `createBill(billData)` | `POST /api/bilingual/bills` |
| `getAllBills()` | `GET /api/bilingual/bills` |
| `getBill(billNo)` | `GET /api/bilingual/bills/<n>` |
| `deleteBill(billNo)` | `DELETE /api/bilingual/bills/<n>` |
| `generateBillNumber()` | `GET /api/bilingual/generate-bill-number` |

Base URL: `http://localhost:5000/api/bilingual`. (Legacy/simplified surface — the main
app uses `ApiService`.)

## 9.4 `LocalData` — `services/local_data.dart`

Bundled **offline fallback** dataset used whenever the backend is unreachable.

| Export | Contents |
|--------|----------|
| `LocalData.products` | ~60 hardcoded `Product` objects (BACKING SODA, APPALAM, oil, kadalai paruppi, …) across categories `Primary`, `Appalam`, `Bala` |
| `LocalData.customers` | Single Walk-in Customer |

Used by `ApiService.getProducts` / `getCustomers` to keep the UI usable with zero
network. Screens show an "offline" banner (`isOffline == true`) and a Retry button.

## Request flow summary

```
UI widget → ApiService / InvoiceExportService
             → http → Flask routes → BillingService → Supabase
             ↳ on failure: LocalData fallback / error message
```

## Related docs

- [03 — Backend API Routes](03_backend_routes.md)
- [08 — Frontend State Provider](08_frontend_state_provider.md)
- [10 — Frontend Screens](10_frontend_screens.md)
