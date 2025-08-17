# Copilot Instructions for this repo

Flutter Web app for a 4‑player Pitch game. Default runtime uses an in‑app mock service; a full Supabase SQL backend exists (not yet wired in Dart).

## Layout and roles
- UI: `lib/ui/` (entry: `LobbyScreen`)
- State: `lib/state/` (e.g., `LobbyStore` with Provider)
- Services: `lib/services/` (`PitchService` contract; `MockPitchService` loads assets)
- Mocks: `mock/*.json` snapshots for lobby/table/hands/bidding/replacements/tricks/scoring
- Supabase SQL: `supabase/sql/` (`001_schema.sql`, `002_rls.sql`, `003_functions.sql`, `005_rules.sql`, `006_scoring.sql`, `004_seed.sql`)
- CI: `.github/workflows/deploy-pages.yml` builds and deploys to two GitHub Pages repos

## Runtime selection (mock vs server)
- Compile‑time flag: `const backend = String.fromEnvironment('BACKEND', defaultValue: 'mock')` (used in `LobbyScreen` title).
- Injection point: `lib/ui/lobby_screen.dart` constructs the service. Swap `MockPitchService()` with a Supabase impl based on `backend`.
  - Future server wiring: use `lib/services/supabase/supabase_pitch_service.dart`. Expect env vars or build‑time defines for `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

## Data shapes and conventions
- Seats are fixed N/E/S/W. Variants: `'4_point' | '10_point'`. Cards use codes like `AS, 10H, QC`.
- `mock/lobby.json`:
  - `tables: [{ id, name, variant, status, occupancy, ... }]` and a `presence` map by table id.
- Models in `lib/services/pitch_service.dart` mirror these fields. `seatsTotal` is constant 4.
- Shared DTOs: see `lib/services/dtos.dart` (`LobbyEntryDto`, `TableSnapshotDto`) for standard mapping across mock/server.

## Patterns to follow
- Provider wiring (see `lib/ui/lobby_screen.dart`):
  `Provider<PitchService>(create: (_) => MockPitchService(), child: ChangeNotifierProvider(create: (ctx) => LobbyStore(ctx.read<PitchService>())..refresh(), child: _LobbyBody(...)))`
- Mock loading (see `lib/services/mock_pitch_service.dart`):
  `rootBundle.loadString('mock/<file>.json')` + `json.decode` → model factories.
- UI lists use `ListView.separated`; keep tiles simple and data‑driven.

## Supabase RPCs to mirror/call later (`supabase/sql/003_functions.sql`)
- `create_table(name text, variant text, target int) → uuid`
- `join_table(table uuid, position text) → boolean`; `leave_table(table uuid) → boolean`
- `start_game(table uuid) → uuid`; `deal_hand(game uuid, hand_number int, dealer text) → uuid`
- `place_bid(hand uuid, value int, pass boolean) → boolean`; `declare_trump(hand uuid, suit text) → boolean`
- `request_replacements(hand uuid, discard text[]) → text[]`; `lock_replacements(hand uuid) → boolean`
- `play_card(trick uuid, card text) → boolean` (legality/turn rules expanded in `005_rules.sql`)

## Build, run, test
- Enable web + deps: `flutter config --enable-web`; `flutter pub get`
- Local builds for Pages:
  - Mock: `flutter build web --release --base-href "/pitch_mock/" --dart-define=BACKEND=mock`
  - Server: `flutter build web --release --base-href "/pitch_server/" --dart-define=BACKEND=server`
- Dev run: `flutter run -d chrome` (defaults to mock unless overridden)
- Tests: `flutter test` (see `test/widget_test.dart` validating the Lobby)

### Supabase client setup (future)
- Add `supabase_flutter` dependency and initialize a client using URL/ANON KEY.
- Recommended folder: `lib/services/supabase/` (stub exists: `supabase_pitch_service.dart`).
- Expose methods that satisfy `PitchService` and map DB/RPC rows to DTOs/models.
 - Build‑time defines (suggested): `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` or read from env for other platforms.

## CI/CD (GitHub Pages)
- Matrix builds (mock/server) via `subosito/flutter-action@v2`; deploy with `peaceiris/actions-gh-pages@v3` to:
  - `tonytmtsh/pitch_mock` (base href `/pitch_mock/`)
  - `tonytmtsh/pitch_server` (base href `/pitch_server/`)
- Requires `PAGES_TOKEN` secret (PAT with `repo` scope) in this repo.

## Contributing
- Keep `PitchService` narrow and UI‑agnostic; provide both mock and server impls.
- Add/update mock JSON for any new UI flow to preserve offline dev.
- Ensure `--base-href` matches the GitHub Pages repo path or assets won’t resolve.
