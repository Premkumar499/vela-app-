"""
Invoice export routes - convert invoice images to PDF and upload to Supabase Storage.

Buckets used:
  - customer_bills      → customer-facing cash bill (simple receipt)
  - company_invoices    → company GST invoice
"""

import os
import io
import base64
from flask import Blueprint, jsonify, request
from datetime import datetime

invoice_export_bp = Blueprint("invoice_export", __name__, url_prefix="/invoice-export")

# Local fallback folder (kept for debugging)
INVOICES_BASE_PATH = os.path.join(os.path.dirname(__file__), "..", "invoices")

BUCKET_MAP = {
    True:  "erp_billing_system_company",   # company GST invoice
    False: "erp_billing_system",           # customer cash bill
}


def _get_supabase():
    from dotenv import load_dotenv
    from supabase import create_client
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    load_dotenv(env_path, override=True)
    url = os.getenv("SUPABASE_URL", "")
    key = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_SECRET_KEY") or ""
    if not url or not key:
        raise ValueError("SUPABASE_URL or key not set in .env")
    from supabase import create_client
    return create_client(url, key)


def _image_bytes_to_pdf(image_bytes: bytes) -> bytes:
    """Convert raw PNG/JPEG bytes → single-page PDF bytes using Pillow."""
    from PIL import Image
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas

    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img_width, img_height = img.size

    # Scale image to fit A4 keeping aspect ratio
    a4_w, a4_h = A4
    scale = min(a4_w / img_width, a4_h / img_height)
    draw_w = img_width * scale
    draw_h = img_height * scale
    x_offset = (a4_w - draw_w) / 2
    y_offset = (a4_h - draw_h) / 2

    # Write image into PDF via reportlab
    pdf_buffer = io.BytesIO()
    c = canvas.Canvas(pdf_buffer, pagesize=A4)
    # Save PIL image to a temp in-memory buffer so reportlab can read it
    tmp_img = io.BytesIO()
    img.save(tmp_img, format="PNG")
    tmp_img.seek(0)
    from reportlab.lib.utils import ImageReader
    c.drawImage(ImageReader(tmp_img), x_offset, y_offset, width=draw_w, height=draw_h)
    c.save()
    return pdf_buffer.getvalue()


# ---------------------------------------------------------------------------
# POST /invoice-export/save
# ---------------------------------------------------------------------------

@invoice_export_bp.post("/save")
def save_invoice_image():
    """
    Accepts a base64-encoded PNG/JPEG image, converts it to PDF,
    and uploads it to the correct Supabase Storage bucket.

    Body (JSON):
    {
      "invoice_number": "INV0025",
      "image_data": "<base64-encoded PNG/JPEG>",
      "is_company_invoice": true
    }
    """
    payload = request.get_json(silent=True)
    if not payload:
        return jsonify({"success": False, "message": "Invalid or missing JSON body"}), 400

    invoice_number = payload.get("invoice_number")
    image_data     = payload.get("image_data")
    is_company     = bool(payload.get("is_company_invoice", True))

    if not invoice_number or not image_data:
        return jsonify({"success": False,
                        "message": "invoice_number and image_data are required"}), 400

    try:
        image_bytes = base64.b64decode(image_data)
    except Exception:
        return jsonify({"success": False, "message": "image_data is not valid base64"}), 400

    try:
        pdf_bytes  = _image_bytes_to_pdf(image_bytes)
        bucket     = BUCKET_MAP[is_company]
        file_name  = f"{invoice_number}.pdf"
        storage_path = file_name          # stored at root of bucket

        sb = _get_supabase()
        # upsert=True overwrites if the same invoice is re-printed
        sb.storage.from_(bucket).upload(
            path=storage_path,
            file=pdf_bytes,
            file_options={
                "content-type": "application/pdf",
                "upsert": "true",
            },
        )

        public_url = sb.storage.from_(bucket).get_public_url(storage_path)

        # Local PNG fallback for debugging
        folder_path = os.path.join(INVOICES_BASE_PATH,
                                   "company_invoices" if is_company else "customer_bills")
        os.makedirs(folder_path, exist_ok=True)
        with open(os.path.join(folder_path, f"{invoice_number}.png"), "wb") as f:
            f.write(image_bytes)

        return jsonify({
            "success":    True,
            "message":    "Invoice converted to PDF and uploaded to Supabase Storage",
            "file_name":  file_name,
            "bucket":     bucket,
            "url":        public_url,
            "pdf_size":   len(pdf_bytes),
        }), 201

    except Exception as e:
        import traceback; traceback.print_exc()
        return jsonify({"success": False, "message": f"Error: {str(e)}"}), 500


# ---------------------------------------------------------------------------
# GET /invoice-export/list/<bucket>
# ---------------------------------------------------------------------------

@invoice_export_bp.get("/list/<bucket>")
def list_invoices(bucket: str):
    """
    GET /invoice-export/list/company_invoices
    GET /invoice-export/list/customer_bills
    Returns a list of PDF files in the given Supabase bucket.
    """
    if bucket not in ("erp_billing_system_company", "erp_billing_system"):
        return jsonify({"success": False, "message": "Invalid bucket name"}), 400

    try:
        sb = _get_supabase()
        files = sb.storage.from_(bucket).list()
        invoices = [
            {
                "file_name":      f["name"],
                "invoice_number": f["name"].replace(".pdf", ""),
                "size":           f.get("metadata", {}).get("size", 0),
                "created_at":     f.get("created_at", ""),
                "url":            sb.storage.from_(bucket).get_public_url(f["name"]),
            }
            for f in files
            if f["name"].endswith(".pdf")
        ]
        return jsonify({"success": True, "bucket": bucket, "invoices": invoices}), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


# ---------------------------------------------------------------------------
# GET /invoice-export/download/<bucket>/<invoice_number>
# ---------------------------------------------------------------------------

@invoice_export_bp.get("/download/<bucket>/<invoice_number>")
def get_invoice_url(bucket: str, invoice_number: str):
    """Returns a signed URL (60 min) for downloading a specific PDF."""
    if bucket not in ("erp_billing_system_company", "erp_billing_system"):
        return jsonify({"success": False, "message": "Invalid bucket name"}), 400

    try:
        sb  = _get_supabase()
        res = sb.storage.from_(bucket).create_signed_url(
            path=f"{invoice_number}.pdf",
            expires_in=3600,
        )
        return jsonify({"success": True, "url": res["signedURL"]}), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
