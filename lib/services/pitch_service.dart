/// Contract for data operations used by the app.
abstract class PitchService {
  Future<List<LobbyTable>> fetchLobby();
  Future<TableDetails> fetchTable(String tableId);
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

  TableDetails({
    required this.id,
    required this.name,
    required this.seats,
    required this.inProgress,
  });

  factory TableDetails.fromJson(Map<String, dynamic> json) => TableDetails(
        id: json['id'] as String,
        name: json['name'] as String,
        inProgress: json['inProgress'] as bool,
        seats: (json['seats'] as List)
            .cast<Map<String, dynamic>>()
            .map(Seat.fromJson)
            .toList(),
      );
}

class Seat {
  final int position; // 0-3
  final String? player;

  Seat({required this.position, required this.player});

  static Seat fromJson(Map<String, dynamic> json) =>
      Seat(position: json['position'] as int, player: json['player'] as String?);
}
