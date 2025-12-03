import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../models/setting.dart';

// Provider for kiosk mode - reads from database
final kioskModeEnabledProvider = FutureProvider<bool>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.isScreenEnabled(SettingKeys.enableKioskMode);
});

// Provider for checking if register screen is enabled
final registerScreenEnabledProvider = FutureProvider<bool>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.isScreenEnabled(SettingKeys.enableRegister);
});

// Provider for checking if borrow screen is enabled
final borrowScreenEnabledProvider = FutureProvider<bool>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.isScreenEnabled(SettingKeys.enableBorrow);
});

// Provider for checking if return screen is enabled
final returnScreenEnabledProvider = FutureProvider<bool>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.isScreenEnabled(SettingKeys.enableReturn);
});

// Settings notifier - manages all settings with database persistence
class SettingsNotifier extends StateNotifier<AsyncValue<Map<String, String>>> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final dbService = _ref.read(databaseServiceProvider);
      final settings = await dbService.getAllSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSetting(String key, String value) async {
    try {
      final dbService = _ref.read(databaseServiceProvider);
      await dbService.updateSetting(key, value);
      await refresh();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateScreenEnabled(String screenKey, bool enabled) async {
    await updateSetting(screenKey, enabled.toString());
  }

  Future<void> toggleScreenAccess(String screenKey) async {
    final currentSettings = state.value ?? {};
    final currentValue = currentSettings[screenKey] ?? 'true';
    final newValue = currentValue.toLowerCase() == 'true' ? 'false' : 'true';
    await updateSetting(screenKey, newValue);
  }

  Future<void> refresh() async {
    await _loadSettings();
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<Map<String, String>>>(
  (ref) => SettingsNotifier(ref),
);
