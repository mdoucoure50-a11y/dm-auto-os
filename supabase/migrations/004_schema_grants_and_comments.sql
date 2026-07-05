-- DM Auto OS - Schema grants, documentation comments, and hardening
-- Run after 001, 002, and 003

-- ---------------------------------------------------------------------------
-- Table documentation
-- ---------------------------------------------------------------------------
COMMENT ON TABLE public.drivers IS
  'Licensed drivers assignable to rentals. Phase 1 primary module.';

COMMENT ON TABLE public.rental_periods IS
  'Billing/contract periods grouping multiple rentals. Supports period closing.';

COMMENT ON TABLE public.transactions IS
  'Cashbook ledger supporting income and expense entries (XAF).';

COMMENT ON TABLE public.expenses IS
  'Vehicle-specific costs. Each vehicle can have many expenses.';

COMMENT ON TABLE public.documents IS
  'File attachments polymorphically linked to vehicles, customers, rentals, transactions, or rental periods.';

COMMENT ON TABLE public.reports IS
  'Saved and generated business reports with JSON parameters.';

COMMENT ON TABLE public.rentals IS
  'Rental agreements. Linked to vehicles, customers, optional rental periods and drivers.';

COMMENT ON TABLE public.vehicles IS
  'Fleet inventory. Parent of expenses and rentals.';

COMMENT ON TABLE public.customers IS
  'Customer records. Parent of rentals and rental periods.';

-- ---------------------------------------------------------------------------
-- View grants (authenticated read access)
-- ---------------------------------------------------------------------------
GRANT SELECT ON public.cashbook_entries TO authenticated;
GRANT SELECT ON public.vehicle_profitability TO authenticated;

-- ---------------------------------------------------------------------------
-- Drivers: allow license reuse after soft delete
-- ---------------------------------------------------------------------------
ALTER TABLE public.drivers
  DROP CONSTRAINT IF EXISTS drivers_license_number_unique;

CREATE UNIQUE INDEX IF NOT EXISTS idx_drivers_license_active
  ON public.drivers(license_number)
  WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- vehicle_sales: add missing audit columns (consistency)
-- ---------------------------------------------------------------------------
ALTER TABLE public.vehicle_sales
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS deleted_by UUID REFERENCES public.profiles(id);

DROP TRIGGER IF EXISTS vehicle_sales_updated_at ON public.vehicle_sales;
CREATE TRIGGER vehicle_sales_updated_at
  BEFORE UPDATE ON public.vehicle_sales
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- Soft-delete utility (sets deleted_at and deleted_by)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.soft_delete_row()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  EXECUTE format(
    'UPDATE %I.%I SET deleted_at = NOW(), deleted_by = $1 WHERE id = $2 AND deleted_at IS NULL',
    TG_TABLE_SCHEMA,
    TG_TABLE_NAME
  ) USING auth.uid(), OLD.id;
  RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public.soft_delete_row() IS
  'BEFORE DELETE trigger helper: converts hard deletes into soft deletes.';

-- ---------------------------------------------------------------------------
-- Relationship integrity comments (for tooling / ERD generators)
-- ---------------------------------------------------------------------------
COMMENT ON COLUMN public.expenses.vehicle_id IS
  'FK → vehicles. A vehicle can have many expenses.';

COMMENT ON COLUMN public.rentals.vehicle_id IS
  'FK → vehicles. A vehicle can have many rentals.';

COMMENT ON COLUMN public.rentals.customer_id IS
  'FK → customers. A customer can have many rentals.';

COMMENT ON COLUMN public.rentals.rental_period_id IS
  'FK → rental_periods. A rental period can contain many rentals.';

COMMENT ON COLUMN public.transactions.transaction_type IS
  'income or expense — both supported in the cashbook.';

COMMENT ON CONSTRAINT documents_single_parent ON public.documents IS
  'Document must attach to exactly one parent: vehicle, customer, rental, transaction, or rental_period.';
