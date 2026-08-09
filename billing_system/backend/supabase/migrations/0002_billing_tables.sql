-- =============================================================
-- Migration: erp_billing_system + erp_billing_system_company
-- Run once in Supabase SQL Editor
-- =============================================================

-- ---------------------------------------------------------------
-- 1. USER BILL HEADER
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS erp_billing_system (
    bill_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_name  VARCHAR(100) NOT NULL DEFAULT 'VELA AGENCY',
    bill_no        VARCHAR(50)  NOT NULL UNIQUE,
    bill_date      DATE         NOT NULL,
    bill_time      TIME         NOT NULL,
    payment_mode   VARCHAR(30)  NOT NULL,
    total_items    INTEGER      DEFAULT 0,
    total_quantity NUMERIC(10,2) DEFAULT 0,
    grand_total    NUMERIC(12,2) NOT NULL,
    created_at     TIMESTAMPTZ  DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- 2. USER BILL LINE ITEMS
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS erp_billing_system_items (
    bill_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id      UUID          NOT NULL REFERENCES erp_billing_system(bill_id) ON DELETE CASCADE,
    sno          INTEGER       NOT NULL,
    description  VARCHAR(255)  NOT NULL,
    quantity     NUMERIC(10,2) NOT NULL,
    rate         NUMERIC(12,2) NOT NULL,
    amount       NUMERIC(12,2) NOT NULL
);

-- ---------------------------------------------------------------
-- 3. COMPANY BILL / INVOICE HEADER
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS erp_billing_system_company (
    invoice_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_no      VARCHAR(50)  NOT NULL UNIQUE,
    invoice_date    DATE         NOT NULL,
    invoice_time    TIME,
    customer_name   VARCHAR(150) NOT NULL,
    customer_phone  VARCHAR(20),
    payment_mode    VARCHAR(30)  NOT NULL,
    transaction_id  VARCHAR(100),
    upi_id          VARCHAR(100),
    total_amount    NUMERIC(12,2) NOT NULL,
    amount_in_words TEXT,
    created_at      TIMESTAMPTZ  DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- 4. COMPANY BILL LINE ITEMS
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS erp_billing_system_company_items (
    item_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id  UUID          NOT NULL REFERENCES erp_billing_system_company(invoice_id) ON DELETE CASCADE,
    sno         INTEGER       NOT NULL,
    description VARCHAR(255)  NOT NULL,
    unit        VARCHAR(30)   NOT NULL DEFAULT 'Nos',
    quantity    NUMERIC(10,2) NOT NULL,
    rate        NUMERIC(12,2) NOT NULL,
    amount      NUMERIC(12,2) NOT NULL
);

-- Indexes for fast lookup by bill/invoice number
CREATE INDEX IF NOT EXISTS idx_erp_billing_bill_no     ON erp_billing_system(bill_no);
CREATE INDEX IF NOT EXISTS idx_erp_billing_company_no  ON erp_billing_system_company(invoice_no);

-- ---------------------------------------------------------------
-- 5. DISABLE RLS so service-role backend can read/write freely
--    (Run this in Supabase SQL Editor if inserts are failing)
-- ---------------------------------------------------------------
ALTER TABLE erp_billing_system              DISABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_items        DISABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_company      DISABLE ROW LEVEL SECURITY;
ALTER TABLE erp_billing_system_company_items DISABLE ROW LEVEL SECURITY;
