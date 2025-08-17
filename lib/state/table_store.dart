import 'package:flutter/foundation.dart';

import '../services/pitch_service.dart';

class TableStore extends ChangeNotifier {
  TableStore(this._service, this.tableId);

  final PitchService _service;
  final String tableId;

  TableDetails? _table;
  bool _loading = false;
  Object? _error;

  // Hand flow snapshots (mock for now; server wiring later)
  BiddingProgress? _bidding;
  List<ReplacementEvent> _replacements = const [];
  List<TrickSnapshot> _tricks = const [];
  final List<TrickSnapshot> _tricksPending = [];
  // Local, in-memory pending bidding actions (demo in mock)
  final List<Map<String, dynamic>> _biddingPending = [];
  String? _selectedBidPos;
  // Local, in-memory pending replacements (demo in mock)
  final List<ReplacementEvent> _replacementsPending = [];

  TableDetails? get table => _table;
  bool get loading => _loading;
  Object? get error => _error;
  BiddingProgress? get bidding => _bidding;
  List<ReplacementEvent> get replacements => _replacements;
  List<ReplacementEvent> get replacementsAll => [
        ..._replacements,
        ..._replacementsPending,
      ];
  List<TrickSnapshot> get tricks => _tricks;
  List<TrickSnapshot> get tricksAll => [
        ..._tricks,
        ..._tricksPending,
      ];
  ScoringBreakdown? _scoring;
  ScoringBreakdown? get scoring => _scoring;
  String _variant = '10_point';
  String get variant => _variant;
  void setVariant(String v) {
    if (_variant == v) return;
    _variant = v;
    _loadScoring();
  }
  List<Map<String, dynamic>> get biddingActions => [
        ...?_bidding?.actions,
        ..._biddingPending,
      ];
  List<String> get biddingOrder => _bidding?.order ?? const ['N', 'E', 'S', 'W'];
  String get selectedBidPos =>
      _selectedBidPos ?? (_bidding?.order.firstOrNull ?? 'N');
  int get biddingWinnerBid {
    int maxBid = _bidding?.winnerBid ?? 0;
    for (final a in _biddingPending) {
      final b = a['bid'];
      if (b is int && b > maxBid) maxBid = b;
    }
    return maxBid;
  }
  String get biddingWinnerPos {
    String pos = _bidding?.winnerPos ?? 'N';
    int bid = _bidding?.winnerBid ?? 0;
    for (final a in _biddingPending) {
      final b = a['bid'];
      if (b is int && b > bid) {
        bid = b;
        pos = a['pos'] as String? ?? pos;
      }
    }
    return pos;
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _table = await _service.fetchTable(tableId);
      if (_table?.variant != null) {
        _variant = _table!.variant!;
      }
      // Best-effort fetch of current hand progress using mock data.
      // The mock ignores handId; server will need a real ID.
      const handId = 'demo';
      try {
        _bidding = await _service.fetchBidding(handId);
      } catch (_) {
        _bidding = null;
      }
  _biddingPending.clear();
  _selectedBidPos = _bidding?.order.firstOrNull;
      try {
        _replacements = await _service.fetchReplacements(handId);
      } catch (_) {
        _replacements = const [];
      }
  _replacementsPending.clear();
      try {
        _tricks = await _service.fetchTricks(handId);
      } catch (_) {
        _tricks = const [];
      }
  _tricksPending.clear();
      await _loadScoring();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadScoring() async {
    try {
      const handId = 'demo';
      _scoring = await _service.fetchScoring(handId, variant: _variant);
    } catch (_) {
      _scoring = null;
    }
    notifyListeners();
  }

  // --- Local demo bidding actions (mock only; not persisted) ---
  void setSelectedBidPos(String pos) {
    _selectedBidPos = pos;
    notifyListeners();
  }

  void submitBid(String pos, int bid) {
    if (bid <= 0) return;
    _biddingPending.add({'pos': pos, 'bid': bid});
    notifyListeners();
  }

  void submitPass(String pos) {
    _biddingPending.add({'pos': pos, 'pass': true});
    notifyListeners();
  }

  // --- Local demo replacements (mock only; not persisted) ---
  void addReplacement(String pos, List<String> discarded, List<String> drawn) {
    _replacementsPending
        .add(ReplacementEvent(pos, List.of(discarded), List.of(drawn)));
    notifyListeners();
  }

  // --- Local demo tricks (mock only; not persisted) ---
  void addTrick({
    required String leader,
    required List<Map<String, String>> plays,
    required String winner,
    bool lastTrick = false,
  }) {
    final nextIndex = tricksAll.length;
    _tricksPending.add(TrickSnapshot(nextIndex, leader, plays, winner, lastTrick));
    notifyListeners();
  }
}
