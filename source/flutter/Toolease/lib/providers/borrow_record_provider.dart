import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/borrow_record.dart';
import 'database_provider.dart';

final allBorrowRecordsProvider = FutureProvider<List<BorrowRecord>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllBorrowRecords();
});

final activeBorrowRecordsCountProvider = FutureProvider<int>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getActiveBorrowRecordsCount();
});

final borrowRecordNotifierProvider = StateNotifierProvider<BorrowRecordNotifier, AsyncValue<List<BorrowRecord>>>(
  (ref) => BorrowRecordNotifier(ref),
);

final activeBorrowCountNotifierProvider = StateNotifierProvider<ActiveBorrowCountNotifier, AsyncValue<int>>(
  (ref) => ActiveBorrowCountNotifier(ref),
);

final recentBorrowRecordsProvider = FutureProvider<List<BorrowRecord>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getRecentBorrowRecords(5);
});

final recentBorrowRecordsNotifierProvider = StateNotifierProvider<RecentBorrowRecordsNotifier, AsyncValue<List<BorrowRecord>>>(
  (ref) => RecentBorrowRecordsNotifier(ref),
);

final recentBorrowRecordsWithNamesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getRecentBorrowRecordsWithStudentNames(5);
});

final recentBorrowRecordsWithNamesNotifierProvider = StateNotifierProvider<RecentBorrowRecordsWithNamesNotifier, AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => RecentBorrowRecordsWithNamesNotifier(ref),
);

class BorrowRecordNotifier extends StateNotifier<AsyncValue<List<BorrowRecord>>> {
  final Ref _ref;

  BorrowRecordNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadBorrowRecords();
  }

  Future<void> _loadBorrowRecords() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final borrowRecords = await databaseService.getAllBorrowRecords();
      state = AsyncValue.data(borrowRecords);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshBorrowRecords() async {
    state = const AsyncValue.loading();
    await _loadBorrowRecords();
  }
}

class ActiveBorrowCountNotifier extends StateNotifier<AsyncValue<int>> {
  final Ref _ref;

  ActiveBorrowCountNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadActiveBorrowCount();
  }

  Future<void> _loadActiveBorrowCount() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final count = await databaseService.getActiveBorrowRecordsCount();
      state = AsyncValue.data(count);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshActiveBorrowCount() async {
    state = const AsyncValue.loading();
    await _loadActiveBorrowCount();
  }
}

class RecentBorrowRecordsNotifier extends StateNotifier<AsyncValue<List<BorrowRecord>>> {
  final Ref _ref;

  RecentBorrowRecordsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadRecentBorrowRecords();
  }

  Future<void> _loadRecentBorrowRecords() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final recentRecords = await databaseService.getRecentBorrowRecords(5);
      state = AsyncValue.data(recentRecords);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshRecentBorrowRecords() async {
    state = const AsyncValue.loading();
    await _loadRecentBorrowRecords();
  }
}

class RecentBorrowRecordsWithNamesNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;

  RecentBorrowRecordsWithNamesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadRecentBorrowRecordsWithNames();
  }

  Future<void> _loadRecentBorrowRecordsWithNames() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final recentRecords = await databaseService.getRecentBorrowRecordsWithStudentNames(5);
      state = AsyncValue.data(recentRecords);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshRecentBorrowRecordsWithNames() async {
    state = const AsyncValue.loading();
    await _loadRecentBorrowRecordsWithNames();
  }
}