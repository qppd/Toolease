import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/student.dart' as models;
import '../models/storage.dart' as models;
import '../models/item.dart' as models;
import '../models/borrow_record.dart' as models;
import '../models/tag.dart' as models;

/// Database service for per-unit item tracking system
/// Each item is a unique physical unit with its own Serial No. (RFID Tag ID)
class DatabaseService {
  final AppDatabase _database;

  DatabaseService(this._database);

  // ============ STUDENTS ============

  Future<List<models.Student>> getAllStudents() async {
    final students = await _database.select(_database.students).get();
    return students
        .map(
          (s) => models.Student(
            id: s.id,
            studentId: s.studentId,
            name: s.name,
            yearLevel: s.yearLevel,
            section: s.section,
            createdAt: s.createdAt,
          ),
        )
        .toList();
  }

  Future<models.Student?> getStudentByStudentId(String studentId) async {
    final student = await (_database.select(_database.students)
          ..where((s) => s.studentId.equals(studentId)))
        .getSingleOrNull();

    if (student == null) return null;

    return models.Student(
      id: student.id,
      studentId: student.studentId,
      name: student.name,
      yearLevel: student.yearLevel,
      section: student.section,
      createdAt: student.createdAt,
    );
  }

  Future<int> insertStudent(models.Student student) async {
    return await _database.into(_database.students).insert(
          StudentsCompanion(
            studentId: Value(student.studentId),
            name: Value(student.name),
            yearLevel: Value(student.yearLevel),
            section: Value(student.section),
          ),
        );
  }

  Future<void> updateStudent(models.Student student) async {
    await (_database.update(_database.students)
          ..where((s) => s.id.equals(student.id)))
        .write(
      StudentsCompanion(
        name: Value(student.name),
        yearLevel: Value(student.yearLevel),
        section: Value(student.section),
      ),
    );
  }

  Future<void> deleteStudent(int studentId) async {
    await (_database.delete(_database.students)
          ..where((s) => s.id.equals(studentId)))
        .go();
  }

  // ============ STORAGES ============

  Future<List<models.Storage>> getAllStorages() async {
    final storages = await _database.select(_database.storages).get();
    return storages
        .map(
          (s) => models.Storage(
            id: s.id,
            name: s.name,
            description: s.description,
            createdAt: s.createdAt,
          ),
        )
        .toList();
  }

  Future<int> insertStorage(models.Storage storage) async {
    return await _database.into(_database.storages).insert(
          StoragesCompanion(
            name: Value(storage.name),
            description: Value(storage.description),
          ),
        );
  }

  Future<void> updateStorage(models.Storage storage) async {
    await (_database.update(_database.storages)
          ..where((s) => s.id.equals(storage.id)))
        .write(
      StoragesCompanion(
        name: Value(storage.name),
        description: Value(storage.description),
      ),
    );
  }

  Future<void> deleteStorage(int storageId) async {
    await (_database.delete(_database.storages)
          ..where((s) => s.id.equals(storageId)))
        .go();
  }

  // ============ ITEMS (PER-UNIT TRACKING) ============

  /// Get all items (each row is a unique physical item)
  Future<List<models.Item>> getAllItems() async {
    final items = await _database.select(_database.items).get();
    return items.map((i) => _itemFromRow(i)).toList();
  }

  /// Get items by status
  Future<List<models.Item>> getItemsByStatus(models.ItemStatus status) async {
    final items = await (_database.select(_database.items)
          ..where((i) => i.status.equals(status.name)))
        .get();
    return items.map((i) => _itemFromRow(i)).toList();
  }

  /// Get available items for borrowing
  Future<List<models.Item>> getAvailableItems() async {
    return getItemsByStatus(models.ItemStatus.available);
  }

  /// Get item by Serial No. (RFID Tag ID)
  Future<models.Item?> getItemBySerialNo(String serialNo) async {
    final item = await (_database.select(_database.items)
          ..where((i) => i.serialNo.equals(serialNo)))
        .getSingleOrNull();

    if (item == null) return null;
    return _itemFromRow(item);
  }

  /// Get item by ID
  Future<models.Item?> getItemById(int id) async {
    final item = await (_database.select(_database.items)
          ..where((i) => i.id.equals(id)))
        .getSingleOrNull();

    if (item == null) return null;
    return _itemFromRow(item);
  }

