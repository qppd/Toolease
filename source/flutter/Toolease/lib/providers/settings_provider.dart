import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/setting.dart';
import 'database_provider.dart';

// Provider for individual setting keys
final settingProvider = FutureProvider.family<String, String>((ref, key) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getSetting(key);
});

// Provider for checking if screen is enabled
final screenEnabledProvider = FutureProvider.family<bool, String>((ref, screenKey) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.isScreenEnabled(screenKey);
});

// Provider for all settings
final allSettingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllSettings();
});

// Settings notifier for updating settings
class SettingsNotifier extends StateNotifier<AsyncValue<Map<String, String>>> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final settings = await databaseService.getAllSettings();
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSetting(String key, String value) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.updateSetting(key, value);
      
      // Refresh the settings
      await _loadSettings();
      
      // Invalidate related providers to trigger refresh
      _ref.invalidate(settingProvider(key));
      _ref.invalidate(screenEnabledProvider(key));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleScreenAccess(String screenKey) async {
    final currentSettings = state.asData?.value ?? {};
    final currentValue = currentSettings[screenKey] ?? 'true';
    final newValue = currentValue.toLowerCase() == 'true' ? 'false' : 'true';
    await updateSetting(screenKey, newValue);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<Map<String, String>>>((ref) {
  return SettingsNotifier(ref);
});

// Convenience providers for specific screens
final registerScreenEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(screenEnabledProvider(SettingKeys.enableRegister).future);
});

final borrowScreenEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(screenEnabledProvider(SettingKeys.enableBorrow).future);
});

final returnScreenEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(screenEnabledProvider(SettingKeys.enableReturn).future);
});

final kioskModeEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(screenEnabledProvider(SettingKeys.enableKioskMode).future);
});