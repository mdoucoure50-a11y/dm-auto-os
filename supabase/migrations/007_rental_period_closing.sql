-- DM Auto OS - Rental Period Closing System
-- Open/close periods, lock closed periods, permanent closing reports

-- ---------------------------------------------------------------------------
-- Rental period open tracking
-- ---------------------------------------------------------------------------
ALTER TABLE public.rental_periods
  ADD COLUMN IF NOT EXISTS opened_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS opened_by UUID REFERENCES public.profiles(id);

-- ---------------------------------------------------------------------------
-- Permanent closing reports
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rental_period_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rental_period_id UUID NOT NULL REFERENCES public.rental_periods(id) ON DELETE RESTRICT,
  closing_id UUID REFERENCES public.rental_period_closings(id) ON DELETE SET NULL,
  period_name TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  total_rental_revenue_xaf INTEGER NOT NULL DEFAULT 0
    CHECK (total_rental_revenue_xaf >= 0),
  total_rental_expenses_xaf INTEGER NOT NULL DEFAULT 0
    CHECK (total_rental_expenses_xaf >= 0),
  net_profit_xaf INTEGER GENERATED ALWAYS AS (
    total_rental_revenue_xaf - total_rental_expenses_xaf
  ) STORED,
  rental_count INTEGER NOT NULL DEFAULT 0 CHECK (rental_count >= 0),
  most_profitable_vehicle_id UUID REFERENCES public.vehicles(id),
  most_profitable_vehicle_label TEXT,
  most_profitable_vehicle_profit_xaf INTEGER,
  most_utilized_vehicle_id UUID REFERENCES public.vehicles(id),
  most_utilized_vehicle_label TEXT,
  most_utilized_rental_days INTEGER,
  closing_notes TEXT,
  generated_by UUID NOT NULL REFERENCES public.profiles(id),
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT rental_period_reports_period_unique UNIQUE (rental_period_id)
);

CREATE INDEX IF NOT EXISTS idx_rental_period_reports_period
  ON public.rental_period_reports(rental_period_id);

CREATE INDEX IF NOT EXISTS idx_rental_period_reports_generated_at
  ON public.rental_period_reports(generated_at DESC);

-- ---------------------------------------------------------------------------
-- Per-vehicle stats for each closing report
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rental_period_vehicle_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID NOT NULL REFERENCES public.rental_period_reports(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE RESTRICT,
  vehicle_label TEXT NOT NULL,
  license_plate TEXT NOT NULL,
  revenue_xaf INTEGER NOT NULL DEFAULT 0 CHECK (revenue_xaf >= 0),
  expenses_xaf INTEGER NOT NULL DEFAULT 0 CHECK (expenses_xaf >= 0),
  profit_xaf INTEGER GENERATED ALWAYS AS (revenue_xaf - expenses_xaf) STORED,
  rental_count INTEGER NOT NULL DEFAULT 0 CHECK (rental_count >= 0),
  rental_days INTEGER NOT NULL DEFAULT 0 CHECK (rental_days >= 0),
  profit_rank INTEGER,
  utilization_rank INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT rental_period_vehicle_stats_unique
    UNIQUE (report_id, vehicle_id)
);

CREATE INDEX IF NOT EXISTS idx_rental_period_vehicle_stats_report
  ON public.rental_period_vehicle_stats(report_id);

CREATE INDEX IF NOT EXISTS idx_rental_period_vehicle_stats_profit
  ON public.rental_period_vehicle_stats(report_id, profit_xaf DESC);

CREATE INDEX IF NOT EXISTS idx_rental_period_vehicle_stats_utilization
  ON public.rental_period_vehicle_stats(report_id, rental_days DESC);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.rental_period_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_period_vehicle_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view rental period reports"
  ON public.rental_period_reports FOR SELECT TO authenticated
  USING (TRUE);

CREATE POLICY "Administrators can insert rental period reports"
  ON public.rental_period_reports FOR INSERT TO authenticated
  WITH CHECK (public.is_administrator());

