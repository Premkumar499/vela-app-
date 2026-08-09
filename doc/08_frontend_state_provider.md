# 8. Frontend — State (BillingProvider)

Location: `billing_system/frontend/flutter_application/lib/providers/billing_provider.dart`

`BillingProvider` is the **single source of truth** for the active (in-progress) bill.
It extends `ChangeNotifier` and is provided app-wide via `MultiProvider` in `main.dart`,
so any screen can read the cart and update it with `provider` / `context.read`.

## State fields

| Field | Default | Meaning |
|-------|---------|---------|
| `_customer` | `Customer.walkIn` | Selected customer |
| `_customerPhone` | `''` | Phone shown/typed at POS |
| `_items` | `[]` | List of `BillItem` (the cart) |
| `_paymentType` | `'Cash'` | Cash / Credit / UPI |
| `_salesType` | `'Retail'` | Retail / Wholesale / Credit |
| `_priceList` | `'Retail'` | Retail / Wholesale / MRP |
| `_through` | `''` | Salesman / agent |
| `_area` | `''` | Sales area |
| `_remarks` | `''` | Notes on the bill |

## Getters

Expose immutable views: `customer`, `customerPhone`, `items` (unmodifiable),
`paymentType`, `salesType`, `priceList`, `through`, `area`, `remarks`, `itemCount`.

## Computed totals (no GST)

| Getter | Formula |
|--------|---------|
| `subtotal` | Σ `grossAmount` |
| `discountTotal` | Σ `discountAmount` |
| `gstTotal` | `0.0` (no GST) |
| `roundOff` | `0.0` (no rounding) |
| `grandTotal` | Σ `total` |
| `gstBreakup` | `{}` (no GST) |

All money values are rounded to 2 decimals via `_r()`.

## Mutators

| Method | Behaviour |
|--------|-----------|
| `setCustomer(c)` | Sets customer, syncs `_area` and `_customerPhone` from the customer |
| `setCustomerPhone(v)` | Updates phone |
| `setPaymentType / setSalesType / setPriceList / setThrough / setArea / setRemarks` | Update a single field |
| `addProduct(product, {quantity=1})` | **Returns `false` if out of stock** (`stock <= 0`). If the product is already in the cart, increases qty up to `maxStock` (respecting available stock); otherwise adds a new `BillItem.fromProduct`. |
| `removeItem(index)` | Removes a line |
| `updateQuantity(index, qty)` | Clamps to `[1, maxStock]` |
| `updateDiscount(index, pct)` | Sets line discount % |
| `clearItems()` | Empties cart |
| `resetBill()` | Resets **everything** (cart, customer, payment, fields) — called when starting a new bill |
| `canSave` | `items.isNotEmpty` — enables the Save/Complete button |

Every mutator calls `notifyListeners()` so subscribed widgets rebuild.

## Where it's used

- **`main.dart`** — provided via `ChangeNotifierProvider` once at app start.
- **`pos_billing_screen.dart`** — the primary consumer: reads products, adds to cart,
  edits quantities/discounts, saves the bill.
- **`dashboard_screen.dart`** — resets the bill before navigating to POS.

## Data flow on save (POS screen)

```
user taps Complete
  → BillingProvider.canSave  (cart not empty)
  → ApiService.saveBill(customer, items, paymentType, …)
      → POST /bill/
      → backend BillingService.create_bill() → returns bill_number
  → InvoiceExportService.generateCompanyInvoice(billNum)   (server-side PDF)
  → build receiptData map
  → show BilingualBillDashboard dialog (translates items to Tamil, auto-saves
    customer receipt + company invoice PDFs)
```

## Related docs

- [07 — Frontend Models](07_frontend_models.md)
- [09 — Frontend Services](09_frontend_services.md)
- [10 — Frontend Screens](10_frontend_screens.md)
