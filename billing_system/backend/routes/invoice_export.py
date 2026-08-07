"""
Invoice export routes - save invoice images
"""

import os
import base64
from flask import Blueprint, jsonify, request
from datetime import datetime

invoice_export_bp = Blueprint("invoice_export", __name__, url_prefix="/invoice-export")

# Base path for storing invoices
INVOICES_BASE_PATH = os.path.join(os.path.dirname(__file__), "..", "invoices")


@invoice_export_bp.post("/save")
def save_invoice_image():
    """
    POST /invoice-export/save
    Body (JSON):
    {
      "invoice_number": "INV0025",
      "image_data": "base64_encoded_png_data",
      "is_company_invoice": true
    }
    """
    payload = request.get_json(silent=True)

    if not payload:
        return jsonify({"success": False, "message": "Invalid or missing JSON body"}), 400

    invoice_number = payload.get("invoice_number")
    image_data = payload.get("image_data")
    is_company = payload.get("is_company_invoice", True)

    if not invoice_number or not image_data:
        return jsonify({
            "success": False,
            "message": "invoice_number and image_data are required"
        }), 400

    try:
        # Determine folder based on invoice type
        folder_name = "company_invoices" if is_company else "customer_bills"
        folder_path = os.path.join(INVOICES_BASE_PATH, folder_name)

        # Create folders if they don't exist
        os.makedirs(folder_path, exist_ok=True)

        # Decode base64 image data
        image_bytes = base64.b64decode(image_data)

        # Save the image
        file_name = f"{invoice_number}.png"
        file_path = os.path.join(folder_path, file_name)

        with open(file_path, "wb") as f:
            f.write(image_bytes)

        return jsonify({
            "success": True,
            "message": "Invoice saved successfully",
            "file_name": file_name,
            "folder": folder_name,
            "path": file_path,
            "size": len(image_bytes),
        }), 201

    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error saving invoice: {str(e)}"
        }), 500


@invoice_export_bp.get("/list/<folder>")
def list_invoices(folder):
    """
    GET /invoice-export/list/company_invoices
    GET /invoice-export/list/customer_bills
    """
    if folder not in ["company_invoices", "customer_bills"]:
        return jsonify({"success": False, "message": "Invalid folder"}), 400

    folder_path = os.path.join(INVOICES_BASE_PATH, folder)

    if not os.path.exists(folder_path):
        return jsonify({"success": True, "invoices": []}), 200

    try:
        files = [f for f in os.listdir(folder_path) if f.endswith('.png')]
        invoices = []
    
        for file_name in files:
            file_path = os.path.join(folder_path, file_name)
            stat = os.stat(file_path)
            invoices.append({
                "file_name": file_name,
                "invoice_number": file_name.replace('.png', ''),
                "size": stat.st_size,
                "created_at": datetime.fromtimestamp(stat.st_ctime).isoformat(),
            })

        return jsonify({"success": True, "invoices": invoices}), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error listing invoices: {str(e)}"
        }), 500
