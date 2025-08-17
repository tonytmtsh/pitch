import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/pitch_service.dart';

enum LobbySort { nameAsc, nameDesc, occupancyAsc, occupancyDesc, statusOpen }

class LobbyStore extends ChangeNotifier {
  LobbyStore(this._service);

  final PitchService _service;

  List<LobbyTable> _tables = const [];
  bool _loading = false;
  Object? _error;
  
  // Search and filter state
  String _searchText = '';
  String? _variantFilter; // null means all variants
  String? _statusFilter; // null means all statuses
  LobbySort _sortBy = LobbySort.nameAsc;
  
  // Debouncing for search
  Timer? _searchDebounce;
  
  List<LobbyTable> get tables => _filteredAndSortedTables;
  List<LobbyTable> get allTables => _tables;
  bool get loading => _loading;
  Object? get error => _error;
  
  String get searchText => _searchText;
  String? get variantFilter => _variantFilter;
  String? get statusFilter => _statusFilter;
  LobbySort get sortBy => _sortBy;

  List<LobbyTable> get _filteredAndSortedTables {
    var filtered = _tables.where((table) {
      // Text search by name
      if (_searchText.isNotEmpty && 
          !table.name.toLowerCase().contains(_searchText.toLowerCase())) {
        return false;
      }
      
      // Variant filter
      if (_variantFilter != null && table.variant != _variantFilter) {
        return false;
      }
      
      // Status filter
      if (_statusFilter != null && table.status != _statusFilter) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    switch (_sortBy) {
      case LobbySort.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case LobbySort.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case LobbySort.occupancyAsc:
        filtered.sort((a, b) => a.occupancy.compareTo(b.occupancy));
        break;
      case LobbySort.occupancyDesc:
        filtered.sort((a, b) => b.occupancy.compareTo(a.occupancy));
        break;
      case LobbySort.statusOpen:
        filtered.sort((a, b) {
          // Open tables first, then by name
          if (a.status == 'open' && b.status != 'open') return -1;
          if (b.status == 'open' && a.status != 'open') return 1;
          return a.name.compareTo(b.name);
        });
        break;
    }
    
    return filtered;
  }

  void setSearchText(String text) {
    _searchText = text;
    
    // Cancel previous debounce timer
    _searchDebounce?.cancel();
    
    // Set up new debounce timer
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      notifyListeners();
    });
  }

  void setVariantFilter(String? variant) {
    _variantFilter = variant;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setSortBy(LobbySort sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void clearFilters() {
    _searchText = '';
    _variantFilter = null;
    _statusFilter = null;
    _sortBy = LobbySort.nameAsc;
    _searchDebounce?.cancel();
    notifyListeners();
  }

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
  
  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
