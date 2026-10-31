#!/usr/bin/env bash
# Builds the web app on Vercel. Supabase settings come from the project's
# Environment Variables (Settings -> Environment Variables), not from env.json.
set -euo pipefail

: "${SUPABASE_URL:?Set SUPABASE_URL in Vercel project settings}"
: "${SUPABASE_PUBLISHABLE_KEY:?Set SUPABASE_PUBLISHABLE_KEY in Vercel project settings}"

flutter/bin/flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
