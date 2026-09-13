import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/constants/app_defaults.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/catalog_notifiers.dart';
import '../notifiers/expense_notifier.dart';
import '../notifiers/pos_notifier.dart';
import '../notifiers/printer_settings_notifier.dart';
import '../notifiers/refund_report_notifier.dart';
import '../notifiers/report_notifier.dart';
import '../notifiers/sale_list_notifier.dart';
import '../notifiers/user_management_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/remote_settings_sync.dart';
import 'auth_gate.dart';

/// Root widget with global state providers and theme.
class CinnamonApp extends StatelessWidget {
  const CinnamonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders,
      child: RemoteSettingsSync(
        child: Consumer<AppSettingsNotifier>(
          builder: (context, settings, _) {
            return MaterialApp(
              title: AppDefaults.appTitle,
              debugShowCheckedModeBanner: false,
              locale: const Locale('id', 'ID'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
              theme: AppTheme.forAppearance(settings.settings.appearance),
              themeMode: ThemeMode.light,
              home: const AuthGate(),
            );
          },
        ),
      ),
    );
  }
}

final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AppSettingsNotifier()),
  ChangeNotifierProvider(create: (_) => AuthNotifier()),
  ChangeNotifierProvider(create: (_) => PrinterSettingsNotifier()),
  ChangeNotifierProvider(create: (_) => UserManagementNotifier()),
  ChangeNotifierProvider(create: (_) => CategoryNotifier()),
  ChangeNotifierProvider(create: (_) => SupplierNotifier()),
  ChangeNotifierProvider(create: (_) => PartnerTenantNotifier()),
  ChangeNotifierProvider(create: (_) => ProductNotifier()),
  ChangeNotifierProvider(create: (_) => PosNotifier()),
  ChangeNotifierProvider(create: (_) => SaleListNotifier()),
  ChangeNotifierProvider(create: (_) => ExpenseNotifier()),
  ChangeNotifierProvider(create: (_) => ReportNotifier()),
  ChangeNotifierProvider(create: (_) => RefundReportNotifier()),
];
