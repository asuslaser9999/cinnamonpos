import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/auth_gate.dart';
import '../notifiers/auth_notifier.dart';

/// Shared auth-related UI actions.
class AuthActions {
  AuthActions._();

  static Future<bool> confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  static Future<void> signOutAndNavigateToLogin(BuildContext context) async {
    await context.read<AuthNotifier>().signOut();
    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  static Future<void> confirmAndSignOut(BuildContext context) async {
    final confirmed = await confirmSignOut(context);
    if (!confirmed || !context.mounted) return;
    await signOutAndNavigateToLogin(context);
  }
}
