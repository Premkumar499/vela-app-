-- Storage bucket policies for invoice PDFs
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor)

-- Allow service role full access to erp_billing_system (customer bills)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'erp_billing_system',
  'erp_billing_system',
  false,
  52428800,
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Allow service role full access to erp_billing_system_company (company invoices)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'erp_billing_system_company',
  'erp_billing_system_company',
  false,
  52428800,
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Policy: service role can upload/read/delete in erp_billing_system
CREATE POLICY "Service role full access - customer bills"
ON storage.objects FOR ALL
TO service_role
USING (bucket_id = 'erp_billing_system')
WITH CHECK (bucket_id = 'erp_billing_system');

-- Policy: service role can upload/read/delete in erp_billing_system_company
CREATE POLICY "Service role full access - company invoices"
ON storage.objects FOR ALL
TO service_role
USING (bucket_id = 'erp_billing_system_company')
WITH CHECK (bucket_id = 'erp_billing_system_company');
