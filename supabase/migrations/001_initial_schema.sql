-- DM Auto OS - Initial Database Schema
-- Primary currency: XAF (Central African CFA franc)

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------
-- Custom types
-- ---------------------------------------------------------------------------
CREATE TYPE public.user_role AS ENUM ('administrator', 'employee');

CREATE TYPE public.vehicle_status AS ENUM (
  'available',
  'rented',
  'in_service',
  'sold',
  'reserved'
);

CREATE TYPE public.rental_status AS ENUM (
  'pending',
  'active',
  'completed',
  'cancelled'
);

CREATE TYPE public.service_status AS ENUM (
  'scheduled',
  'in_progress',
  'completed',
  'cancelled'
);

-- ---------------------------------------------------------------------------
-- Profiles (extends auth.users)
-- ---------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL DEFAULT '',
  role public.user_role NOT NULL DEFAULT 'employee',
  phone TEXT,
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_email ON public.profiles(email);

-- ---------------------------------------------------------------------------
-- Vehicles
-- ---------------------------------------------------------------------------
CREATE TABLE public.vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL CHECK (year >= 1900),
  license_plate TEXT NOT NULL UNIQUE,
  vin TEXT UNIQUE,
  color TEXT,
  mileage INTEGER NOT NULL DEFAULT 0,
  daily_rate_xaf INTEGER NOT NULL DEFAULT 0,
  sale_price_xaf INTEGER,
  status public.vehicle_status NOT NULL DEFAULT 'available',
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vehicles_status ON public.vehicles(status);
CREATE INDEX idx_vehicles_license_plate ON public.vehicles(license_plate);

-- ---------------------------------------------------------------------------
-- Customers
-- ---------------------------------------------------------------------------
CREATE TABLE public.customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT NOT NULL,
  id_number TEXT,
  address TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Rentals
-- ---------------------------------------------------------------------------
CREATE TABLE public.rentals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id),
  customer_id UUID NOT NULL REFERENCES public.customers(id),
  assigned_to UUID REFERENCES public.profiles(id),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  daily_rate_xaf INTEGER NOT NULL,
  total_amount_xaf INTEGER NOT NULL DEFAULT 0,
  deposit_xaf INTEGER NOT NULL DEFAULT 0,
  status public.rental_status NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT rentals_date_check CHECK (end_date >= start_date)
);

CREATE INDEX idx_rentals_status ON public.rentals(status);
CREATE INDEX idx_rentals_vehicle ON public.rentals(vehicle_id);

-- ---------------------------------------------------------------------------
-- Service orders
-- ---------------------------------------------------------------------------
CREATE TABLE public.service_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id),
  customer_id UUID REFERENCES public.customers(id),
  assigned_to UUID REFERENCES public.profiles(id),
  description TEXT NOT NULL,
  labor_cost_xaf INTEGER NOT NULL DEFAULT 0,
  parts_cost_xaf INTEGER NOT NULL DEFAULT 0,
  total_cost_xaf INTEGER GENERATED ALWAYS AS (labor_cost_xaf + parts_cost_xaf) STORED,
  status public.service_status NOT NULL DEFAULT 'scheduled',
  scheduled_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_service_orders_status ON public.service_orders(status);

-- ---------------------------------------------------------------------------
-- Vehicle sales (trading)
-- ---------------------------------------------------------------------------
CREATE TABLE public.vehicle_sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id),
  customer_id UUID NOT NULL REFERENCES public.customers(id),
  sold_by UUID REFERENCES public.profiles(id),
  sale_price_xaf INTEGER NOT NULL,
  sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Updated_at trigger
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER vehicles_updated_at
  BEFORE UPDATE ON public.vehicles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER customers_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER rentals_updated_at
  BEFORE UPDATE ON public.rentals
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER service_orders_updated_at
  BEFORE UPDATE ON public.service_orders
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ---------------------------------------------------------------------------
-- Auto-create profile on signup
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(
      (NEW.raw_user_meta_data->>'role')::public.user_role,
      'employee'
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Helper: check if current user is administrator
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_administrator()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'administrator'
      AND is_active = TRUE
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicle_sales ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Administrators can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.is_administrator());

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Administrators can manage all profiles"
  ON public.profiles FOR ALL
  USING (public.is_administrator());

-- Vehicles policies
CREATE POLICY "Authenticated users can view vehicles"
  ON public.vehicles FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Authenticated users can insert vehicles"
  ON public.vehicles FOR INSERT
  TO authenticated
  WITH CHECK (TRUE);

CREATE POLICY "Authenticated users can update vehicles"
  ON public.vehicles FOR UPDATE
  TO authenticated
  USING (TRUE);

CREATE POLICY "Administrators can delete vehicles"
  ON public.vehicles FOR DELETE
  TO authenticated
  USING (public.is_administrator());

-- Customers policies
CREATE POLICY "Authenticated users can manage customers"
  ON public.customers FOR ALL
  TO authenticated
  USING (TRUE)
  WITH CHECK (TRUE);

-- Rentals policies
CREATE POLICY "Authenticated users can manage rentals"
  ON public.rentals FOR ALL
  TO authenticated
  USING (TRUE)
  WITH CHECK (TRUE);

-- Service orders policies
CREATE POLICY "Authenticated users can manage service orders"
  ON public.service_orders FOR ALL
  TO authenticated
  USING (TRUE)
  WITH CHECK (TRUE);

-- Vehicle sales policies
CREATE POLICY "Authenticated users can manage vehicle sales"
  ON public.vehicle_sales FOR ALL
  TO authenticated
  USING (TRUE)
  WITH CHECK (TRUE);
