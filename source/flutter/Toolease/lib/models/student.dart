class Student {
  final int id;
  final String studentId;
  final String name;
  final String yearLevel;
  final String section;
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.studentId,
    required this.name,
    required this.yearLevel,
    required this.section,
    required this.createdAt,
  });

  Student copyWith({
    int? id,
    String? studentId,
    String? name,
    String? yearLevel,
    String? section,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      yearLevel: yearLevel ?? this.yearLevel,
      section: section ?? this.section,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}