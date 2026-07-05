# DM Auto OS

Business management platform for vehicle rental, trading, and service companies.

**Primary currency:** XAF (Central African CFA franc)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Material Design 3) |
| State Management | Riverpod |
| Backend | Supabase |
| Database | PostgreSQL |
| Routing | go_router |

## Supported Platforms

- Mobile (iOS / Android)
- Tablet
- Desktop (Windows / macOS / Linux)
- Web Browser

## User Roles

| Role | Description |
|------|-------------|
| **Administrator** | Full access including user management, reports, and vehicle deletion |
| **Employee** | Day-to-day operations: rentals, services, trading, customers |

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── bootstrap.dart            # App initialization
├── app.dart                  # Root widget
├── core/
│   ├── constants/            # App, currency, breakpoint constants
│   ├── theme/                # Material Design 3 theming
│   ├── errors/               # Exception & failure types
│   ├── extensions/           # BuildContext extensions
│   ├── permissions/          # RBAC (roles, permissions, guards)
│   ├── responsive/           # Adaptive layout utilities
│   ├── routing/              # go_router configuration
│   ├── utils/                # Currency formatter, logger
│   └── widgets/              # Shared UI components
├── data/
│   ├── datasources/          # Supabase service
│   ├── models/               # Data models (JSON serialization)
│   └── repositories/         # Repository implementations
├── domain/
│   ├── entities/             # Business entities
│   └── repositories/         # Repository contracts
├── features/
│   ├── auth/                 # Login, password reset
│   ├── dashboard/            # Overview & stats
│   ├── rentals/              # Rental agreements (Phase 1)
│   ├── cashbook/             # Income & expense ledger (Phase 1)
│   ├── rental_periods/       # Period closing (Phase 1)
│   ├── vehicle_profitability/# Per-vehicle profit (Phase 1)
│   ├── customers/            # Customer management (Phase 1)
│   ├── drivers/              # Driver registry (Phase 1)
│   ├── documents/            # File attachments (Phase 1)
│   ├── vehicles/             # Fleet inventory
│   ├── services/             # Workshop — optional (Phase 2)
│   ├── trading/                # Vehicle sales (Phase 2)
│   ├── reports/              # Analytics (admin)
│   ├── users/                # User management (admin)
│   ├── settings/             # App settings
│   └── shell/                # Responsive navigation shell
└── providers/                # Riverpod providers
```

## Getting Started

### Prerequisites

- Flutter SDK 3.12+
- A Supabase project (optional for demo mode)

### Setup

1. Clone the repository
2. Configure Supabase credentials — see **[SETUP.md](SETUP.md)** for exactly where to place `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`:

   ```bash
   cp env.local.json.example env.local.json
   # Edit env.local.json with your Supabase URL and publishable key
   ```

   See [DEPLOYMENT.md](DEPLOYMENT.md) for production setup.

3. Set up Supabase project and run migrations (see [supabase/README.md](supabase/README.md))
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run database migrations in your Supabase SQL editor (in order):
   ```
   supabase/migrations/001_initial_schema.sql
   supabase/migrations/002_financial_operations_schema.sql
   supabase/migrations/003_module_priorities.sql
   supabase/migrations/004_schema_grants_and_comments.sql
   supabase/migrations/005_storage_buckets.sql
   ```
   See [supabase/README.md](supabase/README.md) for the full schema reference and ER diagram.
6. Run the app:
   ```bash
   ./scripts/run_dev.sh
   # or: flutter run --dart-define-from-file=env.local.json
   ```

### Demo Mode

Without Supabase configuration, the app runs in demo mode:
- Use any email/password to sign in
- Include `admin` in the email for Administrator role
- All other emails get Employee role

## Development Roadmap

See [ROADMAP.md](ROADMAP.md) for the full phased development plan.

**Current phase (Phase 1):** Rentals, Cashbook, Rental Period Closing, Vehicle Profitability, Customers, Drivers, Documents.

**Secondary (deferred UI):** Workshop (`service_orders`), Trading, Fleet management screens.

## Database Schema

### Core tables (`001_initial_schema.sql`)
- `profiles` — user profiles with roles
- `vehicles` — fleet inventory
- `customers` — customer records
- `rentals` — rental agreements
- `service_orders` — maintenance/repair orders
- `vehicle_sales` — trading/sales records

### Financial & operations (`002_financial_operations_schema.sql`)
- `drivers` — licensed drivers assignable to rentals
- `rental_periods` — billing/contract periods grouping multiple rentals
- `transactions` — income & expense ledger (XAF)
- `expenses` — vehicle-specific costs (linked to vehicles, optional transaction)
- `documents` — file attachments for vehicles, customers, rentals, or transactions
- `reports` — saved and generated business reports

### Module priorities (`003_module_priorities.sql`)
- `rental_period_closings` — audit log for period closing
- `close_rental_period()` — locks period and records totals
- `cashbook_entries` (view) — ledger with running XAF balance
- `vehicle_profitability` (view) — per-vehicle income vs expense
- `service_orders` — vehicle link now **optional** (workshop is secondary)
- `documents` — also attachable to `rental_periods`
- `transactions.is_cashbook_posted` — cashbook posting flag

### Relationships
```
vehicles 1──* expenses
vehicles 1──* rentals
customers 1──* rentals
rental_periods 1──* rentals
vehicles/customers/rentals/transactions 1──* documents
expenses *──1 transactions (optional)
```

All business tables include UUID primary keys, `created_at`/`updated_at` audit timestamps, and `deleted_at` soft deletes. Row Level Security (RLS) policies enforce role-based access and hide soft-deleted records from non-administrators.

## Supabase services

| Service | File | Responsibility |
|---------|------|----------------|
| **Client** | `lib/data/services/supabase_client_service.dart` | SDK initialization from env vars |
| **Auth** | `lib/data/services/supabase_auth_service.dart` | Sign in, sign out, password reset |
| **Database** | `lib/data/services/supabase_database_service.dart` | PostgreSQL queries via PostgREST |
| **Storage** | `lib/data/services/supabase_storage_service.dart` | File uploads and signed URLs |

Configuration is loaded exclusively via `EnvConfig` (`lib/core/config/env_config.dart`).

## Architecture

The app follows **clean architecture** with clear separation:

- **Presentation** — Flutter widgets, screens, feature modules
- **Domain** — Entities and repository interfaces
- **Data** — Supabase integration, models, repository implementations

**State management** uses Riverpod providers for auth, routing, theme, and permissions.

**Routing** uses go_router with auth guards and permission-based redirects.

**Responsive layout** adapts navigation:
- Mobile: bottom navigation bar + drawer
- Tablet: navigation rail
- Desktop: extended navigation rail

## License

Proprietary — DM Auto
