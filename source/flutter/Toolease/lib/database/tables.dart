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

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get storageId => integer().references(Storages, #id)();
  IntColumn get totalQuantity => integer()();
  IntColumn get availableQuantity => integer()();
  TextColumn get serialNo => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class BorrowRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get borrowId => text().unique()();
  IntColumn get studentId => integer().references(Students, #id)();
  TextColumn get status => text()(); // 'active', 'returned', 'archived'
  DateTimeColumn get borrowedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get returnedAt => dateTime().nullable()();
}

class BorrowItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get borrowRecordId => integer().references(BorrowRecords, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  IntColumn get quantity => integer()();
  TextColumn get returnCondition => text().nullable()(); // 'good', 'damaged', 'lost'
}

// New table for individual quantity conditions
class BorrowItemConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get borrowItemId => integer().references(BorrowItems, #id)();
  IntColumn get quantityUnit => integer()(); // 1, 2, 3, etc. representing each unit
  TextColumn get condition => text()(); // 'good', 'damaged', 'lost'
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