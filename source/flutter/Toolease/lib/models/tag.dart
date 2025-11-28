class Tag {
  final int id;
  final String name;
  final String? description;
  final String? color;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.createdAt,
  });

  Tag copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}