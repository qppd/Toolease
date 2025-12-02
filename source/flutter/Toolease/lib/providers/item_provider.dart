import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import 'database_provider.dart';

final allItemsProvider = FutureProvider<List<Item>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllItems();
});

// Temporarily disabled - needs refactoring for per-unit system
// final itemsByStorageProvider = FutureProvider.family<List<Item>, int>((ref, storageId) async {
//   final databaseService = ref.watch(databaseServiceProvider);
//   return await databaseService.getItemsByStorage(storageId);
// });

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

  Future<void> addItem({
    required String toolName,
    required String model,
    required String productNo,
    required String serialNo,
    String? remarks,
    required String year,
    int? storageId,
  }) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final item = Item(
        id: 0, // Will be set by auto-increment
        toolName: toolName,
        model: model,
        productNo: productNo,
        serialNo: serialNo,
        remarks: remarks,
        year: year,
        status: ItemStatus.available,
        storageId: storageId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await databaseService.insertItem(item);
      await refreshItems();
      _ref.invalidate(allItemsProvider);
      // _ref.invalidate(itemsByStorageProvider); // Disabled
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateItem({
    required int itemId,
    required String toolName,
    required String model,
    required String productNo,
    String? remarks,
    required String year,
    required ItemStatus status,
    int? storageId,
    required DateTime createdAt,
  }) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      // Get existing item to preserve serialNo
      final existingItem = await databaseService.getItemById(itemId);
      if (existingItem == null) {
        throw Exception('Item not found');
      }
      
      final item = Item(
        id: itemId,
        toolName: toolName,
        model: model,
        productNo: productNo,
        serialNo: existingItem.serialNo, // Preserve serialNo - cannot change
        remarks: remarks,
        year: year,
        status: status,
        storageId: storageId,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
      await databaseService.updateItem(item);
      await refreshItems();
      _ref.invalidate(allItemsProvider);
      // _ref.invalidate(itemsByStorageProvider); // Disabled
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
  
  Future<Item?> getItemBySerialNo(String serialNo) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      return await databaseService.getItemBySerialNo(serialNo);
    } catch (error) {
      return null;
    }
  }
  
  Future<List<Item>> getAvailableItems() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      return await databaseService.getAvailableItems();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.deleteItem(itemId);
      await refreshItems();
      _ref.invalidate(allItemsProvider);
      // _ref.invalidate(itemsByStorageProvider); // Disabled
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}