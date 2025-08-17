import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/ui/widgets/user_avatar.dart';

void main() {
  group('UserAvatar', () {
    testWidgets('should show empty seat icon when player is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(playerName: null),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should show player initials when player name provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(playerName: 'Alice Johnson'),
          ),
        ),
      );

      expect(find.text('AJ'), findsOneWidget);
    });

    testWidgets('should show "You" badge when isYou is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              playerName: 'Alice Johnson',
              isYou: true,
            ),
          ),
        ),
      );

      expect(find.text('You'), findsOneWidget);
      expect(find.text('AJ'), findsOneWidget);
    });

    testWidgets('should handle names with # format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(playerName: 'Alice#1001'),
          ),
        ),
      );

      expect(find.text('AL'), findsOneWidget);
    });

    testWidgets('should handle single names', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(playerName: 'Bob'),
          ),
        ),
      );

      expect(find.text('BO'), findsOneWidget);
    });
  });
}