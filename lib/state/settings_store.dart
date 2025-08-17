import 'package:flutter/foundation.dart';

class SettingsStore extends ChangeNotifier {
  // Settings with defaults
  bool _showHints = true;
  bool _soundsEnabled = false;
  String _defaultVariant = '10_point';

  // Getters
  bool get showHints => _showHints;
  bool get soundsEnabled => _soundsEnabled;
  String get defaultVariant => _defaultVariant;

  // Setters that notify listeners
  void setShowHints(bool value) {
    if (_showHints == value) return;
    _showHints = value;
    notifyListeners();
  }

  void setSoundsEnabled(bool value) {
    if (_soundsEnabled == value) return;
    _soundsEnabled = value;
    notifyListeners();
  }

  void setDefaultVariant(String value) {
    if (_defaultVariant == value) return;
    _defaultVariant = value;
    notifyListeners();
  }
}