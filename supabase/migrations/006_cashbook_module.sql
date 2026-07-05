-- DM Auto OS - Cashbook module enhancements
-- Multi-currency support, enriched cashbook view, daily/period summaries

-- ---------------------------------------------------------------------------
-- Currency
-- ---------------------------------------------------------------------------
CREATE TYPE public.currency_code AS ENUM ('XAF', 'USD', 'EUR');

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS currency_code public.currency_code NOT NULL DEFAULT 'XAF',
  ADD COLUMN IF NOT EXISTS amount_original INTEGER,
  ADD COLUMN IF NOT EXISTS exchange_rate NUMERIC(18, 6) NOT NULL DEFAULT 1.0
    CHECK (exchange_rate > 0);

-- Backfill amount_original from amount_xaf for existing rows
UPDATE public.transactions
SET amount_original = amount_xaf
WHERE amount_original IS NULL;

ALTER TABLE public.transactions
  ALTER COLUMN amount_original SET NOT NULL;

ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_amount_original_positive
    CHECK (amount_original > 0);

CREATE INDEX IF NOT EXISTS idx_transactions_currency
  ON public.transactions(currency_code)
  WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Enriched cashbook view
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.cashbook_entries AS
SELECT
  t.id,
  t.cashbook_sequence,
  t.transaction_date AS entry_date,
  t.transaction_type,
  t.category,
  t.currency_code,
  t.amount_original,
  t.exchange_rate,
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
  t.notes,
  t.reference_number,
  t.payment_method,
  t.vehicle_id,
  t.customer_id,
  t.rental_id,
  t.rental_period_id,
  t.recorded_by,
  t.created_at,
  c.full_name AS customer_name,
  TRIM(
    CONCAT(v.make, ' ', v.model, ' (', v.license_plate, ')')
  ) AS vehicle_label,
  (
    SELECT COUNT(*)::INTEGER
    FROM public.documents d
    WHERE d.transaction_id = t.id
      AND d.deleted_at IS NULL
  ) AS attachment_count
FROM public.transactions t
LEFT JOIN public.customers c
  ON c.id = t.customer_id AND c.deleted_at IS NULL
LEFT JOIN public.vehicles v
  ON v.id = t.vehicle_id AND v.deleted_at IS NULL
WHERE t.deleted_at IS NULL
  AND t.is_cashbook_posted = TRUE;

COMMENT ON VIEW public.cashbook_entries IS
  'Cashbook ledger with running XAF balance, multi-currency fields, and attachment counts.';

-- ---------------------------------------------------------------------------
-- Daily summary view
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.cashbook_daily_summary AS
SELECT
  t.transaction_date AS summary_date,
  COUNT(*)::INTEGER AS entry_count,
  COALESCE(SUM(
    CASE WHEN t.transaction_type = 'income' THEN t.amount_xaf ELSE 0 END
  ), 0)::INTEGER AS total_income_xaf,
  COALESCE(SUM(
    CASE WHEN t.transaction_type = 'expense' THEN t.amount_xaf ELSE 0 END
  ), 0)::INTEGER AS total_expense_xaf,
  COALESCE(SUM(
    CASE
      WHEN t.transaction_type = 'income' THEN t.amount_xaf
      ELSE -t.amount_xaf
    END
  ), 0)::INTEGER AS net_balance_xaf
FROM public.transactions t
WHERE t.deleted_at IS NULL
  AND t.is_cashbook_posted = TRUE
GROUP BY t.transaction_date
ORDER BY t.transaction_date DESC;

COMMENT ON VIEW public.cashbook_daily_summary IS
  'Per-day cashbook totals in XAF.';

-- ---------------------------------------------------------------------------
-- Period summary function
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_cashbook_period_summary(
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  start_date DATE,
  end_date DATE,
  entry_count INTEGER,
  total_income_xaf INTEGER,
  total_expense_xaf INTEGER,
  net_balance_xaf INTEGER,
  income_count INTEGER,
  expense_count INTEGER
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    p_start_date AS start_date,
    p_end_date AS end_date,
    COUNT(*)::INTEGER AS entry_count,
    COALESCE(SUM(
      CASE WHEN t.transaction_type = 'income' THEN t.amount_xaf ELSE 0 END
    ), 0)::INTEGER AS total_income_xaf,
    COALESCE(SUM(
      CASE WHEN t.transaction_type = 'expense' THEN t.amount_xaf ELSE 0 END
    ), 0)::INTEGER AS total_expense_xaf,
    COALESCE(SUM(
      CASE
        WHEN t.transaction_type = 'income' THEN t.amount_xaf
        ELSE -t.amount_xaf
      END
    ), 0)::INTEGER AS net_balance_xaf,
    COUNT(*) FILTER (WHERE t.transaction_type = 'income')::INTEGER AS income_count,
    COUNT(*) FILTER (WHERE t.transaction_type = 'expense')::INTEGER AS expense_count
  FROM public.transactions t
  WHERE t.deleted_at IS NULL
    AND t.is_cashbook_posted = TRUE
    AND t.transaction_date >= p_start_date
    AND t.transaction_date <= p_end_date;
$$;

GRANT EXECUTE ON FUNCTION public.get_cashbook_period_summary(DATE, DATE)
  TO authenticated;

GRANT SELECT ON public.cashbook_daily_summary TO authenticated;
