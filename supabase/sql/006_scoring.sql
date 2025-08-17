-- 006_scoring.sql — Scoring functions for 4-Point and 10-Point variants

-- Game card value for 4-Point (A=4,K=3,Q=2,J=1,10=10; others 0)
create or replace function public.game_value_4pt(card_code text)
returns int language sql immutable as $$
  select case public.rank_of(card_code)
    when 'A' then 4 when 'K' then 3 when 'Q' then 2 when 'J' then 1 when '10' then 10 else 0 end;
$$;

-- Game card value for 10-Point (10=10, K=3, Q=2, J=1; others 0)
create or replace function public.game_value_10pt(card_code text)
returns int language sql immutable as $$
  select case public.rank_of(card_code)
    when '10' then 10 when 'K' then 3 when 'Q' then 2 when 'J' then 1 else 0 end;
$$;

-- Compute scoring for a hand; returns team deltas and writes to scores table
-- p_variant: '4_point' or '10_point'
create or replace function public.end_hand_score(p_hand uuid)
returns table(team text, delta int) language plpgsql security definer as $$
declare v_variant text; v_game uuid; v_table uuid; v_trump text; v_hand_no int;
        v_last_trick_winner text; v_bidder text; v_bid int; v_target int;
        ns_delta int := 0; ew_delta int := 0; begin
  select g.variant, g.id, g.table_id, h.trump_suit, h.hand_number, h.bid_winner_pos, h.bid_value into v_variant, v_game, v_table, v_trump, v_hand_no, v_bidder, v_bid
  from public.hands h join public.games g on g.id = h.game_id where h.id = p_hand;

  -- Determine last trick winner
  select winning_pos into v_last_trick_winner from public.tricks where hand_id = p_hand and trick_index = 6;

  -- Gather captured cards per team
  with plays as (
    select t.trick_index, tc.position, tc.card_code from public.tricks t join public.trick_cards tc on tc.trick_id = t.id
    where t.hand_id = p_hand
  ), team_map as (
    select 'NS' as team, 'N' as pos union all select 'NS','S' union all select 'EW','E' union all select 'EW','W'
  ), trick_winners as (
    select t.trick_index, t.winning_pos from public.tricks t where t.hand_id = p_hand
  ), captured as (
    select tm.team, p.card_code
    from plays p join trick_winners w on w.trick_index = p.trick_index
    join team_map tm on tm.pos = w.winning_pos
  )
  select coalesce(sum(case when public.suit_of(card_code) = v_trump then 1 else 0 end),0) into strict ns_delta from captured where team='NS' and false;
  -- ns_delta/ew_delta will be computed below per variant

  if v_variant = '4_point' then
    -- High/Low/Jack
    with trumps as (
      select card_code from (
        select unnest(array(select c.card_code from captured c)) as card_code
      ) t where public.suit_of(card_code) = v_trump
    ), tvals as (
      select card_code, public.rank_value(card_code) rv from trumps
    )
    select 1 into ns_delta; -- dummy to ensure block; we compute explicitly next

    -- High (highest trump captured)
    with all_trumps as (
      select tm.team, c.card_code, public.rank_value(c.card_code) rv
      from captured c join (
        select 'NS' as team union all select 'EW'
      ) tm on true
      where public.suit_of(c.card_code) = v_trump
    ), max_trump as (
      select team, rv, card_code from (
        select team, rv, card_code, rank() over (order by rv desc, team) rnk from (
          select team, rv, card_code from all_trumps
        ) x
      ) y where rnk = 1
    )
    select case when exists(select 1 from max_trump where team='NS') then 1 else 0 end into ns_delta;
    select case when exists(select 1 from max_trump where team='EW') then 1 else 0 end into ew_delta;
    -- Since exactly one team can have High, adjust
    if ns_delta = 1 then ew_delta := ew_delta; else ew_delta := 1; end if; ns_delta := 1 - ew_delta;

    -- Low (lowest trump captured)
    if exists (select 1 from captured where public.suit_of(card_code) = v_trump) then
      if (select min(public.rank_value(card_code)) from captured where public.suit_of(card_code)=v_trump and team='NS') <
         (select min(public.rank_value(card_code)) from captured where public.suit_of(card_code)=v_trump and team='EW') then
        ns_delta := ns_delta + 1; else ew_delta := ew_delta + 1; end if;
    end if;

    -- Jack of trump
    if exists (select 1 from captured where card_code = ('J' || v_trump)) then
      if exists (select 1 from captured where team='NS' and card_code=('J' || v_trump)) then ns_delta := ns_delta + 1; else ew_delta := ew_delta + 1; end if;
    end if;

    -- Game point
    declare ns_game int; ew_game int; begin
      select coalesce(sum(public.game_value_4pt(card_code)),0) into ns_game from captured where team='NS';
      select coalesce(sum(public.game_value_4pt(card_code)),0) into ew_game from captured where team='EW';
      if ns_game > ew_game then ns_delta := ns_delta + 1; elsif ew_game > ns_game then ew_delta := ew_delta + 1; end if;
    end;

  elsif v_variant = '10_point' then
    -- High/Low/Jack/Game/LastTrick/Five(5)
    -- High
    if exists (select 1 from public.trick_cards tc join public.tricks t on t.id=tc.trick_id where t.hand_id=p_hand and public.suit_of(tc.card_code)=v_trump) then
      with tr as (
        select tm.team, tc.card_code, public.rank_value(tc.card_code) rv
        from public.tricks t join public.trick_cards tc on tc.trick_id=t.id
        join (values ('NS','N'),('NS','S'),('EW','E'),('EW','W')) tm(team,pos) on tm.pos = t.winning_pos
        where t.hand_id=p_hand and public.suit_of(tc.card_code)=v_trump
      )
      select case when (select team from tr order by rv desc limit 1)='NS' then 1 else 0 end into ns_delta;
      ew_delta := 1 - ns_delta;
    end if;

    -- Low
    if exists (select 1 from public.trick_cards tc join public.tricks t on t.id=tc.trick_id where t.hand_id=p_hand and public.suit_of(tc.card_code)=v_trump) then
      with tr as (
        select tm.team, tc.card_code, public.rank_value(tc.card_code) rv
        from public.tricks t join public.trick_cards tc on tc.trick_id=t.id
        join (values ('NS','N'),('NS','S'),('EW','E'),('EW','W')) tm(team,pos) on tm.pos = t.winning_pos
        where t.hand_id=p_hand and public.suit_of(tc.card_code)=v_trump
      )
      if (select team from tr order by rv asc limit 1)='NS' then ns_delta := ns_delta + 1; else ew_delta := ew_delta + 1; end if;
    end if;

    -- Jack of trump
    if exists (select 1 from public.trick_cards tc join public.tricks t on t.id=tc.trick_id where t.hand_id=p_hand and tc.card_code=('J' || v_trump)) then
      if exists (select 1 from public.tricks t join public.trick_cards tc on tc.trick_id=t.id where t.hand_id=p_hand and t.winning_pos in ('N','S') and tc.card_code=('J' || v_trump)) then
        ns_delta := ns_delta + 1; else ew_delta := ew_delta + 1; end if;
    end if;

    -- Game point (10=10,K=3,Q=2,J=1)
    declare ns_game int; ew_game int; begin
      select coalesce(sum(public.game_value_10pt(tc.card_code)),0) into ns_game
      from public.tricks t join public.trick_cards tc on tc.trick_id=t.id where t.hand_id=p_hand and t.winning_pos in ('N','S');
      select coalesce(sum(public.game_value_10pt(tc.card_code)),0) into ew_game
      from public.tricks t join public.trick_cards tc on tc.trick_id=t.id where t.hand_id=p_hand and t.winning_pos in ('E','W');
      if ns_game > ew_game then ns_delta := ns_delta + 1; elsif ew_game > ns_game then ew_delta := ew_delta + 1; end if;
    end;

    -- Last trick
    if v_last_trick_winner in ('N','S') then ns_delta := ns_delta + 1; else ew_delta := ew_delta + 1; end if;

    -- Five of trump (worth 5)
    if exists (select 1 from public.trick_cards tc join public.tricks t on t.id=tc.trick_id where t.hand_id=p_hand and tc.card_code=('5' || v_trump)) then
      if exists (select 1 from public.tricks t join public.trick_cards tc on tc.trick_id=t.id where t.hand_id=p_hand and t.winning_pos in ('N','S') and tc.card_code=('5' || v_trump)) then
        ns_delta := ns_delta + 5; else ew_delta := ew_delta + 5; end if;
    end if;
  end if;

  -- Apply setback if bidder failed
  if v_bid is not null then
    if (v_bidder in ('N','S') and ns_delta < v_bid) then ns_delta := ns_delta - v_bid; end if;
    if (v_bidder in ('E','W') and ew_delta < v_bid) then ew_delta := ew_delta - v_bid; end if;
  end if;

  -- Persist running totals
  insert into public.scores(game_id, team, hand_number, delta, total)
  values
    (v_game,'NS',v_hand_no,ns_delta, coalesce((select total from public.scores where game_id=v_game and team='NS' order by hand_number desc limit 1),0) + ns_delta),
    (v_game,'EW',v_hand_no,ew_delta, coalesce((select total from public.scores where game_id=v_game and team='EW' order by hand_number desc limit 1),0) + ew_delta);

  return query select 'NS'::text, ns_delta union all select 'EW'::text, ew_delta;
end; $$;
