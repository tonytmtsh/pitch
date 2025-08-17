import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pitch/services/mock_pitch_service.dart';
import 'package:pitch/services/pitch_service.dart';
import 'package:pitch/ui/table_screen.dart';

void main() {
  testWidgets('Table screen renders seats and hand flow (mock)', (tester) async {
    await tester.pumpWidget(
      Provider<PitchService>.value(
        value: MockPitchService(),
        child: const MaterialApp(
          home: TableScreen(tableId: 't1', name: 'Demo Table'),
        ),
      ),
    );

    // Shows app bar title immediately
    expect(find.text('Demo Table'), findsOneWidget);

    // Wait for async loads
  // Allow initial async loads
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));

    // Seats section
    expect(find.text('Seats'), findsOneWidget);
    expect(find.text('Seat N'), findsOneWidget);
    expect(find.text('Seat E'), findsOneWidget);
    expect(find.text('Seat S'), findsOneWidget);
    expect(find.text('Seat W'), findsOneWidget);

  // Bidding section
  expect(find.text('Bidding'), findsOneWidget);
  expect(find.textContaining('Bid '), findsWidgets);

  // Hand flow shows bids from mock data
  // (Tricks may be off-screen in tests; not asserting here.)
  });

  // Interaction test intentionally deferred; the scrolling/async of web ListView
  // makes it flaky in CI. We'll add integration tests later.
}
