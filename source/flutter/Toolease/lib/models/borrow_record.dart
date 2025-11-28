enum BorrowStatus { active, returned, archived }

enum ItemCondition { good, damaged, lost }

class BorrowRecord {
  final int id;
  final String borrowId;
  final int studentId;
  final BorrowStatus status;
  final DateTime borrowedAt;
  final DateTime? returnedAt;
  final List<BorrowItem> items;

  const BorrowRecord({
    required this.id,
    required this.borrowId,
    required this.studentId,
    required this.status,
    required this.borrowedAt,
    this.returnedAt,
    required this.items,
  });

  BorrowRecord copyWith({
    int? id,
    String? borrowId,
    int? studentId,
    BorrowStatus? status,
    DateTime? borrowedAt,
    DateTime? returnedAt,
    List<BorrowItem>? items,
  }) {
    return BorrowRecord(
      id: id ?? this.id,
      borrowId: borrowId ?? this.borrowId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      borrowedAt: borrowedAt ?? this.borrowedAt,
      returnedAt: returnedAt ?? this.returnedAt,
      items: items ?? this.items,
    );
  }
}

class BorrowItem {
  final int id;
  final int borrowRecordId;
  final int itemId;
  final int quantity;
  final ItemCondition? returnCondition; // Overall condition for backward compatibility
  final List<QuantityCondition> quantityConditions; // Individual conditions per quantity unit

  const BorrowItem({
    required this.id,
    required this.borrowRecordId,
    required this.itemId,
    required this.quantity,
    this.returnCondition,
    this.quantityConditions = const [],
  });

  BorrowItem copyWith({
    int? id,
    int? borrowRecordId,
    int? itemId,
    int? quantity,
    ItemCondition? returnCondition,
    List<QuantityCondition>? quantityConditions,
  }) {
    return BorrowItem(
      id: id ?? this.id,
      borrowRecordId: borrowRecordId ?? this.borrowRecordId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      returnCondition: returnCondition ?? this.returnCondition,
      quantityConditions: quantityConditions ?? this.quantityConditions,
    );
  }
}

class QuantityCondition {
  final int id;
  final int borrowItemId;
  final int quantityUnit; // 1, 2, 3, etc.
  final ItemCondition condition;

  const QuantityCondition({
    required this.id,
    required this.borrowItemId,
    required this.quantityUnit,
    required this.condition,
  });

  QuantityCondition copyWith({
    int? id,
    int? borrowItemId,
    int? quantityUnit,
    ItemCondition? condition,
  }) {
    return QuantityCondition(
      id: id ?? this.id,
      borrowItemId: borrowItemId ?? this.borrowItemId,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      condition: condition ?? this.condition,
    );
  }
}