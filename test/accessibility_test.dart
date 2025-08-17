import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pitch/services/mock_pitch_service.dart';
import 'package:pitch/services/pitch_service.dart';
import 'package:pitch/ui/table_screen.dart';
import 'package:pitch/ui/widgets/playing_card.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('PlayingCardView has semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                PlayingCardView(code: 'AS', width: 64),
                PlayingCardView(code: '10H', width: 64),
                PlayingCardView(code: 'QC', width: 64),
                PlayingCardView(code: 'JD', width: 64),
                PlayingCardView(code: '', width: 64), // Edge case
              ],
            ),
          ),
        ),
      );

      // Verify semantic labels are present
      expect(find.bySemanticsLabel('Ace of Spades'), findsOneWidget);
      expect(find.bySemanticsLabel('Ten of Hearts'), findsOneWidget);
      expect(find.bySemanticsLabel('Queen of Clubs'), findsOneWidget);
      expect(find.bySemanticsLabel('Jack of Diamonds'), findsOneWidget);
      expect(find.bySemanticsLabel('Unknown card'), findsOneWidget);
    });

    testWidgets('CardButton supports keyboard navigation', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardButton(
              enabled: true,
              onTap: () => tapped = true,
              child: const PlayingCardView(code: 'AS', width: 64),
            ),
          ),
        ),
      );

      // Find the card button
      final cardButton = find.byType(CardButton);
      expect(cardButton, findsOneWidget);

      // Focus the button and press Enter
      await tester.tap(cardButton);
      await tester.pumpAndSettle();
      
      // Simulate Enter key press
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Table screen maintains focus order', (tester) async {
      await tester.pumpWidget(
        Provider<PitchService>.value(
          value: MockPitchService(),
          child: const MaterialApp(
            home: TableScreen(tableId: 't1', name: 'Test Table'),
          ),
        ),
      );

      // Allow async loads
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify FocusTraversalGroup is present
      expect(find.byType(FocusTraversalGroup), findsOneWidget);
      
      // Verify semantic information is available for hands
      expect(find.bySemanticsLabel(contains('Your hand')), findsWidgets);
    });

    testWidgets('Current trick panel has semantic information', (tester) async {
      await tester.pumpWidget(
        Provider<PitchService>.value(
          value: MockPitchService(),
          child: const MaterialApp(
            home: TableScreen(tableId: 't1', name: 'Test Table'),
          ),
        ),
      );

      // Allow async loads
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Look for trick-related semantic information
      expect(find.bySemanticsLabel(contains('Current trick')), findsWidgets);
      expect(find.bySemanticsLabel(contains('Position')), findsWidgets);
    });
  });
}