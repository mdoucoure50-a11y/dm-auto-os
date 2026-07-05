#!/usr/bin/env bash
# Local development — requires env.local.json (copy from env.local.json.example)
set -euo pipefail

ENV_FILE="${ENV_FILE:-env.local.json}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found."
  echo "Copy env.local.json.example to env.local.json and add your Supabase credentials."
  exit 1
fi

flutter run --dart-define-from-file="$ENV_FILE" "$@"
