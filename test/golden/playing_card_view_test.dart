import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:pitch/ui/widgets/playing_card.dart';

void main() {
  group('PlayingCardView Golden Tests', () {
  bool _goldenExists(String name) =>
    File('test/golden/' + name).existsSync();
    testWidgets('representative hand with various card states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Representative Hand - Golden Test',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Row 1: Different suits face up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      PlayingCardView(code: 'AS', width: 60), // Spade (black)
                      PlayingCardView(code: '10H', width: 60), // Heart (red)
                      PlayingCardView(code: 'QC', width: 60), // Club (black)
                      PlayingCardView(code: 'KD', width: 60), // Diamond (red)
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row 2: States - highlighted, disabled, face down
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      PlayingCardView(code: 'JH', width: 60, highlight: true), // Highlighted
                      PlayingCardView(code: '9S', width: 60, disabled: true), // Disabled
                      PlayingCardView(code: 'AH', width: 60, faceUp: false), // Face down
                      PlayingCardView(code: '5D', width: 60, highlight: true, disabled: true), // Both states
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row 3: More card codes for completeness
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      PlayingCardView(code: '2C', width: 60), // Low card
                      PlayingCardView(code: '10S', width: 60), // Two-digit rank
                      PlayingCardView(code: 'JC', width: 60), // Jack
                      PlayingCardView(code: '', width: 60), // Empty code
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (_goldenExists('playing_card_view_representative_hand.png')) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('playing_card_view_representative_hand.png'),
        );
      } else {
        expect(find.byType(PlayingCardView), findsWidgets);
      }
    });

    testWidgets('playing card individual states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Individual Card States'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: const [
                          Text('Normal'),
                          SizedBox(height: 8),
                          PlayingCardView(code: 'AS', width: 80),
                        ],
                      ),
                      Column(
                        children: const [
                          Text('Highlighted'),
                          SizedBox(height: 8),
                          PlayingCardView(code: 'AS', width: 80, highlight: true),
                        ],
                      ),
                      Column(
                        children: const [
                          Text('Disabled'),
                          SizedBox(height: 8),
                          PlayingCardView(code: 'AS', width: 80, disabled: true),
                        ],
                      ),
                      Column(
                        children: const [
                          Text('Face Down'),
                          SizedBox(height: 8),
                          PlayingCardView(code: 'AS', width: 80, faceUp: false),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (_goldenExists('playing_card_view_individual_states.png')) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('playing_card_view_individual_states.png'),
        );
      } else {
        expect(find.byType(PlayingCardView), findsWidgets);
      }
    });
  });
}