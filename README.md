# StaycationPro

A Flutter app where guests book staycations and owners accept or decline
reservations. Backend: [Supabase](https://supabase.com) (auth, Postgres, realtime).

## Features

**Guests** — browse and search places, see booked dates, request a booking
(dates, number of guests, message to host), track and cancel trips.

**Owners (hosts)** — add/edit/hide places, get booking requests live,
accept or decline, see upcoming stays and history with guest contact details.

Booking rules are enforced in the database, not just the app: prices are
computed server-side, accepted bookings can never overlap, accepting a request
auto-declines overlapping pending ones, and only the owner can accept.

## Setup

1. Create a project at [supabase.com](https://supabase.com).
2. In the dashboard open **SQL Editor** and run, in order:
   [supabase/schema.sql](supabase/schema.sql), then
   [supabase/002_listing_photos.sql](supabase/002_listing_photos.sql) (photo storage).
3. For quick testing, turn off email confirmation:
   **Authentication → Sign In / Providers → Email → Confirm email** (turn it back on before launch).
4. Copy `env.example.json` to `env.json` and fill in your values from
   **Project Settings → API Keys** (project URL and publishable key).
5. Run:

   ```sh
   flutter run --dart-define-from-file=env.json
   ```

To try both sides, sign up once as **"I'm hosting"** and add a place, then sign up
with another email as **"I'm booking"** and request it.

## Project layout

```
lib/
  main.dart            app entry, auth gate, guest/owner navigation
  config.dart          Supabase keys (from --dart-define)
  models.dart          Profile, Listing, Booking
  repository.dart      all Supabase calls
  widgets.dart         shared UI (booking card, status chip, …)
  screens/
    auth_screen.dart
    account_screen.dart
    guest/             browse, listing detail + booking, my trips
    owner/             booking requests, my places, place form
supabase/schema.sql    tables, row-level security, booking functions
```

## Website (Vercel)

The `site/` folder is the public website, deployed to Vercel:

| Path | File |
|---|---|
| `/` | `site/index.html` — landing page |
| `/privacy` | `site/privacy.html` — privacy policy |
| `/delete-account` | `site/delete-account.html` — account deletion |
| `/app/` | `site/app/` — the Flutter web app, generated on every build (not in git) |

Vercel runs `scripts/vercel-build.sh`, which builds the app with `--base-href /app/`
and copies it into `site/app/`. Set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`
in Vercel → Settings → Environment Variables. To build the same site locally:
`bash scripts/vercel-build.sh --local`.

## Before publishing to Google Play

- Change `applicationId` in `android/app/build.gradle.kts` if you want something other than `ph.staycationpro.staycation_pro`.
- Create an upload keystore and configure release signing.
- Add an app icon and a privacy policy URL (required, since the app collects names, emails and phone numbers).
- Build: `flutter build appbundle --dart-define-from-file=env.json`
