import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticUtils {
  /// Light haptic feedback for selections (taps, chips)
  static Future<void> light() async {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium haptic feedback for important actions (save, mark visited)
  static Future<void> medium() async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy haptic feedback for critical actions (delete, complete)
  static Future<void> heavy() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Success vibration pattern (short double-tap feel)
  static Future<void> success() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: 50);
        await Future.delayed(const Duration(milliseconds: 50));
        await Vibration.vibrate(duration: 50);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Error vibration pattern (longer single vibration)
  static Future<void> error() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: 200);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Selection feedback for radio/checkbox/switch
  static Future<void> selection() async {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
