"""
Customer routes.
"""

from flask import Blueprint, jsonify, request
from services.billing_service import billing_service

customers_bp = Blueprint("customers", __name__, url_prefix="/customers")


@customers_bp.get("/")
def list_customers():
    """
    GET /customers/
    Optional query params:
      ?search=abc   – search by name / phone / area
    """
    search = request.args.get("search", "").strip()

    if search:
        data = billing_service.search_customers(search)
    else:
        data = billing_service.get_all_customers()

    return jsonify({"success": True, "data": data, "count": len(data)}), 200


@customers_bp.get("/<int:customer_id>")
def get_customer(customer_id: int):
    """GET /customers/<id>"""
    customer = billing_service.get_customer_by_id(customer_id)
    if customer is None:
        return jsonify({"success": False, "message": "Customer not found"}), 404
    return jsonify({"success": True, "data": customer}), 200
