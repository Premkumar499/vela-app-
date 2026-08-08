# Supabase Database Architecture — ERP Billing System

> Purpose: replace the in-memory + JSON storage with a **Supabase (PostgreSQL)** database.
> This document covers the full schema, migration, data import, and connection plan.

---

## 1. Current State → Target State

| Layer         | Today (prototype)                      | Target (production)              |
|---------------|----------------------------------------|----------------------------------|
| Products      | Hardcoded in `sample_data.py` (545)    | `public.products` table          |
| Customers     | Hardcoded in `sample_data.py` (1)      | `public.customers` table         |
| Bills         | In-memory list + `data/bills.json`     | `public.bills` + `public.bill_items` |
| Bill numbers  | `_invoice_counter` (loses state, races) | Atomic `invoice_series` table    |
| Stock         | In-memory only → resets on restart     | Deducted/restored by DB function |
| Hold / audit  | Not implemented                        | `held_bills`, `audit_log` tables |

---

## 2. How We Connect (two options)

### Option A — Recommended: Flask stays, Supabase is the database
Flutter → Flask API → Supabase (service-role key, RLS bypassed).

- Pros: no Flutter rewiring; all business logic & error handling stay in Python.
- Cons: one extra network hop.
- Config (env vars): `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`.

### Option B — Direct: Flutter → Supabase (`supabase_flutter`)
Flutter talks to Supabase directly with the **anon key + RLS**. Backend Flask can be retired or kept for reporting.

- Pros: fewer moving parts, offline sync possible.
- Cons: RLS policies must be perfect (security), logic moves to DB functions/edge functions.
- `supabase-flutter` uses `create_bill()` via `.rpc()`.

**You can start with Option A now and switch to Option B later** — the schema and the `create_bill` DB function are identical for both.

---

## 3. Entity Relationship

```
invoice_series 1 ──► (generates) bills.bill_number
                         │
customers 1 ────────────► bills.customer_id        (bill stores customer snapshot too)
                         │
bills 1 ────────────────► bill_items (1..N)         (product snapshot per line)
products 1 ─────────────► bill_items.product_id     (nullable: keeps bill if product deleted)
auth.users 1 ───────────► bills.created_by / held_bills.created_by / audit_log.created_by
```

- **products**  = the catalogue ("product input")
- **bills / bill_items** = the sale record ("bill output")
- Denormalised snapshots (`customer_name`, `product_name`, `rate`, `unit`) are intentional — old bills must never change when master data is edited.

---

## 4. Table Reference

### 4.1 `invoice_series`
Atomic counter per invoice series.
| column | type | notes |
|---|---|---|
| `id` | smallint identity PK | |
| `series_prefix` | text UNIQUE | e.g. `INV` |
| `current_number` | bigint | incremented under row lock |
| `padding` | int | `4` → `INV0001` |

Use `public.next_invoice_number('INV')` to get the next number — safe under concurrency.

### 4.2 `products`
| column | type | notes |
|---|---|---|
| `id` | bigint identity PK | preserves existing ids (1–545) |
| `name` | text NOT NULL | |
| `unit` | text | PCS / KG / LTR / PKT / CASE / Bag / Nos |
| `price` | numeric(12,2) | sale price — no GST |
| `mrp` | numeric(12,2) | max retail price |
| `stock` | numeric(12,3) | fractional qty allowed |
| `category` | text | Primary / Appalam / Bala / Pulses … |
| `description` | text | |
| `barcode` | text | future barcode scanning |
| `is_active` | boolean | hide without deleting |

Indexes: `category`, `name` (gin trigram), `barcode`.

### 4.3 `customers`
| column | type | notes |
|---|---|---|
| `id` | bigint identity PK | |
| `name` | text NOT NULL | |
| `phone` / `address` / `area` | text | |
| `gstin` | text | kept for future GST use |
| `credit_limit` | numeric(12,2) | |
| `balance` | numeric(12,2) | outstanding credit |
| `is_active` | boolean | |

### 4.4 `bills` (header)
| column | type | notes |
|---|---|---|
| `id` | uuid PK | `gen_random_uuid()` |
| `bill_number` | text UNIQUE | `INV0033` |
| `series_prefix` | text | which series issued it |
| `customer_id` | bigint FK → customers | `ON DELETE SET NULL` |
| `customer_name` | text NOT NULL | snapshot |
| `customer_phone` | text | snapshot |
| `payment_type` | text | Cash / Credit / UPI / Card |
| `sales_type` | text | Retail / Wholesale / Credit |
| `through`, `area`, `price_list`, `remarks` | text | salesman, area, etc. |
| `subtotal` / `discount_total` / `grand_total` | numeric(12,2) | computed & stored |
| `total_qty` | numeric(12,3) | |
| `item_count` | int | |
| `bill_date` | date | for daily reporting |
| `status` | text | `active` \| `voided` |
| `created_by` | uuid FK → auth.users | who billed |
| `created_at` / `updated_at` | timestamptz | |

