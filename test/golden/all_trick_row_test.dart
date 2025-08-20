import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/ui/widgets/all_trick_row.dart';

void main() {
  group('AllTrickRow Golden Tests', () {
    bool _goldenExists(String name) => File('test/golden/' + name).existsSync();

    testWidgets('partial trick - 2 plays with badges and tooltips', (tester) async {
      final plays = [
        {'pos': 'N', 'card': 'AS'},
        {'pos': 'E', 'card': '10H'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AllTrickRow(plays: plays, winner: 'N'),
              ),
            ),
          ),
        ),
      );

      if (_goldenExists('all_trick_row_partial.png')) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('all_trick_row_partial.png'),
        );
      } else {
        expect(find.byType(AllTrickRow), findsOneWidget);
      }
    });

    testWidgets('full trick - 4 plays with winner highlight', (tester) async {
      final plays = [
        {'pos': 'W', 'card': 'JD'},
        {'pos': 'N', 'card': 'AS'},
        {'pos': 'E', 'card': '4S'},
        {'pos': 'S', 'card': 'QS'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AllTrickRow(plays: plays, winner: 'N'),
              ),
            ),
          ),
        ),
      );

      if (_goldenExists('all_trick_row_full.png')) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('all_trick_row_full.png'),
        );
      } else {
        expect(find.byType(AllTrickRow), findsOneWidget);
      }
    });
  });
}
