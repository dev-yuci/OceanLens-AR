import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // Singleton instance
  static final AudioService instance = AudioService._internal();

  AudioService._internal();

  // Map of audio players per channel to support simultaneous sound effects
  final Map<String, AudioPlayer> _players = {};

  void _play(String filename, {required String channel}) async {
    try {
      final player = _players.putIfAbsent(channel, () => AudioPlayer());
      // Stop currently playing sound on this channel before triggering again
      await player.stop();
      await player.play(AssetSource('sounds/$filename'));
    } catch (e) {
      debugPrint('AudioService error playing $filename on channel $channel: $e');
    }
  }

  /// Plays a short button click sound effect
  void playClick() => _play('click.wav', channel: 'ui');

  /// Plays a bubble pop/eat sound effect when a fish is consumed
  void playEat() => _play('eat.wav', channel: 'game_eat');

  /// Plays a sad falling thud sound effect when player dies
  void playDie() => _play('die.wav', channel: 'game_die');

  /// Plays a cheerful chime sound effect for correct quiz answers
  void playCorrect() => _play('correct.wav', channel: 'quiz');

  /// Plays a low buzz sound effect for wrong quiz answers
  void playWrong() => _play('wrong.wav', channel: 'quiz');

  /// Plays looping background audio on a dedicated 'bgm' channel
  void playBackground(String filename) async {
    try {
      final player = _players.putIfAbsent('bgm', () => AudioPlayer());
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('sounds/$filename'));
    } catch (e) {
      debugPrint('AudioService error playing bgm $filename: $e');
    }
  }

  /// Stops background audio
  void stopBackground() async {
    try {
      final player = _players['bgm'];
      if (player != null) {
        await player.stop();
      }
    } catch (e) {
      debugPrint('AudioService error stopping bgm: $e');
    }
  }

  /// Disposes all audio players to release resources
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
