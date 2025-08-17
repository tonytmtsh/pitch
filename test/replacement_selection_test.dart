import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pitch/services/mock_pitch_service.dart';
import 'package:pitch/services/pitch_service.dart';
import 'package:pitch/state/table_store.dart';
import 'package:pitch/ui/table_screen.dart';
import 'package:pitch/ui/widgets/playing_card.dart';

void main() {
  group('Replacement Selection UI', () {
    testWidgets('Shows card selection interface when replacements not locked', (tester) async {
      final mockService = MockPitchService();
      
      await tester.pumpWidget(
        Provider<PitchService>.value(
          value: mockService,
          child: const MaterialApp(
            home: TableScreen(tableId: 't1', name: 'Test Table'),
          ),
        ),
      );

      // Allow async loads to complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Should show replacements section
      expect(find.text('Replacements'), findsOneWidget);
      
      // Should show selection interface (text should appear when cards are loaded)
      expect(find.textContaining('Select cards'), findsOneWidget);
    });

    testWidgets('Card selection toggles correctly', (tester) async {
      final mockService = MockPitchService();
      final store = TableStore(mockService, 't1');
      
      // Simulate having cards in hand
      await store.refresh();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<TableStore>.value(
          value: store,
          child: Provider<PitchService>.value(
            value: mockService,
            child: const MaterialApp(
              home: Scaffold(
                body: _ReplacementSelectionTestWrapper(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Initially no cards should be selected
      expect(store.selectedCardsForDiscard.isEmpty, isTrue);
      
      // Test card selection (if cards are present)
      if (store.myCards.isNotEmpty) {
        final firstCard = store.myCards.first;
        
        // Simulate selecting a card
        store.toggleCardSelection(firstCard);
        await tester.pump();
        
        expect(store.selectedCardsForDiscard.contains(firstCard), isTrue);
        
        // Simulate deselecting the card
        store.toggleCardSelection(firstCard);
        await tester.pump();
        
        expect(store.selectedCardsForDiscard.contains(firstCard), isFalse);
      }
    });

    testWidgets('Request replacements flow works', (tester) async {
      final mockService = MockPitchService();
      final store = TableStore(mockService, 't1');
      
      await store.refresh();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<TableStore>.value(
          value: store,
          child: Provider<PitchService>.value(
            value: mockService,
            child: const MaterialApp(
              home: Scaffold(
                body: _ReplacementSelectionTestWrapper(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // If we have cards, test the replacement request flow
      if (store.myCards.isNotEmpty) {
        final testCard = store.myCards.first;
        
        // Select a card
        store.toggleCardSelection(testCard);
        await tester.pump();
        
        expect(store.selectedCardsForDiscard.contains(testCard), isTrue);
        
        // Request replacements
        store.requestReplacementsForSelected();
        await tester.pump();
        
        // Selection should be cleared
        expect(store.selectedCardsForDiscard.isEmpty, isTrue);
        
        // Should have pending replacement
        expect(store.hasReplacementInProgress, isTrue);
      }
    });

    testWidgets('Lock replacements flow works', (tester) async {
      final mockService = MockPitchService();
      final store = TableStore(mockService, 't1');
      
      await store.refresh();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<TableStore>.value(
          value: store,
          child: Provider<PitchService>.value(
            value: mockService,
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    _ReplacementSelectionTestWrapper(),
                    ElevatedButton(
                      onPressed: null, // Will be enabled by state
                      child: Text('Lock Replacements'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should start with replacements not locked
      expect(store.replacementsLocked, isFalse);
      
      // Test locking replacements
      await store.lockReplacementsNow();
      await tester.pump();
      
      // Mock service should return true, so replacements should be locked
      expect(store.replacementsLocked, isTrue);
    });
  });
}

// Helper widget to test the replacement selection without full table screen
class _ReplacementSelectionTestWrapper extends StatelessWidget {
  const _ReplacementSelectionTestWrapper();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    final myPos = store.mySeatPos;
    
    if (myPos == null || store.hasReplacementInProgress) {
      return const Text('No selection available');
    }

    return Column(
      children: [
        Text('Select cards to discard (Seat $myPos):'),
        if (store.myCards.isNotEmpty)
          Text('Cards available: ${store.myCards.length}'),
        if (store.selectedCardsForDiscard.isNotEmpty)
          Text('Selected: ${store.selectedCardsForDiscard.join(', ')}'),
      ],
    );
  }
}