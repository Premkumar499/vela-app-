"""
Bill history routes.
"""

from flask import Blueprint, jsonify
from services.billing_service import billing_service

history_bp = Blueprint("history", __name__, url_prefix="/bills")


@history_bp.get("/")
def list_bills():
    """GET /bills/ – return all bills, newest first."""
    data = billing_service.get_all_bills()
    return jsonify({"success": True, "data": data, "count": len(data)}), 200


@history_bp.get("/<string:bill_number>")
def get_bill(bill_number: str):
    """GET /bills/<bill_number>"""
    bill = billing_service.get_bill_by_number(bill_number)
    if bill is None:
        return jsonify({"success": False, "message": f"Bill {bill_number} not found"}), 404
    return jsonify({"success": True, "data": bill}), 200


@history_bp.delete("/<string:bill_number>")
def delete_bill(bill_number: str):
    """DELETE /bills/<bill_number>"""
    result = billing_service.delete_bill(bill_number)
    status = 200 if result["success"] else 404
    return jsonify(result), status


@history_bp.get("/summary")
def summary():
    """GET /bills/summary – dashboard totals."""
    data = billing_service.get_dashboard_summary()
    return jsonify({"success": True, "data": data}), 200
