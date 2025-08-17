-- 003_functions.sql — RPCs for game lifecycle
-- Note: Security definer used for invariants; restrict execution via RLS and grants.

-- Helper: get seat by user in table
create or replace function public.get_user_seat(p_table uuid, p_user uuid)
returns text language sql stable as $$
  select position from public.table_seats
  where table_id = p_table and user_id = p_user
  limit 1;
$$;

-- Create table
create or replace function public.create_table(p_name text, p_variant text, p_target int)
returns uuid language plpgsql security definer as $$
declare v_id uuid; begin
  insert into public.tables(name, variant, owner, target_score)
  values (p_name, p_variant, auth.uid(), p_target)
  returning id into v_id;
  -- initialize empty seats
  insert into public.table_seats(table_id, position) values
    (v_id,'N'),(v_id,'E'),(v_id,'S'),(v_id,'W');
  return v_id;
end; $$;

-- Join table seat
create or replace function public.join_table(p_table uuid, p_position text)
returns boolean language plpgsql security definer as $$
begin
  update public.table_seats set user_id = auth.uid()
  where table_id = p_table and position = p_position and user_id is null;
  return found;
end; $$;

-- Leave table
create or replace function public.leave_table(p_table uuid)
returns boolean language plpgsql security definer as $$
begin
  update public.table_seats set user_id = null, is_ready=false
  where table_id = p_table and user_id = auth.uid();
  return true;
end; $$;

-- Start game (auto when 4 seats filled)
create or replace function public.start_game(p_table uuid)
returns uuid language plpgsql security definer as $$
declare v_game uuid; v_variant text; begin
  select variant into v_variant from public.tables where id = p_table;
  if (select count(*) from public.table_seats where table_id = p_table and user_id is not null) <> 4 then
    raise exception 'Need 4 players';
  end if;
  insert into public.games(table_id, variant) values (p_table, v_variant) returning id into v_game;
  -- set table status
  update public.tables set status='playing' where id=p_table;
  return v_game;
end; $$;

-- Deal hand
create or replace function public.deal_hand(p_game uuid, p_hand_number int, p_dealer text)
returns uuid language plpgsql security definer as $$
declare v_hand uuid; v_variant text; v_table uuid;
        v_deck text[]; v_stock jsonb; begin
  select g.table_id, g.variant into v_table, v_variant from public.games g where g.id = p_game;
  -- build 52-card deck: ranks A,K,Q,J,10,9,8,7,6,5,4,3,2 with suits S,H,D,C
  v_deck := array[
    'AS','KS','QS','JS','10S','9S','8S','7S','6S','5S','4S','3S','2S',
    'AH','KH','QH','JH','10H','9H','8H','7H','6H','5H','4H','3H','2H',
    'AD','KD','QD','JD','10D','9D','8D','7D','6D','5D','4D','3D','2D',
    'AC','KC','QC','JC','10C','9C','8C','7C','6C','5C','4C','3C','2C'
  ];
  -- shuffle using pgcrypto gen_random_uuid ordering
  v_deck := (select array_agg(card) from (select unnest(v_deck) as card order by gen_random_uuid()) s);
  -- deal 6 cards (3 and 3) to N,E,S,W
  insert into public.hands(game_id, hand_number, dealer_pos)
  values (p_game, p_hand_number, p_dealer) returning id into v_hand;
  perform (
    with seats as (
      select position from public.table_seats where table_id=v_table order by case position when 'N' then 0 when 'E' then 1 when 'S' then 2 else 3 end
    )
    select 1
  );
  -- allocate hands
  perform public._deal_to_seats(v_hand, v_table, v_deck);
  -- set stock for 10-point (remaining cards after 24 dealt)
  update public.hands set stock = to_jsonb((select array_agg(card) from (
    select v_deck[i] as card from generate_subscripts(v_deck,1) i where i > 24
  ) t)) where id = v_hand;
  return v_hand;
end; $$;

-- Helper to split deck, fill hands_private in seat order (3 and 3)
create or replace function public._deal_to_seats(p_hand uuid, p_table uuid, p_deck text[])
returns void language plpgsql security definer as $$
declare n text; e text; s text; w text; begin
  -- first 6*4 = 24 cards dealt
  insert into public.hands_private(hand_id, position, cards) values
    (p_hand,'N', to_jsonb(array[p_deck[1],p_deck[2],p_deck[3],p_deck[13],p_deck[14],p_deck[15]])),
    (p_hand,'E', to_jsonb(array[p_deck[4],p_deck[5],p_deck[6],p_deck[16],p_deck[17],p_deck[18]])),
    (p_hand,'S', to_jsonb(array[p_deck[7],p_deck[8],p_deck[9],p_deck[19],p_deck[20],p_deck[21]])),
    (p_hand,'W', to_jsonb(array[p_deck[10],p_deck[11],p_deck[12],p_deck[22],p_deck[23],p_deck[24]]));
