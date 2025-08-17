import 'package:flutter/foundation.dart';

class SettingsStore extends ChangeNotifier {
  bool _showHints = true;
  bool _soundsEnabled = false; // Off by default
  String _defaultVariant = '10_point';

  bool get showHints => _showHints;
  bool get soundsEnabled => _soundsEnabled;
  String get defaultVariant => _defaultVariant;

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