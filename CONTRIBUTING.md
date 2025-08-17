# Contributing

Thanks for your interest in improving Pitch! This repo is a Flutter Web app with an in‑app mock backend and a Supabase SQL backend ready for future wiring.

## How to contribute
1. Fork the repo and create a feature branch from `main`.
2. Make focused changes and include/update mock JSON snapshots if you add new UI flows.
3. Keep `PitchService` narrow and UI‑agnostic; add implementations under `lib/services/`.
4. Run tests locally (see below) and ensure the app builds for web with the correct base href.
5. Open a Pull Request to `main` with a clear summary of changes.

## Local dev
- Enable web + get deps:
  - `flutter config --enable-web`
  - `flutter pub get`
- Run in Chrome (mock backend by default):
  - `flutter run -d chrome`
- Tests:
  - `flutter test`
- Build for GitHub Pages (adjust base href):
  - Mock: `flutter build web --release --base-href "/pitch_mock/" --dart-define=BACKEND=mock`
  - Server: `flutter build web --release --base-href "/pitch_server/" --dart-define=BACKEND=server`

## CI/CD
- Pushes to `main` build and deploy two artifacts to separate Pages repos via `.github/workflows/deploy-pages.yml`.
- A `PAGES_TOKEN` secret (PAT with `repo` scope) in this repo publishes to:
  - `tonytmtsh/pitch_mock` → https://tonytmtsh.github.io/pitch_mock
  - `tonytmtsh/pitch_server` → https://tonytmtsh.github.io/pitch_server

## Style and patterns
- Provider pattern for state (see `lib/state/` and `lib/ui/lobby_screen.dart`).
- Mock assets live under `mock/`; load with `rootBundle`.
- Keep UI lists simple and data-driven; use `ListView.separated`.

## Supabase backend (future work)
- SQL schema and RPCs live under `supabase/sql/`.
- Stub client: `lib/services/supabase/supabase_pitch_service.dart`.
- Add `supabase_flutter` and wire RPCs when ready; keep implementations behind `PitchService`.

Happy hacking!
