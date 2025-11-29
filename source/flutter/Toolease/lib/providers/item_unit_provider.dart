import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final itemUnitProvider = StateNotifierProvider<ItemUnitNotifier, AsyncValue<List<ItemUnit>>>(
  (ref) => ItemUnitNotifier(ref),
);

class ItemUnitNotifier extends StateNotifier<AsyncValue<List<ItemUnit>>> {
  final Ref _ref;

  ItemUnitNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadItemUnits();
  }

  Future<void> _loadItemUnits() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final itemUnits = await databaseService.getAllItemUnits();
      state = AsyncValue.data(itemUnits);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshItemUnits() async {
    state = const AsyncValue.loading();
    await _loadItemUnits();
  }

  Future<void> updateItemUnitRFID(int unitId, String rfid) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.updateItemUnitRFID(unitId, rfid);
      await refreshItemUnits();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}