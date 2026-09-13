import 'package:flutter/material.dart';

import '../core/constants/app_defaults.dart';
import '../models/app_settings.dart';
import '../notifiers/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/store_branding_header.dart';

/// Drawer navigasi untuk pengaturan, akun, dan utilitas.
class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.settings,
    required this.auth,
    required this.onPrinterSettings,
    required this.onAppSettings,
    required this.onUserManagement,
    required this.onSignOut,
  });

  final AppSettings settings;
  final AuthNotifier auth;
  final VoidCallback onPrinterSettings;
  final VoidCallback onAppSettings;
  final VoidCallback onUserManagement;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StoreBrandingHeader(
                      settings: settings,
                      avatarSize: 48,
                      iconSize: 24,
                      nameFontSize: 16,
                      showSubtitle: false,
                      center: false,
                    ),
                  ),
                  _RoleChip(isOwner: auth.isOwner),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Pengaturan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.print_rounded,
                    label: 'Pengaturan Printer',
                    subtitle: 'Bluetooth thermal & struk',
                    color: context.palette.accentTeal,
                    onTap: () {
                      Navigator.pop(context);
                      onPrinterSettings();
                    },
                  ),
                  if (auth.isOwner) ...[
                    _DrawerTile(
                      icon: Icons.tune_rounded,
                      label: 'Pengaturan Aplikasi',
                      subtitle: 'Tema, branding, jam akses kasir',
                      color: context.palette.accentOrange,
                      onTap: () {
                        Navigator.pop(context);
                        onAppSettings();
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.manage_accounts_rounded,
                      label: 'Kelola User',
                      subtitle: 'Akun owner & kasir',
                      color: context.palette.accentPink,
                      onTap: () {
                        Navigator.pop(context);
                        onUserManagement();
                      },
                    ),
                  ],
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      'Akun',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    label: 'Keluar',
                    subtitle: auth.isOwner ? 'Akun owner' : 'Akun kasir',
                    color: context.palette.accentRed,
                    onTap: () {
                      Navigator.pop(context);
                      onSignOut();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${AppDefaults.appTitle} v1.0.0',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppShapes.full),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner
                ? Icons.admin_panel_settings_outlined
                : Icons.person_outline,
            size: 14,
            color: scheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            isOwner ? 'Owner' : 'Kasir',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: AppShapes.borderSmall,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
