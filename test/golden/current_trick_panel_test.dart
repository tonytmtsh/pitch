import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pitch/ui/widgets/playing_card.dart';
import 'package:pitch/services/pitch_service.dart';
import 'package:pitch/state/table_store.dart';

// Mock TableStore for testing CurrentTrickPanel
class MockTableStore extends ChangeNotifier {
  TrickSnapshot? _currentTrick;
  String? _currentTurnPos;

  TrickSnapshot? get currentTrick => _currentTrick;
  String? get currentTurnPos => _currentTurnPos;

  void setCurrentTrick(TrickSnapshot? trick, String? turnPos) {
    _currentTrick = trick;
    _currentTurnPos = turnPos;
    notifyListeners();
  }
}

// Simplified CurrentTrickPanel widget for testing
class CurrentTrickPanel extends StatelessWidget {
  const CurrentTrickPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MockTableStore>();
    final t = store.currentTrick;
    if (t == null) return const SizedBox.shrink();
    
    final plays = {for (final p in t.plays) p['pos']!: p['card']!};
    final turnPos = store.currentTurnPos;

    Widget seat(String pos) {
      final card = plays[pos];
      final style = TextStyle(
        fontWeight: turnPos == pos ? FontWeight.bold : FontWeight.normal,
        color: turnPos == pos ? Colors.teal : null,
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pos, style: style),
          const SizedBox(height: 4),
          if (card != null)
            PlayingCardView(code: card, width: 56)
          else
            Container(
              width: 56,
              height: 56 * 1.4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('—'),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Center(child: seat('N')),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              seat('W'),
              seat('E'),
            ],
          ),
          const SizedBox(height: 8),
          Center(child: seat('S')),
        ],
      ),
    );
  }
}

void main() {
  group('Current Trick Panel Golden Tests', () {
    testWidgets('trick in progress with highlight states', (tester) async {
      final mockStore = MockTableStore();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<MockTableStore>.value(
          value: mockStore,
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.grey[50],
              body: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text('Current Trick Panel - Golden Test',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const CurrentTrickPanel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test case 1: Partial trick - N and E have played, S's turn
      final partialTrick = TrickSnapshot(
        1, 
        'N', 
        [
          {'pos': 'N', 'card': 'AS'},
          {'pos': 'E', 'card': '10H'},
        ], 
        'N', // winner (placeholder, not determined yet)
        false, // not last trick
      );
      
      mockStore.setCurrentTrick(partialTrick, 'S'); // S's turn (should be highlighted)
      await tester.pump();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('current_trick_panel_partial_trick.png'),
      );

      // Test case 2: Full trick completed
      final completeTrick = TrickSnapshot(
        2, 
        'W', 
        [
          {'pos': 'W', 'card': 'JD'},
          {'pos': 'N', 'card': 'AS'},
          {'pos': 'E', 'card': '4S'},
          {'pos': 'S', 'card': 'QS'},
        ], 
        'N', // winner
        false, // not last trick
      );
      
      mockStore.setCurrentTrick(completeTrick, null); // No current turn
      await tester.pump();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('current_trick_panel_complete_trick.png'),
      );
    });

    testWidgets('different turn highlight positions', (tester) async {
      final mockStore = MockTableStore();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<MockTableStore>.value(
          value: mockStore,
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Turn Highlights - Golden Test'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const CurrentTrickPanel(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Test case: Only W has played, N's turn
      final trickNorthTurn = TrickSnapshot(
        1, 
        'W', 
        [
          {'pos': 'W', 'card': 'KD'},
        ], 
        'W', // placeholder winner
        false, // not last trick
      );
      
      mockStore.setCurrentTrick(trickNorthTurn, 'N'); // N's turn
      await tester.pump();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('current_trick_panel_north_turn.png'),
      );
    });

    testWidgets('empty trick state', (tester) async {
      final mockStore = MockTableStore();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<MockTableStore>.value(
          value: mockStore,
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Column(
                children: [
                  const Text('Empty Trick - Golden Test'),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    child: const CurrentTrickPanel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // No trick set - should show nothing
      mockStore.setCurrentTrick(null, null);
      await tester.pump();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('current_trick_panel_empty.png'),
      );
    });
  });
}