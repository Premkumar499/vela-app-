"""
Product model – plain Python dataclass.
No ORM dependency so the migration path to SQLAlchemy is straightforward:
replace the dataclass with a db.Model subclass and keep every other file intact.
"""

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Product:
    id: int
    name: str
    unit: str          # e.g. "KG", "PCS", "LTR"
    price: float       # sale price (final price, no GST)
    mrp: float         # maximum retail price
    stock: float       # available stock quantity
    category: str      # e.g. "Grocery", "Dairy"
    description: Optional[str] = field(default="")

    # ------------------------------------------------------------------
    # Serialisation
    # ------------------------------------------------------------------

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "unit": self.unit,
            "price": self.price,
            "mrp": self.mrp,
            "stock": self.stock,
            "category": self.category,
            "description": self.description,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Product":
        return cls(
            id=data["id"],
            name=data["name"],
            unit=data["unit"],
            price=float(data["price"]),
            mrp=float(data.get("mrp", data["price"])),
            stock=float(data["stock"]),
            category=data.get("category", "General"),
            description=data.get("description", ""),
        )
