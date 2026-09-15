import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/app_settings_notifier.dart';
import '../notifiers/catalog_notifiers.dart';
import '../notifiers/offline_sync_notifier.dart';
import '../notifiers/pos_notifier.dart';
import '../notifiers/printer_settings_notifier.dart';
import '../widgets/pos_cart_panel.dart';
import '../widgets/pos_product_catalog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String? _categoryId;
  String _searchQuery = '';
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductNotifier>().load();
      context.read<CategoryNotifier>().load();
      context.read<PartnerTenantNotifier>().load();
      context.read<PrinterSettingsNotifier>().load();
      final settings = context.read<AppSettingsNotifier>().settings;
      context.read<PosNotifier>().configureFromSettings(settings);
    });
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kosongkan tabel?'),
          content: const Text(
            'Semua produk di tabel sementara akan dihapus. '
            'Transaksi yang sudah tersimpan tidak berubah.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kosongkan'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context.read<PosNotifier>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLines = context.select<PosNotifier, bool>(
      (pos) => pos.lines.isNotEmpty,
    );
    final products = context.watch<ProductNotifier>();
    final categories = context.watch<CategoryNotifier>().activeItems;
    final query = _searchQuery.trim().toLowerCase();
    final filtered = products.activeItems.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          (p.categoryName ?? '').toLowerCase().contains(query);
    }).toList();
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final imageSize = context
        .watch<AppSettingsNotifier>()
        .settings
        .posProductImageSize;

    final catalog = PosProductCatalog(
      categories: categories,
      selectedCategoryId: _categoryId,
      onSelectCategory: (id) => setState(() => _categoryId = id),
      searchOpen: _searchOpen,
      searchQuery: _searchQuery,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      onToggleSearch: () {
        setState(() {
          _searchOpen = !_searchOpen;
          if (!_searchOpen) _searchQuery = '';
        });
      },
      isLoading: products.isLoading,
      products: filtered,
      wide: wide,
      imageSize: imageSize,
      emptyMessage: products.errorMessage,
    );

    final offline = context.watch<OfflineSyncNotifier>();
    final scheme = Theme.of(context).colorScheme;
    final showOfflineBar = offline.hasPending || products.usingCache;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          if (hasLines)
            TextButton.icon(
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Kosongkan'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (showOfflineBar)
            Material(
              color: scheme.tertiaryContainer,
              child: ListTile(
                dense: true,
                leading: Icon(
                  offline.hasPending
                      ? Icons.cloud_upload_outlined
                      : Icons.wifi_off_outlined,
                  color: scheme.onTertiaryContainer,
                ),
                title: Text(
                  offline.hasPending
                      ? '${offline.pendingCount} transaksi menunggu diunggah '
                            'saat internet kembali.'
                      : (products.errorMessage ??
                            'Mode offline: daftar produk dari perangkat ini.'),
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
                trailing: offline.hasPending
                    ? TextButton(
                        onPressed: offline.isSyncing
                            ? null
                            : () => offline.flush(),
                        child: Text(
                          offline.isSyncing ? 'Mengunggah...' : 'Unggah',
                        ),
                      )
                    : null,
              ),
            ),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: catalog),
                      const VerticalDivider(width: 1),
                      const Expanded(flex: 5, child: PosCartPanel()),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 5, child: catalog),
                      const Divider(height: 1),
                      const Expanded(flex: 5, child: PosCartPanel()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
