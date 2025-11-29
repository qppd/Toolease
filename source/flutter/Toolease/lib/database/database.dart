import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Students, Storages, Items, BorrowRecords, BorrowItems, BorrowItemConditions, Settings, Tags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 3) {
            // Add serialNo column to Items table
            await m.addColumn(items, items.serialNo);
          }
        },
      );

  static QueryExecutor _openConnection() {
    // Temporarily changed database name to force recreation with new schema
    // Change back to 'toolease_db' after testing
    return driftDatabase(name: 'toolease_db_v2');
  }
}