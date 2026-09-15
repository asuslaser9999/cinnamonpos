import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/cashier_access_policy.dart';
import '../models/app_settings.dart';
import '../models/cashier_access_mode.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/daily_stock_notifier.dart';
import '../notifiers/expense_notifier.dart';
import '../notifiers/offline_sync_notifier.dart';
import '../notifiers/refund_report_notifier.dart';
import '../notifiers/report_notifier.dart';
import '../notifiers/sale_list_notifier.dart';
import '../notifiers/user_management_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/auth_actions.dart';
import '../widgets/app_navigation_drawer.dart';
import '../widgets/dark_background.dart';
import '../widgets/dashboard_menu_section.dart';
import '../widgets/store_branding_header.dart';
import '../widgets/store_hero_banner.dart';
import 'app_settings_screen.dart';
import 'cashier_access_screen.dart';
import 'cashier_report_screen.dart';
import 'category_list_screen.dart';
import 'daily_stock_screen.dart';
import 'expense_list_screen.dart';
import 'owner_report_screen.dart';
import 'pos_screen.dart';
import 'printer_settings_screen.dart';
import 'product_list_screen.dart';
import 'refund_report_screen.dart';
import 'sale_list_screen.dart';
import 'supplier_list_screen.dart';
import 'tenant_bill_report_screen.dart';
import 'tenant_list_screen.dart';
import 'user_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _accessTimer;
  CashierAccessMode? _scheduledMode;
  String? _scheduledStart;
  String? _scheduledEnd;
  ReportNotifier? _reports;
  SaleListNotifier? _sales;
  ExpenseNotifier? _expenses;
  DailyStockNotifier? _dailyStock;
  RefundReportNotifier? _refunds;
  UserManagementNotifier? _users;

  ReportNotifier get reports => _reports ??= ReportNotifier();
  SaleListNotifier get sales => _sales ??= SaleListNotifier();
  ExpenseNotifier get expenses => _expenses ??= ExpenseNotifier();
  DailyStockNotifier get dailyStock => _dailyStock ??= DailyStockNotifier();
  RefundReportNotifier get refunds => _refunds ??= RefundReportNotifier();
  UserManagementNotifier get users => _users ??= UserManagementNotifier();

  @override
  void dispose() {
    _accessTimer?.cancel();
    _reports?.dispose();
    _sales?.dispose();
    _expenses?.dispose();
    _dailyStock?.dispose();
    _refunds?.dispose();
    _users?.dispose();
    super.dispose();
  }

  void _maybeScheduleAccessRefresh(AppSettings settings) {
    if (_scheduledMode == settings.cashierAccessMode &&
        _scheduledStart == settings.cashierAccessStart &&
        _scheduledEnd == settings.cashierAccessEnd &&
        _accessTimer != null) {
      return;
    }

    _scheduledMode = settings.cashierAccessMode;
    _scheduledStart = settings.cashierAccessStart;
    _scheduledEnd = settings.cashierAccessEnd;
    _scheduleAccessRefresh(settings);
  }

  void _scheduleAccessRefresh(AppSettings settings) {
    _accessTimer?.cancel();
    final delay = CashierAccessPolicy.timeUntilNextBoundary(settings: settings);
    if (delay == null) return;

    _accessTimer = Timer(delay + const Duration(seconds: 1), () {
      if (mounted) setState(() {});
      _scheduleAccessRefresh(settings);
    });
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _pushProvided<T extends ChangeNotifier>(T notifier, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<T>.value(
          value: notifier,
          child: screen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final appSettings = context.watch<AppSettingsNotifier>().settings;
    final menuEnabled = CashierAccessPolicy.isMenuEnabled(
      isOwner: auth.isOwner,
      settings: appSettings,
    );
    final showOutsideHoursBanner =
        auth.isCashier &&
        appSettings.cashierAccessMode == CashierAccessMode.timeRestricted &&
        !menuEnabled;

    _maybeScheduleAccessRefresh(appSettings);

    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final offline = context.watch<OfflineSyncNotifier>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppNavigationDrawer(
        settings: appSettings,
        auth: auth,
        onPrinterSettings: () => _push(const PrinterSettingsScreen()),
        onAppSettings: () => _push(const AppSettingsScreen()),
        onUserManagement: () =>
            _pushProvided(users, const UserManagementScreen()),
        onSignOut: () => AuthActions.confirmAndSignOut(context),
      ),
      appBar: AppBar(
        title: Text(
          appSettings.storeName.trim().isEmpty
              ? AppSettings.defaults.storeName
              : appSettings.storeName.trim(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: DarkBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              if (appSettings.hasHeroBanner)
                SliverToBoxAdapter(
                  child: StoreHeroBanner(settings: appSettings),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    appSettings.hasHeroBanner ? 16 : 4,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!appSettings.hasHeroBanner) ...[
                        StoreBrandingHeader(
                          settings: appSettings,
                          showSubtitle: appSettings.showSubtitleOnDashboard,
                        ),
                        const SizedBox(height: 14),
                      ],
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppShapes.full),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                auth.isOwner
                                    ? Icons.admin_panel_settings_outlined
                                    : Icons.person_outline,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                auth.isOwner
                                    ? 'Owner · Akses penuh'
                                    : CashierAccessPolicy.cashierBadgeLabel(
                                        settings: appSettings,
                                        menuEnabled: menuEnabled,
                                      ),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showOutsideHoursBanner)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: CashierAccessBanner(settings: appSettings),
                  ),
                ),
              if (offline.hasPending)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Material(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: Icon(
                          Icons.cloud_upload_outlined,
                          color: scheme.onTertiaryContainer,
                        ),
                        title: Text(
                          '${offline.pendingCount} transaksi kasir menunggu diunggah.',
                        ),
                        subtitle: const Text(
                          'Akan terkirim otomatis saat internet kembali.',
                        ),
                        trailing: TextButton(
                          onPressed: offline.isSyncing
                              ? null
                              : () => offline.flush(),
                          child: const Text('Unggah'),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardFeaturedAction(
                        icon: Icons.point_of_sale_rounded,
                        label: 'Kasir',
                        subtitle: 'Tunai, EDC, atau via tenan',
                        color: palette.accentBlue,
                        enabled: menuEnabled,
                        onTap: menuEnabled
                            ? () => _push(const PosScreen())
                            : null,
                      ),
                      const SizedBox(height: 20),
                      DashboardMenuSection(
                        title: 'Transaksi',
                        subtitle: 'Daftar, stok harian, dan pengeluaran',
                        children: [
                          DashboardMenuRow(
                            icon: Icons.receipt_long_rounded,
                            label: 'Daftar Transaksi',
                            subtitle: 'Hari ini atau tanggal lain',
                            color: palette.accentTeal,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () => _pushProvided(sales, const SaleListScreen())
                                : null,
                          ),
                          DashboardMenuRow(
                            icon: Icons.inventory_2_outlined,
                            label: 'Stok Harian',
                            subtitle: 'Stok awal, terjual, sisa',
                            color: palette.accentOrange,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () => _pushProvided(
                                    dailyStock,
                                    const DailyStockScreen(),
                                  )
                                : null,
                          ),
                          DashboardMenuRow(
                            icon: Icons.payments_outlined,
                            label: 'Pengeluaran',
                            subtitle: 'Mengurangi laba bersih',
                            color: palette.accentPink,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () => _pushProvided(
                                    expenses,
                                    const ExpenseListScreen(),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DashboardMenuSection(
                        title: 'Laporan',
                        subtitle: 'Pilih periode tanggal di dalam laporan',
                        children: [
                          DashboardMenuRow(
                            icon: Icons.summarize_outlined,
                            label: 'Laporan Kasir',
                            subtitle: 'Penjualan, tunai, donasi & produk',
                            color: palette.accentGreen,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () =>
                                    _pushProvided(
                                      reports,
                                      const CashierReportScreen(),
                                    )
                                : null,
                          ),
                          DashboardMenuRow(
                            icon: Icons.undo_rounded,
                            label: 'Laporan Refund',
                            subtitle: 'Transaksi yang sudah direfund',
                            color: palette.accentRed,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () =>
                                    _pushProvided(
                                      refunds,
                                      const RefundReportScreen(),
                                    )
                                : null,
                          ),
                          DashboardMenuRow(
                            icon: Icons.storefront_outlined,
                            label: 'Tagihan Tenan',
                            subtitle: 'Qty & nominal dijual tenan lain',
                            color: palette.accentTeal,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () =>
                                    _pushProvided(
                                      reports,
                                      const TenantBillReportScreen(),
                                    )
                                : null,
                          ),
                          if (auth.isOwner)
                            DashboardMenuRow(
                              icon: Icons.assessment_rounded,
                              label: 'Laporan Owner',
                              subtitle: 'Laba kotor & laba bersih',
                              color: palette.accentPurple,
                              enabled: menuEnabled,
                              onTap: menuEnabled
                                  ? () =>
                                      _pushProvided(
                                        reports,
                                        const OwnerReportScreen(),
                                      )
                                  : null,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DashboardMenuSection(
                        title: 'Master Data',
                        children: [
                          DashboardMenuRow(
                            icon: Icons.category_outlined,
                            label: 'Kategori Produk',
                            color: palette.accentPink,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () =>
                                    _push(const CategoryListScreen())
                                : null,
                          ),
                          DashboardMenuRow(
                            icon: Icons.bakery_dining_outlined,
                            label: 'Produk',
                            subtitle: 'Buat sendiri & titipan',
                            color: palette.accentOrange,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () => _push(const ProductListScreen())
                                : null,
                          ),
                          DashboardMenuRow(
                            icon: Icons.local_shipping_outlined,
                            label: 'Supplier',
                            subtitle: 'Untuk produk titipan',
                            color: palette.accentIndigo,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () =>
                                    _push(const SupplierListScreen())
                                : null,
                          ),
                          DashboardMenuRow(
                            icon: Icons.store_mall_directory_outlined,
                            label: 'Tenan',
                            subtitle: 'Tenan cafe yang jual produk Anda',
                            color: palette.accentBlue,
                            enabled: menuEnabled,
                            onTap: menuEnabled
                                ? () => _push(const TenantListScreen())
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
