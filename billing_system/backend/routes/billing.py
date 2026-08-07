"""
Billing routes – create a new bill.
"""

from flask import Blueprint, jsonify, request
from services.billing_service import billing_service

billing_bp = Blueprint("billing", __name__, url_prefix="/bill")


@billing_bp.post("/")
def create_bill():
    """
    POST /bill/
    Body (JSON):
    {
      "customer_id": 1,
      "customer_name": "Walk-in Customer",
      "payment_type": "Cash",
      "sales_type": "Retail",
      "remarks": "",
      "through": "",
      "area": "",
      "price_list": "Retail",
      "items": [
        {
          "product_id": 1,
          "product_name": "BACKING SODA",
          "unit": "KG",
          "quantity": 2,
          "rate": 225.00,
          "discount_percent": 0
        }
      ]
    }
    """
    payload = request.get_json(silent=True)

    if not payload:
        return jsonify({"success": False, "message": "Invalid or missing JSON body"}), 400

    result = billing_service.create_bill(payload)

    if not result["success"]:
        return jsonify(result), 422

    return jsonify(result), 201
