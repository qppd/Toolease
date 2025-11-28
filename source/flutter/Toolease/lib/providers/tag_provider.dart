import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import 'database_provider.dart';

final allTagsProvider = FutureProvider<List<Tag>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllTags();
});

final tagNotifierProvider = StateNotifierProvider<TagNotifier, AsyncValue<List<Tag>>>(
  (ref) => TagNotifier(ref),
);

class TagNotifier extends StateNotifier<AsyncValue<List<Tag>>> {
  final Ref _ref;

  TagNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final tags = await databaseService.getAllTags();
      state = AsyncValue.data(tags);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshTags() async {
    state = const AsyncValue.loading();
    await _loadTags();
  }

  Future<void> addTag(Tag tag) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.insertTag(tag);
      await refreshTags();
      _ref.invalidate(allTagsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateTag(Tag tag) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.updateTag(tag);
      await refreshTags();
      _ref.invalidate(allTagsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTag(int tagId) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.deleteTag(tagId);
      await refreshTags();
      _ref.invalidate(allTagsProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}