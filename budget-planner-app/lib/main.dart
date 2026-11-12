import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_gate_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/budget_setup/screens/master_plan_input_screen.dart';
import 'features/budget_setup/screens/plan_overview_screen.dart';
import 'features/daily_checkin/screens/daily_home_screen.dart';
import 'features/reports/screens/monthly_report_screen.dart';
import 'features/profile/screens/profile_screen.dart';

import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style (transparent status bar with dark icons)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization skipped/failed: $e');
  }

  runApp(
    const ProviderScope(
      child: BudgetPlannerApp(),
    ),
  );
}

class BudgetPlannerApp extends ConsumerWidget {
  const BudgetPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Budget Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGateScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/setup': (context) => const MasterPlanInputScreen(),
        '/home': (context) => const MainShellScreen(),
        '/overview': (context) => const PlanOverviewScreen(),
        '/report': (context) => const MonthlyReportScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
