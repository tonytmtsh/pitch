# Pitch (Flutter Web)

Flutter Web app for a 4‑player Pitch card game. The app runs against an in‑app mock backend today and includes a complete Supabase SQL backend for future wiring.

## What’s here
- UI with Provider state (`lib/ui`, `lib/state`)
- Service contract and mock impl (`lib/services/`)
- Mock JSON snapshots (`mock/`) for lobby/table/hands/bidding/replacements/tricks/scoring
- Supabase SQL schema and RPCs (`supabase/sql/`)
- CI that builds two web targets (mock/server) and deploys each to GitHub Pages

## Run locally
```bash
flutter config --enable-web
flutter pub get
flutter run -d chrome
```

Build web for GitHub Pages with correct base paths:
```bash
# Mock build
flutter build web --release --base-href "/pitch_mock/" --dart-define=BACKEND=mock

# Server build
flutter build web --release --base-href "/pitch_server/" --dart-define=BACKEND=server \
	--dart-define=SUPABASE_URL="https://YOUR-PROJECT.supabase.co" \
	--dart-define=SUPABASE_ANON_KEY="YOUR-ANON-KEY"
```

### Supabase (future wiring)
When running with `BACKEND=server`, the app constructs a `SupabasePitchService` using `SUPABASE_URL` and `SUPABASE_ANON_KEY` provided via `--dart-define`. The current stub doesn’t call the API yet; it’s a placeholder for wiring RPCs defined in `supabase/sql/003_functions.sql`.

## Contributing
We welcome PRs. Please branch from `main` and open a Pull Request when ready.

See CONTRIBUTING.md for details on local dev, builds, tests, and CI.
