import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playSuccessSound() async {
    try {
      // Using a public sound URL from Google Actions sounds library
      await _player.play(UrlSource('https://actions.google.com/sounds/v1/alarms/beep_short.ogg'));
    } catch (e) {
      debugPrint('AudioService Error: $e');
    }
  }
}
