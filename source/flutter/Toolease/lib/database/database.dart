import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Students, Storages, Items, BorrowRecords, BorrowItems, Settings, Tags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Incremented for migration

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Migration from v1 to v2: Complete schema restructure
            // Drop old tables that no longer exist
            await m.deleteTable('item_units');
            await m.deleteTable('borrow_item_conditions');
            
            // Recreate Items table with new per-unit structure
            await m.drop(items);
            await m.createTable(items);
            
            // Recreate BorrowItems table without quantity
            await m.drop(borrowItems);
            await m.createTable(borrowItems);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'toolease_db_v4');
  }
}