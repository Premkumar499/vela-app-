"""
BillingService – Supabase-backed bill storage.
Bills are saved to erp_billing_system + erp_billing_system_items tables.
Products and customers are still loaded from Supabase on startup.
"""

import os
from datetime import datetime
from typing import Optional

from config import Config
from models.product import Product
from models.customer import Customer
from models.bill import Bill, BillItem
from services.sample_data import SAMPLE_PRODUCTS, SAMPLE_CUSTOMERS


def _amount_in_words(amount: float) -> str:
    """Convert a rupee amount to words, e.g. 1379.71 → 'One Thousand Three Hundred Seventy Nine Rupees and Seventy One Paise Only'"""
    ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
            'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
            'Seventeen', 'Eighteen', 'Nineteen']
    tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety']

    def _words(n: int) -> str:
        if n == 0:
            return ''
        elif n < 20:
            return ones[n]
        elif n < 100:
            return tens[n // 10] + ((' ' + ones[n % 10]) if n % 10 else '')
        elif n < 1000:
            return ones[n // 100] + ' Hundred' + ((' ' + _words(n % 100)) if n % 100 else '')
        elif n < 100000:
            return _words(n // 1000) + ' Thousand' + ((' ' + _words(n % 1000)) if n % 1000 else '')
        elif n < 10000000:
            return _words(n // 100000) + ' Lakh' + ((' ' + _words(n % 100000)) if n % 100000 else '')
        else:
            return _words(n // 10000000) + ' Crore' + ((' ' + _words(n % 10000000)) if n % 10000000 else '')

    rupees = int(amount)
    paise  = round((amount - rupees) * 100)
    result = (_words(rupees) + ' Rupees') if rupees else ''
    if paise:
        result += (' and ' if result else '') + _words(paise) + ' Paise'
    return (result + ' Only').strip() if result else 'Zero Rupees Only'


def _get_supabase():
    """Return an authenticated Supabase client."""
    from dotenv import load_dotenv
    from supabase import create_client
    _env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    load_dotenv(_env_path, override=True)
    url = os.getenv("SUPABASE_URL", "")
    key = (
        os.getenv("SUPABASE_SERVICE_KEY")
        or os.getenv("SUPABASE_SECRET_KEY")
        or ""
    )
    if not url or not key:
        raise ValueError("SUPABASE_URL or key not set in .env")
    return create_client(url, key)


class BillingService:

    def __init__(self) -> None:
        self._products: list[Product] = self._load_products_from_db()
        self._customers: list[Customer] = self._load_customers_from_db()
        self._hour_prefix: str = ""
        self._hour_seq: int = 0
        self._seed_hour_counter()


    # ------------------------------------------------------------------
    # Invoice number  →  2026AUG08A161  (bill 1 at 16:xx),  2026AUG08A172 (bill 2 at 17:xx)
    # Format: YYYY + MMM(upper) + DD + A + HH + sequence(1…n)
    # Sequence resets to 1 every new hour (or on server restart — seeded from DB)
    # ------------------------------------------------------------------

    def _seed_hour_counter(self) -> None:
        """Sync in-memory counter with the highest sequence in DB for the current hour."""
        now = datetime.now()
        prefix = now.strftime("%Y%b%d").upper() + Config.INVOICE_CONSTANT + now.strftime("%H")
        try:
            sb = _get_supabase()
            resp = sb.table("erp_billing_system").select("bill_no").execute()
            seqs = [
                int(bn[len(prefix):])
                for row in resp.data
                for bn in [row.get("bill_no", "")]
                if bn.startswith(prefix) and bn[len(prefix):].isdigit()
            ]
            self._hour_prefix = prefix
            self._hour_seq = max(seqs, default=0)
        except Exception:
            self._hour_prefix = prefix
            self._hour_seq = 0

    def _next_bill_number(self) -> str:
        now = datetime.now()
        current_prefix = now.strftime("%Y%b%d").upper() + Config.INVOICE_CONSTANT + now.strftime("%H")
        # Hour rolled over — re-seed from DB for the new hour
        if current_prefix != self._hour_prefix:
            self._hour_prefix = current_prefix
            self._hour_seq = 0
            self._seed_hour_counter()
        self._hour_seq += 1
        return self._hour_prefix + str(self._hour_seq)


    # ------------------------------------------------------------------
    # Products loader
    # ------------------------------------------------------------------

    def _load_products_from_db(self) -> list[Product]:
        try:
            sb = _get_supabase()
            inv_resp = sb.table("inventory").select("product_id, available_stock").execute()
            stock_map: dict[str, float] = {
                str(r["product_id"]): float(r.get("available_stock") or 0.0)
                for r in inv_resp.data
            }
            resp = sb.table("products").select(
                "product_id, product_name, selling_price, sku, product_image,"
                "categories(name), units(unit_name), brands(brand_name)"
            ).order("product_name").execute()

            products: list[Product] = []
            for row in resp.data:
                pid = str(row["product_id"])
                products.append(Product(
                    id=pid,
                    name=row.get("product_name") or "",
                    unit=((row.get("units") or {}).get("unit_name") or "Nos"),
                    price=float(row.get("selling_price") or 0.0),
                    mrp=float(row.get("selling_price") or 0.0),
                    stock=stock_map.get(pid, 0.0),
                    category=((row.get("categories") or {}).get("name") or "General"),
                    description=" | ".join(filter(None, [
                        str(row.get("sku") or ""),
                        ((row.get("brands") or {}).get("brand_name") or ""),
                    ])),
                    image_url=row.get("product_image") or None,
                ))
            print(f"[BillingService] Loaded {len(products)} products.")
            return products
        except Exception as exc:
            import traceback; traceback.print_exc()
            print(f"[BillingService] Product load failed: {exc}")
            return list(SAMPLE_PRODUCTS)


    # ------------------------------------------------------------------
    # Customers loader
    # ------------------------------------------------------------------

    def _load_customers_from_db(self) -> list[Customer]:
        walk_in = Customer(
            id="00000000-0000-0000-0000-000000000000",
            name="Walk-in Customer", phone="", address="", email="", area="General",
        )
        try:
            sb = _get_supabase()
            resp = (
                sb.table("customers")
                .select("customer_id, name, phone, email, address")
                .order("name")
                .execute()
            )
            customers: list[Customer] = [walk_in]
            for row in resp.data:
                name = (row.get("name") or "").strip()
                if not name:
                    continue
                customers.append(Customer(
                    id=str(row["customer_id"]),
                    name=name,
                    phone=row.get("phone") or "",
                    address=row.get("address") or "",
                    email=row.get("email") or "",
                    area="",
                ))
            print(f"[BillingService] Loaded {len(customers) - 1} customers.")
            return customers
        except Exception as exc:
            import traceback; traceback.print_exc()
            return [walk_in] + list(SAMPLE_CUSTOMERS)


    # ------------------------------------------------------------------
    # Products – public API
    # ------------------------------------------------------------------

    def get_all_products(self) -> list[dict]:
        return [p.to_dict() for p in self._products]

    def get_product_by_id(self, product_id: str) -> Optional[dict]:
        for p in self._products:
            if p.id == str(product_id):
                return p.to_dict()
        return None

    def get_products_by_category(self, category: str) -> list[dict]:
        return [p.to_dict() for p in self._products if p.category.lower() == category.lower()]

    def search_products(self, query: str) -> list[dict]:
        q = query.lower()
        return [p.to_dict() for p in self._products if q in p.name.lower() or q in p.category.lower()]

    def _deduct_stock(self, product_id, quantity: float) -> None:
        for p in self._products:
            if p.id == str(product_id):
                p.stock = max(0.0, p.stock - quantity)
                break

    def _restore_stock(self, product_id, quantity: float) -> None:
        for p in self._products:
            if p.id == str(product_id):
                p.stock += quantity
                break


    # ------------------------------------------------------------------
    # Customers – public API
    # ------------------------------------------------------------------

    def get_all_customers(self) -> list[dict]:
        return [c.to_dict() for c in self._customers]

    def get_customer_by_id(self, customer_id: str) -> Optional[dict]:
        for c in self._customers:
            if c.id == customer_id:
                return c.to_dict()
        return None

    def search_customers(self, query: str) -> list[dict]:
        q = query.lower()
        return [
            c.to_dict() for c in self._customers
            if q in c.name.lower() or q in (c.phone or "") or q in (c.area or "").lower()
        ]

    def create_customer(self, name: str, phone: str = "", email: str = "", address: str = "") -> dict:
        try:
            sb = _get_supabase()
            resp = sb.table("customers").insert({
                "name": name,
                "phone": phone or None,
                "email": email or None,
                "address": address or None,
            }).execute()
            row = resp.data[0]
            customer = Customer(
                id=str(row["customer_id"]),
                name=row.get("name") or name,
                phone=row.get("phone") or "",
                address=row.get("address") or "",
                email=row.get("email") or "",
            )
            self._customers.append(customer)
            return {"success": True, "data": customer.to_dict()}
        except Exception as exc:
            import traceback; traceback.print_exc()
            return {"success": False, "message": str(exc)}


    # ------------------------------------------------------------------
    # Bills – CREATE (save to Supabase erp_billing_system)
    # ------------------------------------------------------------------

    def create_bill(self, payload: dict) -> dict:
        errors = self._validate_bill_payload(payload)
        if errors:
            return {"success": False, "message": "; ".join(errors)}

        bill_number = self._next_bill_number()
        now = datetime.now()
        items = payload.get("items", [])

        grand_total = round(sum(
            float(i.get("rate", 0)) * float(i.get("quantity", 0)) *
            (1 - float(i.get("discount_percent", 0)) / 100)
            for i in items
        ), 2)

        bill_header = {
            "business_name": "VELA AGENCY",
            "bill_no":       bill_number,
            "bill_date":     now.strftime("%Y-%m-%d"),
            "bill_time":     now.strftime("%H:%M:%S"),
            "payment_mode":  payload.get("payment_type", "Cash").upper(),
            "total_items":   len(items),
            "total_quantity": round(sum(float(i.get("quantity", 0)) for i in items), 2),
            "grand_total":   grand_total,
        }

        # Line rows for user bill (no unit column)
        def _user_line_rows(parent_id: str) -> list[dict]:
            return [
                {
                    "bill_id":     parent_id,
                    "sno":         idx + 1,
                    "description": item.get("product_name", ""),
                    "quantity":    float(item.get("quantity", 0)),
                    "rate":        float(item.get("rate", 0)),
                    "amount":      round(
                        float(item.get("rate", 0)) * float(item.get("quantity", 0)) *
                        (1 - float(item.get("discount_percent", 0)) / 100), 2
                    ),
                }
                for idx, item in enumerate(items)
            ]

        # Line rows for company bill (includes unit)
        def _company_line_rows(parent_id: str) -> list[dict]:
            return [
                {
                    "invoice_id":  parent_id,
                    "sno":         idx + 1,
                    "description": item.get("product_name", ""),
                    "unit":        item.get("unit", "Nos"),
                    "quantity":    float(item.get("quantity", 0)),
                    "rate":        float(item.get("rate", 0)),
                    "amount":      round(
                        float(item.get("rate", 0)) * float(item.get("quantity", 0)) *
                        (1 - float(item.get("discount_percent", 0)) / 100), 2
                    ),
                }
                for idx, item in enumerate(items)
            ]

        try:
            sb = _get_supabase()

            # ── 1. User Bill table ──────────────────────────────────────
            header_resp = sb.table("erp_billing_system").insert(bill_header).execute()
            bill_id = header_resp.data[0]["bill_id"]
            sb.table("erp_billing_system_items").insert(_user_line_rows(bill_id)).execute()

            # ── 2. Company Bill table (same data) ───────────────────────
            company_header = {
                "invoice_no":      bill_number,
                "invoice_date":    now.strftime("%Y-%m-%d"),
                "customer_name":   payload.get("customer_name", "Walk-in Customer"),
                "customer_phone":  payload.get("customer_phone", "") or "",
                "payment_mode":    payload.get("payment_type", "Cash"),
                "transaction_id":  bill_number,
                "upi_id":          None,
                "total_amount":    grand_total,
                "amount_in_words": _amount_in_words(grand_total),
            }
            company_resp = sb.table("erp_billing_system_company").insert(company_header).execute()
            invoice_id = company_resp.data[0]["invoice_id"]
            sb.table("erp_billing_system_company_items").insert(_company_line_rows(invoice_id)).execute()

            # ── 3. Deduct stock in memory ───────────────────────────────
            for item in items:
                self._deduct_stock(item.get("product_id"), float(item.get("quantity", 0)))

            bill = Bill.from_dict({**payload, "bill_number": bill_number, "date": now.isoformat()})
            return {
                "success": True,
                "message": "Bill Saved Successfully",
                "bill_number": bill_number,
                "bill": bill.to_dict(),
            }

        except Exception as exc:
            import traceback; traceback.print_exc()
            return {"success": False, "message": f"Failed to save bill: {exc}"}


    # ------------------------------------------------------------------
    # Bills – READ / DELETE (from Supabase)
    # ------------------------------------------------------------------

    def get_all_bills(self) -> list[dict]:
        try:
            sb = _get_supabase()
            rows = (
                sb.table("erp_billing_system")
                .select("*, erp_billing_system_items(*)")
                .order("created_at", desc=True)
                .execute()
            ).data
            return [self._row_to_bill_dict(r) for r in rows]
        except Exception as exc:
            print(f"[BillingService] get_all_bills failed: {exc}")
            return []

    def get_bill_by_number(self, bill_number: str) -> Optional[dict]:
        try:
            sb = _get_supabase()
            rows = (
                sb.table("erp_billing_system")
                .select("*, erp_billing_system_items(*)")
                .eq("bill_no", bill_number)
                .execute()
            ).data
            return self._row_to_bill_dict(rows[0]) if rows else None
        except Exception as exc:
            print(f"[BillingService] get_bill_by_number failed: {exc}")
            return None

    def delete_bill(self, bill_number: str) -> dict:
        try:
            sb = _get_supabase()

            # ── 1. User bill DB (items auto-cascade via FK ON DELETE CASCADE) ──
            user_rows = (
                sb.table("erp_billing_system")
                .select("bill_id")
                .eq("bill_no", bill_number)
                .execute()
            ).data
            if not user_rows:
                return {"success": False, "message": f"Bill {bill_number} not found"}

            sb.table("erp_billing_system").delete().eq("bill_id", user_rows[0]["bill_id"]).execute()
            print(f"[delete_bill] erp_billing_system deleted: {bill_number}")

            # ── 2. Company invoice DB (items auto-cascade via FK ON DELETE CASCADE) ──
            company_rows = (
                sb.table("erp_billing_system_company")
                .select("invoice_id")
                .eq("invoice_no", bill_number)
                .execute()
            ).data
            if company_rows:
                sb.table("erp_billing_system_company").delete().eq("invoice_id", company_rows[0]["invoice_id"]).execute()
                print(f"[delete_bill] erp_billing_system_company deleted: {bill_number}")
            else:
                print(f"[delete_bill] No matching company invoice found for: {bill_number}")

            # ── 3. Delete PDFs from both Storage buckets ─────────────────
            pdf_file = f"{bill_number}.pdf"
            for bucket in ("erp_billing_system", "erp_billing_system_company"):
                try:
                    sb.storage.from_(bucket).remove([pdf_file])
                    print(f"[delete_bill] Storage bucket '{bucket}' removed: {pdf_file}")
                except Exception as bucket_exc:
                    # File may not exist in bucket — not a fatal error
                    print(f"[delete_bill] Storage bucket '{bucket}' skip ({bucket_exc})")

            # ── 4. Re-sync hour counter so next bill continues from real max ──
            self._seed_hour_counter()

            return {"success": True, "message": f"Bill {bill_number} deleted"}
        except Exception as exc:
            import traceback; traceback.print_exc()
            return {"success": False, "message": str(exc)}


    # ------------------------------------------------------------------
    # Helper – Supabase row → Bill dict (same shape Flutter expects)
    # ------------------------------------------------------------------

    def _row_to_bill_dict(self, row: dict) -> dict:
        items_raw = sorted(
            row.get("erp_billing_system_items") or [],
            key=lambda x: x.get("sno", 0)
        )
        bill_items = [
            {
                "product_id":       None,
                "product_name":     it["description"],
                "unit":             "Nos",
                "quantity":         float(it["quantity"]),
                "rate":             float(it["rate"]),
                "discount_percent": 0.0,
                "discount_amount":  0.0,
                "total":            float(it["amount"]),
            }
            for it in items_raw
        ]
        grand_total = float(row["grand_total"])
        return {
            "bill_number":    row["bill_no"],
            "date":           f"{row['bill_date']}T{row.get('bill_time', '00:00:00')}",
            "customer_id":    0,
            "customer_name":  row.get("business_name", "VELA AGENCY"),
            "customer_phone": "",
            "payment_type":   row.get("payment_mode", "Cash"),
            "sales_type":     "Retail",
            "through":        "",
            "area":           "",
            "price_list":     "Retail",
            "remarks":        "",
            "items":          bill_items,
            "subtotal":       grand_total,
            "discount_total": 0.0,
            "grand_total":    grand_total,
            "gst_total":      0.0,
            "round_off":      0.0,
            "gst_breakup":    {},
            "item_count":     row.get("total_items", len(bill_items)),
        }


    # ------------------------------------------------------------------
    # Dashboard summary
    # ------------------------------------------------------------------

    def get_dashboard_summary(self) -> dict:
        try:
            sb = _get_supabase()
            resp = sb.table("erp_billing_system").select("grand_total").execute()
            total_sales = sum(float(r["grand_total"]) for r in resp.data)
            total_bills = len(resp.data)
        except Exception:
            total_sales, total_bills = 0.0, 0
        return {
            "total_bills":     total_bills,
            "total_sales":     round(total_sales, 2),
            "total_products":  len(self._products),
            "total_customers": len(self._customers),
        }

    # ------------------------------------------------------------------
    # Validation
    # ------------------------------------------------------------------

    def _validate_bill_payload(self, payload: dict) -> list[str]:
        errors: list[str] = []
        if not payload.get("customer_name"):
            errors.append("customer_name is required")
        items = payload.get("items", [])
        if not items:
            errors.append("Bill must contain at least one item")
            return errors
        for idx, item in enumerate(items, start=1):
            if not item.get("product_id"):
                errors.append(f"Item {idx}: product_id is required")
            if float(item.get("quantity", 0)) <= 0:
                errors.append(f"Item {idx}: quantity must be greater than 0")
            if float(item.get("rate", 0)) <= 0:
                errors.append(f"Item {idx}: rate must be greater than 0")
        return errors


# Module-level singleton
billing_service = BillingService()
