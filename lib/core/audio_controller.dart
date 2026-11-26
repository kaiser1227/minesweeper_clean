import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioController {
  bool enabled;
  final AudioPlayer _player = AudioPlayer();

  AudioController({this.enabled = true}) {
    _initPlayer();
  }

  void _initPlayer() {
    try {
      _player.setReleaseMode(ReleaseMode.stop);
      _player.setVolume(0.85);
    } catch (_) {
      // Graceful fallback
    }
  }

  Future<void> _playAsset(String fileName) async {
    if (!enabled) return;
    try {
      // audio assets are located in assets/audio/
      await _player.stop();
      await _player.play(AssetSource('audio/$fileName'));
    } catch (_) {
      // Fallback to system click if asset playback is unavailable
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void playClick() => _playAsset('click.wav');
  void playFlag() => _playAsset('flag.wav');
  void playUnflag() => _playAsset('unflag.wav');
  void playCascade() => _playAsset('cascade.wav');
  void playHint() => _playAsset('hint.wav');
  void playWin() => _playAsset('win.wav');
  void playExplode() => _playAsset('explode.wav');

  void dispose() {
    try {
      _player.dispose();
    } catch (_) {}
  }
}
