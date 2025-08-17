-- 005_rules.sql — Helpers, trick flow, and legality checks

-- Next seat clockwise
create or replace function public.next_pos(p text)
returns text language sql immutable as $$
  select case p when 'N' then 'E' when 'E' then 'S' when 'S' then 'W' else 'N' end;
$$;

-- Extract suit from a card code like '10S' or 'QD'
create or replace function public.suit_of(card_code text)
returns text language sql immutable as $$
  select right(card_code, 1);
$$;

-- Extract rank from card code ('A','K','Q','J','10','9'...'2')
create or replace function public.rank_of(card_code text)
returns text language sql immutable as $$
  select case
    when card_code like '10%' then '10'
    else left(card_code, 1)
  end;
$$;

-- Rank value for comparison (higher is stronger)
create or replace function public.rank_value(card_code text)
returns int language sql immutable as $$
  select case rank_of(card_code)
    when 'A' then 13
    when 'K' then 12
    when 'Q' then 11
    when 'J' then 10
    when '10' then 9
    when '9' then 8
    when '8' then 7
    when '7' then 6
    when '6' then 5
    when '5' then 4
    when '4' then 3
    when '3' then 2
    when '2' then 1
    else 0 end;
$$;

-- Begin tricks for a hand: create first trick led by bid winner
create or replace function public.begin_tricks(p_hand uuid)
returns uuid language plpgsql security definer as $$
declare v_leader text; v_id uuid; begin
  select bid_winner_pos into v_leader from public.hands where id=p_hand;
  if v_leader is null then raise exception 'Bid winner not set'; end if;
  insert into public.tricks(hand_id, trick_index, leader_pos) values (p_hand, 1, v_leader) returning id into v_id;
  return v_id;
end; $$;

-- Determine trick winner
create or replace function public.determine_trick_winner(p_trick uuid)
returns text language plpgsql security definer as $$
declare v_hand uuid; v_trump text; v_led text; v_winner text; begin
  select t.hand_id, h.trump_suit, t.led_suit into v_hand, v_trump, v_led
  from public.tricks t join public.hands h on h.id = t.hand_id where t.id = p_trick;
  if v_led is null then raise exception 'Led suit not set'; end if;
  -- Prefer highest trump if any trumps were played
  with plays as (
    select tc.position, tc.card_code, public.suit_of(tc.card_code) as s, public.rank_value(tc.card_code) as r
    from public.trick_cards tc where tc.trick_id = p_trick
  )
  select position into v_winner from (
    select position, r,
           row_number() over (order by r desc) as rn
    from plays where s = v_trump
    order by r desc
  ) t where t.rn = 1;
  if v_winner is not null then return v_winner; end if;
  -- Otherwise highest card of led suit
  with plays as (
    select tc.position, tc.card_code, public.suit_of(tc.card_code) as s, public.rank_value(tc.card_code) as r
    from public.trick_cards tc where tc.trick_id = p_trick
  )
  select position into v_winner from (
    select position, r, row_number() over (order by r desc) as rn
    from plays where s = v_led
    order by r desc
  ) t where t.rn = 1;
  return v_winner;
end; $$;

-- Play card with legality checks; sets led suit, enforces turn order, follow-suit, and advances trick
create or replace function public.play_card(p_trick uuid, p_card text)
returns boolean language plpgsql security definer as $$
declare v_hand uuid; v_pos text; v_expected text; v_led text; v_turn int; v_cards jsonb; v_trump text;
        v_count int; v_winner text; v_trick_idx int; begin
  select t.hand_id, t.leader_pos, t.led_suit, h.trump_suit into v_hand, v_expected, v_led, v_trump
  from public.tricks t join public.hands h on h.id = t.hand_id where t.id = p_trick;

  -- Determine whose turn based on number of cards already played in this trick
  select count(*) into v_turn from public.trick_cards where trick_id = p_trick;
  if v_turn = 0 then v_expected := v_expected;
  elsif v_turn = 1 then v_expected := public.next_pos(v_expected);
  elsif v_turn = 2 then v_expected := public.next_pos(public.next_pos(v_expected));
  elsif v_turn = 3 then v_expected := public.next_pos(public.next_pos(public.next_pos(v_expected)));
  else raise exception 'Trick already complete';
  end if;

  -- Confirm caller seat matches expected
  select position into v_pos from public.table_seats ts
    join public.games g on g.table_id = ts.table_id
    join public.hands h on h.game_id = g.id
  where h.id = v_hand and ts.user_id = auth.uid();
  if v_pos is null or v_pos <> v_expected then raise exception 'Not your turn'; end if;

  -- Confirm card in hand
  select cards into v_cards from public.hands_private where hand_id = v_hand and position = v_pos;
  if not (p_card = any (select jsonb_array_elements_text(v_cards))) then
    raise exception 'Card not in hand';
  end if;

  -- Follow suit check (if not leading)
  if v_led is not null then
    -- If player holds any of led suit, they must play it
    if exists (
      select 1 from (
        select jsonb_array_elements_text(v_cards) c
      ) c where public.suit_of(c.c) = v_led
    ) and public.suit_of(p_card) <> v_led then
      raise exception 'Must follow suit';
    end if;
  end if;

  -- Set led suit if first play
  if v_led is null then
    update public.tricks set led_suit = public.suit_of(p_card) where id = p_trick;
  end if;

  -- Record play and remove from hand
  insert into public.trick_cards(trick_id, position, card_code, play_order)
  values (p_trick, v_pos, p_card, v_turn + 1)
  on conflict (trick_id, position) do update set card_code=excluded.card_code, play_order=excluded.play_order;

  update public.hands_private set cards = to_jsonb(array(
    select jsonb_array_elements_text(v_cards) except select p_card
  )) where hand_id = v_hand and position = v_pos;

  -- If trick complete, determine winner and create next trick or finish hand
  select count(*) into v_count from public.trick_cards where trick_id = p_trick;
  if v_count = 4 then
    v_winner := public.determine_trick_winner(p_trick);
    update public.tricks set winning_pos = v_winner where id = p_trick;
    select trick_index into v_trick_idx from public.tricks where id = p_trick;
    if v_trick_idx < 6 then
      insert into public.tricks(hand_id, trick_index, leader_pos) values (v_hand, v_trick_idx + 1, v_winner);
    end if;
  end if;

  return true;
end; $$;
