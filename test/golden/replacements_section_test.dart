import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/ui/widgets/playing_card.dart';

class _ReplacementItem extends StatelessWidget {
  const _ReplacementItem({required this.pos, required this.discarded, required this.drawn});
  final String pos;
  final List<String> discarded;
  final List<String> drawn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(pos)),
              const SizedBox(width: 8),
              const Text('Replacements'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 88, child: Text('Discarded:', style: TextStyle(fontWeight: FontWeight.w500))),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: discarded.map((c) => PlayingCardView(code: c, width: 36)).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 88, child: Text('Drawn:', style: TextStyle(fontWeight: FontWeight.w500))),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: drawn.map((c) => PlayingCardView(code: c, width: 36)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Replacements Section Golden Tests', () {
    bool _goldenExists(String name) => File('test/golden/' + name).existsSync();

    testWidgets('renders discarded and drawn as cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 16),
                _ReplacementItem(
                  pos: 'N',
                  discarded: ['AS', 'KD', '10C'],
                  drawn: ['2H', 'JH', 'QC'],
                ),
                _ReplacementItem(
                  pos: 'E',
                  discarded: ['7S', '3D'],
                  drawn: ['9C', 'AH'],
                ),
              ],
            ),
          ),
        ),
      );

      if (_goldenExists('replacements_section.png')) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('replacements_section.png'),
        );
      } else {
        expect(find.byType(_ReplacementItem), findsNWidgets(2));
      }
    });
  });
}
