-- DM Auto OS - Financial & Operations Schema Extension
-- Adds: drivers, rental_periods, transactions, expenses, documents, reports
-- Extends existing tables with soft deletes and audit columns

-- ---------------------------------------------------------------------------
-- New ENUM types
-- ---------------------------------------------------------------------------
CREATE TYPE public.transaction_type AS ENUM ('income', 'expense');

CREATE TYPE public.transaction_category AS ENUM (
  'rental_payment',
  'vehicle_sale',
  'service_payment',
  'deposit',
  'refund',
  'fuel',
  'maintenance',
  'insurance',
  'registration',
  'tax',
  'salary',
  'other_income',
  'other_expense'
);

CREATE TYPE public.expense_category AS ENUM (
  'fuel',
  'maintenance',
  'repair',
  'insurance',
  'registration',
  'cleaning',
  'tires',
  'parts',
  'toll',
  'parking',
  'other'
);

CREATE TYPE public.document_type AS ENUM (
  'contract',
  'invoice',
  'receipt',
  'registration',
  'insurance',
  'license',
  'identity',
  'photo',
  'report',
  'other'
);

CREATE TYPE public.report_type AS ENUM (
  'financial',
  'fleet',
  'rental',
  'expense',
  'revenue',
  'custom'
);

CREATE TYPE public.report_status AS ENUM (
  'draft',
  'generating',
  'generated',
  'failed',
  'archived'
);

CREATE TYPE public.driver_status AS ENUM (
  'active',
  'inactive',
  'suspended'
);

CREATE TYPE public.rental_period_status AS ENUM (
  'planned',
  'active',
  'completed',
  'cancelled'
);

-- ---------------------------------------------------------------------------
-- Soft-delete & audit columns on existing tables
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.profiles(id);

ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.profiles(id);

ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.profiles(id);

ALTER TABLE public.rentals
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.profiles(id);

ALTER TABLE public.service_orders
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.profiles(id);

ALTER TABLE public.vehicle_sales
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.profiles(id);

