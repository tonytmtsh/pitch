// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/main.dart';

void main() {
  testWidgets('Lobby renders with mock data and help button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Initial load shows progress indicator, then lists mock tables.
    expect(find.text('Pitch — Lobby (Mock)'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Demo 10-point'), findsOneWidget);
    expect(find.textContaining('Seats'), findsWidgets);
    
    // Verify help button is present
    expect(find.byTooltip('Rules & Help'), findsOneWidget);
  });
}
