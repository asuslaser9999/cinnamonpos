import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/cinnamon_app.dart';
import 'app/config_error_screen.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env may be absent in CI; --dart-define fallbacks still work.
  }

  if (!SupabaseConfig.isConfigured) {
    runApp(const ConfigErrorScreen());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const CinnamonApp());
}
