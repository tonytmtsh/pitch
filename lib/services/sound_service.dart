import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playCardSound() async {
    try {
      await _player.play(AssetSource('sounds/card_play.mp3'));
    } catch (e) {
      // Graceful fallback - sounds are optional
    }
  }

  Future<void> playTrickWinSound() async {
    try {
      await _player.play(AssetSource('sounds/trick_win.mp3'));
    } catch (e) {
      // Graceful fallback - sounds are optional
    }
  }

  Future<void> playInvalidSound() async {
    try {
      await _player.play(AssetSource('sounds/invalid.mp3'));
    } catch (e) {
      // Graceful fallback - sounds are optional
    }
  }

  void dispose() {
    _player.dispose();
  }
}