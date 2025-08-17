import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/ui/widgets/card_slide_animation.dart';
import 'package:pitch/ui/widgets/playing_card.dart';

void main() {
  group('Card Slide Animation', () {
    testWidgets('animation completes without error', (WidgetTester tester) async {
      final sourceKey = GlobalKey();
      final targetKey = GlobalKey();
      bool animationCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(
                  key: sourceKey,
                  child: const PlayingCardView(code: 'AS', width: 64),
                ),
                const SizedBox(height: 100),
                Container(
                  key: targetKey,
                  child: const PlayingCardView(code: 'AS', width: 56),
                ),
                ElevatedButton(
                  onPressed: () {
                    CardSlideAnimation.playCard(
                      context: sourceKey.currentContext!,
                      cardCode: 'AS',
                      sourceKey: sourceKey,
                      targetKey: targetKey,
                      duration: const Duration(milliseconds: 100), // Shorter for test
                      onComplete: () {
                        animationCompleted = true;
                      },
                    );
                  },
                  child: const Text('Animate'),
                ),
              ],
            ),
          ),
        ),
      );

      // Tap the button to trigger animation
      await tester.tap(find.text('Animate'));
      await tester.pump();

      // Pump frames during animation
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // Verify animation completed
      expect(animationCompleted, isTrue);
    });

    testWidgets('CardButton with animation parameters', (WidgetTester tester) async {
      final targetKey = GlobalKey();
      bool onTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(
                  key: targetKey,
                  width: 56,
                  height: 78,
                  color: Colors.blue,
                ),
                const SizedBox(height: 100),
                CardButton(
                  cardCode: 'AS',
                  targetKey: targetKey,
                  onTap: () {
                    onTapCalled = true;
                  },
                  child: const PlayingCardView(code: 'AS', width: 64),
                ),
              ],
            ),
          ),
        ),
      );

      // Tap the card button
      await tester.tap(find.byType(CardButton));
      await tester.pump();

      // Let the scale animation complete
      await tester.pump(const Duration(milliseconds: 80));

      // Let the slide animation complete
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Verify onTap was called (after animation)
      expect(onTapCalled, isTrue);
    });
  });
}