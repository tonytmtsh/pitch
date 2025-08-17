import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/state/lobby_store.dart';
import 'package:pitch/services/mock_pitch_service.dart';

void main() {
  group('LobbyStore', () {
    late LobbyStore lobbyStore;
    late MockPitchService mockService;

    setUp(() {
      mockService = MockPitchService();
      lobbyStore = LobbyStore(mockService);
    });

    tearDown(() {
      lobbyStore.dispose();
    });

    test('should have default filter values', () {
      expect(lobbyStore.searchText, '');
      expect(lobbyStore.variantFilter, 'all');
      expect(lobbyStore.statusFilter, 'all');
      expect(lobbyStore.sort, LobbySort.nameAsc);
    });

    test('should update search text', () {
      lobbyStore.setSearchText('test');
      expect(lobbyStore.searchText, 'test');
    });

    test('should update variant filter', () {
      lobbyStore.setVariantFilter('4_point');
      expect(lobbyStore.variantFilter, '4_point');
    });

    test('should update status filter', () {
      lobbyStore.setStatusFilter('open');
      expect(lobbyStore.statusFilter, 'open');
    });

    test('should update sort option', () {
      lobbyStore.setSort(LobbySort.nameDesc);
      expect(lobbyStore.sort, LobbySort.nameDesc);
    });

    test('should clear all filters', () {
      lobbyStore.setSearchText('test');
      lobbyStore.setVariantFilter('4_point');
      lobbyStore.setStatusFilter('open');
      lobbyStore.setSort(LobbySort.nameDesc);

      lobbyStore.clearFilters();

      expect(lobbyStore.searchText, '');
      expect(lobbyStore.variantFilter, 'all');
      expect(lobbyStore.statusFilter, 'all');
      expect(lobbyStore.sort, LobbySort.nameAsc);
    });

    test('should not update if same value', () {
      bool notified = false;
      lobbyStore.addListener(() => notified = true);
      
      lobbyStore.setVariantFilter('all'); // Same as default
      expect(notified, false);
    });
  });
}