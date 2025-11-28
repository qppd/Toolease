import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import 'database_provider.dart';

final allStudentsProvider = FutureProvider<List<Student>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllStudents();
});

final studentByIdProvider = FutureProvider.family<Student?, String>((ref, studentId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getStudentByStudentId(studentId);
});

final studentNotifierProvider = StateNotifierProvider<StudentNotifier, AsyncValue<List<Student>>>(
  (ref) => StudentNotifier(ref),
);

class StudentNotifier extends StateNotifier<AsyncValue<List<Student>>> {
  final Ref _ref;

  StudentNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final students = await databaseService.getAllStudents();
      state = AsyncValue.data(students);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshStudents() async {
    state = const AsyncValue.loading();
    await _loadStudents();
  }

  Future<void> addStudent(Student student) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.insertStudent(student);
      await refreshStudents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.updateStudent(student);
      await refreshStudents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteStudent(int studentId) async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.deleteStudent(studentId);
      await refreshStudents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}