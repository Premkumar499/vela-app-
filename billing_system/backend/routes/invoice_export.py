"""
Invoice export routes - convert invoice images to PDF and upload to Supabase Storage.

Buckets used:
  - erp_billing_system         → customer-facing cash bill (simple receipt)
  - erp_billing_system_company → company GST invoice
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

    a4_w, a4_h = A4
    scale = min(a4_w / img_width, a4_h / img_height)
    draw_w = img_width * scale
    draw_h = img_height * scale
    x_offset = (a4_w - draw_w) / 2
    y_offset = (a4_h - draw_h) / 2

    pdf_buffer = io.BytesIO()
    c = canvas.Canvas(pdf_buffer, pagesize=A4)
    tmp_img = io.BytesIO()
    img.save(tmp_img, format="PNG")
    tmp_img.seek(0)
    from reportlab.lib.utils import ImageReader
    c.drawImage(ImageReader(tmp_img), x_offset, y_offset, width=draw_w, height=draw_h)
    c.save()
    return pdf_buffer.getvalue()


def _generate_company_invoice_pdf(invoice_no: str) -> bytes:
    """
    Generate a professional company invoice PDF from DB data using reportlab.
    Reads from erp_billing_system_company + erp_billing_system_company_items.
    """
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.units import mm
    from reportlab.platypus import (
        SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, HRFlowable
    )
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT

    sb = _get_supabase()

    # Fetch header
    header_rows = sb.table("erp_billing_system_company") \
        .select("*") \
        .eq("invoice_no", invoice_no) \
        .execute().data
    if not header_rows:
        raise ValueError(f"Company invoice {invoice_no} not found in DB")
    hdr = header_rows[0]

    # Fetch line items
    items = sb.table("erp_billing_system_company_items") \
        .select("*") \
        .eq("invoice_id", hdr["invoice_id"]) \
        .order("sno") \
        .execute().data

    # ── Styles ────────────────────────────────────────────────────────────
    styles = getSampleStyleSheet()
    navy   = colors.HexColor("#1B2A4A")
    light  = colors.HexColor("#F3F6FC")

    title_style = ParagraphStyle("title", fontSize=18, fontName="Helvetica-Bold",
                                 textColor=navy, alignment=TA_LEFT)
    sub_style   = ParagraphStyle("sub",   fontSize=9,  fontName="Helvetica",
                                 textColor=colors.grey, alignment=TA_LEFT)
    bold_style  = ParagraphStyle("bold",  fontSize=9,  fontName="Helvetica-Bold",
                                 textColor=navy, alignment=TA_LEFT)
    right_style = ParagraphStyle("right", fontSize=9,  fontName="Helvetica",
                                 alignment=TA_RIGHT)
    center_style= ParagraphStyle("ctr",   fontSize=9,  fontName="Helvetica",
                                 alignment=TA_CENTER)

    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4,
                            leftMargin=15*mm, rightMargin=15*mm,
                            topMargin=12*mm, bottomMargin=12*mm)
    story = []

    # ── Header ────────────────────────────────────────────────────────────
    inv_date = hdr.get("invoice_date", "")
    inv_time = hdr.get("invoice_time", "") or ""

    header_data = [
        [
            Paragraph("<b>VELA AGENCY</b>", ParagraphStyle("h", fontSize=16,
                      fontName="Helvetica-Bold", textColor=navy)),
            Paragraph(f"<b>TAX INVOICE</b>", ParagraphStyle("h2", fontSize=14,
                      fontName="Helvetica-Bold", textColor=navy, alignment=TA_RIGHT)),
        ],
        [
            Paragraph("Burgur Road, Vellai Pillaiyar Kovil, Anthiyur, Tamil Nadu.<br/>"
                      "GSTIN: 33BAZPM1155J1ZB | PAN: BAZM115J<br/>"
                      "Phone: +91 9865223355 | Email: velaagency27@gmail.com",
                      ParagraphStyle("addr", fontSize=8, fontName="Helvetica",
                                     textColor=colors.HexColor("#444444"))),
            Paragraph(f"Invoice No: <b>{invoice_no}</b><br/>"
                      f"Date: <b>{inv_date}</b><br/>"
                      f"Time: <b>{inv_time}</b>",
                      ParagraphStyle("meta", fontSize=9, fontName="Helvetica",
                                     alignment=TA_RIGHT, textColor=navy)),
        ],
    ]
    header_tbl = Table(header_data, colWidths=["55%", "45%"])
    header_tbl.setStyle(TableStyle([
        ("VALIGN",      (0, 0), (-1, -1), "TOP"),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    story.append(header_tbl)
    story.append(HRFlowable(width="100%", thickness=1, color=navy, spaceAfter=6))

    # ── Bill To ───────────────────────────────────────────────────────────
    cust_name  = hdr.get("customer_name", "Walk-in Customer")
    cust_phone = hdr.get("customer_phone", "") or ""
    cust_addr  = f"Phone: {cust_phone}" if cust_phone else "Walk-in Customer"
    payment    = hdr.get("payment_mode", "Cash")
    txn_id     = hdr.get("transaction_id", invoice_no) or invoice_no

    bill_to_data = [[
        Paragraph(f"<b>BILL TO</b><br/><font size=12><b>{cust_name}</b></font><br/>{cust_addr}",
                  ParagraphStyle("bt", fontSize=9, fontName="Helvetica", textColor=navy)),
        Paragraph(f"<b>PAYMENT DETAILS</b><br/>Mode: {payment}<br/>Txn ID: {txn_id}",
                  ParagraphStyle("pd", fontSize=9, fontName="Helvetica",
                                 textColor=navy, alignment=TA_RIGHT)),
    ]]
    bill_to_tbl = Table(bill_to_data, colWidths=["55%", "45%"])
    bill_to_tbl.setStyle(TableStyle([
        ("VALIGN",      (0, 0), (-1, -1), "TOP"),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    story.append(bill_to_tbl)
    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.grey, spaceAfter=6))

    # ── Items Table ───────────────────────────────────────────────────────
    col_hdr = [
        Paragraph("<b>S.NO</b>", center_style),
        Paragraph("<b>DESCRIPTION</b>", bold_style),
        Paragraph("<b>UNIT</b>", center_style),
        Paragraph("<b>QTY</b>", center_style),
        Paragraph("<b>RATE (₹)</b>", right_style),
        Paragraph("<b>AMOUNT (₹)</b>", right_style),
    ]
    table_data = [col_hdr]
    for row in items:
        amt = float(row.get("amount", 0))
        table_data.append([
            Paragraph(str(row["sno"]), center_style),
            Paragraph(str(row["description"]), styles["Normal"]),
            Paragraph(str(row.get("unit", "Nos")), center_style),
            Paragraph(str(row["quantity"]), center_style),
            Paragraph(f"{float(row['rate']):.2f}", right_style),
            Paragraph(f"{amt:.2f}", right_style),
        ])

    items_tbl = Table(table_data, colWidths=[10*mm, 70*mm, 20*mm, 20*mm, 25*mm, 30*mm])
    items_tbl.setStyle(TableStyle([
        ("BACKGROUND",   (0, 0), (-1, 0), colors.HexColor("#E7ECF6")),
        ("TEXTCOLOR",    (0, 0), (-1, 0), navy),
        ("GRID",         (0, 0), (-1, -1), 0.4, colors.HexColor("#CCCCCC")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, light]),
        ("VALIGN",       (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING",   (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 5),
    ]))
    story.append(items_tbl)
    story.append(Spacer(1, 6))

    # ── Total ─────────────────────────────────────────────────────────────
    total = float(hdr.get("total_amount", 0))
    words = hdr.get("amount_in_words", "")
    total_data = [
        ["", "", "", "", Paragraph("<b>GRAND TOTAL</b>",
                                    ParagraphStyle("gt", fontSize=11, fontName="Helvetica-Bold",
                                                   textColor=colors.white, alignment=TA_RIGHT)),
                        Paragraph(f"<b>₹ {total:.2f}</b>",
                                    ParagraphStyle("gtv", fontSize=11, fontName="Helvetica-Bold",
                                                   textColor=colors.white, alignment=TA_RIGHT))],
    ]
    total_tbl = Table(total_data, colWidths=[10*mm, 70*mm, 20*mm, 20*mm, 25*mm, 30*mm])
    total_tbl.setStyle(TableStyle([
        ("BACKGROUND",   (4, 0), (-1, 0), navy),
        ("SPAN",         (0, 0), (3, 0)),
        ("TOPPADDING",   (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 6),
    ]))
    story.append(total_tbl)
    if words:
        story.append(Paragraph(f"<i>Amount in Words: {words}</i>",
                               ParagraphStyle("words", fontSize=8, fontName="Helvetica",
                                              textColor=colors.grey, alignment=TA_RIGHT)))

    story.append(Spacer(1, 10))
    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.grey, spaceAfter=4))

    # ── Bank Details + Signature ──────────────────────────────────────────
    bank_data = [[
        Paragraph("<b>BANK DETAILS</b><br/>Bank: HDFC Bank<br/>"
                  "A/C: 50200120799532<br/>IFSC: HDFC0004901",
                  ParagraphStyle("bank", fontSize=8, fontName="Helvetica", textColor=navy)),
        Paragraph("<b>FOR VELA AGENCY</b><br/><br/><br/>_______________________<br/>"
                  "Authorized Signatory",
                  ParagraphStyle("sig", fontSize=8, fontName="Helvetica",
                                 textColor=navy, alignment=TA_RIGHT)),
    ]]
    bank_tbl = Table(bank_data, colWidths=["55%", "45%"])
    bank_tbl.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    story.append(bank_tbl)

    story.append(Spacer(1, 8))
    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.grey, spaceAfter=4))
    story.append(Paragraph(
        "Thank you for your business. "
        "We declare that this invoice shows the actual price of the goods described "
        "and that all particulars are true and correct.",
        ParagraphStyle("footer", fontSize=7.5, fontName="Helvetica",
                       textColor=colors.grey, alignment=TA_CENTER)
    ))

    doc.build(story)
    return buf.getvalue()


# ---------------------------------------------------------------------------
# POST /invoice-export/save  (customer bill image → erp_billing_system bucket)
# ---------------------------------------------------------------------------

@invoice_export_bp.post("/save")
def save_invoice_image():
    """
    Accepts a base64-encoded PNG/JPEG image, converts it to PDF,
    and uploads it to the correct Supabase Storage bucket.

    Body (JSON):
    {
      "invoice_number": "2026AUG08A161",
      "image_data": "<base64-encoded PNG/JPEG>",
      "is_company_invoice": false     ← always false; company uses /generate-company
    }
    """
    payload = request.get_json(silent=True)
    if not payload:
        return jsonify({"success": False, "message": "Invalid or missing JSON body"}), 400

    invoice_number = payload.get("invoice_number")
    image_data     = payload.get("image_data")
    is_company     = bool(payload.get("is_company_invoice", False))

    if not invoice_number or not image_data:
        return jsonify({"success": False,
                        "message": "invoice_number and image_data are required"}), 400

    try:
        image_bytes = base64.b64decode(image_data)
    except Exception:
        return jsonify({"success": False, "message": "image_data is not valid base64"}), 400

    try:
        pdf_bytes    = _image_bytes_to_pdf(image_bytes)
        bucket       = BUCKET_MAP[is_company]
        file_name    = f"{invoice_number}.pdf"

        sb = _get_supabase()
        sb.storage.from_(bucket).upload(
            path=file_name,
            file=pdf_bytes,
            file_options={"content-type": "application/pdf", "upsert": "true"},
        )
        public_url = sb.storage.from_(bucket).get_public_url(file_name)

        # Local PNG fallback for debugging
        folder_path = os.path.join(INVOICES_BASE_PATH,
                                   "company_invoices" if is_company else "customer_bills")
        os.makedirs(folder_path, exist_ok=True)
        with open(os.path.join(folder_path, f"{invoice_number}.png"), "wb") as f:
            f.write(image_bytes)

        return jsonify({
            "success":   True,
            "message":   "Invoice converted to PDF and uploaded to Supabase Storage",
            "file_name": file_name,
            "bucket":    bucket,
            "url":       public_url,
            "pdf_size":  len(pdf_bytes),
        }), 201

    except Exception as e:
        import traceback; traceback.print_exc()
        return jsonify({"success": False, "message": f"Error: {str(e)}"}), 500


# ---------------------------------------------------------------------------
# POST /invoice-export/generate-company/<invoice_number>
# Generates company invoice PDF from DB data → uploads to erp_billing_system_company
# ---------------------------------------------------------------------------

@invoice_export_bp.post("/generate-company/<invoice_number>")
def generate_company_invoice(invoice_number: str):
    """
    Generate and upload company invoice PDF entirely server-side.
    First tries to read from erp_billing_system_company DB table.
    If not found, accepts bill data in the request body as fallback.

    Optional body (JSON) for fallback:
    {
      "customer_name": "Walk-in Customer",
      "customer_phone": "",
      "payment_mode": "Cash",
      "total_amount": 296.27,
      "amount_in_words": "Two Hundred...",
      "invoice_date": "2026-08-08",
      "invoice_time": "18:04:00",
      "items": [
        {"sno": 1, "description": "3 Rose 250g", "unit": "Nos", "quantity": 1.0, "rate": 207.29, "amount": 207.29}
      ]
    }
    """
    try:
        pdf_bytes = _generate_company_invoice_pdf(invoice_number)
    except ValueError:
        # DB record not found — try to build from request body fallback
        payload = request.get_json(silent=True) or {}
        if not payload:
            return jsonify({
                "success": False,
                "message": f"Company invoice {invoice_number} not in DB and no fallback data provided"
            }), 404
        try:
            pdf_bytes = _generate_company_invoice_pdf_from_payload(invoice_number, payload)
        except Exception as e:
            import traceback; traceback.print_exc()
            return jsonify({"success": False, "message": f"Fallback PDF error: {str(e)}"}), 500
    except Exception as e:
        import traceback; traceback.print_exc()
        return jsonify({"success": False, "message": f"Error: {str(e)}"}), 500

    try:
        file_name = f"{invoice_number}.pdf"
        sb = _get_supabase()
        sb.storage.from_("erp_billing_system_company").upload(
            path=file_name,
            file=pdf_bytes,
            file_options={"content-type": "application/pdf", "upsert": "true"},
        )
        public_url = sb.storage.from_("erp_billing_system_company").get_public_url(file_name)
        print(f"[generate_company_invoice] Uploaded {file_name} → erp_billing_system_company")

        return jsonify({
            "success":   True,
            "message":   "Company invoice PDF generated and uploaded",
            "file_name": file_name,
            "bucket":    "erp_billing_system_company",
            "url":       public_url,
            "pdf_size":  len(pdf_bytes),
        }), 201
    except Exception as e:
        import traceback; traceback.print_exc()
        return jsonify({"success": False, "message": f"Upload error: {str(e)}"}), 500


def _generate_company_invoice_pdf_from_payload(invoice_no: str, payload: dict) -> bytes:
    """Same as _generate_company_invoice_pdf but uses dict payload instead of DB lookup."""
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.units import mm
    from reportlab.platypus import (
        SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, HRFlowable
    )
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT

    styles = getSampleStyleSheet()
    navy   = colors.HexColor("#1B2A4A")
    light  = colors.HexColor("#F3F6FC")

    bold_style   = ParagraphStyle("bold",  fontSize=9, fontName="Helvetica-Bold", textColor=navy, alignment=TA_LEFT)
    right_style  = ParagraphStyle("right", fontSize=9, fontName="Helvetica", alignment=TA_RIGHT)
    center_style = ParagraphStyle("ctr",   fontSize=9, fontName="Helvetica", alignment=TA_CENTER)

    hdr   = payload
    items = payload.get("items", [])

    inv_date = hdr.get("invoice_date", datetime.now().strftime("%Y-%m-%d"))
    inv_time = hdr.get("invoice_time", "") or ""

    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, leftMargin=15*mm, rightMargin=15*mm, topMargin=12*mm, bottomMargin=12*mm)
    story = []

    header_data = [
        [Paragraph("<b>VELA AGENCY</b>", ParagraphStyle("h", fontSize=16, fontName="Helvetica-Bold", textColor=navy)),
         Paragraph("<b>TAX INVOICE</b>", ParagraphStyle("h2", fontSize=14, fontName="Helvetica-Bold", textColor=navy, alignment=TA_RIGHT))],
        [Paragraph("Burgur Road, Vellai Pillaiyar Kovil, Anthiyur, Tamil Nadu.<br/>GSTIN: 33BAZPM1155J1ZB | PAN: BAZM115J<br/>Phone: +91 9865223355 | Email: velaagency27@gmail.com",
                   ParagraphStyle("addr", fontSize=8, fontName="Helvetica", textColor=colors.HexColor("#444444"))),
         Paragraph(f"Invoice No: <b>{invoice_no}</b><br/>Date: <b>{inv_date}</b><br/>Time: <b>{inv_time}</b>",
                   ParagraphStyle("meta", fontSize=9, fontName="Helvetica", alignment=TA_RIGHT, textColor=navy))],
    ]
    header_tbl = Table(header_data, colWidths=["55%", "45%"])
    header_tbl.setStyle(TableStyle([("VALIGN", (0,0), (-1,-1), "TOP"), ("BOTTOMPADDING", (0,0), (-1,-1), 4)]))
    story.append(header_tbl)
    story.append(HRFlowable(width="100%", thickness=1, color=navy, spaceAfter=6))

    cust_name  = hdr.get("customer_name", "Walk-in Customer")
    cust_phone = hdr.get("customer_phone", "") or ""
    cust_addr  = f"Phone: {cust_phone}" if cust_phone else "Walk-in Customer"
    payment    = hdr.get("payment_mode", "Cash")
    txn_id     = hdr.get("transaction_id", invoice_no) or invoice_no

    bill_to_data = [[
        Paragraph(f"<b>BILL TO</b><br/><font size=12><b>{cust_name}</b></font><br/>{cust_addr}",
                  ParagraphStyle("bt", fontSize=9, fontName="Helvetica", textColor=navy)),
        Paragraph(f"<b>PAYMENT DETAILS</b><br/>Mode: {payment}<br/>Txn ID: {txn_id}",
                  ParagraphStyle("pd", fontSize=9, fontName="Helvetica", textColor=navy, alignment=TA_RIGHT)),
    ]]
    bill_to_tbl = Table(bill_to_data, colWidths=["55%", "45%"])
    bill_to_tbl.setStyle(TableStyle([("VALIGN", (0,0), (-1,-1), "TOP"), ("BOTTOMPADDING", (0,0), (-1,-1), 6)]))
    story.append(bill_to_tbl)
    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.grey, spaceAfter=6))

    col_hdr = [Paragraph("<b>S.NO</b>", center_style), Paragraph("<b>DESCRIPTION</b>", bold_style),
               Paragraph("<b>UNIT</b>", center_style), Paragraph("<b>QTY</b>", center_style),
               Paragraph("<b>RATE (₹)</b>", right_style), Paragraph("<b>AMOUNT (₹)</b>", right_style)]
    table_data = [col_hdr]
    for row in items:
        amt = float(row.get("amount", 0))
        table_data.append([
            Paragraph(str(row.get("sno", "")), center_style),
            Paragraph(str(row.get("description", "")), styles["Normal"]),
            Paragraph(str(row.get("unit", "Nos")), center_style),
            Paragraph(str(row.get("quantity", "")), center_style),
            Paragraph(f"{float(row.get('rate', 0)):.2f}", right_style),
            Paragraph(f"{amt:.2f}", right_style),
        ])
    items_tbl = Table(table_data, colWidths=[10*mm, 70*mm, 20*mm, 20*mm, 25*mm, 30*mm])
    items_tbl.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#E7ECF6")), ("TEXTCOLOR", (0,0), (-1,0), navy),
        ("GRID", (0,0), (-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.white, light]),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"), ("TOPPADDING", (0,0), (-1,-1), 5), ("BOTTOMPADDING", (0,0), (-1,-1), 5),
    ]))
    story.append(items_tbl)
    story.append(Spacer(1, 6))

    total = float(hdr.get("total_amount", 0))
    words = hdr.get("amount_in_words", "")
    total_data = [["", "", "", "",
        Paragraph("<b>GRAND TOTAL</b>", ParagraphStyle("gt", fontSize=11, fontName="Helvetica-Bold", textColor=colors.white, alignment=TA_RIGHT)),
        Paragraph(f"<b>₹ {total:.2f}</b>", ParagraphStyle("gtv", fontSize=11, fontName="Helvetica-Bold", textColor=colors.white, alignment=TA_RIGHT))]]
    total_tbl = Table(total_data, colWidths=[10*mm, 70*mm, 20*mm, 20*mm, 25*mm, 30*mm])
    total_tbl.setStyle(TableStyle([("BACKGROUND", (4,0), (-1,0), navy), ("SPAN", (0,0), (3,0)),
                                    ("TOPPADDING", (0,0), (-1,-1), 6), ("BOTTOMPADDING", (0,0), (-1,-1), 6)]))
    story.append(total_tbl)
    if words:
        story.append(Paragraph(f"<i>Amount in Words: {words}</i>",
                               ParagraphStyle("words", fontSize=8, fontName="Helvetica", textColor=colors.grey, alignment=TA_RIGHT)))
    story.append(Spacer(1, 10))
    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.grey, spaceAfter=4))
    story.append(Paragraph(
        "Thank you for your business. We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.",
        ParagraphStyle("footer", fontSize=7.5, fontName="Helvetica", textColor=colors.grey, alignment=TA_CENTER)
    ))
    doc.build(story)
    return buf.getvalue()


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
