import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/database_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final database = ref.watch(databaseProvider);
  return DatabaseService(database);
});