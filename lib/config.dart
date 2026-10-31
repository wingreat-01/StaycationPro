// Supabase credentials are passed at build time so they never live in source:
//   flutter run --dart-define-from-file=env.json
// See env.example.json for the expected keys.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);
