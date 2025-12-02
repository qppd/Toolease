import 'package:drift/drift.dart';

class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get studentId => text().unique()();
  TextColumn get name => text()();
  TextColumn get yearLevel => text()();
  TextColumn get section => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Storages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Per-unit item tracking - Each row represents a unique physical item
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get toolName => text()(); // Tool Name
  TextColumn get model => text()(); // Model
  TextColumn get productNo => text()(); // Product No.
  TextColumn get serialNo => text().unique()(); // Serial No. (RFID Tag ID) - UNIQUE and REQUIRED
  TextColumn get remarks => text().nullable()(); // Remarks
  TextColumn get year => text()(); // Year
  TextColumn get status => text().withDefault(const Constant('available'))(); // 'available', 'borrowed', 'lost', 'damaged'
  IntColumn get storageId => integer().nullable().references(Storages, #id)(); // Optional storage location
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class BorrowRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get borrowId => text().unique()(); // Format: YY###### (e.g., 25000001)
  IntColumn get studentId => integer().references(Students, #id)();
  TextColumn get status => text()(); // 'active', 'returned', 'archived'
  DateTimeColumn get borrowedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get returnedAt => dateTime().nullable()();
}

// Per-unit borrow tracking - Each row represents ONE physical item borrowed
class BorrowItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get borrowRecordId => integer().references(BorrowRecords, #id)();
  IntColumn get itemId => integer().references(Items, #id)(); // References the unique item
  TextColumn get condition => text().nullable()(); // 'good', 'damaged', 'lost' - set on return
  DateTimeColumn get returnedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}


// Settings table for app configuration
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Tags table for item categorization or RFID tags
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()(); // Hex color code
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}