  /// Check if Serial No. already exists
  Future<bool> serialNoExists(String serialNo) async {
    final item = await getItemBySerialNo(serialNo);
    return item != null;
  }

  /// Insert new item (Serial No. must be unique)
  Future<int> insertItem(models.Item item) async {
    // Verify Serial No. is unique
    if (await serialNoExists(item.serialNo)) {
      throw Exception('Serial No. ${item.serialNo} already exists');
    }

    return await _database.into(_database.items).insert(
          ItemsCompanion(
            toolName: Value(item.toolName),
            model: Value(item.model),
            productNo: Value(item.productNo),
            serialNo: Value(item.serialNo),
            remarks: Value(item.remarks),
            year: Value(item.year),
            status: Value(item.status.name),
            storageId: Value(item.storageId),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Update item (Serial No. cannot be changed)
  Future<void> updateItem(models.Item item) async {
    await (_database.update(_database.items)
          ..where((i) => i.id.equals(item.id)))
        .write(
      ItemsCompanion(
        toolName: Value(item.toolName),
        model: Value(item.model),
        productNo: Value(item.productNo),
        // serialNo is intentionally omitted - cannot be changed
        remarks: Value(item.remarks),
        year: Value(item.year),
        status: Value(item.status.name),
        storageId: Value(item.storageId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update item status
  Future<void> updateItemStatus(int itemId, models.ItemStatus status) async {
    await (_database.update(_database.items)..where((i) => i.id.equals(itemId)))
        .write(
      ItemsCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete item
  Future<void> deleteItem(int itemId) async {
    await (_database.delete(_database.items)..where((i) => i.id.equals(itemId)))
        .go();
  }

  /// Search items by tool name, model, product no, serial no
  Future<List<models.Item>> searchItems(String query) async {
    final lowerQuery = query.toLowerCase();
    final items = await _database.select(_database.items).get();

    return items
        .where((i) =>
            i.toolName.toLowerCase().contains(lowerQuery) ||
            i.model.toLowerCase().contains(lowerQuery) ||
            i.productNo.toLowerCase().contains(lowerQuery) ||
            i.serialNo.toLowerCase().contains(lowerQuery) ||
            (i.remarks?.toLowerCase().contains(lowerQuery) ?? false))
        .map((i) => _itemFromRow(i))
        .toList();
  }

  // ============ BORROW RECORDS (PER-UNIT) ============

  /// Generate unique Borrow ID: YY###### (e.g., 25000001)
  Future<String> generateBorrowId() async {
    final year = DateTime.now().year;
    final prefix = year.toString().substring(2); // Last 2 digits

    final lastRecord = await (_database.select(_database.borrowRecords)
          ..orderBy([(br) => OrderingTerm.desc(br.id)])
          ..limit(1))
        .getSingleOrNull();

    int nextSequence = 1;
    if (lastRecord != null && lastRecord.borrowId.startsWith(prefix)) {
      final sequence = int.tryParse(lastRecord.borrowId.substring(2)) ?? 0;
      nextSequence = sequence + 1;
    }

    return '$prefix${nextSequence.toString().padLeft(6, '0')}';
  }

  /// Create borrow record for per-unit items
  /// Each itemId in the list represents ONE physical item
  Future<int> createBorrowRecord({
    required int studentId,
    required List<int> itemIds, // List of unique item IDs
  }) async {
    return await _database.transaction(() async {
      // Validate all items are available
      for (final itemId in itemIds) {
        final item = await getItemById(itemId);
        if (item == null) {
          throw Exception('Item ID $itemId not found');
        }
        if (item.status != models.ItemStatus.available) {
          throw Exception(
            'Item ${item.serialNo} is not available (status: ${item.status.displayName})',
          );
        }
      }

      // Generate borrow ID
      final borrowId = await generateBorrowId();

      // Create borrow record
      final recordId = await _database.into(_database.borrowRecords).insert(
            BorrowRecordsCompanion(
              borrowId: Value(borrowId),
              studentId: Value(studentId),
              status: const Value('active'),
            ),
          );

      // Create borrow items and update item status
      for (final itemId in itemIds) {
        await _database.into(_database.borrowItems).insert(
              BorrowItemsCompanion(
                borrowRecordId: Value(recordId),
                itemId: Value(itemId),
              ),
            );

        // Update item status to borrowed
        await updateItemStatus(itemId, models.ItemStatus.borrowed);
      }

      return recordId;
    });
  }

  /// Get all borrow records with full details
  Future<List<models.BorrowRecord>> getAllBorrowRecords() async {
    final records = await _database.select(_database.borrowRecords).get();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in records) {
      final items = await (_database.select(_database.borrowItems)
            ..where((bi) => bi.borrowRecordId.equals(record.id)))
          .get();

      final borrowItems = items
          .map(
            (bi) => models.BorrowItem(
              id: bi.id,
              borrowRecordId: bi.borrowRecordId,
              itemId: bi.itemId,
              condition: bi.condition != null
                  ? models.ItemCondition.fromString(bi.condition!)
                  : null,
              returnedAt: bi.returnedAt,
              createdAt: bi.createdAt,
            ),
          )
          .toList();

      borrowRecords.add(
        models.BorrowRecord(
          id: record.id,
          borrowId: record.borrowId,
          studentId: record.studentId,
          status: models.BorrowStatus.values.firstWhere(
            (s) => s.name == record.status,
          ),
          borrowedAt: record.borrowedAt,
          returnedAt: record.returnedAt,
          items: borrowItems,
        ),
      );
    }
    return borrowRecords;
  }

  /// Get active borrow records
  Future<List<models.BorrowRecord>> getActiveBorrowRecords() async {
    final records = await (_database.select(_database.borrowRecords)
          ..where((br) => br.status.equals('active')))
        .get();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in records) {
      final items = await (_database.select(_database.borrowItems)
            ..where((bi) => bi.borrowRecordId.equals(record.id)))
          .get();

      final borrowItems = items
          .map(
            (bi) => models.BorrowItem(
              id: bi.id,
              borrowRecordId: bi.borrowRecordId,
              itemId: bi.itemId,
              condition: bi.condition != null
                  ? models.ItemCondition.fromString(bi.condition!)
                  : null,
              returnedAt: bi.returnedAt,
              createdAt: bi.createdAt,
            ),
          )
          .toList();

      borrowRecords.add(
        models.BorrowRecord(
          id: record.id,
          borrowId: record.borrowId,
          studentId: record.studentId,
          status: models.BorrowStatus.active,
          borrowedAt: record.borrowedAt,
          returnedAt: record.returnedAt,
          items: borrowItems,
        ),
      );
    }
    return borrowRecords;
  }

  /// Get borrow record by ID
  Future<models.BorrowRecord?> getBorrowRecordById(int id) async {
    final record = await (_database.select(_database.borrowRecords)
          ..where((br) => br.id.equals(id)))
        .getSingleOrNull();

    if (record == null) return null;

    final items = await (_database.select(_database.borrowItems)
          ..where((bi) => bi.borrowRecordId.equals(record.id)))
        .get();

    final borrowItems = items
        .map(
          (bi) => models.BorrowItem(
            id: bi.id,
            borrowRecordId: bi.borrowRecordId,
            itemId: bi.itemId,
            condition: bi.condition != null
                ? models.ItemCondition.fromString(bi.condition!)
                : null,
            returnedAt: bi.returnedAt,
            createdAt: bi.createdAt,
          ),
        )
        .toList();

    return models.BorrowRecord(
      id: record.id,
      borrowId: record.borrowId,
      studentId: record.studentId,
      status: models.BorrowStatus.values.firstWhere(
        (s) => s.name == record.status,
      ),
      borrowedAt: record.borrowedAt,
      returnedAt: record.returnedAt,
      items: borrowItems,
    );
  }

  /// Get borrow record by Borrow ID
  Future<models.BorrowRecord?> getBorrowRecordByBorrowId(
    String borrowId,
  ) async {
    final record = await (_database.select(_database.borrowRecords)
          ..where((br) => br.borrowId.equals(borrowId)))
        .getSingleOrNull();

    if (record == null) return null;
    return getBorrowRecordById(record.id);
  }

  /// Get active borrows by student
  Future<List<models.BorrowRecord>> getActiveBorrowsByStudent(
    int studentId,
  ) async {
    final records = await (_database.select(_database.borrowRecords)
          ..where(
            (br) => br.studentId.equals(studentId) & br.status.equals('active'),
          ))
        .get();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in records) {
      final fullRecord = await getBorrowRecordById(record.id);
      if (fullRecord != null) {
        borrowRecords.add(fullRecord);
      }
    }
    return borrowRecords;
  }

  /// Return specific items (partial or full return)
  /// itemReturns: List of (borrowItemId, condition)
  Future<void> returnItems({
    required int borrowRecordId,
    required List<({int borrowItemId, models.ItemCondition condition})>
        itemReturns,
  }) async {
    await _database.transaction(() async {
      for (final returnInfo in itemReturns) {
        // Get the borrow item
        final borrowItem = await (_database.select(_database.borrowItems)
              ..where((bi) => bi.id.equals(returnInfo.borrowItemId)))
            .getSingle();

        // Update borrow item with condition and return time
        await (_database.update(_database.borrowItems)
              ..where((bi) => bi.id.equals(returnInfo.borrowItemId)))
            .write(
          BorrowItemsCompanion(
            condition: Value(returnInfo.condition.name),
            returnedAt: Value(DateTime.now()),
          ),
        );

        // Update item status based on condition
        models.ItemStatus newStatus;
        switch (returnInfo.condition) {
          case models.ItemCondition.good:
            newStatus = models.ItemStatus.available;
            break;
          case models.ItemCondition.damaged:
            newStatus = models.ItemStatus.damaged;
            break;
          case models.ItemCondition.lost:
            newStatus = models.ItemStatus.lost;
            break;
        }

        await updateItemStatus(borrowItem.itemId, newStatus);
      }

      // Check if all items in the borrow record have been returned
      final allBorrowItems = await (_database.select(_database.borrowItems)
            ..where((bi) => bi.borrowRecordId.equals(borrowRecordId)))
          .get();

      final allReturned =
          allBorrowItems.every((bi) => bi.returnedAt != null);

      if (allReturned) {
        // Mark borrow record as returned
        await (_database.update(_database.borrowRecords)
              ..where((br) => br.id.equals(borrowRecordId)))
            .write(
          BorrowRecordsCompanion(
            status: const Value('returned'),
            returnedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  /// Get count of active borrow records
  Future<int> getActiveBorrowRecordsCount() async {
    final count = await (_database.selectOnly(_database.borrowRecords)
          ..addColumns([_database.borrowRecords.id.count()])
          ..where(_database.borrowRecords.status.equals('active')))
        .getSingle();

    return count.read(_database.borrowRecords.id.count()) ?? 0;
  }

  /// Get recent borrow records
  Future<List<models.BorrowRecord>> getRecentBorrowRecords(int limit) async {
    final records = await (_database.select(_database.borrowRecords)
          ..orderBy([(br) => OrderingTerm.desc(br.borrowedAt)])
          ..limit(limit))
        .get();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in records) {
      final fullRecord = await getBorrowRecordById(record.id);
      if (fullRecord != null) {
        borrowRecords.add(fullRecord);
      }
    }
    return borrowRecords;
  }

  /// Get recent borrow records with student names
  Future<List<Map<String, dynamic>>> getRecentBorrowRecordsWithStudentNames(
    int limit,
  ) async {
    final records = await getRecentBorrowRecords(limit);
    List<Map<String, dynamic>> result = [];

    for (final record in records) {
      final student = await (_database.select(_database.students)
            ..where((s) => s.id.equals(record.studentId)))
          .getSingleOrNull();

      result.add({
        'borrowRecord': record,
        'studentName': student?.name ?? 'Unknown',
      });
    }

    return result;
  }

  // ============ TAGS ============

  Future<List<models.Tag>> getAllTags() async {
    final tags = await _database.select(_database.tags).get();
    return tags
        .map(
          (t) => models.Tag(
            id: t.id,
            name: t.name,
            description: t.description,
            color: t.color,
            createdAt: t.createdAt,
          ),
        )
        .toList();
  }

  Future<int> insertTag(models.Tag tag) async {
    return await _database.into(_database.tags).insert(
          TagsCompanion(
            name: Value(tag.name),
            description: Value(tag.description),
            color: Value(tag.color),
          ),
        );
  }

  Future<void> updateTag(models.Tag tag) async {
    await (_database.update(_database.tags)..where((t) => t.id.equals(tag.id)))
        .write(
      TagsCompanion(
        name: Value(tag.name),
        description: Value(tag.description),
        color: Value(tag.color),
      ),
    );
  }

  Future<void> deleteTag(int tagId) async {
    await (_database.delete(_database.tags)..where((t) => t.id.equals(tagId)))
        .go();
  }

  // ============ HELPER METHODS ============

  models.Item _itemFromRow(Item i) {
    return models.Item(
      id: i.id,
      toolName: i.toolName,
      model: i.model,
      productNo: i.productNo,
      serialNo: i.serialNo,
      remarks: i.remarks,
      year: i.year,
      status: models.ItemStatus.fromString(i.status),
      storageId: i.storageId,
      createdAt: i.createdAt,
      updatedAt: i.updatedAt,
    );
  }

  // ============ DATABASE OPERATIONS ============

  /// Clear all data from database
  Future<void> clearAllData() async {
    await _database.transaction(() async {
      await _database.delete(_database.borrowItems).go();
      await _database.delete(_database.borrowRecords).go();
      await _database.delete(_database.items).go();
      await _database.delete(_database.storages).go();
      await _database.delete(_database.students).go();
      await _database.delete(_database.tags).go();
    });
  }

  /// Export database
  // Implementation depends on platform-specific code

  /// Import database
  // Implementation depends on platform-specific code

  // ============ BULK DELETE METHODS ============

  Future<void> deleteSelectedStudents(List<int> studentIds) async {
    if (studentIds.isEmpty) return;
    await (_database.delete(_database.students)
          ..where((s) => s.id.isIn(studentIds)))
        .go();
  }

  Future<void> deleteAllStudents() async {
    await _database.delete(_database.students).go();
  }

  Future<void> deleteSelectedStorages(List<int> storageIds) async {
    if (storageIds.isEmpty) return;
    await (_database.delete(_database.storages)
          ..where((s) => s.id.isIn(storageIds)))
        .go();
  }

  Future<void> deleteAllStorages() async {
    await _database.delete(_database.storages).go();
  }

  Future<void> deleteSelectedItems(List<int> itemIds) async {
    if (itemIds.isEmpty) return;
    await (_database.delete(_database.items)
          ..where((i) => i.id.isIn(itemIds)))
        .go();
  }

  Future<void> deleteAllItems() async {
    await _database.delete(_database.items).go();
  }

  Future<void> deleteSelectedBorrowRecords(List<int> recordIds) async {
    if (recordIds.isEmpty) return;
    // First delete associated borrow items
    await (_database.delete(_database.borrowItems)
          ..where((bi) => bi.borrowRecordId.isIn(recordIds)))
        .go();
    // Then delete the records
    await (_database.delete(_database.borrowRecords)
          ..where((br) => br.id.isIn(recordIds)))
        .go();
  }

  Future<void> deleteAllBorrowRecords() async {
    await _database.delete(_database.borrowItems).go();
    await _database.delete(_database.borrowRecords).go();
  }

  // ============ SETTINGS ============

  Future<String> getSetting(String key, {String defaultValue = 'true'}) async {
    final setting = await (_database.select(_database.settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();

    if (setting == null) {
      // Initialize with default value
      await _database.into(_database.settings).insert(
            SettingsCompanion(
              key: Value(key),
              value: Value(defaultValue),
            ),
          );
      return defaultValue;
    }

    return setting.value;
  }

  Future<void> updateSetting(String key, String value) async {
    final existingSetting = await (_database.select(_database.settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();

    if (existingSetting == null) {
      await _database.into(_database.settings).insert(
            SettingsCompanion(
              key: Value(key),
              value: Value(value),
            ),
          );
    } else {
      await (_database.update(_database.settings)
            ..where((s) => s.key.equals(key)))
          .write(
        SettingsCompanion(
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<Map<String, String>> getAllSettings() async {
    final settings = await _database.select(_database.settings).get();
    return {for (final setting in settings) setting.key: setting.value};
  }

  Future<bool> isScreenEnabled(String screenKey) async {
    final value = await getSetting(screenKey);
    return value.toLowerCase() == 'true';
  }
}
