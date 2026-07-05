-- DM Auto OS - Module priorities & rental operations data model
-- Prioritizes: Rentals, Cashbook, Rental Period Closing, Vehicle Profitability,
--              Customers, Drivers, Documents
-- Workshop (service_orders) remains optional / secondary

-- ---------------------------------------------------------------------------
-- Rental period closing support
-- ---------------------------------------------------------------------------
ALTER TYPE public.rental_period_status ADD VALUE IF NOT EXISTS 'closed';

ALTER TABLE public.rental_periods
  ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS closed_by UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS closing_notes TEXT,
  ADD COLUMN IF NOT EXISTS total_income_xaf INTEGER NOT NULL DEFAULT 0
    CHECK (total_income_xaf >= 0),
  ADD COLUMN IF NOT EXISTS total_expense_xaf INTEGER NOT NULL DEFAULT 0
    CHECK (total_expense_xaf >= 0),
  ADD COLUMN IF NOT EXISTS net_balance_xaf INTEGER GENERATED ALWAYS AS (
    total_income_xaf - total_expense_xaf
  ) STORED,
  ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_rental_periods_closed
  ON public.rental_periods(closed_at DESC)
  WHERE deleted_at IS NULL AND closed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rental_periods_open
  ON public.rental_periods(status)
  WHERE deleted_at IS NULL AND is_locked = FALSE;

-- ---------------------------------------------------------------------------
-- Service orders — optional workshop module (vehicle no longer required)
-- ---------------------------------------------------------------------------
ALTER TABLE public.service_orders
  ALTER COLUMN vehicle_id DROP NOT NULL;

ALTER TABLE public.service_orders
  ALTER COLUMN description SET DEFAULT '';

ALTER TABLE public.service_orders
  ALTER COLUMN description DROP NOT NULL;

COMMENT ON TABLE public.service_orders IS
  'Optional workshop module. Secondary development priority — not required for core rental operations.';

-- ---------------------------------------------------------------------------
-- Cashbook enhancements on transactions
-- ---------------------------------------------------------------------------
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS is_cashbook_posted BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS cashbook_sequence BIGSERIAL;

CREATE INDEX IF NOT EXISTS idx_transactions_cashbook
  ON public.transactions(transaction_date DESC, cashbook_sequence DESC)
  WHERE deleted_at IS NULL AND is_cashbook_posted = TRUE;

-- ---------------------------------------------------------------------------
-- Documents — attach to rental periods (period closing reports)
-- ---------------------------------------------------------------------------
ALTER TABLE public.documents
  ADD COLUMN IF NOT EXISTS rental_period_id UUID
    REFERENCES public.rental_periods(id) ON DELETE CASCADE;

ALTER TABLE public.documents
  DROP CONSTRAINT IF EXISTS documents_single_parent;

ALTER TABLE public.documents
  ADD CONSTRAINT documents_single_parent CHECK (
    num_nonnulls(
      vehicle_id,
      customer_id,
      rental_id,
      transaction_id,
      rental_period_id
    ) = 1
  );

CREATE INDEX IF NOT EXISTS idx_documents_rental_period
  ON public.documents(rental_period_id)
  WHERE deleted_at IS NULL AND rental_period_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Cashbook view (income & expense entries with running balance)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.cashbook_entries AS
SELECT
  t.id,
  t.cashbook_sequence,
  t.transaction_date AS entry_date,
  t.transaction_type,
  t.category,
  t.amount_xaf,
  CASE
    WHEN t.transaction_type = 'income' THEN t.amount_xaf
    ELSE -t.amount_xaf
  END AS signed_amount_xaf,
  SUM(
    CASE
      WHEN t.transaction_type = 'income' THEN t.amount_xaf
      ELSE -t.amount_xaf
    END
  ) OVER (
    ORDER BY t.transaction_date, t.cashbook_sequence
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )::INTEGER AS running_balance_xaf,
  t.description,
  t.reference_number,
  t.payment_method,
  t.vehicle_id,
  t.customer_id,
  t.rental_id,
  t.rental_period_id,
  t.recorded_by,
  t.created_at
FROM public.transactions t
WHERE t.deleted_at IS NULL
  AND t.is_cashbook_posted = TRUE;

COMMENT ON VIEW public.cashbook_entries IS
  'Primary cashbook module — chronological ledger with running XAF balance.';

-- ---------------------------------------------------------------------------
-- Vehicle profitability view
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.vehicle_profitability AS
SELECT
  v.id AS vehicle_id,
  v.make,
  v.model,
  v.year,
  v.license_plate,
  v.status,
  COALESCE(inc.total_income_xaf, 0) AS rental_income_xaf,
  COALESCE(exp.total_expense_xaf, 0) AS vehicle_expense_xaf,
  COALESCE(inc.total_income_xaf, 0) - COALESCE(exp.total_expense_xaf, 0)
    AS net_profit_xaf,
  COALESCE(rnt.active_rentals, 0) AS active_rentals_count
