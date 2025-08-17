import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/ui/widgets/card_fan.dart';
import 'package:pitch/ui/widgets/playing_card.dart';

void main() {
  group('CardFan Widget Tests', () {
    testWidgets('renders empty fan when no children provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardFan(children: []),
          ),
        ),
      );

      expect(find.byType(CardFan), findsOneWidget);
      // Should render but be empty
      final cardFan = tester.widget<CardFan>(find.byType(CardFan));
      expect(cardFan.children.isEmpty, true);
    });

    testWidgets('renders cards in fan layout', (WidgetTester tester) async {
      final cards = [
        const PlayingCardView(code: 'AS', width: 64),
        const PlayingCardView(code: 'KH', width: 64),
        const PlayingCardView(code: 'QD', width: 64),
        const PlayingCardView(code: 'JC', width: 64),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardFan(children: cards),
          ),
        ),
      );

      expect(find.byType(CardFan), findsOneWidget);
      expect(find.byType(PlayingCardView), findsNWidgets(4));
      
      // Check that all cards are rendered
      expect(find.text('A'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
      expect(find.text('Q'), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('handles single card correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardFan(
              children: [
                PlayingCardView(code: 'AS', width: 64),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CardFan), findsOneWidget);
      expect(find.byType(PlayingCardView), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('respects custom card width parameter', (WidgetTester tester) async {
      const customWidth = 80.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardFan(
              cardWidth: customWidth,
              children: [
                PlayingCardView(code: 'AS', width: customWidth),
              ],
            ),
          ),
        ),
      );

      final cardFan = tester.widget<CardFan>(find.byType(CardFan));
      expect(cardFan.cardWidth, customWidth);
    });

    testWidgets('scales responsively on narrow screens', (WidgetTester tester) async {
      // Set a narrow screen size
      await tester.binding.setSurfaceSize(const Size(300, 600));
      
      final cards = List.generate(6, (i) => 
        PlayingCardView(code: '${i + 1}H', width: 64)
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardFan(children: cards),
          ),
        ),
      );

      expect(find.byType(CardFan), findsOneWidget);
      expect(find.byType(PlayingCardView), findsNWidgets(6));
      
      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });
  });
}