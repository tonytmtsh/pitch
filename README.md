# Pitch (Flutter Web)

Flutter Web app for a 4‑player Pitch card game. The app runs against an in‑app mock backend today and includes a complete Supabase SQL backend for future wiring.

## What’s here

## Run locally
```bash
flutter config --enable-web
flutter pub get
flutter run -d chrome
```

 Dev run: `flutter run -d chrome` (defaults to mock unless overridden)
 Note: Ensure the app never initializes Supabase or shows sign-in in mock mode; use `--dart-define=BACKEND=mock` to enforce this.
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
