-- 007_views.sql — convenience views

-- View to expose trick_cards with hand_id for filtering
create or replace view public.trick_cards_by_hand as
select
  tc.trick_id,
  tc.position,
  tc.card_code,
  tc.play_order,
  t.hand_id
from public.trick_cards tc
join public.tricks t on t.id = tc.trick_id;
