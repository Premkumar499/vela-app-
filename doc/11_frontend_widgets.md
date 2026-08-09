# 11. Frontend — Widgets

Location: `billing_system/frontend/flutter_application/lib/widgets/`

Reusable UI pieces. Most are POS-flavoured (`pos_*`) used by the billing screen, plus a
set for invoice/company view and generic cards.

## 11.1 POS widgets

### `PosProductCard` — `widgets/pos_product_card.dart`
Compact product tile in the POS grid. Shows name, unit, price, and available stock.
Disabled look when out of stock. Tap → adds to cart.

### `PosBillItemRow` — `widgets/pos_bill_item_row.dart`
A line in the active cart: description, qty, rate, discount %, amount, and a remove
button. Tap opens `QuantityDialog`.

### `PosSummarySection` — `widgets/pos_summary_section.dart`
Collapsible totals block: **subtotal**, **discount total**, **grand total** (no GST).
Used at the bottom of the cart panel.

### `PosPaymentSelector` — `widgets/pos_payment_selector.dart`
Payment-mode chooser — **Cash / Credit / UPI** toggle chips. Also exposes sales-type /
price-list selection used when saving the bill.

### `QuantityDialog` — `widgets/quantity_dialog.dart`
Modal dialog to set quantity and discount % for a cart item, clamped to available
stock.

### `ModernCartItem` / `ModernProductGridItem` — `modern_cart_item.dart`, `modern_product_grid_item.dart`
Alternate, more polished cart-item and product-grid widgets (used by the "modern"
billing variants).

### `BillingTable` — `widgets/billing_table.dart`
Read-only line-item table (description, qty, rate, amount) — used in bill history /
details.

### `BottomToolbar` — `widgets/bottom_toolbar.dart`
Bottom action bar with the total and the primary **Complete Sale** button.

## 11.2 Invoice widgets

### `InvoicePreview` — `widgets/invoice_preview.dart`
Full company-invoice layout (navy/blue colour scheme):

- **Header**: VELA AGENCY name/address, GSTIN/FSSAI/PAN, phone/email, logo area.
- **Invoice meta**: invoice no, date, time, payment mode, txn id, UPI id.
- **Bill-to**: customer name, address, GSTIN, PAN.
- **Items table**: description, HSN, unit, qty, rate, amount.
- **Totals**: subtotal, discount, **grand total**, amount-in-words.
- **Footer**: bank details (HDFC), signature blocks, "E.&O.E.".
- Wrapped in a `RepaintBoundary` so it can be exported as an image
  (`InvoiceExportService.saveInvoiceAsImage`).

### `ReceiptWidget` — `widgets/receipt_widget.dart`
Compact thermal-style customer receipt layout (small width, monospace-friendly): shop
header, date, bill number, items, totals. Used for the in-app preview before saving.

## 11.3 Bilingual bill

### `BilingualBillDashboard` — `widgets/bilingual_bill_dashboard.dart`
Dialog shown after completing a sale. It:

- Translates item descriptions English → **Tamil** using `translateToTamil`.
- Renders a preview with both languages.
- Auto-saves the **customer receipt** image and the **company invoice** PDF to the
  respective Storage buckets via `InvoiceExportService` (`_autoSaveBoth()`).
- Lets the user re-save / view saved URLs; has an awaited-fix for sequential saves.

## 11.4 Cards & shared

| Widget | Purpose |
|--------|---------|
| `ProductCard` — `product_card.dart` | General catalogue card (name, price, stock, edit/delete actions) |
| `CustomerCard` — `customer_card.dart` | Customer info card (name, phone, area, balance) |
| `GrandTotalCard` — `grand_total_card.dart` | Prominent grand-total display used in dashboards/cart |
| `TaxSummary` — `tax_summary.dart` | Tax breakdown panel — **shows ₹0.00 GST rows only** (no GST) |
| `TopPanel` — `top_panel.dart` | POS top bar: search field, selected customer chip, live total |

## Related docs

- [08 — Frontend State Provider](08_frontend_state_provider.md)
- [10 — Frontend Screens](10_frontend_screens.md)
- [12 — Frontend Utils](12_frontend_utils.md)
