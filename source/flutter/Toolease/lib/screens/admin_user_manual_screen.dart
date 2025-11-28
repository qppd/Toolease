import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../shared/widgets/app_card.dart';

class AdminUserManualScreen extends StatelessWidget {
  const AdminUserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Admin User Manual',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: AppSpacing.xl),
            _buildSystemOverviewSection(context),
            const SizedBox(height: AppSpacing.xl),
            _buildManagementFeaturesSection(context),
            const SizedBox(height: AppSpacing.xl),
            _buildSettingsSection(context),
            const SizedBox(height: AppSpacing.xl),
            _buildBestPracticesSection(context),
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
                  Icons.admin_panel_settings_outlined,
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
                      'Admin Control Panel',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Complete guide to managing your ToolEase inventory system.',
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

  Widget _buildSystemOverviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How ToolEase Works',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          variant: AppCardVariant.outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewItem(
                context,
                Icons.person_add_outlined,
                'Student Workflow',
                'Students register themselves, borrow items by entering their ID, and return items with condition marking (Good/Damaged/Lost).',
                AppColors.info,
              ),
              const Divider(height: AppSpacing.lg),
              _buildOverviewItem(
                context,
                Icons.admin_panel_settings_outlined,
                'Admin Access',
                'Secure authentication using device PIN/password. Access admin panel via the help button or admin panel button on home screen.',
                AppColors.primary,
              ),
              const Divider(height: AppSpacing.lg),
              _buildOverviewItem(
                context,
                Icons.inventory_outlined,
                'Inventory Tracking',
                'Real-time quantity updates when items are borrowed/returned. Individual condition tracking for each item unit.',
                AppColors.secondary,
              ),
              const Divider(height: AppSpacing.lg),
              _buildOverviewItem(
                context,
                Icons.phone_android_outlined,
                'Kiosk Deployment',
                'Designed for Android tablets with optional kiosk mode. When enabled, restricts system navigation for secure public use.',
                AppColors.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFeatureCard(
          context,
          '1',
          'Dashboard Overview',
          'Real-time system metrics showing total students, storages, items, and active borrows. Inventory utilization rates and quick access to management functions.',
          Icons.dashboard_outlined,
          AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFeatureCard(
          context,
          '2',
          'Manage Storages',
          'Create, edit, and delete storage locations like drawers, cabinets, or rooms. Each storage can contain multiple items with individual tracking.',
          Icons.storage_outlined,
          AppColors.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFeatureCard(
          context,
          '3',
          'Manage Items',
          'Add inventory items with names, descriptions, total quantities, and available quantities. Assign items to specific storage locations for organization.',
          Icons.inventory_2_outlined,
          AppColors.accent,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFeatureCard(
          context,
          '4',
          'Manage Students',
          'View, edit, and delete student records. Students register themselves, but you can update their information (name, year level, section) as needed.',
          Icons.people_outline,
          AppColors.info,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFeatureCard(
          context,
          '5',
          'Manage Records',
          'Monitor all borrowing transactions: active borrows (currently out), returned items, and archived records. Track individual item conditions on return.',
          Icons.assignment_outlined,
          AppColors.warning,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFeatureCard(
          context,
          '6',
          'Generate Reports',
          'Create detailed PDF reports filtered by date ranges. Export to external storage and share via other apps for analysis and record-keeping.',
          Icons.analytics_outlined,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Settings',
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
              _buildSettingItem(
                context,
                Icons.toggle_on_outlined,
                'Feature Controls',
                'Enable or disable student access to Register, Borrow, and Return screens. Useful for maintenance or restricted operations.',
                AppColors.secondary,
              ),
              const Divider(height: AppSpacing.lg),
              _buildSettingItem(
                context,
                Icons.lock_outline,
                'Kiosk Mode Toggle',
                'Enable kiosk mode to prevent students from accessing system settings or other apps. Toggle this setting in the admin settings panel.',
                AppColors.accent,
              ),
              const Divider(height: AppSpacing.lg),
              _buildSettingItem(
                context,
                Icons.logout_outlined,
                'Session Management',
                'Secure logout from admin panel returns to student interface. No automatic session timeout - manual logout required.',
                AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestPracticesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Best Practices',
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
              _buildPracticeItem(
                context,
                Icons.dashboard_outlined,
                'Monitor Dashboard Daily',
                'Check real-time metrics for active borrows, item availability, and system utilization rates.',
                AppColors.primary,
              ),
              const Divider(height: AppSpacing.lg),
              _buildPracticeItem(
                context,
                Icons.inventory_outlined,
                'Update Item Information',
                'Keep item names, descriptions, and quantities accurate. Add new items and remove discontinued ones promptly.',
                AppColors.accent,
              ),
              const Divider(height: AppSpacing.lg),
              _buildPracticeItem(
                context,
                Icons.assignment_outlined,
                'Review Return Conditions',
                'Regularly check returned items marked as damaged or lost. Take appropriate action for inventory management.',
                AppColors.warning,
              ),
              const Divider(height: AppSpacing.lg),
              _buildPracticeItem(
                context,
                Icons.analytics_outlined,
                'Generate Regular Reports',
                'Create monthly or semester reports to track usage patterns and plan inventory needs.',
                AppColors.info,
              ),
              const Divider(height: AppSpacing.lg),
              _buildPracticeItem(
                context,
                Icons.archive_outlined,
                'Archive Old Records',
                'Periodically archive completed transactions to maintain system performance and organize historical data.',
                AppColors.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewItem(
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildSettingItem(
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeItem(
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}