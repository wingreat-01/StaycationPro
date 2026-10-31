#!/usr/bin/env bash
# Builds the Flutter web app into site/app/, next to the landing page and
# legal pages, so Vercel can serve the whole site/ folder.
#
# On Vercel, Supabase settings come from the project's Environment Variables
# (Settings -> Environment Variables). Locally, run it with env.json instead:
#   bash scripts/vercel-build.sh --local
set -euo pipefail

# Stop Git Bash on Windows from rewriting "/app/" into a Windows path.
export MSYS_NO_PATHCONV=1

# Use the SDK cloned by vercel-install.sh if present, else the one on PATH.
FLUTTER=flutter
[ -x flutter/bin/flutter ] && FLUTTER=flutter/bin/flutter

if [ "${1:-}" = "--local" ]; then
  DEFINES=(--dart-define-from-file=env.json)
else
  : "${SUPABASE_URL:?Set SUPABASE_URL in Vercel project settings}"
  : "${SUPABASE_PUBLISHABLE_KEY:?Set SUPABASE_PUBLISHABLE_KEY in Vercel project settings}"
  DEFINES=(
    --dart-define=SUPABASE_URL="$SUPABASE_URL"
    --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
  )
fi

# The app is served from /app/, so its asset paths must start there.
"$FLUTTER" build web --release --base-href /app/ "${DEFINES[@]}"

rm -rf site/app
cp -r build/web site/app
echo "Site ready in site/ (web app in site/app/)"
