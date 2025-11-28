import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

class KioskService {
  static bool _isKioskModeActive = false;

  static bool get isKioskModeActive => _isKioskModeActive;

  static Future<void> enableKioskMode() async {
    try {
      await startKioskMode();
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      _isKioskModeActive = true;
    } catch (e) {
      print('Error enabling kiosk mode: $e');
    }
  }

  static Future<void> disableKioskMode() async {
    try {
      await stopKioskMode();
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _isKioskModeActive = false;
    } catch (e) {
      print('Error disabling kiosk mode: $e');
    }
  }

  static Future<void> toggleKioskMode(bool enabled) async {
    if (enabled && !_isKioskModeActive) {
      await enableKioskMode();
    } else if (!enabled && _isKioskModeActive) {
      await disableKioskMode();
    }
  }

  static Future<void> initializeKioskMode(bool enabled) async {
    if (enabled) {
      await enableKioskMode();
    }
  }
}