-- 001_schema.sql — Core schema for Pitch Online (MVP)
-- Note: Uses public schema; enable RLS where indicated. Run in Supabase SQL Editor or CLI.

-- Profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  avatar text,
  created_at timestamptz not null default now()
);

-- Tables (lobbies)
create table if not exists public.tables (
  id uuid primary key default gen_random_uuid(),
  name text,
  variant text not null check (variant in ('4_point','10_point')),
  status text not null default 'open' check (status in ('open','playing','finished')),
  owner uuid not null references public.profiles(id) on delete cascade,
  target_score int not null,
  created_at timestamptz not null default now()
);

-- Seats
create table if not exists public.table_seats (
  table_id uuid not null references public.tables(id) on delete cascade,
  position text not null check (position in ('N','E','S','W')),
  user_id uuid references public.profiles(id) on delete set null,
  is_ready boolean not null default false,
  primary key (table_id, position)
);

-- Games
create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  table_id uuid not null references public.tables(id) on delete cascade,
  variant text not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  winning_team text check (winning_team in ('NS','EW'))
);

-- Hands (includes 10-point replacement support)
create table if not exists public.hands (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  hand_number int not null,
  dealer_pos text not null check (dealer_pos in ('N','E','S','W')),
  bid_winner_pos text check (bid_winner_pos in ('N','E','S','W')),
  bid_value int,
  trump_suit text check (trump_suit in ('S','H','D','C')),
  stock jsonb,
  replacements_locked boolean not null default false,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

-- Bids
create table if not exists public.bids (
  hand_id uuid not null references public.hands(id) on delete cascade,
  position text not null check (position in ('N','E','S','W')),
  value int,
  passed boolean not null default false,
  order_index int not null,
  primary key (hand_id, position)
);

-- Private hands per seat
create table if not exists public.hands_private (
  id uuid primary key default gen_random_uuid(),
  hand_id uuid not null references public.hands(id) on delete cascade,
  position text not null check (position in ('N','E','S','W')),
  cards jsonb not null -- array of card codes
);

-- Replacements audit (10-point)
create table if not exists public.replacements (
  id uuid primary key default gen_random_uuid(),
  hand_id uuid not null references public.hands(id) on delete cascade,
  position text not null check (position in ('N','E','S','W')),
  discarded jsonb not null,
  drawn jsonb not null,
  order_index int not null,
  created_at timestamptz not null default now()
);

-- Tricks and plays
create table if not exists public.tricks (
  id uuid primary key default gen_random_uuid(),
  hand_id uuid not null references public.hands(id) on delete cascade,
  trick_index int not null,
  leader_pos text not null check (leader_pos in ('N','E','S','W')),
  winning_pos text check (winning_pos in ('N','E','S','W')),
  led_suit text check (led_suit in ('S','H','D','C'))
);

create table if not exists public.trick_cards (
  trick_id uuid not null references public.tricks(id) on delete cascade,
  position text not null check (position in ('N','E','S','W')),
  card_code text not null,
  play_order int not null,
  primary key (trick_id, position)
);

-- Scores per hand
create table if not exists public.scores (
  game_id uuid not null references public.games(id) on delete cascade,
  team text not null check (team in ('NS','EW')),
  hand_number int not null,
  delta int not null,
  total int not null,
  primary key (game_id, team, hand_number)
);

-- Chat
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  table_id uuid not null references public.tables(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  sent_at timestamptz not null default now()
);

-- Helpful indexes
create index if not exists idx_tables_status on public.tables(status);
create index if not exists idx_table_seats_user on public.table_seats(user_id);
create index if not exists idx_games_table on public.games(table_id);
create index if not exists idx_hands_game on public.hands(game_id);
create index if not exists idx_tricks_hand on public.tricks(hand_id);
create index if not exists idx_bids_hand on public.bids(hand_id);
create index if not exists idx_scores_game on public.scores(game_id);
create index if not exists idx_chat_table on public.chat_messages(table_id);
