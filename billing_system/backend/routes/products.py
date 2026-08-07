"""
Product routes.
"""

from flask import Blueprint, jsonify, request
from services.billing_service import billing_service

products_bp = Blueprint("products", __name__, url_prefix="/products")


@products_bp.get("/")
def list_products():
    """
    GET /products/
    Optional query params:
      ?category=Grocery   – filter by category
      ?search=rice        – search by name / category
    """
    category = request.args.get("category", "").strip()
    search = request.args.get("search", "").strip()

    if search:
        data = billing_service.search_products(search)
    elif category:
        data = billing_service.get_products_by_category(category)
    else:
        data = billing_service.get_all_products()

    return jsonify({"success": True, "data": data, "count": len(data)}), 200


@products_bp.get("/<int:product_id>")
def get_product(product_id: int):
    """GET /products/<id>"""
    product = billing_service.get_product_by_id(product_id)
    if product is None:
        return jsonify({"success": False, "message": "Product not found"}), 404
    return jsonify({"success": True, "data": product}), 200
