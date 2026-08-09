#!/usr/bin/env python3
"""
Test script to verify company invoice generation works correctly.
This simulates what happens when a bill is created through the UI.
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:5000"

def create_test_bill():
    """Create a test bill via API"""
    print("=" * 60)
    print("TEST: Creating a test bill...")
    print("=" * 60)
    
    payload = {
        "customer_name": "Test Customer",
        "customer_phone": "9876543210",
        "payment_type": "Cash",
        "items": [
            {
                "product_id": "1",
                "product_name": "Test Product 1",
                "unit": "Kg",
                "quantity": 2.0,
                "rate": 150.0,
                "discount_percent": 0,
            },
            {
                "product_id": "2",
                "product_name": "Test Product 2",
                "unit": "Nos",
                "quantity": 3.0,
                "rate": 50.0,
                "discount_percent": 0,
            }
        ]
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/bill/",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 201:
            result = response.json()
            print(f"✓ Bill created successfully!")
            print(f"  Bill Number: {result.get('bill_number')}")
            return result.get('bill_number')
        else:
            print(f"✗ Failed to create bill: {response.status_code}")
            print(f"  Response: {response.text}")
            return None
    except Exception as e:
        print(f"✗ Error creating bill: {str(e)}")
        return None


def test_company_invoice_generation(bill_number):
    """Test company invoice PDF generation"""
    print("\n" + "=" * 60)
    print(f"TEST: Generating company invoice PDF for: {bill_number}")
    print("=" * 60)
    
    try:
        response = requests.post(
            f"{BASE_URL}/invoice-export/generate-company/{bill_number}",
            json={},
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 201:
            result = response.json()
            print(f"✓ Company invoice generated successfully!")
            print(f"  File: {result.get('file_name')}")
            print(f"  Bucket: {result.get('bucket')}")
            print(f"  Size: {result.get('pdf_size')} bytes")
            print(f"  URL: {result.get('url')}")
            return True
        else:
            print(f"✗ Failed to generate company invoice: {response.status_code}")
            print(f"  Response: {response.text}")
            return False
    except Exception as e:
        print(f"✗ Error generating company invoice: {str(e)}")
        return False


def check_database(bill_number):
    """Check if the bill exists in both tables"""
    print("\n" + "=" * 60)
    print(f"TEST: Checking database for bill: {bill_number}")
    print("=" * 60)
    
    try:
        # Check user bill table
        response = requests.get(f"{BASE_URL}/bills/{bill_number}")
        if response.status_code == 200:
            print(f"✓ User bill found in erp_billing_system")
        else:
            print(f"✗ User bill NOT found in erp_billing_system")
        
        # Note: We can't directly check the company table via API,
        # but the PDF generation will fail if it's not there
        print(f"  Company bill check: Will verify via PDF generation")
        
    except Exception as e:
        print(f"✗ Error checking database: {str(e)}")


def main():
    print("\n")
    print("╔════════════════════════════════════════════════════════╗")
    print("║  COMPANY INVOICE GENERATION TEST                       ║")
    print("╚════════════════════════════════════════════════════════╝")
    print()
    
    # Step 1: Create a test bill
    bill_number = create_test_bill()
    if not bill_number:
        print("\n✗ TEST FAILED: Could not create test bill")
        return
    
    # Step 2: Check database
    check_database(bill_number)
    
    # Step 3: Generate company invoice
    success = test_company_invoice_generation(bill_number)
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    if success:
        print("✓ ALL TESTS PASSED")
        print(f"  Bill {bill_number} was created and company invoice was generated")
        print(f"  Check backend logs for detailed execution trace")
    else:
        print("✗ TEST FAILED")
        print(f"  Company invoice generation failed for bill {bill_number}")
        print(f"  Check backend logs for error details")
    print("=" * 60)


if __name__ == "__main__":
    main()
