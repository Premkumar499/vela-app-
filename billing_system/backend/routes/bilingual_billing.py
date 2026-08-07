"""
Simplified Bilingual Billing Routes - for Vela Agency Bill System
"""

from flask import Blueprint, jsonify, request
from datetime import datetime

bilingual_bp = Blueprint("bilingual", __name__, url_prefix="/api/bilingual")

# In-memory storage for simplified bills
_simple_bills = []
_bill_counter = 94001  # Start from 94001 as per your example


@bilingual_bp.route("/bills", methods=["POST"])
def create_simple_bill():
    """Create a new simplified bill"""
    global _bill_counter
    
    try:
        data = request.get_json()
        
        # Generate bill number
        bill_no = str(_bill_counter).zfill(5)
        _bill_counter += 1
        
        # Get current date and time
        now = datetime.now()
        date = now.strftime("%d/%m/%Y")
        time = now.strftime("%I:%M %p")
        
        bill = {
            "billNo": bill_no,
            "date": date,
            "time": time,
            "paymentMode": data.get("paymentMode", "CASH"),
            "customerName": data.get("customerName", "Walk-in Customer"),
            "items": data.get("items", [])
        }
        
        _simple_bills.append(bill)
        
        return jsonify({
            "success": True,
            "message": "Bill created successfully",
            "bill": bill
        }), 201
        
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error creating bill: {str(e)}"
        }), 400


@bilingual_bp.route("/bills", methods=["GET"])
def get_all_simple_bills():
    """Get all simplified bills"""
    return jsonify({
        "success": True,
        "bills": list(reversed(_simple_bills))  # Most recent first
    }), 200


@bilingual_bp.route("/bills/<bill_no>", methods=["GET"])
def get_simple_bill(bill_no):
    """Get a specific bill by number"""
    for bill in _simple_bills:
        if bill["billNo"] == bill_no:
            return jsonify({
                "success": True,
                "bill": bill
            }), 200
    
    return jsonify({
        "success": False,
        "message": f"Bill {bill_no} not found"
    }), 404


@bilingual_bp.route("/bills/<bill_no>", methods=["DELETE"])
def delete_simple_bill(bill_no):
    """Delete a bill by number"""
    global _simple_bills
    
    for i, bill in enumerate(_simple_bills):
        if bill["billNo"] == bill_no:
            _simple_bills.pop(i)
            return jsonify({
                "success": True,
                "message": f"Bill {bill_no} deleted successfully"
            }), 200
    
    return jsonify({
        "success": False,
        "message": f"Bill {bill_no} not found"
    }), 404


@bilingual_bp.route("/generate-bill-number", methods=["GET"])
def generate_bill_number():
    """Generate next bill number without creating a bill"""
    bill_no = str(_bill_counter).zfill(5)
    now = datetime.now()
    
    return jsonify({
        "success": True,
        "billNo": bill_no,
        "date": now.strftime("%d/%m/%Y"),
        "time": now.strftime("%I:%M %p")
    }), 200
