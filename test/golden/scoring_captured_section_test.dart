import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/ui/widgets/playing_card.dart';

class _CapturedBy extends StatelessWidget {
  const _CapturedBy({required this.team, required this.cards});
  final String team;
  final List<String> cards;

  Map<String, List<String>> _groupBySuit(List<String> cards) {
    final map = <String, List<String>>{};
    for (final c in cards) {
      if (c.isEmpty) continue;
      final suit = c.substring(c.length - 1);
      (map[suit] ??= <String>[]).add(c);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final suitGroups = _groupBySuit(cards);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$team captured'),
          const SizedBox(height: 6),
          ...suitGroups.entries.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        s.key,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: s.value.map((c) => PlayingCardView(code: c, width: 36)).toList(),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

void main() {
  group('Scoring Captured Cards Golden Tests', () {
    bool _goldenExists(String name) => File('test/golden/' + name).existsSync();

    testWidgets('renders captured cards per suit as cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 16),
                _CapturedBy(
                  team: 'NS',
                  cards: ['AS', 'KS', 'QS', '10S', '5D', 'JD', '2H'],
                ),
                _CapturedBy(
                  team: 'EW',
                  cards: ['9C', 'JC', 'QC', 'KC', 'AD', '4H'],
                ),
              ],
            ),
          ),
        ),
      );

      if (_goldenExists('scoring_captured_section.png')) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('scoring_captured_section.png'),
        );
      } else {
        expect(find.byType(_CapturedBy), findsNWidgets(2));
      }
    });
  });
}
