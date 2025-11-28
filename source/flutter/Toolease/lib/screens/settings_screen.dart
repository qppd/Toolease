import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/setting.dart';
import '../shared/widgets/app_scaffold.dart';
import '../services/kiosk_service.dart';
import 'database_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return AppScaffold(
      title: 'Settings',
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading settings: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(settingsNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(settingsNotifierProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.screen_lock_landscape,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Screen Access Control',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Control which screens are accessible to users from the home screen.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingTile(
                          context,
                          ref,
                          title: 'Student Registration',
                          description: 'Allow students to register new accounts',
                          icon: Icons.person_add,
                          settingKey: SettingKeys.enableRegister,
                          currentValue: settings[SettingKeys.enableRegister] ?? 'true',
                        ),
                        const Divider(),
                        _buildSettingTile(
                          context,
                          ref,
                          title: 'Borrow Items',
                          description: 'Allow students to borrow items',
                          icon: Icons.shopping_cart,
                          settingKey: SettingKeys.enableBorrow,
                          currentValue: settings[SettingKeys.enableBorrow] ?? 'true',
                        ),
                        const Divider(),
                        _buildSettingTile(
                          context,
                          ref,
                          title: 'Return Items',
                          description: 'Allow students to return borrowed items',
                          icon: Icons.keyboard_return,
                          settingKey: SettingKeys.enableReturn,
                          currentValue: settings[SettingKeys.enableReturn] ?? 'true',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fullscreen,
                              color: Colors.purple.shade600,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Kiosk Mode',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Control whether the app runs in kiosk mode (fullscreen with hidden system UI).',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingTile(
                          context,
                          ref,
                          title: 'Enable Kiosk Mode',
                          description: 'Hide system navigation and run in fullscreen mode',
                          icon: Icons.fullscreen_exit,
                          settingKey: SettingKeys.enableKioskMode,
                          currentValue: settings[SettingKeys.enableKioskMode] ?? 'true',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage_outlined,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Database Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage and delete database records. Use with caution as these actions cannot be undone.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DatabaseManagementScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: const Text('Manage Database'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Disabled screens will not be accessible from the home screen\n'
                          '• Students will see a "Feature disabled" message when trying to access disabled screens\n'
                          '• Admin functions remain unaffected by these settings\n'
                          '• Database management allows deletion of data - use with extreme caution',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String description,
    required IconData icon,
    required String settingKey,
    required String currentValue,
  }) {
    final isEnabled = currentValue.toLowerCase() == 'true';
    
    return ListTile(
      leading: Icon(
        icon,
        size: 32,
        color: isEnabled ? Colors.green : Colors.grey,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch.adaptive(
        value: isEnabled,
        onChanged: (value) async {
          final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
          await settingsNotifier.toggleScreenAccess(settingKey);
          
          // Special handling for kiosk mode
          if (settingKey == SettingKeys.enableKioskMode) {
            await KioskService.toggleKioskMode(value);
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$title ${value ? 'enabled' : 'disabled'}',
                ),
                backgroundColor: value ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        activeColor: Colors.green,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }
}