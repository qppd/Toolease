class Item {
  final int id;
  final String name;
  final String? description;
  final int storageId;
  final int totalQuantity;
  final int availableQuantity;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.name,
    this.description,
    required this.storageId,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.createdAt,
  });

  Item copyWith({
    int? id,
    String? name,
    String? description,
    int? storageId,
    int? totalQuantity,
    int? availableQuantity,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      storageId: storageId ?? this.storageId,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}