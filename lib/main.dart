import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme.dart';

/// NutriSmart: log meals, understand their nutrition and get personalised
/// advice. Entry point of the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load(); // read saved data from the phone
  await NotificationService.instance.init();
  runApp(NutriSmartApp(state: state));
}

class NutriSmartApp extends StatelessWidget {
  final AppState state;
  const NutriSmartApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'NutriSmart',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const _Root(),
      ),
    );
  }
}

/// Shows onboarding until a profile exists, then the main app.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return state.hasProfile ? const HomeShell() : const OnboardingScreen();
  }
}
