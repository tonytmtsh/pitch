/// Contract for data operations used by the app.
abstract class PitchService {
  Future<List<LobbyTable>> fetchLobby();
  Future<TableDetails> fetchTable(String tableId);
  // Hand flows (mock/server parity later)
  Future<BiddingProgress> fetchBidding(String handId);
  Future<List<ReplacementEvent>> fetchReplacements(String handId);
  Future<List<TrickSnapshot>> fetchTricks(String handId);
  Future<ScoringBreakdown> fetchScoring(String handId, {String variant = '10_point'});
}

/// Minimal models matching mock JSON shape we created under /mock.
class LobbyTable {
  final String id;
  final String name;
  final String variant; // '10_point' | '4_point'
  final String status; // 'open' | 'playing' | etc.
  final int occupancy; // number seated

  LobbyTable({
    required this.id,
    required this.name,
  required this.variant,
  required this.status,
  required this.occupancy,
  });

  factory LobbyTable.fromJson(Map<String, dynamic> json) => LobbyTable(
        id: json['id'] as String,
        name: json['name'] as String,
    variant: json['variant'] as String,
    status: json['status'] as String,
    occupancy: json['occupancy'] as int,
      );

  int get seatsTotal => 4; // fixed for Pitch
  int get seatsTaken => occupancy;
  bool get inProgress => status == 'playing';
}

class TableDetails {
  final String id;
  final String name;
  final List<Seat> seats;
  final bool inProgress;
  final String? variant;

  TableDetails({
    required this.id,
    required this.name,
    required this.seats,
    required this.inProgress,
    this.variant,
  });

  factory TableDetails.fromJson(Map<String, dynamic> json) => TableDetails(
        id: json['id'] as String,
        name: json['name'] as String,
        inProgress: json['inProgress'] as bool,
        seats: (json['seats'] as List)
            .cast<Map<String, dynamic>>()
            .map(Seat.fromJson)
            .toList(),
        variant: json['variant'] as String?,
      );
}

class Seat {
  final int position; // 0-3
  final String? player;

  Seat({required this.position, required this.player});

  static Seat fromJson(Map<String, dynamic> json) =>
      Seat(position: json['position'] as int, player: json['player'] as String?);
}

// Minimal app-side models for hand flows
class BiddingProgress {
  final List<String> order;
  final List<Map<String, dynamic>> actions;
  final String winnerPos;
  final int winnerBid;
  BiddingProgress(this.order, this.actions, this.winnerPos, this.winnerBid);
}

class ReplacementEvent {
  final String pos;
  final List<String> discarded;
  final List<String> drawn;
  ReplacementEvent(this.pos, this.discarded, this.drawn);
}

class TrickSnapshot {
  final int index;
  final String leader;
  final List<Map<String, String>> plays; // {pos, card}
  final String winner;
  final bool lastTrick;
  TrickSnapshot(this.index, this.leader, this.plays, this.winner, this.lastTrick);
}

class ScoringBreakdown {
  final String trumps;
  final Map<String, List<String>> capturedBy; // team -> cards
  final Map<String, int> gameValues; // or totals, depends on variant
  final Map<String, String> awards; // category -> team
  final Map<String, int> delta; // team -> points change
  ScoringBreakdown({
    required this.trumps,
    required this.capturedBy,
    required this.gameValues,
    required this.awards,
    required this.delta,
  });
}
