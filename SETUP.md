# DM Auto OS — Supabase Setup Guide

This guide explains **exactly where** to place `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` for local development and production deployment.

> **Never commit real credentials.** Placeholder templates are in the repo; your actual keys go in gitignored files or CI secrets only.

---

## Where to find your Supabase values

1. Open [supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Project Settings → API**
4. Copy:

| Dashboard field | Environment variable |
|-----------------|----------------------|
| **Project URL** | `SUPABASE_URL` |
| **Publishable key** (`anon` / `public`) | `SUPABASE_PUBLISHABLE_KEY` |

Example values (format only — use your own):

```
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## How the app reads credentials

`lib/core/config/env_config.dart` loads variables in this order:

| Priority | Source | Used for |
|----------|--------|----------|
| 1 (highest) | `--dart-define-from-file` or `--dart-define` | **Local dev & production builds** |
| 2 (fallback) | `assets/.env.example` via flutter_dotenv | Demo mode only (placeholders) |

If real credentials are not found, the app runs in **demo mode** (no Supabase connection).

---

## Local development

### Recommended: `env.local.json` (project root)

**File location:**

```
dm-auto-os/
├── env.local.json          ← PUT CREDENTIALS HERE (gitignored)
├── env.local.json.example  ← template (committed)
├── env.example.json
└── ...
```

**Steps:**

```bash
# 1. Create your local secrets file from the template
cp env.local.json.example env.local.json

# 2. Edit env.local.json with your real values
```

**`env.local.json` contents:**

```json
{
  "SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR-PUBLISHABLE-KEY"
}
```

**Run the app:**

```bash
./scripts/run_dev.sh
```

`scripts/run_dev.sh` runs:

```bash
flutter run --dart-define-from-file=env.local.json
```

**Or run manually:**

```bash
flutter run --dart-define-from-file=env.local.json
```

**IDE (VS Code / Cursor):**

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "DM Auto OS (local)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "toolArgs": [
        "--dart-define-from-file=env.local.json"
      ]
    }
  ]
}
```

---

### Alternative: individual `--dart-define` flags

Useful for quick tests without a JSON file:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR-PUBLISHABLE-KEY
```

---

### Not recommended for real credentials: `assets/.env`

The repo ships `assets/.env.example` with placeholders for documentation only. The app loads this file as a **fallback** when no dart-define values are set.

Do **not** put production secrets in `assets/.env` — it is bundled into the app binary.

---

## Production deployment

### Recommended: `env.production.json` (project root, gitignored)

**File location:**

```
dm-auto-os/
├── env.production.json     ← PUT PRODUCTION CREDENTIALS HERE (gitignored)
├── env.example.json        ← template (committed)
└── ...
```

**Steps:**

```bash
cp env.example.json env.production.json
# Edit env.production.json with production Supabase project values
```

**`env.production.json` contents:**

```json
{
  "SUPABASE_URL": "https://YOUR-PROD-PROJECT-REF.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR-PROD-PUBLISHABLE-KEY"
}
```

### Web production build

```bash
./scripts/build_web.sh
```

Which runs:

```bash
flutter build web --release --dart-define-from-file=env.production.json
```

Override the env file path:

```bash
ENV_FILE=env.production.json ./scripts/build_web.sh
```

### Android production build

```bash
flutter build apk --release --dart-define-from-file=env.production.json
```

### iOS production build

```bash
flutter build ios --release --dart-define-from-file=env.production.json
```

### CI/CD (GitHub Actions, GitLab CI, etc.)

**Do not** commit `env.production.json`. Store secrets in your CI provider:

| CI secret name | Maps to |
|----------------|---------|
| `SUPABASE_URL` | `SUPABASE_URL` |
| `SUPABASE_PUBLISHABLE_KEY` | `SUPABASE_PUBLISHABLE_KEY` |

**GitHub Actions example:**

```yaml
- name: Create env file from secrets
  run: |
    cat > env.production.json << EOF
    {
      "SUPABASE_URL": "${{ secrets.SUPABASE_URL }}",
      "SUPABASE_PUBLISHABLE_KEY": "${{ secrets.SUPABASE_PUBLISHABLE_KEY }}"
    }
    EOF

- name: Build web
  run: flutter build web --release --dart-define-from-file=env.production.json
```

**GitLab CI example:**

```yaml
build:
  script:
    - |
      cat > env.production.json << EOF
      {
        "SUPABASE_URL": "${SUPABASE_URL}",
        "SUPABASE_PUBLISHABLE_KEY": "${SUPABASE_PUBLISHABLE_KEY}"
      }
      EOF
    - flutter build web --release --dart-define-from-file=env.production.json
```

Set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as **masked/protected** CI variables in your pipeline settings.

---

## Files reference

| File | Commit to git? | Purpose |
|------|----------------|---------|
| `env.local.json` | **No** (gitignored) | Local development credentials |
| `env.production.json` | **No** (gitignored) | Production build credentials |
| `env.local.json.example` | Yes | Template for local setup |
| `env.example.json` | Yes | Template for production setup |
| `assets/.env.example` | Yes | Placeholder fallback (demo mode) |
| `assets/.env` | **No** (gitignored) | Optional local override (not recommended) |

---

## Verify your setup

1. Run the app with `env.local.json` configured
2. Sign in with a Supabase user account
3. Open **Settings** in the app — you should see:
   - **Supabase: Connected**
   - Your project URL
   - Storage bucket names

If you see **Demo mode**, credentials were not loaded. Check:

- [ ] `env.local.json` exists at the **project root** (same level as `pubspec.yaml`)
- [ ] JSON keys are exactly `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`
- [ ] Values are not placeholders (`your-project`, `your-publishable-key`)
- [ ] You launched with `--dart-define-from-file=env.local.json`

---

## Security reminders

- The **publishable key** is safe to embed in client apps — access is enforced by Row Level Security (RLS).
- **Never** put the **service role key** in the Flutter app or any client-side file.
- Use a **separate Supabase project** for production vs development when possible.
- Run database migrations before first use — see [DEPLOYMENT.md](DEPLOYMENT.md).

---

## Next steps

1. [DEPLOYMENT.md](DEPLOYMENT.md) — full Supabase project setup, auth, storage, migrations
2. [supabase/README.md](supabase/README.md) — database schema reference
3. [ROADMAP.md](ROADMAP.md) — development priorities
