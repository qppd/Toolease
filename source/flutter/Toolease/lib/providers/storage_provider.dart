import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/storage.dart';
import 'database_provider.dart';

final allStoragesProvider = FutureProvider<List<Storage>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllStorages();
});

final storageNotifierProvider = StateNotifierProvider<StorageNotifier, AsyncValue<List<Storage>>>(
  (ref) => StorageNotifier(ref),
);

class StorageNotifier extends StateNotifier<AsyncValue<List<Storage>>> {
  final Ref _ref;

  StorageNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadStorages();
  }

  Future<void> _loadStorages() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final storages = await databaseService.getAllStorages();
      state = AsyncValue.data(storages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshStorages() async {
    state = const AsyncValue.loading();
    await _loadStorages();
  }

  Future<void> addStorage(Storage storage) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.insertStorage(storage);
      await refreshStorages();
      _ref.invalidate(allStoragesProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStorage(Storage storage) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.updateStorage(storage);
      await refreshStorages();
      _ref.invalidate(allStoragesProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteStorage(int storageId) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.deleteStorage(storageId);
      await refreshStorages();
      _ref.invalidate(allStoragesProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}