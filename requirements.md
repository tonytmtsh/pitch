# Pitch Online – Requirements (MVP)

This document defines the requirements for a 4‑player online Pitch card game built with Flutter (Web for MVP) and Supabase as the backend. State management uses Provider. Users must authenticate to play. Tables support two variants: 4‑Point and 10‑Point Pitch.

Note: Pitch/Setback has many regional variants. Below are commonly accepted rule sets for the two targeted variants. Where differences exist, assumptions are called out and open questions are listed for your confirmation.

## Goals and scope

- Playable web MVP (Flutter Web) with Supabase backend and realtime gameplay.
- 4 players per table, two fixed teams (N–S vs E–W). Partner sits across.
- Tables labeled by variant: “4‑Point” or “10‑Point”.
- Lobby to discover/join/create tables. Game auto‑starts when 4 seats are filled. (Ready‑up can be optional later.)
- Full hand lifecycle: deal, bidding, declare trump, trick play, scoring, rotate dealer.
- Auth required; display profile/display name.
- Use a card UI package from pub.dev to render cards.

Out of scope (MVP): bots/AI, ranked matchmaking, money/wagers, spectators, mobile builds, tournaments.

## Platforms and tech

- Client: Flutter (stable), Web target for MVP; Provider for state management.
- Backend: Supabase (Postgres + Auth + Realtime + RLS + optional Edge Functions/SQL RPC).
- Realtime: Supabase Realtime channels for lobby presence, seating, bidding, trick events, scoring, and chat.
- Auth: Supabase Auth (email OTP/magic link; optionally Google/GitHub later).

## Game variants and rules

Two table types exist. Unless noted, standard trick‑taking rules apply: follow suit if able; otherwise, any card (including trump). Highest trump wins the trick; if no trump was played, highest card of the suit led wins.

### 4‑Point Pitch (a.k.a. Setback / Auction Pitch)

Assumed variant for MVP:
- Deck: 52 cards; rank high‑to‑low within suit A K Q J 10 … 2.
- Players: 4, fixed partnerships (N–S vs E–W).
- Deal: 6 cards each (commonly 3‑and‑3). Dealer rotates clockwise each hand. First dealer = North.
- Bidding:
  - Starts left of dealer; one round. Options: Pass or integer bid (typ. 2–4).
  - Minimum opening bid: 2. Highest bid wins and declares trump. If all pass, redeal by next dealer.
- Play:
  - Bid winner declares trump before first trick.
  - Must follow suit if able; otherwise may play any card.
  - 6 tricks are played; trick winner leads next.
- Scoring categories (4 total points per hand):
  - High: 1 point for capturing the highest trump that was played (usually Ace if played).
  - Low: 1 point for capturing the lowest trump that was played (could be 2 if played).
  - Jack: 1 point for capturing the Jack of trump (only if the Jack of trump is dealt/played this hand).
  - Game: 1 point to the team with most “game” card points captured across all tricks.
    - Game card values: Ace = 4, King = 3, Queen = 2, Jack = 1, Ten = 10; others = 0. Only captured cards count. Tie → no Game point.
  - Bidding team must make at least their bid in total points; failing results in setback (deduct bid from their score).
- Match end: First team to reach target score (commonly 7 or 11). MVP default: 11. Floor at 0 by default.

Assumptions to confirm: 6‑card deal; min bid=2; single‑round bidding; Game values above; target=11.

### 10‑Point Pitch (user rules)

This variant matches your ruleset:
- Deck: 52 cards (no Jokers). Rank within suit A K Q J 10 … 2.
- Players: 4, fixed partnerships.
- Deal: 6 cards each (3‑and‑3). If all pass, redeal by next dealer.
- Replacement phase: After bidding and trump declaration, each player may discard 0–6 cards and draw replacements from the undealt stock to return to 6 cards.
- Bidding:
  - Starts left of dealer; one round; bids typically 3–10. Minimum bid = 3. Highest bid wins and declares trump.
- Play: Follow suit if able; otherwise any card; trump may be led.
- Scoring per hand (maximum 10 points):
  1) High: 1 point for the highest trump captured (usually Ace if played).
  2) Low: 1 point for the lowest trump captured that was played (could be 2 if played).
  3) Jack: 1 point for capturing the Jack of trump (only if dealt/played).
  4) Game: 1 point to the team with the highest “game” card points captured.
     - Game card values: Ten = 10, King = 3, Queen = 2, Jack = 1; all other cards = 0.
     - Only captured cards count. Tie → no Game point.
  5) Last Trick: 1 point to the team that wins the last trick of the hand.
  6) Five: 5 points for capturing the Five of trump (only if dealt/played).
  - Bidding team must meet or exceed their bid; failing incurs a setback equal to the bid.
