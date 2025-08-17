import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/pitch_service.dart';

enum LobbySort {
  nameAsc,
  nameDesc,
  leastFull,
  mostFull,
  openFirst,
}

class LobbyStore extends ChangeNotifier {
  LobbyStore(this._service);

  final PitchService _service;

  List<LobbyTable> _tables = const [];
  bool _loading = false;
  Object? _error;

  // Search and filter state
  String _searchText = '';
  String _variantFilter = 'all'; // 'all', '4_point', '10_point'
  String _statusFilter = 'all'; // 'all', 'open', 'playing'
  LobbySort _sort = LobbySort.nameAsc;
  Timer? _searchDebounceTimer;

  List<LobbyTable> get allTables => _tables;
  List<LobbyTable> get filteredTables => _applyFiltersAndSort();
  bool get loading => _loading;
  Object? get error => _error;
  String get searchText => _searchText;
  String get variantFilter => _variantFilter;
  String get statusFilter => _statusFilter;
  LobbySort get sort => _sort;

  // For backward compatibility
  List<LobbyTable> get tables => filteredTables;

  int get totalTables => _tables.length;
  int get filteredTablesCount => filteredTables.length;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tables = await _service.fetchLobby();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearchText(String text) {
    _searchText = text;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      notifyListeners();
    });
  }

  void setVariantFilter(String filter) {
    if (_variantFilter == filter) return;
    _variantFilter = filter;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    notifyListeners();
  }

  void setSort(LobbySort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void clearFilters() {
    _searchText = '';
    _variantFilter = 'all';
    _statusFilter = 'all';
    _sort = LobbySort.nameAsc;
    _searchDebounceTimer?.cancel();
    notifyListeners();
  }

  List<LobbyTable> _applyFiltersAndSort() {
    var filtered = _tables.where((table) {
      // Search filter (case-insensitive)
      if (_searchText.isNotEmpty && 
          !table.name.toLowerCase().contains(_searchText.toLowerCase())) {
        return false;
      }

      // Variant filter
      if (_variantFilter != 'all' && table.variant != _variantFilter) {
        return false;
      }

      // Status filter
      if (_statusFilter != 'all') {
        final isOpen = !table.inProgress;
        if (_statusFilter == 'open' && !isOpen) return false;
        if (_statusFilter == 'playing' && isOpen) return false;
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sort) {
      case LobbySort.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case LobbySort.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case LobbySort.leastFull:
        filtered.sort((a, b) => a.seatsTaken.compareTo(b.seatsTaken));
        break;
      case LobbySort.mostFull:
        filtered.sort((a, b) => b.seatsTaken.compareTo(a.seatsTaken));
        break;
      case LobbySort.openFirst:
        filtered.sort((a, b) {
          if (a.inProgress != b.inProgress) {
            return a.inProgress ? 1 : -1; // Open tables first
          }
          return a.name.compareTo(b.name);
        });
        break;
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
