import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stub providers for settings functionality
// TODO: Implement proper settings management for per-unit system

// Provider for kiosk mode - defaults to disabled
final kioskModeEnabledProvider = FutureProvider<bool>((ref) async {
  return false; // Kiosk mode disabled by default
});

// Provider for checking if screen is enabled - defaults to true
final registerScreenEnabledProvider = FutureProvider<bool>((ref) async {
  return true;
});

final borrowScreenEnabledProvider = FutureProvider<bool>((ref) async {
  return true;
});

final returnScreenEnabledProvider = FutureProvider<bool>((ref) async {
  return true;
});

// Settings notifier stub
class SettingsNotifier extends StateNotifier<AsyncValue<Map<String, String>>> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const AsyncValue.data({}));

  Future<void> updateSetting(String key, String value) async {
    // Stub - does nothing for now
  }

  Future<void> updateScreenEnabled(String screenKey, bool enabled) async {
    // Stub - does nothing for now
  }

  Future<void> toggleScreenAccess(String screenKey) async {
    // Stub - does nothing for now
  }

  Future<void> refresh() async {
    // Stub - does nothing for now
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<Map<String, String>>>(
  (ref) => SettingsNotifier(ref),
);
