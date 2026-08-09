#!/usr/bin/env python3
"""
Check if bills are being saved to both database tables.
"""

import os
from dotenv import load_dotenv
from supabase import create_client

# Load environment variables
env_path = os.path.join("billing_system", "backend", ".env")
load_dotenv(env_path, override=True)

url = os.getenv("SUPABASE_URL", "")
key = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_SECRET_KEY") or ""

if not url or not key:
    print("❌ ERROR: SUPABASE_URL or key not set in .env")
    exit(1)

sb = create_client(url, key)

print("=" * 60)
print("DATABASE CHECK")
print("=" * 60)

# Check user bills table
print("\n1. Checking erp_billing_system table...")
user_bills = sb.table("erp_billing_system").select("bill_no, bill_date, grand_total").order("created_at", desc=True).limit(5).execute()
print(f"   Found {len(user_bills.data)} recent bills:")
for bill in user_bills.data:
    print(f"   - {bill['bill_no']}: ₹{bill['grand_total']} on {bill['bill_date']}")

# Check company invoices table
print("\n2. Checking erp_billing_system_company table...")
company_bills = sb.table("erp_billing_system_company").select("invoice_no, invoice_date, total_amount, customer_name").order("created_at", desc=True).limit(5).execute()
print(f"   Found {len(company_bills.data)} recent company invoices:")
for bill in company_bills.data:
    print(f"   - {bill['invoice_no']}: ₹{bill['total_amount']} - {bill['customer_name']} on {bill['invoice_date']}")

# Check if they match
print("\n3. Comparing tables...")
user_bill_nos = {b['bill_no'] for b in user_bills.data}
company_bill_nos = {b['invoice_no'] for b in company_bills.data}

missing_in_company = user_bill_nos - company_bill_nos
missing_in_user = company_bill_nos - user_bill_nos

if missing_in_company:
    print(f"   ⚠️  WARNING: {len(missing_in_company)} bills in user table but NOT in company table:")
    for bill_no in missing_in_company:
        print(f"      - {bill_no}")
else:
    print(f"   ✅ All user bills have matching company invoices")

if missing_in_user:
    print(f"   ⚠️  WARNING: {len(missing_in_user)} bills in company table but NOT in user table:")
    for bill_no in missing_in_user:
        print(f"      - {bill_no}")

# Check storage buckets
print("\n4. Checking Storage Buckets...")

print("\n   erp_billing_system bucket:")
try:
    files = sb.storage.from_("erp_billing_system").list()
    pdf_files = [f for f in files if f['name'].endswith('.pdf')]
    print(f"   Found {len(pdf_files)} PDF files")
    if pdf_files:
        for f in pdf_files[-5:]:
            print(f"   - {f['name']}")
except Exception as e:
    print(f"   ❌ Error: {e}")

print("\n   erp_billing_system_company bucket:")
try:
    files = sb.storage.from_("erp_billing_system_company").list()
    pdf_files = [f for f in files if f['name'].endswith('.pdf')]
    print(f"   Found {len(pdf_files)} PDF files")
    if pdf_files:
        for f in pdf_files[-5:]:
            print(f"   - {f['name']}")
    else:
        print(f"   ⚠️  No PDF files found in company bucket!")
except Exception as e:
    print(f"   ❌ Error: {e}")

print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)
print(f"User bills in DB:     {len(user_bills.data)}")
print(f"Company bills in DB:  {len(company_bills.data)}")
print(f"PDFs in user bucket:  (check above)")
print(f"PDFs in company bucket: (check above)")
print("=" * 60)
