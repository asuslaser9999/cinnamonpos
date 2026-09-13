import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/cashier_access_policy.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/auth_notifier.dart';
import '../screens/cashier_access_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';

/// Routes users based on authentication state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    switch (auth.status) {
      case AuthStatus.initial:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        final settings = context.watch<AppSettingsNotifier>().settings;
        if (CashierAccessPolicy.isFullyBlocked(
          isOwner: auth.isOwner,
          settings: settings,
        )) {
          return const CashierBlockedScreen();
        }
        return const DashboardScreen();
    }
  }
}
