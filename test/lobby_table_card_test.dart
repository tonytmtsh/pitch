import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pitch/ui/widgets/lobby_table_card.dart';
import 'package:pitch/services/pitch_service.dart';
import 'package:pitch/services/mock_pitch_service.dart';

void main() {
  group('LobbyTableCard', () {
    late LobbyTable testTable;
    bool onTapCalled = false;
    bool onQuickJoinCalled = false;

    setUp(() {
      testTable = LobbyTable(
        id: 'test-id',
        name: 'Test Table',
        variant: '10_point',
        status: 'open',
        occupancy: 2,
      );
      onTapCalled = false;
      onQuickJoinCalled = false;
    });

    Widget createTestWidget({LobbyTable? table, bool showQuickJoin = true}) {
      return Provider<PitchService>(
        create: (_) => MockPitchService(),
        child: MaterialApp(
          home: Scaffold(
            body: LobbyTableCard(
              table: table ?? testTable,
              onTap: () => onTapCalled = true,
              onQuickJoin: showQuickJoin ? () => onQuickJoinCalled = true : null,
            ),
          ),
        ),
      );
    }

    testWidgets('should display table name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Test Table'), findsOneWidget);
    });

    testWidgets('should display variant chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('10-Point'), findsOneWidget);
    });

    testWidgets('should display status chip for open table', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('should display occupancy chip', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('2/4'), findsOneWidget);
    });

    testWidgets('should show quick join button for open table with space', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Quick Join'), findsOneWidget);
    });

    testWidgets('should not show quick join button for full table', (tester) async {
      final fullTable = LobbyTable(
        id: 'test-id',
        name: 'Full Table',
        variant: '10_point',
        status: 'open',
        occupancy: 4,
      );
      
      await tester.pumpWidget(createTestWidget(table: fullTable));
      expect(find.text('Quick Join'), findsNothing);
    });

    testWidgets('should not show quick join button for playing table', (tester) async {
      final playingTable = LobbyTable(
        id: 'test-id',
        name: 'Playing Table',
        variant: '10_point',
        status: 'playing',
        occupancy: 4,
      );
      
      await tester.pumpWidget(createTestWidget(table: playingTable));
      expect(find.text('Quick Join'), findsNothing);
    });

    testWidgets('should call onTap when view/join button pressed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      await tester.tap(find.text('Join'));
      expect(onTapCalled, true);
    });

    testWidgets('should call onQuickJoin when quick join button pressed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      await tester.tap(find.text('Quick Join'));
      expect(onQuickJoinCalled, true);
    });

    testWidgets('should show correct status for playing table', (tester) async {
      final playingTable = LobbyTable(
        id: 'test-id',
        name: 'Playing Table',
        variant: '10_point',
        status: 'playing',
        occupancy: 4,
      );
      
      await tester.pumpWidget(createTestWidget(table: playingTable));
      expect(find.text('PLAYING'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    });
  });
}