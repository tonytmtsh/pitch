import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/pitch_service.dart';

class TableStore extends ChangeNotifier {
  TableStore(this._service, this.tableId);

  final PitchService _service;
  final String tableId;
  StreamSubscription<void>? _sub;

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
  // Card selection for replacements
  final Set<String> _selectedCardsForDiscard = <String>{};

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
  bool _replacementsLocked = false; // fallback when handState not available
  bool get replacementsLocked => _handState?.replacementsLocked ?? _replacementsLocked;
  ScoringBreakdown? _scoring;
  ScoringBreakdown? get scoring => _scoring;
  HandState? _handState;
  HandState? get handState => _handState;
  List<String> _myCards = const [];
  List<String> get myCards => _myCards;
  Set<String> get selectedCardsForDiscard => _selectedCardsForDiscard;
  bool get hasReplacementInProgress => _replacementsPending.any((r) => r.pos == mySeatPos);
  bool get canRequestReplacements {
    // Can request if we have cards, no replacement in progress, and replacements aren't locked
    return myCards.isNotEmpty && !hasReplacementInProgress && !replacementsLocked;
  }
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

  // --- Seat and turn helpers ---
  String? get mySeatPos {
    final uid = _service.currentUserId();
    final t = _table;
    if (uid == null || t == null) return null;
    for (final s in t.seats) {
      if (s.userId == uid) {
        const order = ['N', 'E', 'S', 'W'];
        return order[s.position];
      }
    }
    return null;
  }

  String get nextBidPos {
    final order = biddingOrder;
    if (biddingActions.isEmpty) return order.first;
    final last = biddingActions.last;
    final lastPos = (last['pos'] as String?) ?? order.first;
    final idx = order.indexOf(lastPos);
    return order[(idx + 1) % order.length];
  }

  bool get isMyBidTurn => mySeatPos != null && mySeatPos == nextBidPos;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _table = await _service.fetchTable(tableId);
      if (_table?.variant != null) {
        _variant = _table!.variant!;
      }
  final handId = _table?.handId ?? 'demo';
  try {
        _bidding = await _service.fetchBidding(handId);
      } catch (_) {
        _bidding = null;
      }
  _biddingPending.clear();
  // Prefer my seat if known; else first in order
  _selectedBidPos = mySeatPos ?? _bidding?.order.firstOrNull;
  try {
        _replacements = await _service.fetchReplacements(handId);
      } catch (_) {
        _replacements = const [];
      }
  _replacementsPending.clear();
  _selectedCardsForDiscard.clear();
  // If any replacement events exist for all four seats, assume locked
  final seatsDone = _replacements.map((r) => r.pos).toSet();
  _replacementsLocked = seatsDone.length >= 4;
      try {
        _tricks = await _service.fetchTricks(handId);
      } catch (_) {
        _tricks = const [];
      }
  _tricksPending.clear();
      try {
        _handState = await _service.fetchHandState(handId);
      } catch (_) {
        _handState = null;
      }
      try {
        final myPos = mySeatPos;
        _myCards = myPos != null ? await _service.fetchPrivateHand(handId, myPos) : const [];
      } catch (_) {
        _myCards = const [];
      }
      await _loadScoring();
      // Start/refresh realtime subscription
      await _sub?.cancel();
      _sub = _service.handEvents(handId).listen((_) {
        // Lightweight refresh of hand-related sections
        _refreshHandParts();
      });
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshHandParts() async {
    final handId = _table?.handId;
    if (handId == null) return;
    try {
      _bidding = await _service.fetchBidding(handId);
    } catch (_) {}
    try {
      _replacements = await _service.fetchReplacements(handId);
    } catch (_) {}
    try {
      _tricks = await _service.fetchTricks(handId);
    } catch (_) {}
    try {
      _handState = await _service.fetchHandState(handId);
    } catch (_) {}
    try {
      final myPos = mySeatPos;
      _myCards = myPos != null ? await _service.fetchPrivateHand(handId, myPos) : const [];
    } catch (_) {}
    try {
      await _loadScoring();
    } catch (_) {}
    notifyListeners();
  }

  // Placeholder: simple legal cards filter (server enforces real rules)
  List<String> legalCardsForTurn() {
    final myPos = mySeatPos;
    if (myPos == null || _myCards.isEmpty || _tricks.isEmpty) return _myCards;
    final active = _tricks.last;
    if (active.plays.isEmpty) return _myCards; // leading can play any
    final led = active.plays.first['card'];
    if (led == null || led.isEmpty) return _myCards;
  final ledSuit = led.substring(led.length - 1);
  final hasLed = _myCards.any((c) => c.isNotEmpty && c[c.length - 1] == ledSuit);
    if (!hasLed) return _myCards;
  return _myCards.where((c) => c.isNotEmpty && c[c.length - 1] == ledSuit).toList();
  }

