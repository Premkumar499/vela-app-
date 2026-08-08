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


@customers_bp.get("/<string:customer_id>")
def get_customer(customer_id: str):
    """GET /customers/<uuid>"""
    customer = billing_service.get_customer_by_id(customer_id)
    if customer is None:
        return jsonify({"success": False, "message": "Customer not found"}), 404
    return jsonify({"success": True, "data": customer}), 200


@customers_bp.post("/")
def create_customer():
    """
    POST /customers/
    Body: { "name": str, "phone": str, "email": str, "address": str }
    Inserts into Supabase and returns the created customer.
    """
    body = request.get_json(silent=True) or {}
    name = (body.get("name") or "").strip()
    if not name:
        return jsonify({"success": False, "message": "name is required"}), 400

    result = billing_service.create_customer(
        name=name,
        phone=(body.get("phone") or "").strip(),
        email=(body.get("email") or "").strip(),
        address=(body.get("address") or "").strip(),
    )
    if result.get("success"):
        return jsonify(result), 201
    return jsonify(result), 500
