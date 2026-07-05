-- DM Auto OS - Mission-based rentals
-- Rentals optionally belong to a mission; closing reports include mission profitability

-- ---------------------------------------------------------------------------
-- Missions
-- ---------------------------------------------------------------------------
CREATE TYPE public.mission_status AS ENUM ('active', 'inactive', 'completed');

CREATE TABLE IF NOT EXISTS public.missions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  description TEXT,
  status public.mission_status NOT NULL DEFAULT 'active',
  start_date DATE,
  end_date DATE,
  client_name TEXT,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  updated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES public.profiles(id),
  CONSTRAINT missions_code_unique UNIQUE (code),
  CONSTRAINT missions_date_check CHECK (
    start_date IS NULL
    OR end_date IS NULL
    OR end_date >= start_date
  )
);

CREATE INDEX IF NOT EXISTS idx_missions_status
  ON public.missions(status) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_missions_name
  ON public.missions(name) WHERE deleted_at IS NULL;

CREATE TRIGGER missions_updated_at
  BEFORE UPDATE ON public.missions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- Link rentals to missions (optional)
-- ---------------------------------------------------------------------------
ALTER TABLE public.rentals
  ADD COLUMN IF NOT EXISTS mission_id UUID
    REFERENCES public.missions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_rentals_mission
  ON public.rentals(mission_id)
  WHERE deleted_at IS NULL AND mission_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Per-mission stats on closing reports
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rental_period_mission_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID NOT NULL REFERENCES public.rental_period_reports(id) ON DELETE CASCADE,
  mission_id UUID REFERENCES public.missions(id) ON DELETE SET NULL,
  mission_name TEXT NOT NULL,
  mission_code TEXT,
  revenue_xaf INTEGER NOT NULL DEFAULT 0 CHECK (revenue_xaf >= 0),
  expenses_xaf INTEGER NOT NULL DEFAULT 0 CHECK (expenses_xaf >= 0),
  profit_xaf INTEGER GENERATED ALWAYS AS (revenue_xaf - expenses_xaf) STORED,
  rental_count INTEGER NOT NULL DEFAULT 0 CHECK (rental_count >= 0),
  rental_days INTEGER NOT NULL DEFAULT 0 CHECK (rental_days >= 0),
  profit_rank INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT rental_period_mission_stats_unique
    UNIQUE NULLS NOT DISTINCT (report_id, mission_id)
);

CREATE INDEX IF NOT EXISTS idx_rental_period_mission_stats_report
  ON public.rental_period_mission_stats(report_id);

CREATE INDEX IF NOT EXISTS idx_rental_period_mission_stats_profit
  ON public.rental_period_mission_stats(report_id, profit_xaf DESC);

-- ---------------------------------------------------------------------------
-- RLS — missions
-- ---------------------------------------------------------------------------
ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_period_mission_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view active missions"
  ON public.missions FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "Administrators can view deleted missions"
  ON public.missions FOR SELECT TO authenticated
  USING (public.is_administrator() AND deleted_at IS NOT NULL);

CREATE POLICY "Authenticated users can insert missions"
  ON public.missions FOR INSERT TO authenticated
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Authenticated users can update active missions"
  ON public.missions FOR UPDATE TO authenticated
  USING (deleted_at IS NULL)
  WITH CHECK (deleted_at IS NULL);

CREATE POLICY "Administrators can soft-delete missions"
  ON public.missions FOR UPDATE TO authenticated
  USING (public.is_administrator())
  WITH CHECK (TRUE);

CREATE POLICY "Authenticated users can view mission period stats"
  ON public.rental_period_mission_stats FOR SELECT TO authenticated
  USING (TRUE);

CREATE POLICY "Administrators can insert mission period stats"
  ON public.rental_period_mission_stats FOR INSERT TO authenticated
  WITH CHECK (public.is_administrator());

-- ---------------------------------------------------------------------------
-- Seed default missions
-- ---------------------------------------------------------------------------
INSERT INTO public.missions (name, code, description, status)
VALUES
  (
    'African Union Summit',
    'au-summit',
    'VIP fleet and protocol transport for AU Summit events',
    'active'
  ),
  (
    'COMILOG Contract',
    'comilog',
    'Long-term corporate contract with COMILOG mining operations',
    'active'
  ),
  (
    'Airport Transfer',
    'airport-transfer',
    'Airport pickup and drop-off services',
    'active'
  ),
  (
    'Private Client Rental',
    'private-client',
    'Individual and private corporate client rentals',
    'active'
  )
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Update close_rental_period to include mission profitability
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

  -- Per-vehicle stats
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

  -- Per-mission profitability (includes unassigned bucket)
  INSERT INTO public.rental_period_mission_stats (
    report_id,
    mission_id,
    mission_name,
    mission_code,
    revenue_xaf,
    expenses_xaf,
    rental_count,
    rental_days
  )
  SELECT
    v_report.id,
    ms.mission_id,
    ms.mission_name,
    ms.mission_code,
    ms.revenue_xaf,
    ms.expenses_xaf,
    ms.rental_count,
    ms.rental_days
  FROM (
    SELECT
      r.mission_id,
      COALESCE(m.name, 'Unassigned') AS mission_name,
      m.code AS mission_code,
      COALESCE(SUM(
        CASE WHEN t.transaction_type = 'income' THEN t.amount_xaf ELSE 0 END
      ), 0)::INTEGER AS revenue_xaf,
      COALESCE(SUM(
        CASE WHEN t.transaction_type = 'expense' THEN t.amount_xaf ELSE 0 END
      ), 0)::INTEGER AS expenses_xaf,
      COUNT(DISTINCT r.id)::INTEGER AS rental_count,
      COALESCE(SUM(r.end_date - r.start_date + 1), 0)::INTEGER AS rental_days
    FROM public.rentals r
    LEFT JOIN public.missions m ON m.id = r.mission_id AND m.deleted_at IS NULL
    LEFT JOIN public.transactions t
      ON t.rental_id = r.id
      AND t.deleted_at IS NULL
      AND t.rental_period_id = p_rental_period_id
    WHERE r.rental_period_id = p_rental_period_id
      AND r.deleted_at IS NULL
    GROUP BY r.mission_id, m.name, m.code
  ) ms
  WHERE ms.rental_count > 0
     OR ms.revenue_xaf > 0
     OR ms.expenses_xaf > 0;

  WITH mission_ranked AS (
    SELECT
      id,
      RANK() OVER (ORDER BY profit_xaf DESC, revenue_xaf DESC) AS profit_rank
    FROM public.rental_period_mission_stats
    WHERE report_id = v_report.id
  )
  UPDATE public.rental_period_mission_stats s
  SET profit_rank = mr.profit_rank
  FROM mission_ranked mr
  WHERE s.id = mr.id;

  SELECT
    vehicle_id,
    TRIM(CONCAT(vehicle_label, ' (', license_plate, ')')),
    profit_xaf
  INTO v_top_profit
  FROM public.rental_period_vehicle_stats
  WHERE report_id = v_report.id
  ORDER BY profit_xaf DESC, revenue_xaf DESC
  LIMIT 1;

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
      'most_utilized_vehicle_label', v_top_util.vehicle_label,
      'mission_count', (
        SELECT COUNT(*) FROM public.rental_period_mission_stats
        WHERE report_id = v_report.id
      )
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

COMMENT ON TABLE public.missions IS
  'Mission-based rental contracts (e.g. AU Summit, COMILOG, airport transfers).';

COMMENT ON TABLE public.rental_period_mission_stats IS
  'Per-mission profitability snapshot stored on period closing.';
