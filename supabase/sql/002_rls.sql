-- 002_rls.sql — Row Level Security policies

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.tables enable row level security;
alter table public.table_seats enable row level security;
alter table public.games enable row level security;
alter table public.hands enable row level security;
alter table public.bids enable row level security;
alter table public.hands_private enable row level security;
alter table public.replacements enable row level security;
alter table public.tricks enable row level security;
alter table public.trick_cards enable row level security;
alter table public.scores enable row level security;
alter table public.chat_messages enable row level security;

-- Profiles: owner can read/update self; all can read minimal for display
create policy profiles_select on public.profiles for select using (true);
create policy profiles_update on public.profiles for update using (auth.uid() = id);
create policy profiles_insert on public.profiles for insert with check (auth.uid() = id);

-- Tables: readable by all for lobby; insert by authenticated; update owner
create policy tables_select on public.tables for select using (true);
create policy tables_insert on public.tables for insert with check (auth.uid() is not null);
create policy tables_update on public.tables for update using (exists (
  select 1 from public.tables t where t.id = id and t.owner = auth.uid()
));

-- Seats: visible for table; write by seat owner or table owner
create policy seats_select on public.table_seats for select using (true);
create policy seats_upsert on public.table_seats for insert with check (auth.uid() is not null);
create policy seats_update on public.table_seats for update using (
  user_id = auth.uid() or exists (select 1 from public.tables t where t.id = table_id and t.owner = auth.uid())
);

-- Games: readable; insert restricted to server function role (assume using rpc guarded by security definer)
create policy games_select on public.games for select using (true);

-- Hands: readable for members of the table; insert/update via server function
create policy hands_select on public.hands for select using (
  exists (
    select 1 from public.games g join public.tables tb on tb.id = g.table_id
    join public.table_seats s on s.table_id = tb.id
    where g.id = game_id and s.user_id = auth.uid()
  )
);

-- Bids: readable for table members
create policy bids_select on public.bids for select using (
  exists (
    select 1 from public.hands h join public.games g on g.id = h.game_id
    join public.table_seats s on s.table_id = g.table_id
    where h.id = hand_id and s.user_id = auth.uid()
  )
);

-- Hands private: only the seat owner can read
create policy hands_private_select on public.hands_private for select using (
  exists (
    select 1 from public.hands h join public.games g on g.id = h.game_id
    join public.table_seats s on s.table_id = g.table_id
    where h.id = hand_id and s.position = hands_private.position and s.user_id = auth.uid()
  )
);

-- Replacements, Tricks, Trick Cards, Scores, Chat: readable for table members
create policy replacements_select on public.replacements for select using (
  exists (
    select 1 from public.hands h join public.games g on g.id = h.game_id
    join public.table_seats s on s.table_id = g.table_id
    where h.id = hand_id and s.user_id = auth.uid()
  )
);

create policy tricks_select on public.tricks for select using (
  exists (
    select 1 from public.hands h join public.games g on g.id = h.game_id
    join public.table_seats s on s.table_id = g.table_id
    where h.id = hand_id and s.user_id = auth.uid()
  )
);

create policy trick_cards_select on public.trick_cards for select using (
  exists (
    select 1 from public.tricks t join public.hands h on h.id = t.hand_id
    join public.games g on g.id = h.game_id
    join public.table_seats s on s.table_id = g.table_id
    where t.id = trick_id and s.user_id = auth.uid()
  )
);

create policy scores_select on public.scores for select using (
  exists (
    select 1 from public.games g join public.table_seats s on s.table_id = g.table_id
    where g.id = scores.game_id and s.user_id = auth.uid()
  )
);

create policy chat_select on public.chat_messages for select using (
  exists (
    select 1 from public.tables tb join public.chat_messages cm on cm.table_id = tb.id
    join public.table_seats s on s.table_id = tb.id
    where cm.id = chat_messages.id and s.user_id = auth.uid()
  )
);

-- Inserts/updates for these tables should be driven via RPCs with security definer to maintain invariants.
