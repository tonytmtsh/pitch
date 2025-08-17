# Pitch Online – User Stories (MVP)

This set of user stories translates the requirements into implementable, testable units. Stories are grouped by epics. Each story includes clear acceptance criteria to guide development and QA. Variant‑specific scoring matches the current rules in `requirements.md` (4‑Point and your 10‑Point ruleset).

Legend
- Roles: Guest (unauthenticated), Player (authenticated), Table Owner (creator of a table)
- Variants: 4‑Point = [High, Low, Jack, Game]; 10‑Point (custom) = [High, Low, Jack, Game, Last Trick, Five (5 pts)]

## Epic A: Authentication & Profile

A1. As a Guest, I can sign up or log in so I can play
- Acceptance criteria
  - Given I am logged out, when I open the app, I can log in via email magic link/OTP.
  - After successful auth, a profile row is created if one doesn’t exist.
  - My session persists across refreshes until logout/expiry.

A2. As a Player, I can view/edit my display name and avatar
- Acceptance criteria
  - I can set a display name (with validation: 2–20 chars, no profanity list).
  - I can select an avatar (color/emoji).
  - Changes reflect in lobby and table presence in <2s.
  - If my chosen display name already exists, the system appends a unique 4‑digit suffix (e.g., Tony#4821) to ensure uniqueness.

A3. As a Player, I can log out
- Acceptance criteria
  - Logout clears session locally and on Supabase; redirects to Auth screen.

## Epic B: Lobby & Tables

B1. As a Player, I can see a realtime list of open tables
- Acceptance criteria
  - Lobby shows table name, variant, occupancy (0–4), status (Open/Playing/Finished), owner, created at.
  - List updates in realtime when tables are created/filled/start/end.

B2. As a Player, I can create a table
- Acceptance criteria
  - I can choose variant: 4‑Point or 10‑Point.
  - Optional: name, target score (defaults: 4‑Point=11, 10‑Point=50), start policy (Auto by default; Ready‑up optional later).
  - On create, a table record is stored; I auto‑join and sit at a seat selection view.

B3. As a Player, I can join an open table
- Acceptance criteria
  - I can join a table with <4 seats filled.
  - If full, I see it as Full and cannot join.
  - On join, I appear in presence and can select a seat.

B4. As a Player, I can select or change my seat before the game starts
- Acceptance criteria
  - Seats N/E/S/W are shown; partner sits across (N–S vs E–W).
  - A seat can be claimed if empty; changing seats releases the old one.
  - Seat changes are disabled after game start.

B5. As a Player, I can leave a table before the game starts
- Acceptance criteria
  - Leaving vacates my seat and removes my presence.
  - Table Owner can close the table if no longer needed.

B6. As a Table Owner, I can require players to Ready‑up (if enabled)
- Acceptance criteria
  - If Ready‑up is enabled, Start occurs when all 4 players press Ready.
  - If disabled (Auto), Start occurs when all 4 seats are filled (default behavior).

## Epic C: Game Lifecycle & Flow

C1. As a Table, the first dealer is North, then rotates clockwise each hand
- Acceptance criteria
  - Initial hand dealer = North; then E → S → W → N and so on.

C2. As a Player, I receive a private hand when the hand starts
- Acceptance criteria
  - Server deals 6 cards per seat (current default) using secure shuffle.
  - Only I can see my cards (RLS enforced); others cannot access them.

C3. As Players, we perform a single bidding round starting left of the dealer
- Acceptance criteria
  - Turn order for bidding: left of dealer → clockwise.
  - Each player either Passes or Bids an integer.
  - 4‑Point: min bid = 2 (typ. 2–4). 10‑Point: min bid = 3 (typ. 3–10). (Configurable per table.)
  - Highest bid wins. If all pass, redeal with next dealer.

C4. As Bid Winner, I declare trump before the first trick
- Acceptance criteria
  - I can select one suit as trump (♠/♥/♦/♣).
  - Trump is displayed to all players.

C5. As Players in 10‑Point, we may replace up to 6 cards after bidding
- Acceptance criteria
  - After trump is declared, each player in turn (starting with bid winner, clockwise) may discard 0–6 cards and draw from the stock to return to 6 cards.
  - Server validates discards are from hand and draws from stock; stock decreases accordingly.
  - Replacement actions are logged; once all players have had the opportunity, play proceeds to the first trick.

C6. As Players, we play 6 tricks following suit if able
- Acceptance criteria
  - The leader plays one card; then clockwise players must follow suit if possible.
  - If unable to follow suit, any card may be played; trump may be played.
  - Trick winner is determined: highest trump wins; if no trump, highest of led suit wins.
  - Trick winner leads the next trick.

C7. As a Table, we score the hand per variant, apply setback if needed, then rotate dealer
- Acceptance criteria
  - Variant rules compute team deltas correctly.
  - If bidding team fails to meet/exceed bid, subtract bid from their score (setback).
  - Add delta to running total; show a per‑hand scoreboard log.
  - Next hand rotates dealer.

C8. As a Table, we end the game when a team reaches the target score
- Acceptance criteria
  - Target score defaults: 4‑Point=11, 10‑Point=50 (configurable at table create).
  - 10‑Point win rule: A team must be the bidding team on the winning hand to win at/over 50 (“must bid to win”).
  - Float rule: If a team reaches 60 at any time (and bids up to 10 are allowed), they win immediately.
  - On reaching target/float, winner is announced; table can auto‑reset to Open or offer Rematch.

## Epic D: Variant Rules – 4‑Point

D1. As a Table, 4‑Point scoring uses High/Low/Jack/Game
- Acceptance criteria
  - High = 1: captured highest trump actually played.
  - Low = 1: captured lowest trump actually played.
  - Jack = 1: captured Jack of trump (only if dealt/played).
  - Game = 1: team with most Game points wins (values: A=4, K=3, Q=2, J=1, 10=10; others 0). Tie → no Game point.
  - If all pass in bidding, hand is redealt by next dealer.

## Epic E: Variant Rules – 10‑Point (custom)

E1. As a Table, 10‑Point scoring uses High/Low/Jack/Game/Last Trick/ Five (5)
- Acceptance criteria
  - High = 1: captured highest trump actually played.
  - Low = 1: captured lowest trump actually played.
  - Jack = 1: captured Jack of trump (only if dealt/played).
  - Game = 1: team with most Game points wins (values: 10=10, K=3, Q=2, J=1; others 0). Tie → no Game point.
  - Last Trick = 1: team that wins the last trick of the hand.
  - Five (of trump) = 5: capturing team gains 5 points (only if dealt/played).
  - Total available per hand = up to 10 points.
  - Deck is 52 cards (no Jokers, no Off‑Jack). Follow‑suit rules same as 4‑Point.

E2. As a Table, 10‑Point bidding and targets are appropriate for the variant
- Acceptance criteria
  - Min bid default = 3 (configurable per table).
  - Target score default = 50 (configurable per table); must‑bid‑to‑win; float at 60 if allowed.

## Epic F: Timers, Resilience, and Conduct

F1. As a Table, per‑turn timers enforce pace of play
- Acceptance criteria
  - Default per‑turn timer = 30s (configurable per table).
  - Bidding timeout → auto‑pass.
  - Trick play timeout → auto‑play lowest legal card.
  - Repeated timeouts are tracked; after N infractions, table owner may kick or table may forfeit per policy.

F2. As a Player, I can reconnect and resume my seat/state
- Acceptance criteria
  - Temporary disconnects reserve my seat for 2 minutes.
  - On reconnect, my hand, current trick, and turn timer restore.

F3. As a Table, we can resolve an absence via forfeit policy
- Acceptance criteria
  - If a player is absent beyond threshold (e.g., 3–5 min), the other team can claim forfeit.
  - Forfeit ends the current game with the opposing team declared winner.

## Epic G: Table Chat (minimal)

G1. As a Player, I can send and receive table chat messages
- Acceptance criteria
  - Messages appear in order with sender name and timestamp.
  - Rate limiting is enforced (e.g., max N msgs per 10s).
  - Basic emoji supported; no markdown/links execution.

## Epic H: UX & Accessibility

H1. As a Player, I get a responsive layout on web
- Acceptance criteria
  - Lobby/table/game screens adapt for common desktop/tablet widths.
  - Hands and center trick are readable without overlap.

H2. As a Player, I see clear feedback for turns, bids, and scores
- Acceptance criteria
  - Highlight current player’s turn.
  - Show trump suit and bidding winner.
  - Scoreboard updates immediately after each hand with a breakdown (per point category).

H3. As a Player, I get helpful error messages
- Acceptance criteria
  - Illegal play attempts show a non‑blocking message explaining why (e.g., must follow suit).
  - Network errors show retry guidance.

## Epic I: Security & Fairness

I1. As a Table, the server is authoritative for shuffle, deal, and outcomes
- Acceptance criteria
  - Shuffle/deal performed server‑side with crypto RNG; store per‑hand seed for audit.
  - Clients cannot override trick outcomes; server validates turn order and legal cards.

I2. As a Player, my private information stays private
- Acceptance criteria
  - RLS policies ensure only the seat owner can read their hand.
  - Non‑members cannot read table internals; chat limited to table participants.

## Epic J: Observability & Admin (MVP‑light)

J1. As Developers, we can diagnose common issues
- Acceptance criteria
  - Logs when a hand starts/ends, bids placed, trump chosen, tricks resolved, scores applied.
  - Minimal metrics: hands per game, average hand duration, disconnect count.

J2. As a Table Owner, I can remove a disruptive player (optional if time)
- Acceptance criteria
  - Owner UI to remove a seat pre‑start; in‑game removal subject to forfeit/vote‑kick policy.

---

## Technical Stories (Schema, RPC, Client State)

T1. Define Supabase schema and RLS
- Acceptance criteria
  - Tables created as per `requirements.md` (profiles, tables, table_seats, games, hands, bids, hands_private, tricks, trick_cards, scores, chat_messages).
  - 10‑Point replacements support: `hands.stock` jsonb for undealt cards and `replacements_locked` flag; `replacements` audit table (hand_id, position, discarded, drawn, order_index, created_at).
  - RLS policies enforce: seat privacy for hands_private; table membership for reads/writes; owner moderation rights.

T2. Edge Functions / SQL RPC for game actions
- Acceptance criteria
  - RPCs exist: create_table, join_table, leave_table, set_ready, start_game (auto), deal_hand, place_bid, declare_trump, request_replacements, lock_replacements, play_card, end_hand_score, end_game.
  - Each RPC checks seat ownership, turn order, legality (follow‑suit and replacement validity), variant rules, and updates rows atomically.

T3. Realtime channels and presence
- Acceptance criteria
  - Lobby channel streams table list updates.
  - Per‑table channels broadcast seating, bidding, trick plays, scoring, and chat.
  - Presence shows connected users; disconnects handled gracefully.

T4. Flutter Provider stores and navigation
- Acceptance criteria
  - Providers: AuthState, LobbyState, TableState, GameState.
  - Routes: / (Auth), /lobby, /table/:id, /game/:id.
  - Card rendering uses a pub.dev package; hands are interactive with legality hints.

T5. Scoring engines for variants
- Acceptance criteria
  - 4‑Point engine (High/Low/Jack/Game with A=4,K=3,Q=2,J=1,10=10; tie=no point).
  - 10‑Point engine (High 1, Low 1, Jack 1, Game 1 with 10=10,K=3,Q=2,J=1; Last Trick 1; Five of trump 5; tie=no Game point).
  - Unit tests cover bidding winner, trick resolution, and both scoring engines (happy path + ties + missing cards).

---

## Definition of Done (per story)
- UI/UX implemented and responsive on web.
- State changes reflected via Provider and persisted/replayed via Supabase.
- Server validations prevent illegal actions; errors surfaced to user.
- Unit tests for logic; manual smoke test for UI flows.
- No console errors; basic logs present.

## Suggested Delivery Order
1) Auth + Profile (A1–A3)
2) Lobby + Table Create/Join/Seat (B1–B6)
3) Schema/RLS/RPC/Realtime (T1–T3)
4) Game loop: Deal → Bid → Trump → Tricks (C1–C5)
5) Scoring engines + Scoreboard (C6, D1, E1–E2, T5)
6) End game + Rematch (C7)
7) Timers/Reconnect/Forfeit (F1–F3)
8) Chat (G1)
9) UX polish + QA + Metrics (H1–H3, I1–I2, J1)

## Open Items to Confirm
- Threshold for absence/forfeit (e.g., 3–5 minutes) and number of infractions before kick.
- Any house‑rule toggles to expose at table creation (e.g., allow bids up to 10 to enable float at 60).
