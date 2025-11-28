import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/app_card.dart';

class StudentUserManualScreen extends StatelessWidget {
  const StudentUserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'User Manual',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: AppSpacing.xl),
            _buildHowToSection(context),
            const SizedBox(height: AppSpacing.xl),
            _buildTipsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to ToolEase',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your inventory management system for borrowing and returning equipment.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowToSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Use ToolEase',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildStepCard(
          context,
          '1',
          'Register as Student',
          'Before borrowing any items, you must first register as a student. Click on "Register Student" and fill in your information including Student ID, name, year level, and section.',
          Icons.person_add_outlined,
          AppColors.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildStepCard(
          context,
          '2',
          'Borrow Items',
          'Enter your Student ID, select the storage location, choose items you want to borrow, and specify quantities. A unique borrow ID will be generated for your transaction.',
          Icons.shopping_bag_outlined,
          AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildStepCard(
          context,
          '3',
          'Return Items',
          'When returning items, enter your Student ID, review your borrowed items, and mark the condition of each item (Good, Damaged, or Lost). Items in good condition will be returned to inventory.',
          Icons.assignment_return_outlined,
          AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    String stepNumber,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      variant: AppCardVariant.outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Important Tips',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          variant: AppCardVariant.outlined,
          child: Column(
            children: [
              _buildTipItem(
                context,
                Icons.info_outline,
                'Remember Your Student ID',
                'You\'ll need your Student ID for both borrowing and returning items.',
                AppColors.info,
              ),
              const Divider(height: AppSpacing.lg),
              _buildTipItem(
                context,
                Icons.warning_amber_outlined,
                'Check Item Condition',
                'Always inspect items before borrowing. Report any damage immediately.',
                AppColors.warning,
              ),
              const Divider(height: AppSpacing.lg),
              _buildTipItem(
                context,
                Icons.schedule_outlined,
                'Return On Time',
                'Return items promptly to ensure availability for other students.',
                AppColors.accent,
              ),
              const Divider(height: AppSpacing.lg),
              _buildTipItem(
                context,
                Icons.help_outline,
                'Need Help?',
                'Contact the administrator if you encounter any issues or need assistance.',
                AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
