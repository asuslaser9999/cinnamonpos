import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../notifiers/auth_notifier.dart';

/// Blocks non-owner users from owner-only screens.
class OwnerGate extends StatelessWidget {
  const OwnerGate({
    super.key,
    required this.child,
    this.title = 'Akses Ditolak',
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    if (!auth.isOwner) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Halaman ini hanya dapat diakses oleh Owner.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return child;
  }
}
