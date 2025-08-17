// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/main.dart';
import 'package:pitch/ui/widgets/lobby_table_card.dart';

void main() {
  testWidgets('Lobby renders with mock data and help button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Initial load shows progress indicator, then lists mock tables.
    expect(find.text('Pitch — Lobby (Mock)'), findsOneWidget);
    await tester.pumpAndSettle();

  // At least one table card should render; on default 800x600, grid shows 2 cards
  expect(find.byType(LobbyTableCard), findsWidgets);
  // A known first-row table name should be visible without scrolling
  expect(find.text('Casual 4-point'), findsOneWidget);
  // Occupancy chip displays as taken/total (e.g., 2/4)
  expect(find.textContaining('/4'), findsWidgets);
    
    // Verify help button is present
    expect(find.byTooltip('Rules & Help'), findsOneWidget);
  });
}
