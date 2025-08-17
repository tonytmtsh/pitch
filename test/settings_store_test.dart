import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/state/settings_store.dart';

void main() {
  group('SettingsStore', () {
    late SettingsStore settingsStore;

    setUp(() {
      settingsStore = SettingsStore();
    });

    test('should have correct default values', () {
      expect(settingsStore.showHints, true);
      expect(settingsStore.soundsEnabled, false);
      expect(settingsStore.defaultVariant, '10_point');
    });

    test('should update showHints and notify listeners', () {
      bool notified = false;
      settingsStore.addListener(() {
        notified = true;
      });

      settingsStore.setShowHints(false);

      expect(settingsStore.showHints, false);
      expect(notified, true);
    });

    test('should not notify listeners when setting same value for showHints', () {
      bool notified = false;
      settingsStore.addListener(() {
        notified = true;
      });

      settingsStore.setShowHints(true); // Same as default

      expect(settingsStore.showHints, true);
      expect(notified, false);
    });

    test('should update soundsEnabled and notify listeners', () {
      bool notified = false;
      settingsStore.addListener(() {
        notified = true;
      });

      settingsStore.setSoundsEnabled(true);

      expect(settingsStore.soundsEnabled, true);
      expect(notified, true);
    });

    test('should not notify listeners when setting same value for soundsEnabled', () {
      bool notified = false;
      settingsStore.addListener(() {
        notified = true;
      });

      settingsStore.setSoundsEnabled(false); // Same as default

      expect(settingsStore.soundsEnabled, false);
      expect(notified, false);
    });

    test('should update defaultVariant and notify listeners', () {
      bool notified = false;
      settingsStore.addListener(() {
        notified = true;
      });

      settingsStore.setDefaultVariant('4_point');

      expect(settingsStore.defaultVariant, '4_point');
      expect(notified, true);
    });

    test('should not notify listeners when setting same value for defaultVariant', () {
      bool notified = false;
      settingsStore.addListener(() {
        notified = true;
      });

      settingsStore.setDefaultVariant('10_point'); // Same as default

      expect(settingsStore.defaultVariant, '10_point');
      expect(notified, false);
    });
  });
}