import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../pitch_service.dart';

/// Supabase-backed implementation of PitchService.
class SupabasePitchService implements PitchService {
  SupabasePitchService({required String url, required String anonKey})
      : _client = Supabase.instance.client;

  final SupabaseClient _client;
  @override
  String? currentUserId() => _client.auth.currentUser?.id;
  @override
  bool supportsIdentity() => true;

  @override
  Future<List<LobbyTable>> fetchLobby() async {
    // Select tables and compute occupancy via a lateral count.
    final res = await _client
        .from('tables')
        .select('id,name,variant,status,target_score,table_seats!inner(user_id)')
        .order('created_at', ascending: false);

    // Supabase returns a List<dynamic> of maps; transform to LobbyTable.
    final List data = res as List;
    return data.map((row) {
      final seats = (row['table_seats'] as List?) ?? const [];
      final occupancy = seats.where((s) => s['user_id'] != null).length;
      return LobbyTable(
        id: row['id'] as String,
        name: row['name'] as String,
        variant: row['variant'] as String,
        status: row['status'] as String,
        occupancy: occupancy,
      );
    }).toList();
  }

  @override
  Future<TableDetails> fetchTable(String tableId) async {
    // Fetch table record
  final rows = await _client
        .from('tables')
  .select('id,name,variant,status,table_seats(position,user_id,profiles!inner(username)),hands!left(id,hand_number,status)')
        .eq('id', tableId)
        .limit(1);

  if (rows.isEmpty) {
      throw StateError('Table not found');
    }
  final row = rows.first;
  final seatsRaw = (row['table_seats'] as List?) ?? const [];
  final seats = seatsRaw.map((s) {
      final prof = s['profiles'] as Map<String, dynamic>?;
      final username = prof != null ? prof['username'] as String? : null;
      final uid = s['user_id'] as String?;
      return Seat(
        position: _posToIndex(s['position'] as String?),
    player: username,
    userId: uid,
      );
    }).toList();

    // Determine current hand: pick the highest hand_number with status in ('dealt','bidding','in_play') else latest id
    String? handId;
    final hands = (row['hands'] as List?) ?? const [];
    if (hands.isNotEmpty) {
      hands.sort((a, b) {
        final an = (a['hand_number'] as num?)?.toInt() ?? 0;
        final bn = (b['hand_number'] as num?)?.toInt() ?? 0;
        return bn.compareTo(an);
      });
      for (final h in hands) {
        final st = h['status'] as String?;
        if (st == 'dealt' || st == 'bidding' || st == 'in_play') {
          handId = h['id'] as String?;
          break;
        }
      }
      handId ??= (hands.first)['id'] as String?;
    }

    return TableDetails(
      id: row['id'] as String,
      name: row['name'] as String,
      seats: seats,
      inProgress: (row['status'] as String) == 'playing',
  variant: row['variant'] as String?,
  handId: handId,
    );
  }

  int _posToIndex(String? pos) {
    switch (pos) {
      case 'N':
        return 0;
      case 'E':
        return 1;
      case 'S':
        return 2;
      case 'W':
        return 3;
      default:
        return 0;
    }
  }

  // --- Hand flow stubs (server wiring later) ---
  @override
  Future<BiddingProgress> fetchBidding(String handId) async {
    final biddingRows = await _client
        .from('bids')
        .select('position,value,pass')
        .eq('hand_id', handId)
        .order('created_at');
    final actions = <Map<String, dynamic>>[];
    for (final r in (biddingRows as List? ?? const [])) {
      final pos = r['position'] as String? ?? '?';
      final pass = (r['pass'] as bool?) ?? false;
      final bid = (r['value'] as num?)?.toInt();
      actions.add({'pos': pos, if (bid != null) 'bid': bid, if (pass) 'pass': true});
    }
    // Winner: max value among non-pass
    String winnerPos = 'N';
    int winnerBid = 0;
    for (final a in actions) {
      final b = a['bid'];
      if (b is int && b > winnerBid) {
        winnerBid = b;
        winnerPos = a['pos'] as String? ?? winnerPos;
      }
    }
    final order = const ['N', 'E', 'S', 'W'];
    return BiddingProgress(order, actions, winnerPos, winnerBid);
  }

  @override
  Future<List<ReplacementEvent>> fetchReplacements(String handId) async {
    final rows = await _client
        .from('replacements')
        .select('position,discarded,drawn')
        .eq('hand_id', handId)
        .order('created_at');
    final out = <ReplacementEvent>[];
    for (final r in (rows as List? ?? const [])) {
      out.add(ReplacementEvent(
        (r['position'] as String?) ?? '?',
        ((r['discarded'] as List?) ?? const []).cast<String>(),
        ((r['drawn'] as List?) ?? const []).cast<String>(),
      ));
    }
    return out;
  }

  @override
  Future<List<TrickSnapshot>> fetchTricks(String handId) async {
  final trickRows = await _client
    .from('tricks')
    .select('id,index,leader,winner,last_trick,trick_cards(position,card)')
        .eq('hand_id', handId)
        .order('index');
    final out = <TrickSnapshot>[];
    for (final t in (trickRows as List? ?? const [])) {
      final plays = ((t['trick_cards'] as List?) ?? const [])
          .map((p) => {'pos': p['position'] as String, 'card': p['card'] as String})
          .toList();
      out.add(TrickSnapshot(
        (t['index'] as num?)?.toInt() ?? 0,
        t['leader'] as String? ?? 'N',
        plays,
        t['winner'] as String? ?? 'N',
        (t['last_trick'] as bool?) ?? false,
        id: t['id'] as String?,
      ));
    }
    return out;
  }

