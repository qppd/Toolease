class Storage {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  const Storage({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  Storage copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Storage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}