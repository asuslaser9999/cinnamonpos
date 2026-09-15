import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/app_settings_notifier.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/offline_sync_notifier.dart';

/// Menarik pengaturan akses kasir dari Supabase saat login dan app resume.
class RemoteSettingsSync extends StatefulWidget {
  const RemoteSettingsSync({super.key, required this.child});

  final Widget child;

  @override
  State<RemoteSettingsSync> createState() => _RemoteSettingsSyncState();
}

class _RemoteSettingsSyncState extends State<RemoteSettingsSync>
    with WidgetsBindingObserver {
  AuthNotifier? _auth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfAuthenticated());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthNotifier>();
    if (_auth != auth) {
      _auth?.removeListener(_syncIfAuthenticated);
      _auth = auth;
      _auth!.addListener(_syncIfAuthenticated);
    }
    _syncIfAuthenticated();
  }

  @override
  void dispose() {
    _auth?.removeListener(_syncIfAuthenticated);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncIfAuthenticated();
    }
  }

  void _syncIfAuthenticated() {
    if (!mounted) return;
    final auth = context.read<AuthNotifier>();
    final offline = context.read<OfflineSyncNotifier>();
    if (auth.status != AuthStatus.authenticated) {
      offline.stopAutoSync();
      return;
    }
    offline.startAutoSync();
    context.read<AppSettingsNotifier>().syncFromRemote();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
