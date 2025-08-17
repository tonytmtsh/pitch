/// Sample DTOs for common RPCs and API payloads.
/// These standardize shapes across mock and future Supabase service.

class LobbyEntryDto {
  final String id;
  final String name;
  final String variant; // '4_point' | '10_point'
  final String status; // 'open' | 'playing' | 'finished'
  final int occupancy; // 0-4

  const LobbyEntryDto({
    required this.id,
    required this.name,
    required this.variant,
    required this.status,
    required this.occupancy,
  });

  factory LobbyEntryDto.fromJson(Map<String, dynamic> json) => LobbyEntryDto(
        id: json['id'] as String,
        name: json['name'] as String,
        variant: json['variant'] as String,
        status: json['status'] as String,
        occupancy: (json['occupancy'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'variant': variant,
        'status': status,
        'occupancy': occupancy,
      };
}

class TableSeatDto {
  final String position; // 'N' | 'E' | 'S' | 'W'
  final String? user; // username or null

  const TableSeatDto({required this.position, required this.user});

  factory TableSeatDto.fromJson(Map<String, dynamic> json) =>
      TableSeatDto(position: json['position'] as String, user: json['user'] as String?);

  Map<String, dynamic> toJson() => {
        'position': position,
        'user': user,
      };
}

class TableSnapshotDto {
  final String id;
  final String name;
  final String variant;
  final String status;
  final int targetScore;
  final List<TableSeatDto> seats;

  const TableSnapshotDto({
    required this.id,
    required this.name,
    required this.variant,
    required this.status,
    required this.targetScore,
    required this.seats,
  });

  factory TableSnapshotDto.fromJson(Map<String, dynamic> json) => TableSnapshotDto(
        id: json['id'] as String,
        name: json['name'] as String,
        variant: json['variant'] as String,
        status: json['status'] as String,
        targetScore: (json['target_score'] as num).toInt(),
        seats: (json['seats'] as List)
            .cast<Map<String, dynamic>>()
            .map(TableSeatDto.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'variant': variant,
        'status': status,
        'target_score': targetScore,
        'seats': seats.map((e) => e.toJson()).toList(),
      };
}
