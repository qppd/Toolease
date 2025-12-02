// Item status enum for per-unit tracking
enum ItemStatus {
  available,
  borrowed,
  lost,
  damaged;

  String get displayName {
    switch (this) {
      case ItemStatus.available:
        return 'Available';
      case ItemStatus.borrowed:
        return 'Borrowed';
      case ItemStatus.lost:
        return 'Lost';
      case ItemStatus.damaged:
        return 'Damaged';
    }
  }

  static ItemStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return ItemStatus.available;
      case 'borrowed':
        return ItemStatus.borrowed;
      case 'lost':
        return ItemStatus.lost;
      case 'damaged':
        return ItemStatus.damaged;
      default:
        return ItemStatus.available;
    }
  }
}

// Per-unit Item model - Each instance represents a unique physical item
class Item {
  final int id;
  final String toolName;
  final String model;
  final String productNo;
  final String serialNo; // RFID Tag ID - unique identifier
  final String? remarks;
  final String year;
  final ItemStatus status;
  final int? storageId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.id,
    required this.toolName,
    required this.model,
    required this.productNo,
    required this.serialNo,
    this.remarks,
    required this.year,
    required this.status,
    this.storageId,
    required this.createdAt,
    required this.updatedAt,
  });

  Item copyWith({
    int? id,
    String? toolName,
    String? model,
    String? productNo,
    String? serialNo,
    String? remarks,
    String? year,
    ItemStatus? status,
    int? storageId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      model: model ?? this.model,
      productNo: productNo ?? this.productNo,
      serialNo: serialNo ?? this.serialNo,
      remarks: remarks ?? this.remarks,
      year: year ?? this.year,
      status: status ?? this.status,
      storageId: storageId ?? this.storageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if item can be borrowed
  bool get canBorrow => status == ItemStatus.available;

  // Get status color for UI
  String get statusColor {
    switch (status) {
      case ItemStatus.available:
        return '#4CAF50'; // Green
      case ItemStatus.borrowed:
        return '#FF9800'; // Orange
      case ItemStatus.lost:
        return '#F44336'; // Red
      case ItemStatus.damaged:
        return '#9C27B0'; // Purple
    }
  }
}