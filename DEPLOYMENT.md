# DM Auto OS — Production Deployment

> **Setup credentials first:** See [SETUP.md](SETUP.md) for exactly where to place `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` for local and production environments.

> **Integration reference:** See [docs/SUPABASE.md](docs/SUPABASE.md) for Auth, PostgreSQL, and Storage configuration.

All secrets are supplied via **environment variables**. No credentials are hardcoded in the application.

## Required environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL (`https://<ref>.supabase.co`) |
| `SUPABASE_PUBLISHABLE_KEY` | Yes | Supabase publishable (anon) key |
| `SUPABASE_STORAGE_DOCUMENTS_BUCKET` | No | Default: `documents` |
| `SUPABASE_STORAGE_VEHICLE_PHOTOS_BUCKET` | No | Default: `vehicle-photos` |

Placeholders are in:
- `env.local.json.example`
- `env.production.json.example`
- `env.example.json`
- `assets/.env.example`

## Local development

See [SETUP.md](SETUP.md) for the full local setup guide. Quick start:

```bash
cp env.local.json.example env.local.json
# Edit env.local.json with your Supabase credentials

chmod +x scripts/run_dev.sh
./scripts/run_dev.sh
```

## Supabase project setup

### 1. Create project

1. Create a project at [supabase.com](https://supabase.com)
2. Copy **Project URL** → `SUPABASE_URL`
3. Copy **publishable** key → `SUPABASE_PUBLISHABLE_KEY`

### 2. Run database migrations

In the Supabase SQL editor, run in order:

```
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_financial_operations_schema.sql
supabase/migrations/003_module_priorities.sql
supabase/migrations/004_schema_grants_and_comments.sql
supabase/migrations/005_storage_buckets.sql
supabase/migrations/006_cashbook_module.sql
supabase/migrations/007_rental_period_closing.sql
supabase/migrations/008_mission_rentals.sql
```

This configures:
- PostgreSQL tables and relationships
- Row Level Security (RLS) on all business tables
- Storage buckets (`documents`, `vehicle-photos`) with RLS

### 3. Configure Authentication

In **Authentication → Providers**:
- Enable **Email** provider
- Set **Site URL** to your production domain (e.g. `https://app.dmauto.com`)
- Add **Redirect URLs** for each platform:
  - Web: `https://app.dmauto.com/**`
  - Mobile: `com.dmauto.dm_auto_os://login-callback/`

The app uses **PKCE** flow (`AuthFlowType.pkce`) for secure browser and mobile auth.

### 4. Storage buckets

Migration `005_storage_buckets.sql` creates:
- `documents` — PDFs, contracts, receipts (50 MB max)
- `vehicle-photos` — vehicle images (10 MB max)

Both buckets are **private**; access uses authenticated RLS and signed URLs.

## Production builds

### Web

```bash
cp env.production.json.example env.production.json
# Add production Supabase credentials to env.production.json

chmod +x scripts/build_web.sh
./scripts/build_web.sh
```

Deploy the `build/web` folder to your static host (Firebase Hosting, Vercel, Nginx, etc.).

### Android

```bash
flutter build apk --release --dart-define-from-file=env.production.json
```

### iOS

```bash
flutter build ios --release --dart-define-from-file=env.production.json
```

### CI/CD (GitHub Actions example)

Store secrets in your CI provider:

```
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

Build step:

```bash
cat > env.production.json << EOF
{
  "SUPABASE_URL": "${SUPABASE_URL}",
  "SUPABASE_PUBLISHABLE_KEY": "${SUPABASE_PUBLISHABLE_KEY}"
}
EOF

flutter build web --release --dart-define-from-file=env.production.json
```

**Never** commit `env.local.json` or `env.production.json`.

## Security notes

- The **publishable key** is safe to embed in client apps; access is enforced by RLS.
- Never expose the **service role key** in the Flutter app.
- All tables use RLS; soft-deleted records are hidden from non-administrators.
- Storage buckets are private; use signed URLs for downloads.

## Verify connection

After configuring credentials, the **Settings** screen shows:
- Connected to Supabase (green)
- Project URL (redacted in logs)
- Storage bucket names
