import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/state/settings_store.dart';
import 'package:pitch/ui/settings_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  group('SettingsSheet', () {
    testWidgets('displays all settings controls', (WidgetTester tester) async {
      final settingsStore = SettingsStore();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsStore>.value(
            value: settingsStore,
            child: Scaffold(
              body: const SettingsSheet(),
            ),
          ),
        ),
      );

      // Check that all settings are displayed
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Show legal hints'), findsOneWidget);
      expect(find.text('Sounds'), findsOneWidget);
      expect(find.text('Default variant'), findsOneWidget);

      // Check default states
      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('updates settings when controls are tapped', (WidgetTester tester) async {
      final settingsStore = SettingsStore();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsStore>.value(
            value: settingsStore,
            child: Scaffold(
              body: const SettingsSheet(),
            ),
          ),
        ),
      );

      // Find the hints switch and tap it
      final hintsSwitch = find.byType(Switch).first;
      await tester.tap(hintsSwitch);
      await tester.pump();

      // Verify the setting was changed
      expect(settingsStore.showHints, false);

      // Find the sounds switch and tap it  
      final soundsSwitch = find.byType(Switch).last;
      await tester.tap(soundsSwitch);
      await tester.pump();

      // Verify the setting was changed
      expect(settingsStore.soundsEnabled, true);
    });

    testWidgets('dropdown shows correct variant values', (WidgetTester tester) async {
      final settingsStore = SettingsStore();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsStore>.value(
            value: settingsStore,
            child: Scaffold(
              body: const SettingsSheet(),
            ),
          ),
        ),
      );

      // Verify the dropdown shows the correct default value
      expect(find.text('10-point'), findsOneWidget);
    });
  });
}