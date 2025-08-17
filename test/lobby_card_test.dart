import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pitch/services/mock_pitch_service.dart';
import 'package:pitch/services/pitch_service.dart';
import 'package:pitch/ui/widgets/lobby_table_card.dart';

void main() {
  group('LobbyTableCard Widget Tests', () {
    late LobbyTable testTable10Point;
    late LobbyTable testTable4Point;
    late LobbyTable testTableFull;
    late LobbyTable testTablePlaying;

    setUp(() {
      testTable10Point = LobbyTable(
        id: 'test-1',
        name: 'Test 10-Point Table',
        variant: '10_point',
        status: 'open',
        occupancy: 2,
      );

      testTable4Point = LobbyTable(
        id: 'test-2',
        name: 'Test 4-Point Table',
        variant: '4_point',
        status: 'open',
        occupancy: 1,
      );

      testTableFull = LobbyTable(
        id: 'test-3',
        name: 'Full Table',
        variant: '10_point',
        status: 'open',
        occupancy: 4,
      );

      testTablePlaying = LobbyTable(
        id: 'test-4',
        name: 'Playing Table',
        variant: '4_point',
        status: 'playing',
        occupancy: 4,
      );
    });

    Widget createTestWidget(LobbyTable table, {VoidCallback? onQuickJoin}) {
      return Provider<PitchService>.value(
        value: MockPitchService(),
        child: MaterialApp(
          home: Scaffold(
            body: LobbyTableCard(
              table: table,
              onQuickJoin: onQuickJoin,
            ),
          ),
        ),
      );
    }

    testWidgets('displays table name and status correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(testTable10Point));

      expect(find.text('Test 10-Point Table'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('displays variant chip correctly for 10-point', (tester) async {
      await tester.pumpWidget(createTestWidget(testTable10Point));

      expect(find.text('10-Point'), findsOneWidget);
    });

    testWidgets('displays variant chip correctly for 4-point', (tester) async {
      await tester.pumpWidget(createTestWidget(testTable4Point));

      expect(find.text('4-Point'), findsOneWidget);
    });

    testWidgets('displays status chip correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(testTable10Point));

      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('displays occupancy chip correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(testTable10Point));

      expect(find.text('2/4'), findsOneWidget);
    });

    testWidgets('shows quick join button for open table with available seats', (tester) async {
      bool quickJoinCalled = false;
      await tester.pumpWidget(createTestWidget(
        testTable10Point,
        onQuickJoin: () => quickJoinCalled = true,
      ));

      expect(find.text('Quick Join'), findsOneWidget);
      
      await tester.tap(find.text('Quick Join'));
      expect(quickJoinCalled, isTrue);
    });

    testWidgets('does not show quick join button for full table', (tester) async {
      await tester.pumpWidget(createTestWidget(
        testTableFull,
        onQuickJoin: () {},
      ));

      expect(find.text('Quick Join'), findsNothing);
    });

    testWidgets('shows correct icon for playing table', (tester) async {
      await tester.pumpWidget(createTestWidget(testTablePlaying));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsNothing);
    });

    testWidgets('shows View button for playing table', (tester) async {
      await tester.pumpWidget(createTestWidget(testTablePlaying));

      expect(find.text('View'), findsOneWidget);
    });

    testWidgets('shows Join button for open table', (tester) async {
      await tester.pumpWidget(createTestWidget(testTable10Point));

      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets('displays playing status correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(testTablePlaying));

      expect(find.text('PLAYING'), findsOneWidget);
    });
  });
}