- Match end: First team to 50 points wins, with “must bid to win” rule: the winning hand must belong to the bidding team. A team may “float out” at 60 points (instant win) if bids up to 10 are allowed at the table.

Decisions: 6‑card deal (3‑and‑3); replacements allowed up to 6 after bidding; min bid=3; target=50 with must‑bid‑to‑win and float‑at‑60; Game values as below; Five of trump = 5 points.

## Functional requirements

### Authentication and profile
- Users must log in via Supabase Auth.
- On first login, create profile with display name and avatar (emoji/color).
- Username policy: If a display name is duplicated, append a unique 4‑digit numeric suffix (e.g., Tony#4821) to ensure uniqueness.
- Show online presence in lobby.

### Lobby and tables
- Lobby lists tables in realtime with: name/ID, variant (4‑Point/10‑Point), occupancy (0–4), status (Open/Playing/Finished), owner, created at.
- Actions:
  - Create table (choose variant, optional name, optional target score, optional seat lock; defaults per variant).
  - Join table; pick seat (N/E/S/W). Partner sits across.
  - Leave table before game start; owner can close table.
- Start condition: When 4 seats are filled, transition to Dealing (default). Optional Ready‑up requirement can be added later.

### Seating and teams
- Fixed seating N–S vs E–W.
- Seat changes allowed until start (subject to owner lock). Then fixed.

### Game lifecycle
1) Dealer assignment: First hand dealer = North; then rotate clockwise.
2) Deal: Server deals cards; hands private to seats.
3) Bidding: One round, clockwise from left of dealer; track passes/highest bid.
4) Trump declaration: Bid winner declares trump suit.
5) Replacement phase (10‑Point only): In turn order starting with the bid winner (clockwise), each player may discard 0–6 cards and draw from stock to return to 6 cards.
6) Trick play: 6 tricks total; enforce follow‑suit; detect trick winner; next lead.
7) Scoring: Compute per variant; apply setback if bidder fails.
8) Next hand: Rotate dealer; continue until a team meets match target/win condition.
9) End of game: Apply win rules (10‑Point requires bidder to win; float at 60). Announce winner; table returns to Open or offer rematch.

### Timers and timeouts
- Per‑turn timer (default 30s). If expired:
  - During bidding: auto‑pass.
  - During trick play: auto‑play lowest legal card (server policy). Track infractions; allow vote‑kick or auto‑forfeit after repeated timeouts.

### Reconnection and resilience
- Reserve seat for disconnecting player for 2 minutes; allow reconnect.
- Opponents may claim forfeit if a seat is absent beyond threshold (default 3–5 minutes; configurable by table owner).

### Chat (minimal)
- Table chat with rate limiting; emoji reactions optional.

## Non‑functional requirements
- Fairness: Server‑authoritative shuffling, dealing, turn enforcement, trick resolution, scoring.
- Shuffling: Cryptographically strong RNG; store/seed per hand for audit.
- Access control: RLS so only a seat sees its hand; opponents cannot read others’ cards.
- Performance: Aim <200ms event propagation on good networks.
- Observability: Structured logs for hands, bids, tricks, scores, errors.
- Privacy: Minimal PII; allow display name changes.

## Data model (proposed Supabase schema)

Tables (public.):
- profiles (id uuid PK = auth.uid, username text unique, avatar text, created_at timestamptz)
- tables (id uuid PK, name text, variant text check in ('4_point','10_point'), status text check in ('open','playing','finished'), owner uuid FK->profiles, target_score int, created_at timestamptz)
- table_seats (table_id uuid FK->tables, position text check in ('N','E','S','W'), user_id uuid FK->profiles, is_ready bool, primary key (table_id, position))
- games (id uuid PK, table_id uuid FK, variant text, started_at timestamptz, ended_at timestamptz, winning_team text nullable check in ('NS','EW'))
- hands (id uuid PK, game_id uuid FK, hand_number int, dealer_pos text, bid_winner_pos text nullable, bid_value int nullable, trump_suit text nullable, started_at timestamptz, ended_at timestamptz, stock jsonb null, replacements_locked bool default false)
- bids (hand_id uuid FK, position text, value int nullable, passed bool, order_index int, primary key (hand_id, position))
- hands_private (id uuid PK, hand_id uuid FK, position text, cards jsonb) — RLS: only that position’s user can read.
- replacements (id uuid PK, hand_id uuid FK, position text, discarded jsonb, drawn jsonb, order_index int, created_at timestamptz)
- tricks (id uuid PK, hand_id uuid FK, trick_index int, leader_pos text, winning_pos text nullable, led_suit text nullable)
- trick_cards (trick_id uuid FK, position text, card_code text, play_order int, primary key (trick_id, position))
- scores (game_id uuid FK, team text check in ('NS','EW'), hand_number int, delta int, total int, primary key (game_id, team, hand_number))
- chat_messages (id uuid PK, table_id uuid FK, user_id uuid FK, body text, sent_at timestamptz)

