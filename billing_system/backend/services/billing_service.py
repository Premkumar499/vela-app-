"""
BillingService – in-memory data store with JSON file persistence for bills.
Products are loaded live from the Supabase `products` table on startup.
"""

import json
import os
from datetime import datetime
from typing import Optional

from config import Config
from models.product import Product
from models.customer import Customer
from models.bill import Bill, BillItem
from services.sample_data import SAMPLE_PRODUCTS, SAMPLE_CUSTOMERS

# Path to persist bills across restarts
_BILLS_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "bills.json")


class BillingService:
    """Central service that owns every in-memory collection."""

    def __init__(self) -> None:
        self._products: list[Product] = self._load_products_from_db()
        self._customers: list[Customer] = self._load_customers_from_db()
        self._bills: list[Bill] = []
        self._invoice_counter: int = 0
        self._load_bills()

    # ==================================================================
    # DB product loader
    # ==================================================================

    def _load_products_from_db(self) -> list[Product]:
        """
        Fetch products from Supabase with FK joins:
          categories(name), units(unit_name), brands(brand_name)
        Also fetches available_stock from inventory table keyed by product_id.
        Falls back to SAMPLE_PRODUCTS on any error.
        """
        try:
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

            sb = create_client(url, key)

            # Build a product_id → available_stock map from inventory
            inv_response = sb.table("inventory").select(
                "product_id, available_stock"
            ).execute()
            stock_map: dict[str, float] = {
                str(r["product_id"]): float(r.get("available_stock") or 0.0)
                for r in inv_response.data
            }

            # Fetch all products with joined category/unit/brand names
            response = sb.table("products").select(
                "product_id,"
                "product_name,"
                "selling_price,"
                "sku,"
                "product_image,"
                "categories(name),"
                "units(unit_name),"
                "brands(brand_name)"
            ).order("product_name").execute()

            products: list[Product] = []
            for row in response.data:
                category_name = (row.get("categories") or {}).get("name") or "General"
                unit_name     = (row.get("units") or {}).get("unit_name") or "Nos"
                brand_name    = (row.get("brands") or {}).get("brand_name") or ""
                pid           = str(row["product_id"])

                description = " | ".join(filter(None, [
                    str(row.get("sku") or ""),
                    brand_name,
                ]))

                products.append(Product(
                    id=pid,
                    name=row.get("product_name") or "",
                    unit=unit_name,
                    price=float(row.get("selling_price") or 0.0),
                    mrp=float(row.get("selling_price") or 0.0),
                    stock=stock_map.get(pid, 0.0),
                    category=category_name,
                    description=description,
                    image_url=row.get("product_image") or None,
                ))

            print(f"[BillingService] Loaded {len(products)} products from Supabase.")
            return products

        except Exception as exc:
            import traceback
            print(f"[BillingService] Supabase load FAILED: {exc}")
            traceback.print_exc()
            return list(SAMPLE_PRODUCTS)

    # ==================================================================
    # DB customer loader
    # ==================================================================

    def _load_customers_from_db(self) -> list[Customer]:
        """
        Fetch customers from Supabase `customers` table.
        Falls back to SAMPLE_CUSTOMERS on any error.
        """
        # Always prepend Walk-in Customer
        walk_in = Customer(
            id="00000000-0000-0000-0000-000000000000",
            name="Walk-in Customer",
            phone="",
            address="",
            email="",
            area="General",
        )
        try:
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

            sb = create_client(url, key)

            response = (
                sb.table("customers")
                .select("customer_id, name, phone, email, address")
                .order("name")
                .execute()
            )

            customers: list[Customer] = [walk_in]
            for row in response.data:
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

            print(f"[BillingService] Loaded {len(customers) - 1} customers from Supabase.")
            return customers

        except Exception as exc:
            import traceback
            print(f"[BillingService] Supabase customer load FAILED: {exc}")
            traceback.print_exc()
            return [walk_in] + list(SAMPLE_CUSTOMERS)

    # ==================================================================
    # Persistence helpers
    # ==================================================================

    def _bills_file(self) -> str:
        os.makedirs(os.path.dirname(_BILLS_FILE), exist_ok=True)
        return _BILLS_FILE

    def _load_bills(self) -> None:
        """Load bills from disk on startup."""
        path = self._bills_file()
        if not os.path.exists(path):
            return
        try:
            with open(path, "r") as f:
                data = json.load(f)
            self._bills = [Bill.from_dict(b) for b in data.get("bills", [])]
            self._invoice_counter = data.get("counter", 0)
        except Exception:
            self._bills = []
            self._invoice_counter = 0

    def _save_bills(self) -> None:
        """Persist bills to disk."""
        try:
            with open(self._bills_file(), "w") as f:
                json.dump({
                    "counter": self._invoice_counter,
                    "bills": [b.to_dict() for b in self._bills],
                }, f, indent=2)
        except Exception:
            pass  # never crash on persistence failure

    # ==================================================================
    # Invoice numbering
    # ==================================================================

    def _next_bill_number(self) -> str:
        self._invoice_counter += 1
        padded = str(self._invoice_counter).zfill(Config.INVOICE_PADDING)
        return f"{Config.INVOICE_PREFIX}{padded}"

    # ==================================================================
    # Products
    # ==================================================================

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

    def _deduct_stock(self, product_id: int, quantity: float) -> None:
        for p in self._products:
            if p.id == product_id:
                p.stock = max(0.0, p.stock - quantity)
                break

    def _restore_stock(self, product_id: int, quantity: float) -> None:
        for p in self._products:
            if p.id == product_id:
                p.stock += quantity
                break

    # ==================================================================
    # Customers
    # ==================================================================

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

    # ==================================================================
    # Bills
    # ==================================================================

    def create_bill(self, payload: dict) -> dict:
        errors = self._validate_bill_payload(payload)
        if errors:
            return {"success": False, "message": "; ".join(errors)}

        bill_number = self._next_bill_number()
        payload["bill_number"] = bill_number
        payload["date"] = datetime.now().isoformat()

        bill = Bill.from_dict(payload)
        self._bills.append(bill)

        for item in bill.items:
            self._deduct_stock(item.product_id, item.quantity)

        self._save_bills()  # persist immediately

        return {
            "success": True,
            "message": "Bill Saved Successfully",
            "bill_number": bill_number,
            "bill": bill.to_dict(),
        }

    def get_all_bills(self) -> list[dict]:
        return [b.to_dict() for b in reversed(self._bills)]

    def get_bill_by_number(self, bill_number: str) -> Optional[dict]:
        for b in self._bills:
            if b.bill_number == bill_number:
                return b.to_dict()
        return None

    def delete_bill(self, bill_number: str) -> dict:
        for i, b in enumerate(self._bills):
            if b.bill_number == bill_number:
                for item in b.items:
                    self._restore_stock(item.product_id, item.quantity)
                self._bills.pop(i)
                self._save_bills()
                return {"success": True, "message": f"Bill {bill_number} deleted"}
        return {"success": False, "message": f"Bill {bill_number} not found"}

    # ==================================================================
    # Summary
    # ==================================================================

    def get_dashboard_summary(self) -> dict:
        total_sales = sum(b.grand_total for b in self._bills)
        return {
            "total_bills": len(self._bills),
            "total_sales": round(total_sales, 2),
            "total_products": len(self._products),
            "total_customers": len(self._customers),
        }

    # ==================================================================
    # Validation
    # ==================================================================

    def _validate_bill_payload(self, payload: dict) -> list[str]:
        errors: list[str] = []
        if not payload.get("customer_id"):
            errors.append("customer_id is required")
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
