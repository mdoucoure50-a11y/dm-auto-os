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
│   ├── vehicles/             # Fleet management
│   ├── rentals/              # Rental agreements
│   ├── services/             # Service orders
│   ├── trading/              # Vehicle sales
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
2. Copy environment file:
   ```bash
   cp assets/.env.example assets/.env
   ```
3. Add your Supabase credentials to `assets/.env`:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run database migrations in your Supabase SQL editor:
   ```
   supabase/migrations/001_initial_schema.sql
   ```
6. Run the app:
   ```bash
   flutter run
   ```

### Demo Mode

Without Supabase configuration, the app runs in demo mode:
- Use any email/password to sign in
- Include `admin` in the email for Administrator role
- All other emails get Employee role

## Database Schema

The initial migration creates:
- `profiles` — user profiles with roles
- `vehicles` — fleet inventory
- `customers` — customer records
- `rentals` — rental agreements
- `service_orders` — maintenance/repair orders
- `vehicle_sales` — trading/sales records

Row Level Security (RLS) policies enforce role-based data access at the database level.

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