  @override
  Future<ScoringBreakdown> fetchScoring(String handId,
      {String variant = '10_point'}) async {
    try {
      final res = await _client.rpc('hand_scoring', params: {
        'hand_id': handId,
      });
      // RPC may return a map or list; normalize to a map
      final Map<String, dynamic> row;
      if (res is List && res.isNotEmpty) {
        row = (res.first as Map).cast<String, dynamic>();
      } else if (res is Map) {
        row = (res).cast<String, dynamic>();
      } else {
        return ScoringBreakdown(
          trumps: '-',
          capturedBy: const {},
          gameValues: const {},
          awards: const {},
          delta: const {},
        );
      }

      String trumps = (row['trumps'] as String?) ?? '-';
      final capturedRaw = (row['captured_by'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final captured = capturedRaw.map((k, v) => MapEntry(k, (v as List).cast<String>()));
      final awardsRaw = (row['awards'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final awards = awardsRaw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      final deltaRaw = (row['delta'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final delta = deltaRaw.map((k, v) => MapEntry(k, (v as num).toInt()));
      // Support either game_values or game_totals
      final gameField = row.containsKey('game_values') ? 'game_values' : 'game_totals';
      final gameRaw = (row[gameField] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final gameValues = gameRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

      return ScoringBreakdown(
        trumps: trumps,
        capturedBy: captured,
        gameValues: gameValues,
        awards: awards,
        delta: delta,
      );
    } catch (_) {
      return ScoringBreakdown(
        trumps: '-',
        capturedBy: const {},
        gameValues: const {},
        awards: const {},
        delta: const {},
      );
    }
  }

  @override
  Future<HandState> fetchHandState(String handId) async {
    final rows = await _client
        .from('hands')
        .select('replacements_locked,trump_suit')
        .eq('id', handId)
        .limit(1);
    if (rows.isEmpty) return const HandState(replacementsLocked: false);
    final r = (rows.first as Map).cast<String, dynamic>();
    return HandState(
      replacementsLocked: (r['replacements_locked'] as bool?) ?? false,
      trumpSuit: r['trump_suit'] as String?,
    );
  }

  @override
  Future<List<String>> fetchPrivateHand(String handId, String pos) async {
    final rows = await _client
        .from('hands_private')
        .select('cards')
        .eq('hand_id', handId)
        .eq('position', pos)
        .limit(1);
    if (rows.isEmpty) return const [];
    final r = (rows.first as Map).cast<String, dynamic>();
    final list = (r['cards'] as List?)?.cast<String>() ?? const <String>[];
    return list;
  }

  @override
  Future<bool> placeBid(String handId, {int? value, bool pass = false}) async {
    final res = await _client.rpc('place_bid', params: {
      'hand': handId,
      'value': value,
      'pass': pass,
    });
    return (res is bool) ? res : true;
  }

  @override
  Future<List<String>> requestReplacements(String handId, List<String> discarded) async {
    final res = await _client.rpc('request_replacements', params: {
      'hand': handId,
      'discard': discarded,
    });
    if (res is List) return res.cast<String>();
    return const [];
  }

  @override
  Future<bool> lockReplacements(String handId) async {
    final res = await _client.rpc('lock_replacements', params: {
      'hand': handId,
    });
    return (res is bool) ? res : true;
  }

  @override
  Future<bool> declareTrump(String handId, String suit) async {
    final res = await _client.rpc('declare_trump', params: {
      'hand': handId,
      'suit': suit,
    });
    return (res is bool) ? res : true;
  }

  @override
  Future<bool> playCard(String trickId, String card) async {
    final res = await _client.rpc('play_card', params: {
      'trick': trickId,
      'card': card,
    });
    return (res is bool) ? res : true;
  }

  @override
  Stream<void> handEvents(String handId) {
  final bids$ = _client
    .from('bids')
    .stream(primaryKey: ['id'])
    .eq('hand_id', handId);
  final reps$ = _client
    .from('replacements')
    .stream(primaryKey: ['id'])
    .eq('hand_id', handId);
  final tricks$ = _client
    .from('tricks')
    .stream(primaryKey: ['id'])
    .eq('hand_id', handId);
  // Use a view that adds hand_id to trick_cards so we can filter by hand
  final trickCards$ = _client
    .from('trick_cards_by_hand')
    .stream(primaryKey: ['trick_id', 'position'])
    .eq('hand_id', handId);

    // Merge streams manually into a broadcast controller that emits void
    final controller = StreamController<void>.broadcast();
    void onData(_) {
      // emit a unit event
      controller.add(null);
    }
    final subs = <StreamSubscription>[];
    subs.add(bids$.listen(onData));
    subs.add(reps$.listen(onData));
    subs.add(tricks$.listen(onData));
    subs.add(trickCards$.listen(onData));
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return controller.stream;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
