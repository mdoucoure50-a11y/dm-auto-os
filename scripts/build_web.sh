#!/usr/bin/env bash
# Production web build — inject secrets via env file (never commit env.production.json)
set -euo pipefail

ENV_FILE="${ENV_FILE:-env.production.json}"
OUTPUT="${OUTPUT:-build/web}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found."
  echo "Create env.production.json with SUPABASE_URL and SUPABASE_ANON_KEY."
  exit 1
fi

flutter build web \
  --release \
  --dart-define-from-file="$ENV_FILE" \
  --output="$OUTPUT" \
  "$@"

echo "Built to $OUTPUT"