CREATE POLICY "Authenticated users can view vehicle period stats"
  ON public.rental_period_vehicle_stats FOR SELECT TO authenticated
  USING (TRUE);

CREATE POLICY "Administrators can insert vehicle period stats"
  ON public.rental_period_vehicle_stats FOR INSERT TO authenticated
  WITH CHECK (public.is_administrator());

-- ---------------------------------------------------------------------------
-- Function: open a rental period
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.open_rental_period(
  p_name TEXT,
  p_start_date DATE,
  p_end_date DATE,
  p_customer_id UUID DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS public.rental_periods
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_period public.rental_periods;
BEGIN
  IF p_end_date < p_start_date THEN
    RAISE EXCEPTION 'End date must be on or after start date';
  END IF;

  INSERT INTO public.rental_periods (
    name,
    description,
    customer_id,
    start_date,
    end_date,
    status,
    notes,
    opened_at,
    opened_by,
    created_by,
    is_locked
  )
  VALUES (
    p_name,
    p_description,
    p_customer_id,
    p_start_date,
    p_end_date,
    'active',
    p_notes,
    NOW(),
    auth.uid(),
    auth.uid(),
    FALSE
  )
  RETURNING * INTO v_period;

  RETURN v_period;
END;
$$;

GRANT EXECUTE ON FUNCTION public.open_rental_period(TEXT, DATE, DATE, UUID, TEXT, TEXT)
  TO authenticated;

-- ---------------------------------------------------------------------------
-- Function: close rental period (admin only), lock, generate permanent report
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.close_rental_period(
  p_rental_period_id UUID,
  p_closing_notes TEXT DEFAULT NULL
)
RETURNS public.rental_period_reports
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
  v_report public.rental_period_reports;
  v_top_profit RECORD;
  v_top_util RECORD;
BEGIN
  IF NOT public.is_administrator() THEN
    RAISE EXCEPTION 'Only administrators can close rental periods';
  END IF;

  SELECT * INTO v_period
  FROM public.rental_periods
  WHERE id = p_rental_period_id
    AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Rental period not found';
  END IF;

  IF v_period.is_locked OR v_period.status = 'closed' THEN
    RAISE EXCEPTION 'Rental period is already closed and locked';
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

  INSERT INTO public.rental_period_reports (
    rental_period_id,
    closing_id,
    period_name,
    period_start,
    period_end,
    total_rental_revenue_xaf,
    total_rental_expenses_xaf,
    rental_count,
    closing_notes,
    generated_by
  )
  VALUES (
    p_rental_period_id,
    v_closing.id,
    v_period.name,
    v_period.start_date,
    v_period.end_date,
    v_income,
    v_expense,
    v_rental_count,
    p_closing_notes,
    auth.uid()
  )
  RETURNING * INTO v_report;

  -- Per-vehicle stats from transactions + rental utilization
  INSERT INTO public.rental_period_vehicle_stats (
    report_id,
    vehicle_id,
    vehicle_label,
    license_plate,
    revenue_xaf,
    expenses_xaf,
    rental_count,
    rental_days
  )
  SELECT
    v_report.id,
    v.id,
    TRIM(CONCAT(v.make, ' ', v.model)),
    v.license_plate,
    COALESCE(tx.revenue_xaf, 0),
    COALESCE(tx.expenses_xaf, 0),
    COALESCE(rnt.rental_count, 0),
    COALESCE(rnt.rental_days, 0)
  FROM public.vehicles v
  LEFT JOIN (
    SELECT
      vehicle_id,
      SUM(CASE WHEN transaction_type = 'income' THEN amount_xaf ELSE 0 END) AS revenue_xaf,
      SUM(CASE WHEN transaction_type = 'expense' THEN amount_xaf ELSE 0 END) AS expenses_xaf
    FROM public.transactions
    WHERE rental_period_id = p_rental_period_id
      AND deleted_at IS NULL
      AND vehicle_id IS NOT NULL
    GROUP BY vehicle_id
  ) tx ON tx.vehicle_id = v.id
  LEFT JOIN (
    SELECT
      vehicle_id,
      COUNT(*)::INTEGER AS rental_count,
      COALESCE(SUM(end_date - start_date + 1), 0)::INTEGER AS rental_days
    FROM public.rentals
    WHERE rental_period_id = p_rental_period_id
      AND deleted_at IS NULL
    GROUP BY vehicle_id
  ) rnt ON rnt.vehicle_id = v.id
  WHERE v.deleted_at IS NULL
    AND (
      COALESCE(tx.revenue_xaf, 0) > 0
      OR COALESCE(tx.expenses_xaf, 0) > 0
      OR COALESCE(rnt.rental_count, 0) > 0
    );

  -- Profit rankings
  WITH ranked AS (
    SELECT
      id,
      RANK() OVER (ORDER BY profit_xaf DESC, revenue_xaf DESC) AS profit_rank,
      RANK() OVER (ORDER BY rental_days DESC, rental_count DESC) AS utilization_rank
    FROM public.rental_period_vehicle_stats
    WHERE report_id = v_report.id
  )
  UPDATE public.rental_period_vehicle_stats s
  SET
    profit_rank = r.profit_rank,
    utilization_rank = r.utilization_rank
  FROM ranked r
  WHERE s.id = r.id;

  -- Top profitable vehicle
  SELECT
    vehicle_id,
    TRIM(CONCAT(vehicle_label, ' (', license_plate, ')')),
    profit_xaf
  INTO v_top_profit
  FROM public.rental_period_vehicle_stats
  WHERE report_id = v_report.id
  ORDER BY profit_xaf DESC, revenue_xaf DESC
  LIMIT 1;

  -- Top utilized vehicle
  SELECT
    vehicle_id,
    TRIM(CONCAT(vehicle_label, ' (', license_plate, ')')),
    rental_days
  INTO v_top_util
  FROM public.rental_period_vehicle_stats
  WHERE report_id = v_report.id
  ORDER BY rental_days DESC, rental_count DESC
  LIMIT 1;

  UPDATE public.rental_period_reports
  SET
    most_profitable_vehicle_id = v_top_profit.vehicle_id,
    most_profitable_vehicle_label = v_top_profit.vehicle_label,
    most_profitable_vehicle_profit_xaf = v_top_profit.profit_xaf,
    most_utilized_vehicle_id = v_top_util.vehicle_id,
    most_utilized_vehicle_label = v_top_util.vehicle_label,
    most_utilized_rental_days = v_top_util.rental_days
  WHERE id = v_report.id
  RETURNING * INTO v_report;

  -- Also persist in generic reports table for archive
  INSERT INTO public.reports (
    title,
    report_type,
    status,
    parameters,
    summary,
    period_start,
    period_end,
    generated_at,
    generated_by,
    created_by
  )
  VALUES (
    'Rental Period Closing — ' || v_period.name,
    'rental',
    'generated',
    jsonb_build_object(
      'rental_period_id', p_rental_period_id,
      'closing_id', v_closing.id,
      'report_id', v_report.id
    ),
    jsonb_build_object(
      'total_rental_revenue_xaf', v_income,
      'total_rental_expenses_xaf', v_expense,
      'net_profit_xaf', v_income - v_expense,
      'most_profitable_vehicle_label', v_top_profit.vehicle_label,
      'most_utilized_vehicle_label', v_top_util.vehicle_label
    ),
    v_period.start_date,
    v_period.end_date,
    NOW(),
    auth.uid(),
    auth.uid()
  );

  RETURN v_report;
END;
$$;

GRANT EXECUTE ON FUNCTION public.close_rental_period(UUID, TEXT) TO authenticated;

COMMENT ON TABLE public.rental_period_reports IS
  'Permanent rental period closing reports with fleet-wide totals and rankings.';

COMMENT ON TABLE public.rental_period_vehicle_stats IS
  'Per-vehicle revenue, expenses, profit, and utilization for a closing report.';
