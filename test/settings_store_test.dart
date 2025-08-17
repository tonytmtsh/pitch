import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/state/settings_store.dart';

void main() {
  group('SettingsStore', () {
    test('should default to showing card hints', () {
      final store = SettingsStore();
      expect(store.showCardHints, true);
    });

    test('should toggle card hints', () {
      final store = SettingsStore();
      expect(store.showCardHints, true);
      
      store.toggleCardHints();
      expect(store.showCardHints, false);
      
      store.toggleCardHints();
      expect(store.showCardHints, true);
    });

    test('should set card hints value', () {
      final store = SettingsStore();
      
      store.setCardHints(false);
      expect(store.showCardHints, false);
      
      store.setCardHints(true);
      expect(store.showCardHints, true);
    });
  });
}