-- Partial indexes for active (non-deleted) records on existing tables
CREATE INDEX IF NOT EXISTS idx_profiles_active
  ON public.profiles(id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_vehicles_active
  ON public.vehicles(status) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_customers_active
  ON public.customers(full_name) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_rentals_active
  ON public.rentals(status, vehicle_id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_rentals_customer
  ON public.rentals(customer_id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_service_orders_active
  ON public.service_orders(status, vehicle_id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_vehicle_sales_active
  ON public.vehicle_sales(vehicle_id, sale_date) WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Drivers
-- ---------------------------------------------------------------------------
CREATE TABLE public.drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  license_number TEXT NOT NULL,
  license_class TEXT,
  license_expiry DATE,
  id_number TEXT,
  address TEXT,
  date_of_birth DATE,
  status public.driver_status NOT NULL DEFAULT 'active',
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES public.profiles(id),
  CONSTRAINT drivers_license_number_unique UNIQUE (license_number)
);

CREATE INDEX idx_drivers_status ON public.drivers(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_drivers_license_expiry ON public.drivers(license_expiry)
  WHERE deleted_at IS NULL AND license_expiry IS NOT NULL;
CREATE INDEX idx_drivers_full_name ON public.drivers(full_name) WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Rental periods (group multiple rentals under one billing/contract period)
-- ---------------------------------------------------------------------------
CREATE TABLE public.rental_periods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  customer_id UUID REFERENCES public.customers(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status public.rental_period_status NOT NULL DEFAULT 'planned',
  total_amount_xaf INTEGER NOT NULL DEFAULT 0 CHECK (total_amount_xaf >= 0),
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES public.profiles(id),
  CONSTRAINT rental_periods_date_check CHECK (end_date >= start_date)
);

CREATE INDEX idx_rental_periods_status ON public.rental_periods(status)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_rental_periods_customer ON public.rental_periods(customer_id)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_rental_periods_dates ON public.rental_periods(start_date, end_date)
  WHERE deleted_at IS NULL;

-- Link rentals to rental periods and drivers
ALTER TABLE public.rentals
  ADD COLUMN IF NOT EXISTS rental_period_id UUID REFERENCES public.rental_periods(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS deleted_by UUID REFERENCES public.profiles(id);

CREATE INDEX IF NOT EXISTS idx_rentals_rental_period
  ON public.rentals(rental_period_id) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_rentals_driver
  ON public.rentals(driver_id) WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Transactions (income & expense ledger)
-- ---------------------------------------------------------------------------
CREATE TABLE public.transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_type public.transaction_type NOT NULL,
  category public.transaction_category NOT NULL,
  amount_xaf INTEGER NOT NULL CHECK (amount_xaf > 0),
  description TEXT NOT NULL,
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  reference_number TEXT,
  payment_method TEXT,
  -- Optional links to business entities
  vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  rental_id UUID REFERENCES public.rentals(id) ON DELETE SET NULL,
  rental_period_id UUID REFERENCES public.rental_periods(id) ON DELETE SET NULL,
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE SET NULL,
  vehicle_sale_id UUID REFERENCES public.vehicle_sales(id) ON DELETE SET NULL,
  notes TEXT,
  recorded_by UUID REFERENCES public.profiles(id),
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES public.profiles(id)
);

CREATE INDEX idx_transactions_type ON public.transactions(transaction_type)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_transactions_category ON public.transactions(category)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_transactions_date ON public.transactions(transaction_date DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_transactions_vehicle ON public.transactions(vehicle_id)
  WHERE deleted_at IS NULL AND vehicle_id IS NOT NULL;
CREATE INDEX idx_transactions_customer ON public.transactions(customer_id)
  WHERE deleted_at IS NULL AND customer_id IS NOT NULL;
CREATE INDEX idx_transactions_rental ON public.transactions(rental_id)
  WHERE deleted_at IS NULL AND rental_id IS NOT NULL;
CREATE INDEX idx_transactions_rental_period ON public.transactions(rental_period_id)
  WHERE deleted_at IS NULL AND rental_period_id IS NOT NULL;
CREATE INDEX idx_transactions_reference ON public.transactions(reference_number)
  WHERE deleted_at IS NULL AND reference_number IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Expenses (vehicle-specific cost tracking)
-- ---------------------------------------------------------------------------
CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE RESTRICT,
  transaction_id UUID UNIQUE REFERENCES public.transactions(id) ON DELETE SET NULL,
  category public.expense_category NOT NULL,
  description TEXT NOT NULL,
  amount_xaf INTEGER NOT NULL CHECK (amount_xaf > 0),
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  vendor TEXT,
  receipt_number TEXT,
  odometer_reading INTEGER CHECK (odometer_reading IS NULL OR odometer_reading >= 0),
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES public.profiles(id)
);

CREATE INDEX idx_expenses_vehicle ON public.expenses(vehicle_id)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_category ON public.expenses(category)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_date ON public.expenses(expense_date DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_transaction ON public.expenses(transaction_id)
  WHERE deleted_at IS NULL AND transaction_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Documents (attachable to vehicles, customers, rentals, transactions)
-- ---------------------------------------------------------------------------
CREATE TABLE public.documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  document_type public.document_type NOT NULL DEFAULT 'other',
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  mime_type TEXT,
  file_size_bytes BIGINT CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0),
  description TEXT,
  -- Polymorphic parent: exactly one must be set
  vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
  rental_id UUID REFERENCES public.rentals(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES public.transactions(id) ON DELETE CASCADE,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES public.profiles(id),
  CONSTRAINT documents_single_parent CHECK (
    num_nonnulls(vehicle_id, customer_id, rental_id, transaction_id) = 1
  )
);

CREATE INDEX idx_documents_vehicle ON public.documents(vehicle_id)
  WHERE deleted_at IS NULL AND vehicle_id IS NOT NULL;
CREATE INDEX idx_documents_customer ON public.documents(customer_id)
  WHERE deleted_at IS NULL AND customer_id IS NOT NULL;
CREATE INDEX idx_documents_rental ON public.documents(rental_id)
  WHERE deleted_at IS NULL AND rental_id IS NOT NULL;
CREATE INDEX idx_documents_transaction ON public.documents(transaction_id)
  WHERE deleted_at IS NULL AND transaction_id IS NOT NULL;
CREATE INDEX idx_documents_type ON public.documents(document_type)
  WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Reports (saved/generated business reports)
-- ---------------------------------------------------------------------------
CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  report_type public.report_type NOT NULL,
  status public.report_status NOT NULL DEFAULT 'draft',
  parameters JSONB NOT NULL DEFAULT '{}',
  summary JSONB,
  file_path TEXT,
  file_name TEXT,
  period_start DATE,
  period_end DATE,
  generated_at TIMESTAMPTZ,
  error_message TEXT,
  generated_by UUID REFERENCES public.profiles(id),
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES public.profiles(id),
  CONSTRAINT reports_period_check CHECK (
    period_start IS NULL
    OR period_end IS NULL
    OR period_end >= period_start
  )
);

CREATE INDEX idx_reports_type ON public.reports(report_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_reports_status ON public.reports(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_reports_period ON public.reports(period_start, period_end)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_reports_generated_at ON public.reports(generated_at DESC)
  WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Audit triggers for new tables
-- ---------------------------------------------------------------------------
CREATE TRIGGER drivers_updated_at
  BEFORE UPDATE ON public.drivers
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER rental_periods_updated_at
  BEFORE UPDATE ON public.rental_periods
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER expenses_updated_at
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER documents_updated_at
  BEFORE UPDATE ON public.documents
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER reports_updated_at
  BEFORE UPDATE ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- Helper: active-record filter (non-deleted)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_not_deleted(deleted_at_value TIMESTAMPTZ)
RETURNS BOOLEAN AS $$
  SELECT deleted_at_value IS NULL;
$$ LANGUAGE sql IMMUTABLE;

-- ---------------------------------------------------------------------------
-- Row Level Security — new tables
-- ---------------------------------------------------------------------------
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Drivers
CREATE POLICY "Authenticated users can view active drivers"
  ON public.drivers FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted drivers"
  ON public.drivers FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can insert drivers"
  ON public.drivers FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active drivers"
  ON public.drivers FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete drivers"
  ON public.drivers FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

-- Rental periods
CREATE POLICY "Authenticated users can view active rental periods"
  ON public.rental_periods FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted rental periods"
  ON public.rental_periods FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can manage rental periods"
  ON public.rental_periods FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active rental periods"
  ON public.rental_periods FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete rental periods"
  ON public.rental_periods FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

-- Transactions
CREATE POLICY "Authenticated users can view active transactions"
  ON public.transactions FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted transactions"
  ON public.transactions FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can insert transactions"
  ON public.transactions FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active transactions"
  ON public.transactions FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete transactions"
  ON public.transactions FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

-- Expenses
CREATE POLICY "Authenticated users can view active expenses"
  ON public.expenses FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted expenses"
  ON public.expenses FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can insert expenses"
  ON public.expenses FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active expenses"
  ON public.expenses FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete expenses"
  ON public.expenses FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

-- Documents
CREATE POLICY "Authenticated users can view active documents"
  ON public.documents FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted documents"
  ON public.documents FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can upload documents"
  ON public.documents FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active documents"
  ON public.documents FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete documents"
  ON public.documents FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

-- Reports
CREATE POLICY "Authenticated users can view active reports"
  ON public.reports FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view all reports"
  ON public.reports FOR SELECT TO authenticated
  USING (public.is_administrator());

CREATE POLICY "Authenticated users can create reports"
  ON public.reports FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update own draft reports"
  ON public.reports FOR UPDATE TO authenticated
  USING (deleted_at IS NULL AND (created_by = auth.uid() OR public.is_administrator()))
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can manage all reports"
  ON public.reports FOR ALL TO authenticated
  USING (public.is_administrator())
  WITH CHECK (public.is_administrator());

-- ---------------------------------------------------------------------------
-- Update RLS on existing tables for soft-delete awareness
-- ---------------------------------------------------------------------------

-- Vehicles
DROP POLICY IF EXISTS "Authenticated users can view vehicles" ON public.vehicles;
CREATE POLICY "Authenticated users can view active vehicles"
  ON public.vehicles FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted vehicles"
  ON public.vehicles FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can update vehicles" ON public.vehicles;
CREATE POLICY "Authenticated users can update active vehicles"
  ON public.vehicles FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete vehicles"
  ON public.vehicles FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Administrators can delete vehicles" ON public.vehicles;

-- Customers
DROP POLICY IF EXISTS "Authenticated users can manage customers" ON public.customers;

CREATE POLICY "Authenticated users can view active customers"
  ON public.customers FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted customers"
  ON public.customers FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can insert customers"
  ON public.customers FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active customers"
  ON public.customers FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete customers"
  ON public.customers FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

-- Rentals
DROP POLICY IF EXISTS "Authenticated users can manage rentals" ON public.rentals;

CREATE POLICY "Authenticated users can view active rentals"
  ON public.rentals FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted rentals"
  ON public.rentals FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can insert rentals"
  ON public.rentals FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active rentals"
  ON public.rentals FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete rentals"
  ON public.rentals FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

-- Service orders
DROP POLICY IF EXISTS "Authenticated users can manage service orders" ON public.service_orders;

CREATE POLICY "Authenticated users can view active service orders"
  ON public.service_orders FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted service orders"
  ON public.service_orders FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can insert service orders"
  ON public.service_orders FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active service orders"
  ON public.service_orders FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete service orders"
  ON public.service_orders FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

-- Vehicle sales
DROP POLICY IF EXISTS "Authenticated users can manage vehicle sales" ON public.vehicle_sales;

CREATE POLICY "Authenticated users can view active vehicle sales"
  ON public.vehicle_sales FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted vehicle sales"
  ON public.vehicle_sales FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can insert vehicle sales"
  ON public.vehicle_sales FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active vehicle sales"
  ON public.vehicle_sales FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete vehicle sales"
  ON public.vehicle_sales FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);
