-- Enable Row Level Security - BACKEND ONLY ACCESS
-- Run this in Supabase SQL Editor if you want ONLY your backend API to access tables
-- (No direct database access from frontend/other clients)

-- ============================================================================
-- ENABLE RLS ON ALL BILLING TABLES
-- ============================================================================

ALTER TABLE erp_billing_system ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_company ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_company_items ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- BACKEND-ONLY POLICIES (Service Role Only)
-- ============================================================================

-- Customer bills - service role only
CREATE POLICY "Backend API only - customer bills"
ON erp_billing_system
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Customer bill items - service role only
CREATE POLICY "Backend API only - customer bill items"
ON erp_billing_system_items
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Company invoices - service role only
CREATE POLICY "Backend API only - company invoices"
ON erp_billing_system_company
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Company invoice items - service role only
CREATE POLICY "Backend API only - company invoice items"
ON erp_billing_system_company_items
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================================================
-- RESULT: Tables are now RESTRICTED
-- ============================================================================
-- ✅ Only your backend API (using SUPABASE_SERVICE_KEY) can access data
-- ✅ Direct database access from frontend/other clients is blocked
-- ✅ "UNRESTRICTED" warning will disappear
-- ============================================================================
