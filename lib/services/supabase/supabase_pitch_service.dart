import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../pitch_service.dart';

/// Supabase-backed implementation of PitchService.
class SupabasePitchService implements PitchService {
  SupabasePitchService({required String url, required String anonKey})
      : _client = Supabase.instance.client;

  final SupabaseClient _client;

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
    .select('id,name,variant,status,table_seats(position,user_id,profiles!inner(username))')
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
      return Seat(
        position: _posToIndex(s['position'] as String?),
    player: username,
      );
    }).toList();

    return TableDetails(
      id: row['id'] as String,
      name: row['name'] as String,
      seats: seats,
      inProgress: (row['status'] as String) == 'playing',
  variant: row['variant'] as String?,
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
    // Not wired yet on server; return empty snapshot.
    return BiddingProgress(const [], const [], 'N', 0);
  }

  @override
  Future<List<ReplacementEvent>> fetchReplacements(String handId) async {
    return const [];
  }

  @override
  Future<List<TrickSnapshot>> fetchTricks(String handId) async {
    return const [];
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
}
