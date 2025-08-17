````markdown
# Pitch — a modern, web‑based 4‑player Pitch card game

[![CI • Build & Deploy](https://github.com/tonytmtsh/pitch/actions/workflows/deploy-pages.yml/badge.svg)](https://github.com/tonytmtsh/pitch/actions/workflows/deploy-pages.yml)

Play Pitch in the browser with a clean Flutter UI, fast local mock data for instant iteration, and a production‑grade Supabase SQL backend ready to wire in. The goal: a crisp, turn‑gated, realtime experience that feels like shuffling a real deck.

## Highlights

- Turn‑based flow: bidding → (optional) replacements → tricks → scoring
- 10‑point and 4‑point variants (toggle at runtime)
- “Current Trick” panel with N/E/S/W layout and turn highlighting
- Legal card gating on the client; server‑side legality ready in SQL
- My Hand panel with clickable cards (mock mode) and tap‑to‑play wiring
- Clean state via Provider; services are backend‑agnostic
- Mock JSON snapshots for every phase to develop fully offline
- Full Supabase SQL schema, RLS, and RPCs for a secure server mode
- CI builds both targets (mock/server) and deploys to GitHub Pages

## Live demo

- Mock backend (no auth, instant load):
	- https://tonytmtsh.github.io/pitch_mock/
- Server backend (auth + realtime; when enabled):
	- https://tonytmtsh.github.io/pitch_server/

Note: The app defaults to mock mode for local dev and PR previews.

## Quick start

Run in mock mode (recommended):

```bash
flutter config --enable-web
flutter pub get
flutter run -d chrome --dart-define=BACKEND=mock
```

VS Code: use the launch config “Flutter Web (Mock)” if present.

Build for GitHub Pages:

```bash
# Mock
flutter build web --release --base-href "/pitch_mock/" --dart-define=BACKEND=mock

# Server (requires Supabase project env)
flutter build web --release --base-href "/pitch_server/" --dart-define=BACKEND=server \
	--dart-define=SUPABASE_URL="https://YOUR-PROJECT.supabase.co" \
	--dart-define=SUPABASE_ANON_KEY="YOUR-ANON-KEY"
```

## Architecture at a glance

- UI: `lib/ui/` (entry: `LobbyScreen` → `TableScreen`)
- State: `lib/state/` (e.g., `LobbyStore`, `TableStore` with Provider)
- Services: `lib/services/` (`PitchService` contract; `MockPitchService` today)
- Supabase SQL: `supabase/sql/` (schema, RLS, RPCs, rules, scoring, seed)
- Mocks: `mock/*.json` (lobby, table, hands, bidding, replacements, tricks, scoring)
- CI/CD: `.github/workflows/deploy-pages.yml` (builds both mock/server targets)

Contract‑first design keeps UI independent of the backend:

```text
UI → State Store → PitchService (mock | supabase) → (assets | DB/RPC)
```

## Backend (Supabase) — ready when you are

SQL functions mirror game actions (see `supabase/sql/003_functions.sql`):

- create_table, join_table, leave_table
- start_game, deal_hand
- place_bid, declare_trump
- request_replacements, lock_replacements
- play_card (with turn/legality in SQL rules)

Row‑Level Security policies protect hidden info (hands) and enforce fairness. A realtime view streams trick plays to clients.

## Roadmap

- Richer card visuals (fans, drag‑to‑play, micro‑animations)
- Server‑auth’d multi‑user play with presence and chat
- Stricter legality hints from server to match UI exactly
- Mobile polish (one‑handed layout and compact controls)
- Spectator mode and hand replays

## Contributing

PRs welcome! A good first step is improving UI polish or wiring one RPC end‑to‑end. Please branch from `main` and open a PR.

Dev tips:

- Keep additions mock‑friendly (update `mock/*.json` where relevant)
- Preserve `PitchService` as the narrow, backend‑agnostic contract
- Use Provider for state; prefer `ListView.separated` for lists
- Ensure `--base-href` matches the target Pages repo path when building

---

Built with Flutter Web, Provider, and Supabase.
````