Realtime/presence:
- Supabase Realtime channels per table: presence, seating, bidding, trick events, scoring, chat.

Auth & RLS highlights:
- profiles row owned by auth.uid().
- table_seats readable by table members; writes limited to seat owner + table owner for moderation.
- hands_private row visible only if table_seats.user_id == auth.uid() and positions match.
- Mutations via Edge Functions / SQL RPC enforce invariants (turn order, legal plays, variant rules).

## API and server logic (Edge Functions / RPC)

- create_table(variant, name?, target_score?) → table_id
- join_table(table_id, position) → success/error
- leave_table(table_id) → success/error
- set_ready(table_id, ready: bool)
- start_game(table_id) (auto when 4 seats ready)
- deal_hand(game_id) → create hands + hands_private per seat
- place_bid(hand_id, value | pass)
- declare_trump(hand_id, suit)
- request_replacements(hand_id, discarded_cards[]) → { drawn_cards[] }
- lock_replacements(hand_id) → prevents further replacements; signals trick play can begin
- play_card(trick_id, card_code)
- end_hand_score(hand_id) → calculate and persist scores
- end_game(game_id)

All endpoints validate seat ownership, turn order, card legality (follow suit), and variant rules.

## Flutter client architecture

- Provider stores:
  - AuthState (session, profile)
  - LobbyState (tables + presence)
  - TableState (seats, ready, chat)
  - GameState (hand, bids, tricks, scores, timers)
- Navigation (Web):
  - / → Splash/Auth
  - /lobby → table list + create
  - /table/:id → seating, ready, chat
  - /game/:id → bidding, play, scoreboard
- UI:
  - Card rendering via pub.dev package (e.g., playing_cards or similar).
  - Hand view shows only own cards; center area shows trick; scoreboard side panel.
  - Bidding controls (Pass, bid slider/buttons by variant); trump picker.

## Validation and scoring specifics

4‑Point:
- Game calculation values: A=4, K=3, Q=2, J=1, 10=10; others=0. Higher total gets 1 Game point; tie → no point.
- High/Low/Jack awarded only if the card was played in a trick.

10‑Point:
 - High, Low, Jack, Last Trick each worth 1 point if applicable; Five of trump worth 5 points if captured; Game worth 1 point to higher total using values Ten=10, King=3, Queen=2, Jack=1 (others 0). Items not dealt/played award 0.
 - High/Low determined among trumps actually played.
 - Bidding team setback equals bid if they fail to meet.
 - Win condition: First to 50 points, but team must be the bidder on the winning hand. Float at 60 (instant win) if bids up to 10 are allowed.

## Edge cases and clarifications
- All pass → redeal by next dealer (dealer rotates).
- Misdeal/irregularities: if incorrect hand sizes or exposed card, cancel hand and redeal (same dealer) per house rule.
- Leading trump is allowed.
- Must follow suit when able; otherwise any card.
// Jokers and Off‑Jack are not used in this 10‑Point variant.
// Replacement phase applies only to the 10‑Point variant as described.

## Security and fairness
- Server‑only shuffle and deal; client never adjudicates outcomes.
- Strict server validation for turn order and legal plays; RLS to prevent data leakage.
- Action/chat rate limiting to prevent spam.

## Testing
- Unit tests: bidding winner logic; trick resolution (follow‑suit + trump); 4‑Point Game calculation; 10‑Point scoring items; setback.
- Integration tests: simulate full hand; reconnection flow; timer expiries.

## Telemetry and admin
- Minimal metrics (hands/game, duration, disconnects). Admin tools later.

## Roadmap (post‑MVP)
- iOS/Android builds and PWA polish.
- Spectators, invites/friends, rankings/ELO, cosmetics.
- Bots, rematch, tournaments, variants toggles.

---

## Decisions confirmed

1. 4‑Point: 6‑card deal; min bid=2; target=11; Game values A=4, K=3, Q=2, J=1, 10=10; tie → no Game point.
2. 10‑Point scoring: High(1), Low(1), Jack(1), Game(1), Last Trick(1), Five of trump(5).
3. 10‑Point Game values: Ten=10, King=3, Queen=2, Jack=1; others 0.
4. 10‑Point deal and replacements: 6 cards (3‑and‑3); after bidding and trump, each player may replace up to 6 cards from stock.
5. 10‑Point bidding: Minimum bid = 3; bids up to 10 allowed.
6. 10‑Point win: First to 50; must bid to win; float at 60 if bids up to 10 are allowed.
7. Start policy: Auto‑start when 4 players join.
8. Turn timer: 30 seconds per turn.
9. Chat: Include table chat in MVP.
10. Usernames: If duplicate, append a unique 4‑digit suffix.
