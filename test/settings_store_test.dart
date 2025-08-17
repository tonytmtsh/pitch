import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/state/settings_store.dart';

void main() {
  group('SettingsStore', () {
    late SettingsStore settingsStore;

    setUp(() {
      settingsStore = SettingsStore();
    });

    test('should have default values', () {
      expect(settingsStore.showHints, true);
      expect(settingsStore.soundsEnabled, false);
      expect(settingsStore.defaultVariant, '10_point');
    });

    test('should update showHints', () {
      settingsStore.setShowHints(false);
      expect(settingsStore.showHints, false);
    });

    test('should update soundsEnabled', () {
      settingsStore.setSoundsEnabled(true);
      expect(settingsStore.soundsEnabled, true);
    });

    test('should update defaultVariant', () {
      settingsStore.setDefaultVariant('4_point');
      expect(settingsStore.defaultVariant, '4_point');
    });

    test('should not notify listeners if value is same', () {
      bool notified = false;
      settingsStore.addListener(() => notified = true);
      
      settingsStore.setShowHints(true); // Same as default
      expect(notified, false);
    });

    test('should notify listeners when value changes', () {
      bool notified = false;
      settingsStore.addListener(() => notified = true);
      
      settingsStore.setShowHints(false); // Different from default
      expect(notified, true);
    });
  });
}