FROM public.vehicles v
LEFT JOIN (
  SELECT
    vehicle_id,
    SUM(amount_xaf) AS total_income_xaf
  FROM public.transactions
  WHERE deleted_at IS NULL
    AND transaction_type = 'income'
    AND vehicle_id IS NOT NULL
  GROUP BY vehicle_id
) inc ON inc.vehicle_id = v.id
LEFT JOIN (
  SELECT
    vehicle_id,
    SUM(amount_xaf) AS total_expense_xaf
  FROM public.expenses
  WHERE deleted_at IS NULL
  GROUP BY vehicle_id
) exp ON exp.vehicle_id = v.id
LEFT JOIN (
  SELECT
    vehicle_id,
    COUNT(*) AS active_rentals
  FROM public.rentals
  WHERE deleted_at IS NULL
    AND status = 'active'
  GROUP BY vehicle_id
) rnt ON rnt.vehicle_id = v.id
WHERE v.deleted_at IS NULL;

COMMENT ON VIEW public.vehicle_profitability IS
  'Per-vehicle income vs expense summary for profitability analysis (XAF).';

-- ---------------------------------------------------------------------------
-- Rental period closing audit log
-- ---------------------------------------------------------------------------
CREATE TABLE public.rental_period_closings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rental_period_id UUID NOT NULL REFERENCES public.rental_periods(id) ON DELETE RESTRICT,
  closed_by UUID NOT NULL REFERENCES public.profiles(id),
  closed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  total_income_xaf INTEGER NOT NULL DEFAULT 0 CHECK (total_income_xaf >= 0),
  total_expense_xaf INTEGER NOT NULL DEFAULT 0 CHECK (total_expense_xaf >= 0),
  net_balance_xaf INTEGER GENERATED ALWAYS AS (
    total_income_xaf - total_expense_xaf
  ) STORED,
  rental_count INTEGER NOT NULL DEFAULT 0 CHECK (rental_count >= 0),
  closing_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rental_period_closings_period
  ON public.rental_period_closings(rental_period_id);

CREATE INDEX idx_rental_period_closings_date
  ON public.rental_period_closings(closed_at DESC);

ALTER TABLE public.rental_period_closings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view rental period closings"
  ON public.rental_period_closings FOR SELECT TO authenticated
  USING (TRUE);

CREATE POLICY "Authenticated users can record rental period closings"
  ON public.rental_period_closings FOR INSERT TO authenticated
  WITH CHECK (TRUE);

-- ---------------------------------------------------------------------------
-- Function: close a rental period (locks period, records audit)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.close_rental_period(
  p_rental_period_id UUID,
  p_closing_notes TEXT DEFAULT NULL
)
RETURNS public.rental_period_closings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_period public.rental_periods;
  v_income INTEGER;
  v_expense INTEGER;
  v_rental_count INTEGER;
  v_closing public.rental_period_closings;
BEGIN
  SELECT * INTO v_period
  FROM public.rental_periods
  WHERE id = p_rental_period_id
    AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Rental period not found';
  END IF;

  IF v_period.is_locked THEN
    RAISE EXCEPTION 'Rental period is already closed';
  END IF;

  SELECT COALESCE(SUM(
    CASE WHEN transaction_type = 'income' THEN amount_xaf ELSE 0 END
  ), 0),
  COALESCE(SUM(
    CASE WHEN transaction_type = 'expense' THEN amount_xaf ELSE 0 END
  ), 0)
  INTO v_income, v_expense
  FROM public.transactions
  WHERE rental_period_id = p_rental_period_id
    AND deleted_at IS NULL;

  SELECT COUNT(*) INTO v_rental_count
  FROM public.rentals
  WHERE rental_period_id = p_rental_period_id
    AND deleted_at IS NULL;

  UPDATE public.rental_periods
  SET
    status = 'closed',
    closed_at = NOW(),
    closed_by = auth.uid(),
    closing_notes = p_closing_notes,
    total_income_xaf = v_income,
    total_expense_xaf = v_expense,
    is_locked = TRUE,
    updated_by = auth.uid()
  WHERE id = p_rental_period_id;

  INSERT INTO public.rental_period_closings (
    rental_period_id,
    closed_by,
    total_income_xaf,
    total_expense_xaf,
    rental_count,
    closing_notes
  )
  VALUES (
    p_rental_period_id,
    auth.uid(),
    v_income,
    v_expense,
    v_rental_count,
    p_closing_notes
  )
  RETURNING * INTO v_closing;

  RETURN v_closing;
END;
$$;

GRANT EXECUTE ON FUNCTION public.close_rental_period(UUID, TEXT) TO authenticated;
