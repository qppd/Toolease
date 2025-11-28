import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../models/student.dart';
import '../providers/database_provider.dart';
import '../providers/student_provider.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/app_input.dart';
import '../shared/widgets/app_button.dart';
import '../shared/widgets/app_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _yearLevelController = TextEditingController();
  final _sectionController = TextEditingController();

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _yearLevelController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final databaseService = ref.read(databaseServiceProvider);
    
    // Check if student already exists
    final existingStudent = await databaseService.getStudentByStudentId(_studentIdController.text.trim());
    if (existingStudent != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Student ID already exists!'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
      return;
    }

    final student = Student(
      id: 0, // Will be auto-generated
      studentId: _studentIdController.text.trim(),
      name: _nameController.text.trim(),
      yearLevel: _yearLevelController.text.trim(),
      section: _sectionController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      // Use the StateNotifier instead of direct database service
      await ref.read(studentNotifierProvider.notifier).addStudent(student);
      // Also invalidate other student providers to ensure they refresh
      ref.invalidate(allStudentsProvider);
      ref.invalidate(studentByIdProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Student registered successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering student: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Register Student',
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: AppSpacing.iconSizeXxl,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(
                      label: 'Student ID',
                      hint: 'Enter student ID number',
                      controller: _studentIdController,
                      prefixIcon: Icons.badge_rounded,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter student ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(
                      label: 'Full Name',
                      hint: 'Enter student full name',
                      controller: _nameController,
                      prefixIcon: Icons.person_rounded,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(
                      label: 'Year Level',
                      hint: 'e.g., 1st Year, 2nd Year',
                      controller: _yearLevelController,
                      prefixIcon: Icons.school_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter year level';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(
                      label: 'Section',
                      hint: 'Enter section/class',
                      controller: _sectionController,
                      prefixIcon: Icons.class_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter section';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Register Student',
              onPressed: _registerStudent,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              fullWidth: true,
              icon: Icons.person_add_rounded,
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}