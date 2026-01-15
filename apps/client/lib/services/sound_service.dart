import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService extends ChangeNotifier {
  static final SoundService _instance = SoundService._internal();

  factory SoundService() {
    return _instance;
  }

  SoundService._internal();

  final AudioPlayer _effectPlayer = AudioPlayer();
  // Keep multiple players for overlapping sounds if needed, but for now simple 1 player for effects
  // Actually for rapid effects like typing or rapid selection, we might need a pool or allow overlap.
  // AudioPlayers 'mode' defaults to different behaviors. 
  
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  Future<void> playSound(String soundName, {double volume = 1.0}) async {
    if (_isMuted) return;

    try {
      // Re-creating player for overlapping sounds is a common pattern if play mode isn't enough,
      // but let's try just playing content.
      // Note: In newer AudioPlayers, we assume the file is in assets/sounds/
      // and we use AssetSource('sounds/$soundName.mp3')
      
      // For overlapping sounds (like rapid fire), it is often better to create a new player or use low latency mode
      // For this game, simple playback is likely fine. 
      // If we want overlap (e.g. quick successions), we might create a temporary player.
      
      final player = AudioPlayer();
      await player.play(
        AssetSource('sounds/$soundName.mp3', mimeType: 'audio/mpeg'),
        volume: volume,
      );
      // We rely on garbage collection or dispose when done... 
      // Actually AudioPlayer needs disposal.
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
      
    } catch (e) {
      if (kDebugMode) {
        print("Error playing sound $soundName: $e");
      }
    }
  }

  // Pre-refined list of sounds
  static const String correct = 'correct';
  static const String wrong = 'wrong';
  static const String tick = 'tick';
  static const String victory = 'victory';
  static const String fiasco = 'fiasco';
  static const String gameOver = 'game_over';
  static const String select = 'select';
  static const String reveal = 'reveal';
  static const String trophy = 'trophy';
  static const String explosion = 'explosion';
}
