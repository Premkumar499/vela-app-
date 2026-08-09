-- Enable Row Level Security on all billing tables
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor)

-- ============================================================================
-- ENABLE RLS ON ALL BILLING TABLES
-- ============================================================================

ALTER TABLE erp_billing_system ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_company ENABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_company_items ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLICIES FOR erp_billing_system (customer bills)
-- ============================================================================

-- Service role has full access
CREATE POLICY "Service role full access - customer bills"
ON erp_billing_system
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Authenticated users can read all bills
CREATE POLICY "Authenticated users can read customer bills"
ON erp_billing_system
FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can insert bills
CREATE POLICY "Authenticated users can insert customer bills"
ON erp_billing_system
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================================================
-- POLICIES FOR erp_billing_system_items (customer bill items)
-- ============================================================================

-- Service role has full access
CREATE POLICY "Service role full access - customer bill items"
ON erp_billing_system_items
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Authenticated users can read all items
CREATE POLICY "Authenticated users can read customer bill items"
ON erp_billing_system_items
FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can insert items
CREATE POLICY "Authenticated users can insert customer bill items"
ON erp_billing_system_items
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================================================
-- POLICIES FOR erp_billing_system_company (company invoices)
-- ============================================================================

-- Service role has full access
CREATE POLICY "Service role full access - company invoices"
ON erp_billing_system_company
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Authenticated users can read all invoices
CREATE POLICY "Authenticated users can read company invoices"
ON erp_billing_system_company
FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can insert invoices
CREATE POLICY "Authenticated users can insert company invoices"
ON erp_billing_system_company
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================================================
-- POLICIES FOR erp_billing_system_company_items (company invoice items)
-- ============================================================================

-- Service role has full access
CREATE POLICY "Service role full access - company invoice items"
ON erp_billing_system_company_items
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Authenticated users can read all items
CREATE POLICY "Authenticated users can read company invoice items"
ON erp_billing_system_company_items
FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can insert items
CREATE POLICY "Authenticated users can insert company invoice items"
ON erp_billing_system_company_items
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================================================
-- NOTES:
-- ============================================================================
-- 1. Service role (used by backend API) has FULL access to all operations
-- 2. Authenticated users can READ and INSERT (for multi-user scenarios)
-- 3. DELETE operations are restricted to service role only (backend API)
-- 4. This protects your data while keeping backend functionality intact
-- 
-- If you want to make tables completely private (backend API only):
-- Remove all "authenticated" policies and keep only "service_role" policies
-- ============================================================================