  TrickSnapshot? get currentTrick {
    if (_tricks.isEmpty) return null;
    return _tricks.last;
  }

  String? get currentTurnPos {
    final t = currentTrick;
    if (t == null) return null;
    final order = const ['N', 'E', 'S', 'W'];
    final leadIdx = order.indexOf(t.leader);
    if (leadIdx < 0) return null;
    final turnIdx = (leadIdx + t.plays.length) % 4;
    return order[turnIdx];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadScoring() async {
    try {
  final handId = _table?.handId ?? 'demo';
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
    final effectivePos = mySeatPos ?? pos;
    final action = {'pos': effectivePos, 'bid': bid};
    _biddingPending.add(action);
    notifyListeners();
    // Optimistic server call (mock will just return true)
    final handId = _table?.handId;
    if (handId != null) {
      _service.placeBid(handId, value: bid, pass: false).then((ok) {
        if (!ok) {
          _biddingPending.remove(action);
          _error = 'Bid rejected';
          notifyListeners();
        }
      }).catchError((e) {
        _biddingPending.remove(action);
        _error = e;
        notifyListeners();
      });
    }
  }

  void submitPass(String pos) {
    final effectivePos = mySeatPos ?? pos;
    final action = {'pos': effectivePos, 'pass': true};
    _biddingPending.add(action);
    notifyListeners();
    final handId = _table?.handId;
    if (handId != null) {
      _service.placeBid(handId, pass: true).then((ok) {
        if (!ok) {
          _biddingPending.remove(action);
          _error = 'Pass rejected';
          notifyListeners();
        }
      }).catchError((e) {
        _biddingPending.remove(action);
        _error = e;
        notifyListeners();
      });
    }
  }

  // --- Local demo replacements (mock only; not persisted) ---
  void toggleCardSelection(String card) {
    if (_selectedCardsForDiscard.contains(card)) {
      _selectedCardsForDiscard.remove(card);
    } else {
      _selectedCardsForDiscard.add(card);
    }
    notifyListeners();
  }

  void clearCardSelection() {
    _selectedCardsForDiscard.clear();
    notifyListeners();
  }

  void requestReplacementsForSelected() {
    if (_selectedCardsForDiscard.isEmpty) return;
    final effectivePos = mySeatPos;
    if (effectivePos == null) return; // Safety check
    
    final discarded = _selectedCardsForDiscard.toList();
    
    // Create pending replacement with selected cards
    final pending = ReplacementEvent(effectivePos, List.of(discarded), const []);
    _replacementsPending.add(pending);
    
    // Clear selection since we've submitted
    _selectedCardsForDiscard.clear();
    notifyListeners();
    
    final handId = _table?.handId;
    if (handId != null) {
      _service.requestReplacements(handId, discarded).then((drawnServer) {
        // Update the pending entry's drawn cards with server result
        final idx = _replacementsPending.indexOf(pending);
        if (idx >= 0) {
          _replacementsPending[idx] = ReplacementEvent(effectivePos, pending.discarded, List.of(drawnServer));
          notifyListeners();
        }
      }).catchError((e) {
        _replacementsPending.remove(pending);
        _error = e;
        notifyListeners();
      });
    }
  }

  void addReplacement(String pos, List<String> discarded, List<String> drawn) {
    final effectivePos = mySeatPos ?? pos;
    final pending = ReplacementEvent(effectivePos, List.of(discarded), List.of(drawn));
    _replacementsPending.add(pending);
    notifyListeners();
    final handId = _table?.handId;
    if (handId != null) {
      _service.requestReplacements(handId, discarded).then((drawnServer) {
        // Update the pending entry's drawn cards with server result
        final idx = _replacementsPending.indexOf(pending);
        if (idx >= 0) {
          _replacementsPending[idx] = ReplacementEvent(effectivePos, pending.discarded, List.of(drawnServer));
          notifyListeners();
        }
      }).catchError((e) {
        _replacementsPending.remove(pending);
        _error = e;
        notifyListeners();
      });
    }
  }

  Future<void> lockReplacementsNow() async {
    final handId = _table?.handId;
    if (handId == null) return;
    final ok = await _service.lockReplacements(handId);
    if (ok) {
      _replacementsLocked = true;
      notifyListeners();
    }
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
