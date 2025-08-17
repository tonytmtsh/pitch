import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for managing game sound effects.
/// Handles audio playback with graceful fallback for permission issues.
class SoundService extends ChangeNotifier {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = false; // Default OFF as per requirements
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;

  /// Initialize the sound service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Set audio mode for web compatibility
      if (kIsWeb) {
        await _player.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            defaultToSpeaker: true,
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.defaultToSpeaker,
            ],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
        ));
      }
      _initialized = true;
    } catch (e) {
      // Graceful fallback - continue without audio
      if (kDebugMode) {
        print('SoundService initialization failed: $e');
      }
    }
  }

  /// Toggle sound on/off
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
  }

  /// Play card play sound
  Future<void> playCardPlay() async {
    if (!_soundEnabled) return;
    await _playSound('card_play.wav');
  }

  /// Play trick win sound
  Future<void> playTrickWin() async {
    if (!_soundEnabled) return;
    await _playSound('trick_win.wav');
  }

  /// Play invalid tap sound
  Future<void> playInvalidTap() async {
    if (!_soundEnabled) return;
    await _playSound('invalid_tap.wav');
  }

  /// Internal method to play a sound file
  Future<void> _playSound(String filename) async {
    if (!_initialized) await initialize();
    
    try {
      // Stop any currently playing sound
      await _player.stop();
      
      // Play the sound from assets
      await _player.play(AssetSource('sounds/$filename'));
    } catch (e) {
      // Graceful fallback - continue without audio
      if (kDebugMode) {
        print('Failed to play sound $filename: $e');
      }
    }
  }

  /// Cleanup resources
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}