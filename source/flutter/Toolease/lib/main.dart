import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/borrow_screen.dart';
import 'screens/return_screen.dart';
import 'screens/admin_login_screen.dart';
import 'services/kiosk_service.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: ToolEaseApp()));
}

class ToolEaseApp extends ConsumerStatefulWidget {
  const ToolEaseApp({super.key});

  @override
  ConsumerState<ToolEaseApp> createState() => _ToolEaseAppState();
}

class _ToolEaseAppState extends ConsumerState<ToolEaseApp> {
  @override
  void initState() {
    super.initState();
    _initializeKioskMode();
  }

  Future<void> _initializeKioskMode() async {
    try {
      final kioskEnabled = await ref.read(kioskModeEnabledProvider.future);
      await KioskService.initializeKioskMode(kioskEnabled);
    } catch (e) {
      print('Error initializing kiosk mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToolEase',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/borrow': (context) => const BorrowScreen(),
        '/return': (context) => const ReturnScreen(),
        '/login': (context) => const AdminLoginScreen(),
      },
    );
  }
}
