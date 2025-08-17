import 'package:flutter/foundation.dart';
import '../services/sound_service.dart';

/// Store for managing user settings and preferences
class SettingsStore extends ChangeNotifier {
  static final SettingsStore _instance = SettingsStore._internal();
  factory SettingsStore() => _instance;
  SettingsStore._internal();

  final SoundService _soundService = SoundService();

  /// Get current sound enabled state
  bool get soundEnabled => _soundService.soundEnabled;

  /// Initialize the settings store
  Future<void> initialize() async {
    await _soundService.initialize();
    // Listen to sound service changes
    _soundService.addListener(_onSoundServiceChanged);
  }

  /// Toggle sound on/off
  void setSoundEnabled(bool enabled) {
    _soundService.setSoundEnabled(enabled);
  }

  void _onSoundServiceChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _soundService.removeListener(_onSoundServiceChanged);
    super.dispose();
  }
}