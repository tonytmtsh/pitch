-- 004_seed.sql — Seed data for local development

-- Create demo users (replace these with your own auth users in Supabase)
-- Note: In Supabase, auth.users are managed by Auth. Here we just seed profiles.
insert into public.profiles(id, username, avatar)
values
  ('00000000-0000-0000-0000-000000000001','Alice#1001','🂡'),
  ('00000000-0000-0000-0000-000000000002','Bob#1002','🂮'),
  ('00000000-0000-0000-0000-000000000003','Carol#1003','🂭'),
  ('00000000-0000-0000-0000-000000000004','Dave#1004','🂫')
on conflict (id) do nothing;

-- Create a 10-point table (auto-start disabled in seed)
insert into public.tables(id, name, variant, status, owner, target_score)
values ('11111111-1111-1111-1111-111111111111','Demo 10-point','10_point','open','00000000-0000-0000-0000-000000000001',50)
on conflict (id) do nothing;

-- Seat players
insert into public.table_seats(table_id, position, user_id) values
  ('11111111-1111-1111-1111-111111111111','N','00000000-0000-0000-0000-000000000001'),
  ('11111111-1111-1111-1111-111111111111','E','00000000-0000-0000-0000-000000000002'),
  ('11111111-1111-1111-1111-111111111111','S','00000000-0000-0000-0000-000000000003'),
  ('11111111-1111-1111-1111-111111111111','W','00000000-0000-0000-0000-000000000004')
on conflict do nothing;
