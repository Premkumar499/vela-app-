# 5. Backend — Models

Plain Python dataclasses with no ORM dependency. The docstrings note the migration
path to SQLAlchemy: replace the dataclass with a `db.Model` subclass and keep every
other file intact.

## 5.1 `Product` — `models/product.py`

```python
@dataclass
class Product:
    id: str            # UUID from Supabase (e.g. "0ddb5e4f-...")
    name: str
    unit: str          # e.g. "KG", "PCS", "LTR", "PKT", "CASE", "Bag", "Nos"
    price: float       # final sale price (no GST)
    mrp: float         # maximum retail price
    stock: float       # available stock quantity
    category: str      # e.g. "Primary", "Appalam", "Bala", "Grocery"
    description: Optional[str] = ""
    image_url: Optional[str] = None
```

- `to_dict()` → JSON-friendly dict (`id`, `name`, `unit`, `price`, `mrp`, `stock`,
  `category`, `description`, `image_url`).
- `from_dict(data)` → constructs from a dict (used when loading sample data / API bodies).

## 5.2 `Customer` — `models/customer.py`

```python
@dataclass
class Customer:
    id: str            # UUID from Supabase
    name: str
    phone: str
    address: str
    email: Optional[str] = ""
    area: Optional[str] = ""
    gstin: Optional[str] = ""
    credit_limit: float = 0.0
    balance: float = 0.0
```

- `to_dict()` / `from_dict()` as above.

## 5.3 `BillItem` — `models/bill.py`

```python
@dataclass
class BillItem:
    product_id: int
    product_name: str
    unit: str
    quantity: float
    rate: float          # sale price per unit (no GST)
    discount_percent: float = 0.0
```

**Computed properties (2-decimal rounding):**
| Property | Formula |
|----------|---------|
| `gross_amount` | `rate × quantity` |
| `discount_amount` | `gross_amount × discount_percent / 100` |
| `total` | `gross_amount − discount_amount` |

Serialisation includes the computed fields (`discount_amount`, `total`) so the client
receives a fully-denormalised line.

## 5.4 `Bill` — `models/bill.py`

```python
@dataclass
class Bill:
    bill_number: str
    date: str                     # ISO-8601
    customer_id: int
    customer_name: str
    customer_phone: str = ""
    payment_type: str = "Cash"    # Cash | Credit | UPI
    items: List[BillItem] = ...
    remarks: str = ""
    sales_type: str = "Retail"    # Retail | Wholesale | Credit
    through: str = ""             # salesman / agent
    area: str = ""
    price_list: str = "Retail"
```

**Computed totals:**
| Property | Meaning |
|----------|---------|
| `subtotal` | Σ `gross_amount` |
| `discount_total` | Σ `discount_amount` |
| `grand_total` | Σ `total` |
| `item_count` | `len(items)` |

`to_dict()` returns the exact JSON shape the Flutter `Bill.fromJson` expects
(`bill_number`, `date`, `customer_id`, `customer_name`, `customer_phone`,
`payment_type`, `sales_type`, `through`, `area`, `price_list`, `remarks`, `items`,
`subtotal`, `discount_total`, `grand_total`, `item_count`).

## How models are used

- **Routes** call `BillingService`, which returns model `to_dict()` payloads.
- **`billing_service._load_products_from_db`** / **`_load_customers_from_db`** map
  Supabase rows onto `Product` / `Customer`.
- **`create_bill`** builds a `Bill` via `Bill.from_dict` for the success response.
- **`_row_to_bill_dict`** converts raw Supabase rows directly to dicts (no dataclass)
  in the same response shape.

## Related docs

- [04 — Backend Services](04_backend_services.md)
- [07 — Frontend Models](07_frontend_models.md)
- [06 — Supabase Database](06_supabase_database.md)
