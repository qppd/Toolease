import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../shared/widgets/app_scaffold.dart';
import '../shared/widgets/action_card.dart';
import '../shared/widgets/app_card.dart';
import '../providers/settings_provider.dart';
import '../providers/borrow_record_provider.dart';
import '../models/borrow_record.dart';
import '../providers/websocket_connection_provider.dart';
import 'student_user_manual_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh recent activity when screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentBorrowRecordsWithNamesNotifierProvider.notifier).refreshRecentBorrowRecordsWithNames();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh recent activity when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      ref.read(recentBorrowRecordsWithNamesNotifierProvider.notifier).refreshRecentBorrowRecordsWithNames();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'ToolEase',
      showBackButton: false,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Consumer(
                builder: (context, ref, _) {
                  final connected = ref.watch(websocketConnectionProvider);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        connected ? Icons.wifi : Icons.wifi_off,
                        color: connected ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        connected ? 'Connected to ESP32' : 'Not connected to ESP32',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: connected ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.1,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final registerEnabledAsync = ref.watch(
                        registerScreenEnabledProvider,
                      );
                      return registerEnabledAsync.when(
                        loading: () => ActionCard(
                          title: 'Register Student',
                          subtitle: 'Add new student',
                          icon: Icons.person_add_rounded,
                          color: AppColors.secondary,
                          isLarge: true,
                          onTap: () {},
                        ),
                        error: (_, __) => ActionCard(
                          title: 'Register Student',
                          subtitle: 'Add new student',
                          icon: Icons.person_add_rounded,
                          color: AppColors.secondary,
                          isLarge: true,
                          onTap: () =>
                              Navigator.pushNamed(context, '/register'),
                        ),
                        data: (isEnabled) => ActionCard(
                          title: 'Register Student',
                          subtitle: isEnabled
                              ? 'Add new student'
                              : 'Feature disabled',
                          icon: Icons.person_add_rounded,
                          color: isEnabled ? AppColors.secondary : Colors.grey,
                          isLarge: true,
                          onTap: isEnabled
                              ? () => Navigator.pushNamed(context, '/register')
                              : () => _showFeatureDisabledDialog(
                                  context,
                                  'Student Registration',
                                ),
                        ),
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final borrowEnabledAsync = ref.watch(
                        borrowScreenEnabledProvider,
                      );
                      return borrowEnabledAsync.when(
                        loading: () => ActionCard(
                          title: 'Borrow Items',
                          subtitle: 'Check out equipment',
                          icon: Icons.shopping_bag_rounded,
                          color: AppColors.primary,
                          isLarge: true,
                          onTap: () {},
                        ),
                        error: (_, __) => ActionCard(
                          title: 'Borrow Items',
                          subtitle: 'Check out equipment',
                          icon: Icons.shopping_bag_rounded,
                          color: AppColors.primary,
                          isLarge: true,
                          onTap: () => Navigator.pushNamed(context, '/borrow'),
                        ),
                        data: (isEnabled) => ActionCard(
                          title: 'Borrow Items',
                          subtitle: isEnabled
                              ? 'Check out equipment'
                              : 'Feature disabled',
                          icon: Icons.shopping_bag_rounded,
                          color: isEnabled ? AppColors.primary : Colors.grey,
                          isLarge: true,
                          onTap: isEnabled
                              ? () => Navigator.pushNamed(context, '/borrow')
                              : () => _showFeatureDisabledDialog(
                                  context,
                                  'Borrow Items',
                                ),
                        ),
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final returnEnabledAsync = ref.watch(
                        returnScreenEnabledProvider,
                      );
                      return returnEnabledAsync.when(
                        loading: () => ActionCard(
                          title: 'Return Items',
                          subtitle: 'Check in equipment',
                          icon: Icons.assignment_return_rounded,
                          color: AppColors.accent,
                          isLarge: true,
                          onTap: () {},
                        ),
                        error: (_, __) => ActionCard(
                          title: 'Return Items',
                          subtitle: 'Check in equipment',
                          icon: Icons.assignment_return_rounded,
                          color: AppColors.accent,
                          isLarge: true,
                          onTap: () => Navigator.pushNamed(context, '/return'),
                        ),
                        data: (isEnabled) => ActionCard(
                          title: 'Return Items',
                          subtitle: isEnabled
                              ? 'Check in equipment'
                              : 'Feature disabled',
                          icon: Icons.assignment_return_rounded,
                          color: isEnabled ? AppColors.accent : Colors.grey,
                          isLarge: true,
                          onTap: isEnabled
                              ? () => Navigator.pushNamed(context, '/return')
                              : () => _showFeatureDisabledDialog(
                                  context,
                                  'Return Items',
                                ),
                        ),
                      );
                    },
                  ),
                  ActionCard(
                    title: 'Admin Panel',
                    subtitle: 'Manage system',
                    icon: Icons.admin_panel_settings_rounded,
                    color: AppColors.error,
                    isLarge: true,
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildUserManualButton(context),
            const SizedBox(height: AppSpacing.md),
            Consumer(
              builder: (context, ref, child) {
                final recentRecordsAsync = ref.watch(recentBorrowRecordsWithNamesNotifierProvider);
                return _buildRecentActivityCard(recentRecordsAsync);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManualButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const StudentUserManualScreen(),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info.withValues(alpha: 0.1),
          foregroundColor: AppColors.info,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: BorderSide(
              color: AppColors.info.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline_rounded, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'User Manual',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(AsyncValue<List<Map<String, dynamic>>> recentRecordsAsync) {
    return AppCard(
      variant: AppCardVariant.outlined,
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: AppColors.textSecondary,
                    size: AppSpacing.iconSizeMd,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Recent Activity', style: AppTypography.h6),
                ],
              ),
            ),
            Expanded(
              child: recentRecordsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: AppSpacing.iconSizeXl,
                        color: AppColors.error,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text('Error loading recent activity', style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
                data: (recentRecords) {
                  if (recentRecords.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: AppSpacing.iconSizeXl,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text('No recent activity', style: AppTypography.bodyMedium),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: recentRecords.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final recordWithName = recentRecords[index];
                      final record = recordWithName['borrowRecord'] as BorrowRecord;
                      final studentName = recordWithName['studentName'] as String;
                      
                      final isReturned = record.returnedAt != null;
                      final activityDate = isReturned ? record.returnedAt! : record.borrowedAt;
                      final activityType = isReturned ? 'Returned' : 'Borrowed';
                      final activityIcon = isReturned ? Icons.assignment_return_rounded : Icons.shopping_bag_rounded;
                      final activityColor = isReturned ? AppColors.success : AppColors.primary;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              activityIcon,
                              size: AppSpacing.iconSizeSm,
                              color: activityColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        record.borrowId,
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        '• $activityType',
                                        style: AppTypography.caption.copyWith(
                                          color: activityColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    studentName,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(activityDate),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: activityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusText(record.status),
                                style: AppTypography.caption.copyWith(
                                  color: activityColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _getStatusText(BorrowStatus status) {
    switch (status) {
      case BorrowStatus.active:
        return 'Active';
      case BorrowStatus.returned:
        return 'Returned';
      case BorrowStatus.archived:
        return 'Archived';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showFeatureDisabledDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Text('Feature Disabled'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              '$featureName is currently disabled by the administrator. '
              'Please contact the admin if you need access to this feature.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
