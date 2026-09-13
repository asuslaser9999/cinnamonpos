import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../core/constants/app_defaults.dart';
import '../theme/app_theme.dart';

/// Shown when Supabase credentials are missing or still use placeholder values.
class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppDefaults.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.settings_suggest_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Konfigurasi Supabase Belum Lengkap',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Salin .env.example menjadi .env lalu isi SUPABASE_URL '
                  'dan SUPABASE_ANON_KEY dari dashboard Supabase.\n\n'
                  'Alternatif build release:\n'
                  'flutter build apk '
                  '--dart-define=SUPABASE_URL=... '
                  '--dart-define=SUPABASE_ANON_KEY=...',
                ),
                const SizedBox(height: 16),
                Text(
                  'URL saat ini: ${SupabaseConfig.url}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
