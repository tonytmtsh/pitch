import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/services/mock_pitch_service.dart';
import 'package:pitch/state/lobby_store.dart';

void main() {
  group('LobbyStore Search/Filter/Sort Tests', () {
    late LobbyStore store;
    late MockPitchService mockService;

    setUp(() {
      mockService = MockPitchService();
      store = LobbyStore(mockService);
    });

    tearDown(() {
      store.dispose();
    });

    testWidgets('Initial state has no filters applied', (tester) async {
      expect(store.searchText, equals(''));
      expect(store.variantFilter, isNull);
      expect(store.statusFilter, isNull);
      expect(store.sortBy, equals(LobbySort.nameAsc));
    });

    testWidgets('Search text filters tables by name', (tester) async {
      await store.refresh();
      await tester.pump();
      
      // Should have some tables initially
      expect(store.allTables.length, greaterThan(0));
      
      // Search for specific table
      store.setSearchText('Demo');
      await tester.pump(const Duration(milliseconds: 400)); // Wait for debounce
      
      // Should filter to only tables containing "Demo"
      expect(store.tables.every((t) => t.name.toLowerCase().contains('demo')), isTrue);
    });

    testWidgets('Variant filter works correctly', (tester) async {
      await store.refresh();
      await tester.pump();
      
      // Filter by 4-point variant
      store.setVariantFilter('4_point');
      
      // Should only show 4-point tables
      expect(store.tables.every((t) => t.variant == '4_point'), isTrue);
      
      // Filter by 10-point variant
      store.setVariantFilter('10_point');
      
      // Should only show 10-point tables
      expect(store.tables.every((t) => t.variant == '10_point'), isTrue);
    });

    testWidgets('Status filter works correctly', (tester) async {
      await store.refresh();
      await tester.pump();
      
      // Filter by open status
      store.setStatusFilter('open');
      
      // Should only show open tables
      expect(store.tables.every((t) => t.status == 'open'), isTrue);
    });

    testWidgets('Sort by name works correctly', (tester) async {
      await store.refresh();
      await tester.pump();
      
      if (store.allTables.length < 2) return; // Skip if not enough data
      
      // Sort ascending
      store.setSortBy(LobbySort.nameAsc);
      final ascNames = store.tables.map((t) => t.name).toList();
      
      // Sort descending
      store.setSortBy(LobbySort.nameDesc);
      final descNames = store.tables.map((t) => t.name).toList();
      
      // Verify they're opposite orders
      expect(ascNames.reversed.toList(), equals(descNames));
    });

    testWidgets('Sort by occupancy works correctly', (tester) async {
      await store.refresh();
      await tester.pump();
      
      if (store.allTables.length < 2) return; // Skip if not enough data
      
      // Sort by least full
      store.setSortBy(LobbySort.occupancyAsc);
      final occupancies = store.tables.map((t) => t.occupancy).toList();
      
      // Verify ascending order
      for (int i = 1; i < occupancies.length; i++) {
        expect(occupancies[i], greaterThanOrEqualTo(occupancies[i - 1]));
      }
    });

    testWidgets('Clear filters resets all state', (tester) async {
      await store.refresh();
      await tester.pump();
      
      // Set some filters
      store.setSearchText('test');
      store.setVariantFilter('4_point');
      store.setStatusFilter('open');
      store.setSortBy(LobbySort.nameDesc);
      
      // Clear all filters
      store.clearFilters();
      
      // Verify reset state
      expect(store.searchText, equals(''));
      expect(store.variantFilter, isNull);
      expect(store.statusFilter, isNull);
      expect(store.sortBy, equals(LobbySort.nameAsc));
    });

    testWidgets('Multiple filters work together', (tester) async {
      await store.refresh();
      await tester.pump();
      
      // Apply multiple filters
      store.setVariantFilter('10_point');
      store.setStatusFilter('open');
      
      // Should only show tables matching both criteria
      expect(store.tables.every((t) => t.variant == '10_point' && t.status == 'open'), isTrue);
    });
  });
}