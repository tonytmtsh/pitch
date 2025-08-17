import 'package:flutter/foundation.dart';

/// Store for user interface settings and preferences
class SettingsStore extends ChangeNotifier {
  bool _showCardHints = true;

  /// Whether to show legal card hints and tooltips
  bool get showCardHints => _showCardHints;

  /// Toggle the card hints visibility
  void toggleCardHints() {
    _showCardHints = !_showCardHints;
    notifyListeners();
  }

  /// Set the card hints visibility
  void setCardHints(bool enabled) {
    if (_showCardHints == enabled) return;
    _showCardHints = enabled;
    notifyListeners();
  }
}