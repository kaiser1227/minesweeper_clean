import 'package:flutter/services.dart';

/// Direct Native Vibration & System Haptic controller.
/// Bypasses Android's silent system touch-feedback flag when in-game vibration is enabled,
/// ensuring high-fidelity tactile feedback for all mobile devices.
class HapticController {
  bool enabled;
  static const MethodChannel _nativeChannel =
      MethodChannel('minesweeper/vibration');

  HapticController({this.enabled = true});

  void lightImpact() {
    if (!enabled) return;
    _invokeNativeVibrate(duration: 25, amplitude: 80, fallback: HapticFeedback.lightImpact);
  }

  void mediumImpact() {
    if (!enabled) return;
    _invokeNativeVibrate(duration: 50, amplitude: 160, fallback: HapticFeedback.mediumImpact);
  }

  void heavyImpact() {
    if (!enabled) return;
    _invokeNativeVibrate(duration: 160, amplitude: 255, fallback: HapticFeedback.heavyImpact);
  }

  void selectionClick() {
    if (!enabled) return;
    _invokeNativeVibrate(duration: 18, amplitude: 90, fallback: HapticFeedback.selectionClick);
  }

  void victoryPattern() async {
    if (!enabled) return;
    try {
      await _nativeChannel.invokeMethod('pattern', {
        'timings': [0, 80, 80, 150, 100, 70],
        'amplitudes': [0, 140, 0, 255, 0, 120],
      });
    } catch (_) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.lightImpact();
    }
  }

  void _invokeNativeVibrate({
    required int duration,
    required int amplitude,
    required VoidCallback fallback,
  }) async {
    try {
      await _nativeChannel.invokeMethod('vibrate', {
        'duration': duration,
        'amplitude': amplitude,
      });
    } catch (_) {
      fallback();
    }
  }
}
