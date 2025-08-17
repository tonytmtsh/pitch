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

// --- Hand-related DTOs ---

class BiddingActionDto {
  final String pos; // 'N'|'E'|'S'|'W'
  final int? bid;
  final bool pass;

  const BiddingActionDto({required this.pos, this.bid, this.pass = false});

  factory BiddingActionDto.fromJson(Map<String, dynamic> json) => BiddingActionDto(
        pos: json['pos'] as String,
        bid: (json['bid'] as num?)?.toInt(),
        pass: (json['pass'] as bool?) ?? false,
      );
}

class BiddingProgressDto {
  final List<String> order; // play order of positions
  final List<BiddingActionDto> actions;
  final String winnerPos;
  final int winnerBid;

  const BiddingProgressDto({
    required this.order,
    required this.actions,
    required this.winnerPos,
    required this.winnerBid,
  });

  factory BiddingProgressDto.fromJson(Map<String, dynamic> json) {
    final bidding = json['bidding'] as Map<String, dynamic>;
    final actions = (bidding['actions'] as List)
        .cast<Map<String, dynamic>>()
        .map(BiddingActionDto.fromJson)
        .toList();
    final winner = bidding['winner'] as Map<String, dynamic>;
    return BiddingProgressDto(
      order: (bidding['order'] as List).cast<String>(),
      actions: actions,
      winnerPos: winner['pos'] as String,
      winnerBid: (winner['bid'] as num).toInt(),
    );
  }
}

class ReplacementEventDto {
  final String pos;
  final List<String> discarded;
  final List<String> drawn;

  const ReplacementEventDto({
    required this.pos,
    required this.discarded,
    required this.drawn,
  });

  factory ReplacementEventDto.fromJson(Map<String, dynamic> json) =>
      ReplacementEventDto(
        pos: json['pos'] as String,
        discarded: (json['discarded'] as List).cast<String>(),
        drawn: (json['drawn'] as List).cast<String>(),
      );
}

class TrickPlayDto {
  final String pos;
  final String card;
  const TrickPlayDto({required this.pos, required this.card});
  factory TrickPlayDto.fromJson(Map<String, dynamic> json) =>
      TrickPlayDto(pos: json['pos'] as String, card: json['card'] as String);
}

class TrickSnapshotDto {
  final int index;
  final String leader;
  final List<TrickPlayDto> plays;
  final String winner;
  final bool lastTrick;

  const TrickSnapshotDto({
    required this.index,
    required this.leader,
    required this.plays,
    required this.winner,
    required this.lastTrick,
  });

  factory TrickSnapshotDto.fromJson(Map<String, dynamic> json) => TrickSnapshotDto(
        index: (json['index'] as num).toInt(),
        leader: json['leader'] as String,
        plays: (json['plays'] as List)
            .cast<Map<String, dynamic>>()
            .map(TrickPlayDto.fromJson)
            .toList(),
        winner: json['winner'] as String,
        lastTrick: (json['last_trick'] as bool?) ?? false,
      );
}