end; $$;

-- Place bid
create or replace function public.place_bid(p_hand uuid, p_value int, p_pass boolean)
returns boolean language plpgsql security definer as $$
begin
  insert into public.bids(hand_id, position, value, passed, order_index)
  values (p_hand, (select position from public.table_seats ts join public.games g on g.table_id=ts.table_id join public.hands h on h.game_id=g.id where h.id=p_hand and ts.user_id=auth.uid()), p_value, p_pass,
          (select coalesce(max(order_index),0)+1 from public.bids where hand_id=p_hand))
  on conflict (hand_id, position) do update set value=excluded.value, passed=excluded.passed;
  return true;
end; $$;

-- Declare trump
create or replace function public.declare_trump(p_hand uuid, p_suit text)
returns boolean language plpgsql security definer as $$
begin
  update public.hands set trump_suit = p_suit where id = p_hand;
  return true;
end; $$;

-- Request replacements (10-point)
create or replace function public.request_replacements(p_hand uuid, p_discard text[])
returns text[] language plpgsql security definer as $$
declare v_cards jsonb; v_stock jsonb; v_new_hand text[]; v_drawn text[]; v_pos text; begin
  if (select replacements_locked from public.hands where id=p_hand) then
    raise exception 'Replacements locked';
  end if;
  select position into v_pos from public.table_seats ts
    join public.games g on g.table_id=ts.table_id
    join public.hands h on h.game_id=g.id
  where h.id=p_hand and ts.user_id=auth.uid();

  select cards into v_cards from public.hands_private where hand_id=p_hand and position=v_pos;
  -- validate discards are subset of current hand
  if exists (select 1 from unnest(p_discard) d where not (d = any (select jsonb_array_elements_text(v_cards)))) then
    raise exception 'Discard contains card not in hand';
  end if;
  -- remove discards
  v_new_hand := array(select jsonb_array_elements_text(v_cards) except select unnest(p_discard));
  select stock into v_stock from public.hands where id=p_hand;
  -- draw same number from front of stock
  v_drawn := (select array_agg(elem) from (
    select jsonb_array_elements_text(v_stock) elem limit coalesce(array_length(p_discard,1),0)
  ) t);
  -- update hand and stock
  update public.hands_private set cards = to_jsonb(v_new_hand || v_drawn) where hand_id=p_hand and position=v_pos;
  update public.hands set stock = to_jsonb((select array_agg(elem) from (
    select jsonb_array_elements_text(v_stock) elem offset coalesce(array_length(p_discard,1),0)
  ) t)) where id=p_hand;
  -- log replacement
  insert into public.replacements(hand_id, position, discarded, drawn, order_index)
  values (p_hand, v_pos, to_jsonb(p_discard), to_jsonb(v_drawn), (select coalesce(max(order_index),0)+1 from public.replacements where hand_id=p_hand));
  return v_drawn;
end; $$;

-- Lock replacements (proceed to tricks)
create or replace function public.lock_replacements(p_hand uuid)
returns boolean language plpgsql security definer as $$
begin
  update public.hands set replacements_locked=true where id=p_hand;
  return true;
end; $$;

-- Play card (skeleton, legality checks to be expanded server-side)
create or replace function public.play_card(p_trick uuid, p_card text)
returns boolean language plpgsql security definer as $$
declare v_hand uuid; v_pos text; v_cards jsonb; begin
  select hand_id into v_hand from public.tricks where id=p_trick;
  select position into v_pos from public.table_seats ts
    join public.games g on g.table_id=ts.table_id
    join public.hands h on h.game_id=g.id
  where h.id=v_hand and ts.user_id=auth.uid();
  select cards into v_cards from public.hands_private where hand_id=v_hand and position=v_pos;
  if not (p_card = any (select jsonb_array_elements_text(v_cards))) then
    raise exception 'Card not in hand';
  end if;
  -- TODO: enforce follow suit and turn order
  insert into public.trick_cards(trick_id, position, card_code, play_order)
  values (p_trick, v_pos, p_card, (select coalesce(max(play_order),0)+1 from public.trick_cards where trick_id=p_trick))
  on conflict (trick_id, position) do update set card_code=excluded.card_code;
  update public.hands_private set cards = to_jsonb(array(
    select jsonb_array_elements_text(v_cards) except select p_card
  )) where hand_id=v_hand and position=v_pos;
  return true;
end; $$;
