import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/student_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/item_provider.dart';
import '../providers/borrow_record_provider.dart';
import '../core/design_system.dart';
import '../shared/widgets/app_card.dart';
import 'manage_storages_screen.dart';
import 'manage_items_screen.dart';
import 'manage_students_screen.dart';
import 'manage_records_screen.dart';
import 'manage_tags_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'admin_user_manual_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all StateNotifier providers for real-time data
    final studentsAsync = ref.watch(studentNotifierProvider);
    final storagesAsync = ref.watch(storageNotifierProvider);
    final itemsAsync = ref.watch(itemNotifierProvider);
    final activeBorrowCountAsync = ref.watch(activeBorrowCountNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () => _showLogoutDialog(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AdminUserManualScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          await ref.read(studentNotifierProvider.notifier).refreshStudents();
          await ref.read(storageNotifierProvider.notifier).refreshStorages();
          await ref.read(itemNotifierProvider.notifier).refreshItems();
          await ref
              .read(activeBorrowCountNotifierProvider.notifier)
              .refreshActiveBorrowCount();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(context),

              const SizedBox(height: AppSpacing.lg),

              // Real-time stats grid
              _buildStatsGrid(
                studentsAsync,
                storagesAsync,
                itemsAsync,
                activeBorrowCountAsync,
                context,
                ref,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Inventory Summary - Real-time data
              _buildInventorySummary(itemsAsync, context),

              const SizedBox(height: AppSpacing.xl),

              // Quick Actions Section
              _buildQuickActions(context),

              const SizedBox(height: AppSpacing.xl),

              // Management Options
              _buildManagementSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.dashboard_outlined,
              color: AppColors.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back, Admin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Manage your inventory system',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    AsyncValue studentsAsync,
    AsyncValue storagesAsync,
    AsyncValue itemsAsync,
    AsyncValue<int> activeBorrowCountAsync,
    BuildContext context,
    WidgetRef ref,
  ) {
    // Handle loading states
    if (studentsAsync.isLoading ||
        storagesAsync.isLoading ||
        itemsAsync.isLoading ||
        activeBorrowCountAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Handle error states
    if (studentsAsync.hasError ||
        storagesAsync.hasError ||
        itemsAsync.hasError ||
        activeBorrowCountAsync.hasError) {
      return AppCard(
        variant: AppCardVariant.outlined,
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Error loading dashboard data',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(studentNotifierProvider.notifier)
                    .refreshStudents();
                await ref
                    .read(storageNotifierProvider.notifier)
                    .refreshStorages();
                await ref.read(itemNotifierProvider.notifier).refreshItems();
                await ref
                    .read(activeBorrowCountNotifierProvider.notifier)
                    .refreshActiveBorrowCount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      );
    }

    // Extract data from AsyncValue
    final students = studentsAsync.value ?? [];
    final storages = storagesAsync.value ?? [];
    final items = itemsAsync.value ?? [];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      children: [
        _buildStatCard(
          'Students',
          students.length,
          Icons.people_outline,
          AppColors.info,
          'Total registered students',
          context,
        ),
        _buildStatCard(
          'Storages',
          storages.length,
          Icons.storage_outlined,
          AppColors.secondary,
          'Storage locations',
          context,
        ),
        _buildStatCard(
          'Items',
          items.length,
          Icons.inventory_2_outlined,
          AppColors.accent,
          'Total inventory items',
          context,
        ),
        _buildStatCard(
          'Active Borrows',
          activeBorrowCountAsync.value ?? 0,
          Icons.assignment_outlined,
          AppColors.error,
          'Currently borrowed items',
          context,
        ),
      ],
    );
  }

  Widget _buildInventorySummary(AsyncValue itemsAsync, BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Inventory Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          itemsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, _) => Center(
              child: Text(
                'Error loading inventory data',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            data: (items) {
              final totalQuantity = items.fold(
                0,
                (sum, item) => sum + item.totalQuantity,
              );
              final availableQuantity = items.fold(
                0,
                (sum, item) => sum + item.availableQuantity,
              );
              final borrowedQuantity = totalQuantity - availableQuantity;
              final utilizationRate = totalQuantity > 0
                  ? (borrowedQuantity / totalQuantity * 100)
                  : 0;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInventoryMetric(
                          'Total Items',
                          '$totalQuantity',
                          Icons.inventory_outlined,
                          AppColors.textPrimary,
                          context,
                        ),
                      ),
                      Expanded(
                        child: _buildInventoryMetric(
                          'Available',
                          '$availableQuantity',
                          Icons.check_circle_outline,
                          AppColors.secondary,
                          context,
                        ),
                      ),
                      Expanded(
                        child: _buildInventoryMetric(
                          'Borrowed',
                          '$borrowedQuantity',
                          Icons.schedule_outlined,
                          AppColors.accent,
                          context,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Utilization Rate: ${utilizationRate.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryMetric(
    String label,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
    String description,
    BuildContext context,
  ) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_outlined, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              const Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from admin dashboard?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onError,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Add Item',
                Icons.add_box_outlined,
                AppColors.secondary,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ManageItemsScreen(),
                  ),
                ),
                context,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickActionCard(
                'View Reports',
                Icons.analytics_outlined,
                AppColors.accent,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                ),
                context,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return AppCard(
      onTap: onTap,
      variant: AppCardVariant.outlined,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Management',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          children: [
            _buildManagementCard(
              'Manage Storages',
              'Organize storage locations',
              Icons.storage_outlined,
              AppColors.secondary,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageStoragesScreen(),
                ),
              ),
              context,
            ),
            _buildManagementCard(
              'Manage Items',
              'Add and edit inventory',
              Icons.inventory_2_outlined,
              AppColors.accent,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageItemsScreen(),
                ),
              ),
              context,
            ),
            _buildManagementCard(
              'Manage Students',
              'Student registration',
              Icons.people_outline,
              AppColors.info,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageStudentsScreen(),
                ),
              ),
              context,
            ),
            _buildManagementCard(
              'Manage Records',
              'View & archive records',
              Icons.assignment_outlined,
              AppColors.warning,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageRecordsScreen(),
                ),
              ),
              context,
            ),
            _buildManagementCard(
              'Reports',
              'Generate system reports',
              Icons.analytics_outlined,
              AppColors.primary,
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              ),
              context,
            ),
            _buildManagementCard(
              'Manage Tags',
              'Organize item categories',
              Icons.tag_outlined,
              AppColors.secondary,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageTagsScreen(),
                ),
              ),
              context,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
