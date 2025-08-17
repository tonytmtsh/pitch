import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'pitch_service.dart';
import 'dtos.dart';

class MockPitchService implements PitchService {
  @override
  Future<List<LobbyTable>> fetchLobby() async {
    final raw = await rootBundle.loadString('mock/lobby.json');
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final tables = (jsonMap['tables'] as List)
        .cast<Map<String, dynamic>>()
        .map((e) => LobbyTable.fromJson(e))
        .toList();
    return tables;
  }

  @override
  Future<TableDetails> fetchTable(String tableId) async {
    // For simplicity, a single representative table snapshot.
    final raw = await rootBundle.loadString('mock/table_10pt_full.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final tbl = map['table'] as Map<String, dynamic>;

    final seatsMap = (tbl['seats'] as Map<String, dynamic>);
    final order = ['N', 'E', 'S', 'W'];
    final seats = <Seat>[];
    for (var i = 0; i < order.length; i++) {
      final key = order[i];
      final entry = seatsMap[key] as Map<String, dynamic>?
          ?? const <String, dynamic>{};
      seats.add(Seat(position: i, player: entry['user'] as String?));
    }

    return TableDetails(
      id: tbl['id'] as String,
      name: tbl['name'] as String,
      seats: seats,
      inProgress: (tbl['status'] as String) == 'playing',
  variant: tbl['variant'] as String?,
    );
  }

  @override
  Future<BiddingProgress> fetchBidding(String handId) async {
    final raw = await rootBundle.loadString('mock/bidding_progress.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final dto = BiddingProgressDto.fromJson(map);
    final actions = dto.actions
        .map((a) => {
              'pos': a.pos,
              if (a.bid != null) 'bid': a.bid,
              if (a.pass) 'pass': true,
            })
        .toList();
    return BiddingProgress(dto.order, actions, dto.winnerPos, dto.winnerBid);
  }

  @override
  Future<List<ReplacementEvent>> fetchReplacements(String handId) async {
    final raw = await rootBundle.loadString('mock/replacements.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final list = (map['replacements'] as List)
        .cast<Map<String, dynamic>>()
        .map(ReplacementEventDto.fromJson)
        .map((e) => ReplacementEvent(e.pos, e.discarded, e.drawn))
        .toList();
    return list;
  }

  @override
  Future<List<TrickSnapshot>> fetchTricks(String handId) async {
    final raw = await rootBundle.loadString('mock/trick_sequence.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final list = (map['tricks'] as List)
        .cast<Map<String, dynamic>>()
        .map(TrickSnapshotDto.fromJson)
        .map((t) => TrickSnapshot(
              t.index,
              t.leader,
              t.plays.map((p) => {'pos': p.pos, 'card': p.card}).toList(),
              t.winner,
              t.lastTrick,
            ))
        .toList();
    return list;
  }

  @override
  Future<ScoringBreakdown> fetchScoring(String handId,
      {String variant = '10_point'}) async {
    final raw = await rootBundle.loadString('mock/scoring_breakdown.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final key = variant == '4_point' ? 'four_point' : 'ten_point';
    final s = map[key] as Map<String, dynamic>;

    final captured = (s['captured_by'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List).cast<String>()),
    );
    final awards = (s['awards'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    );
    final delta = (s['delta'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
    final gameField = key == 'ten_point' ? 'game_values' : 'game_totals';
    final game = (s[gameField] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );

    return ScoringBreakdown(
      trumps: s['trumps'] as String,
      capturedBy: captured,
      gameValues: game,
      awards: awards,
      delta: delta,
    );
  }
}
