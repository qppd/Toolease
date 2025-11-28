import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import 'database_provider.dart';

final allItemsProvider = FutureProvider<List<Item>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllItems();
});

final itemsByStorageProvider = FutureProvider.family<List<Item>, int>((ref, storageId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getItemsByStorage(storageId);
});

final itemNotifierProvider = StateNotifierProvider<ItemNotifier, AsyncValue<List<Item>>>(
  (ref) => ItemNotifier(ref),
);

class ItemNotifier extends StateNotifier<AsyncValue<List<Item>>> {
  final Ref _ref;

  ItemNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final items = await databaseService.getAllItems();
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshItems() async {
    state = const AsyncValue.loading();
    await _loadItems();
  }

  Future<void> addItem(Item item) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.insertItem(item);
      await refreshItems();
      _ref.invalidate(allItemsProvider);
      _ref.invalidate(itemsByStorageProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateItem(Item item) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.updateItem(item);
      await refreshItems();
      _ref.invalidate(allItemsProvider);
      _ref.invalidate(itemsByStorageProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.deleteItem(itemId);
      await refreshItems();
      _ref.invalidate(allItemsProvider);
      _ref.invalidate(itemsByStorageProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}