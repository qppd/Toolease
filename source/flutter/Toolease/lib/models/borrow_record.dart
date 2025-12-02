enum BorrowStatus { active, returned, archived }

enum ItemCondition { 
  good, 
  damaged, 
  lost;

  String get displayName {
    switch (this) {
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.damaged:
        return 'Damaged';
      case ItemCondition.lost:
        return 'Lost';
    }
  }

  static ItemCondition fromString(String value) {
    switch (value.toLowerCase()) {
      case 'good':
        return ItemCondition.good;
      case 'damaged':
        return ItemCondition.damaged;
      case 'lost':
        return ItemCondition.lost;
      default:
        return ItemCondition.good;
    }
  }
}

class BorrowRecord {
  final int id;
  final String borrowId; // Format: YY###### (e.g., 25000001)
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

  // Check if all items have been returned
  bool get isFullyReturned => items.every((item) => item.isReturned);

  // Check if partially returned
  bool get isPartiallyReturned => items.any((item) => item.isReturned) && !isFullyReturned;

  // Get count of unreturned items
  int get unreturnedCount => items.where((item) => !item.isReturned).length;
}

// Per-unit BorrowItem - Each instance represents ONE physical item borrowed
class BorrowItem {
  final int id;
  final int borrowRecordId;
  final int itemId;
  final ItemCondition? condition; // Set when item is returned
  final DateTime? returnedAt;
  final DateTime createdAt;

  const BorrowItem({
    required this.id,
    required this.borrowRecordId,
    required this.itemId,
    this.condition,
    this.returnedAt,
    required this.createdAt,
  });

  BorrowItem copyWith({
    int? id,
    int? borrowRecordId,
    int? itemId,
    ItemCondition? condition,
    DateTime? returnedAt,
    DateTime? createdAt,
  }) {
    return BorrowItem(
      id: id ?? this.id,
      borrowRecordId: borrowRecordId ?? this.borrowRecordId,
      itemId: itemId ?? this.itemId,
      condition: condition ?? this.condition,
      returnedAt: returnedAt ?? this.returnedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Check if item has been returned
  bool get isReturned => returnedAt != null;
}