### 4.5 `bill_items` (lines)
| column | type | notes |
|---|---|---|
| `id` | uuid PK | |
| `bill_id` | uuid FK → bills | `ON DELETE CASCADE` |
| `line_no` | int | ordering |
| `product_id` | bigint FK → products | `ON DELETE SET NULL` |
| `product_name` | text | snapshot |
| `unit` | text | snapshot |
| `quantity` | numeric(12,3) | |
| `rate` | numeric(12,2) | snapshot |
| `discount_percent` | numeric(5,2) | |
| `discount_amount` / `gross_amount` / `total` | numeric(12,2) | computed & stored |

### 4.6 `held_bills` (Hold feature)
| column | type | notes |
|---|---|---|
| `id` | uuid PK | |
| `customer_name` | text | |
| `items` | jsonb | full cart snapshot |
| `payment_type` | text | |
| `total_qty` / `grand_total` | numeric | display on recall |
| `held_at` | timestamptz | |
| `status` | text | held / recalled / discarded |

### 4.7 `audit_log`
| column | type | notes |
|---|---|---|
| `id` | uuid PK | |
| `action` / `entity` / `entity_id` | text | e.g. `CREATE` / `bill` / `INV0033` |
| `payload` | jsonb | optional detail |
| `created_by` | uuid | |
| `created_at` | timestamptz | |

---

## 5. Migration SQL

The complete, runnable migration is at:

**`supabase/migrations/0001_init.sql`**

Run it in Supabase Dashboard → **SQL Editor** (safe to re-run). It creates:
- all 7 tables + indexes + triggers
- `next_invoice_number(series)` — atomic invoice numbering
- `create_bill(...)` — **one transaction**: invoice number + header + lines + stock deduction + audit, refuses overselling
- `void_bill(bill_number)` — restores stock + marks voided + audit
- reporting views `v_daily_sales`, `v_top_products`
- RLS enabled with `authenticated` policies

### Why `create_bill()` as a DB function?
Today's flow does three steps (number → insert → deduct stock) that can race or partially fail. The DB function wraps everything in a single **atomic transaction** — the same guarantee you get with SQLAlchemy sessions, without the complexity. Supabase clients call it via RPC:

```sql
-- example call
SELECT public.create_bill(
  1, 'Walk-in Customer', '', 'Cash', 'Retail', '', '', 'Retail', '',
  '[{"product_id":1,"product_name":"BACKING SODA","unit":"KG","quantity":2,"rate":225,"discount_percent":0}]'::jsonb
);
```

---

## 6. RLS & Security

- **Flask (service key):** RLS is bypassed automatically. Keep keys in `.env`, never in Flutter.
- **Flutter direct (anon key):** the `authenticated` policies apply. If you later add login, link `created_by` to `auth.uid()`.
- Add a `Content-Length` / payload limit on `create_bill` RPC and the old `/invoice-export/save` route.
- Never expose the service key to the client.

---

## 7. Migrating Existing Data

### 7.1 One-time loader (products + customers + 28 existing bills)

Create a virtualenv with `pip install supabase`, then run:

```python
# scripts/import_to_supabase.py  (run from billing_system/backend)
import json, os, re
from supabase import create_client

URL = os.environ["SUPABASE_URL"]
KEY = os.environ["SUPABASE_SERVICE_KEY"]
sb = create_client(URL, KEY)

# ---- 1. Products (545 rows) -------------------------------------------
from services.sample_data import SAMPLE_PRODUCTS
rows = [p.to_dict() for p in SAMPLE_PRODUCTS]          # id,name,unit,price,mrp,stock,category,description
sb.table("products").upsert(rows, on_conflict="id").execute()
print("products:", len(rows))

# ---- 2. Customers -----------------------------------------------------
from services.sample_data import SAMPLE_CUSTOMERS
sb.table("customers").upsert([c.to_dict() for c in SAMPLE_CUSTOMERS], on_conflict="id").execute()

# ---- 3. Bills (from data/bills.json) -----------------------------------
with open("data/bills.json") as f:
    data = json.load(f)

max_num = 0
for b in data["bills"]:
    num = int(re.sub(r"\D", "", b["bill_number"]))
    max_num = max(max_num, num)

    bill_row = {
        "bill_number":    b["bill_number"],
        "customer_id":    b["customer_id"],
        "customer_name":  b["customer_name"],
        "customer_phone": b.get("customer_phone", ""),
        "payment_type":   b.get("payment_type", "Cash"),
        "sales_type":     b.get("sales_type", "Retail"),
        "through":        b.get("through", ""),
        "area":           b.get("area", ""),
        "price_list":     b.get("price_list", "Retail"),
        "remarks":        b.get("remarks", ""),
        "subtotal":       b.get("subtotal", 0),
        "discount_total": b.get("discount_total", 0),
        "grand_total":    b.get("grand_total", 0),
        "total_qty":      sum(i["quantity"] for i in b["items"]),
        "item_count":     b.get("item_count", len(b["items"])),
        "bill_date":      b.get("date", "")[:10],
        "status":         "active",
    }
    r = sb.table("bills").insert(bill_row).execute()
    bill_id = r.data[0]["id"]

    line_rows = [
        {
            "bill_id": bill_id, "line_no": idx + 1,
            "product_id":       i.get("product_id"),
            "product_name":     i["product_name"],
            "unit":             i.get("unit", "PCS"),
            "quantity":         i["quantity"],
            "rate":             i["rate"],
            "discount_percent": i.get("discount_percent", 0),
            "discount_amount":  i.get("discount_amount", 0),
            "gross_amount":     round(i["rate"] * i["quantity"], 2),
            "total":            i.get("total", 0),
        }
        for idx, i in enumerate(b["items"])
    ]
    sb.table("bill_items").insert(line_rows).execute()

# ---- 4. Sync the counter so next bill continues correctly --------------
sb.table("invoice_series").update({"current_number": max_num}).eq("series_prefix", "INV").execute()
print("bills imported, max INV number =", max_num)
```

