"""
Customer model.
"""

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Customer:
    id: str            # UUID from Supabase
    name: str
    phone: str
    address: str
    email: Optional[str] = field(default="")
    area: Optional[str] = field(default="")
    gstin: Optional[str] = field(default="")
    credit_limit: float = 0.0
    balance: float = 0.0

    # ------------------------------------------------------------------
    # Serialisation
    # ------------------------------------------------------------------

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "phone": self.phone,
            "address": self.address,
            "email": self.email,
            "area": self.area,
            "gstin": self.gstin,
            "credit_limit": self.credit_limit,
            "balance": self.balance,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Customer":
        return cls(
            id=str(data["id"]),
            name=data["name"],
            phone=data.get("phone", ""),
            address=data.get("address", ""),
            email=data.get("email", ""),
            area=data.get("area", ""),
            gstin=data.get("gstin", ""),
            credit_limit=float(data.get("credit_limit", 0)),
            balance=float(data.get("balance", 0)),
        )