Run it:
```bash
export SUPABASE_URL="https://XXXX.supabase.co"
export SUPABASE_SERVICE_KEY="sb_secret..."
python scripts/import_to_supabase.py
```

> ⚠️ The imported bills keep their old `bill_number` (`INV0001`…`INV0032`). The counter is then set to `32`, so the next bill is `INV0033`. No duplicates.

---

## 8. Backend Integration (Flask)

Add `supabase` to `requirements.txt`, then create a thin data layer that mirrors today's `BillingService` interface:

```python
# backend/services/supabase_service.py (sketch)
from supabase import create_client
import os

sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_KEY"])

def get_all_products():
    return sb.table("products").select("*").eq("is_active", True).order("name").execute().data

def create_bill(payload):
    items = [
        {"product_id": it["product_id"], "product_name": it["product_name"],
         "unit": it.get("unit", "PCS"), "quantity": it["quantity"],
         "rate": it["rate"], "discount_percent": it.get("discount_percent", 0)}
        for it in payload["items"]
    ]
    
    data, count = sb.rpc("create_bill", {
        "p_customer_id": payload["customer_id"],
        "p_customer_name": payload["customer_name"],
        "p_customer_phone": payload.get("customer_phone", ""),
        "p_payment_type": payload.get("payment_type", "Cash"),
        "p_sales_type": payload.get("sales_type", "Retail"),
        "p_through": payload.get("through", ""),
        "p_area": payload.get("area", ""),
        "p_price_list": payload.get("price_list", "Retail"),
        "p_remarks": payload.get("remarks", ""),
        "p_items": items,
    }).execute()
    return data[0]  # full bill incl. items
```

Your existing Flask routes (`POST /bill/`, `GET /products/`, …) stay unchanged — only `BillingService` internals swap. The Flutter app keeps working with **zero UI changes**.

---

## 9. Flutter Integration (Option B, direct)

```yaml
# pubspec.yaml
supabase_flutter: ^2.0.0
```

```dart
// main.dart
await Supabase.initialize(
  url: 'https://XXXX.supabase.co',
  anonKey: 'anon...',   // NEVER the service key
);

// saving a bill
final data = await Supabase.instance.client
    .rpc('create_bill', params: {...})
    .execute();
```

---

## 10. Env / Secrets (.env)

```
SUPABASE_URL=https://XXXX.supabase.co
SUPABASE_SERVICE_KEY=sb_secret_xxxx        # backend only
SUPABASE_ANON_KEY=eyJhbGci...              # flutter direct mode
SUPABASE_DB_PASSWORD=...
FLASK_SECRET_KEY=...
```

Keep these out of Git. Add `.env` to `.gitignore`.

---

## 11. Rollback / Backup

- **Backup:** Supabase → Database → Backups (PITR recommended for production), or:
  ```bash
  pg_dump "$DATABASE_URL" -Fc -f backup.dump
  ```
- **Rollback plan:** keep the current JSON backend untouched until the Supabase version passes a week of real use. Both can run side-by-side (different ports / base URLs).
- If a migration goes wrong: re-run `0001_init.sql` is idempotent; to fully reset, `DROP SCHEMA public CASCADE; CREATE SCHEMA public;` then re-run.

---

## 12. Implementation Checklist

- [ ] Run `supabase/migrations/0001_init.sql` in SQL Editor
- [ ] Create a Supabase project & get URL + service key
- [ ] Install `supabase` python lib; write `scripts/import_to_supabase.py`
- [ ] Swap `BillingService` to `SupabaseService` (same method signatures)
- [ ] Move `baseUrl`/keys to `.env`
- [ ] Point Flutter at Flask (unchanged) — verify POS flow end-to-end
- [ ] Test concurrent bill saves → unique numbers guaranteed by DB
- [ ] Restart backend → stock survives (fixes the biggest current bug)
- [ ] Add product/customer CRUD endpoints (next milestone)
- [ ] (Later) direct Flutter mode + login + RLS per user

---

## Related files
- `supabase/migrations/0001_init.sql` — runnable migration
- `billing_system/backend/models/*` — current data shapes being replaced
- `billing_system/backend/services/billing_service.py` — logic moving to DB function `create_bill`
