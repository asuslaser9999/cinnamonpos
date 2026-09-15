import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/daily_stock.dart';
import '../notifiers/daily_stock_notifier.dart';
import '../notifiers/offline_sync_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class DailyStockScreen extends StatefulWidget {
  const DailyStockScreen({super.key});

  @override
  State<DailyStockScreen> createState() => _DailyStockScreenState();
}

class _DailyStockScreenState extends State<DailyStockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyStockNotifier>().load();
    });
  }

  Future<void> _pickDate() async {
    final notifier = context.read<DailyStockNotifier>();
    final picked = await showDatePicker(
      context: context,
      initialDate: notifier.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Tanggal stok harian',
    );
    if (picked == null || !mounted) return;
    await notifier.load(date: picked);
  }

  Future<void> _save() async {
    final notifier = context.read<DailyStockNotifier>();
    final success = await notifier.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Stok harian disimpan.'
              : (notifier.errorMessage ?? 'Gagal menyimpan.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<DailyStockNotifier>();
    final pending = context.watch<OfflineSyncNotifier>().pendingCount;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Harian'),
        actions: [
          TextButton(
            onPressed: _pickDate,
            child: Text(CurrencyFormatter.formatDate(notifier.date)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: notifier.isSaving || notifier.isLoading ? null : _save,
        icon: notifier.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(notifier.isSaving ? 'Menyimpan...' : 'Simpan'),
      ),
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Satu kue satu baris. Pagi isi stok awal, malam isi sisa. '
                        'Kolom kasir dan tenan terisi otomatis.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (pending > 0) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: scheme.tertiaryContainer,
                          borderRadius: AppShapes.borderSmall,
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.cloud_upload_outlined),
                            title: Text(
                              '$pending transaksi masih mengantri. '
                              'Qty terjual belum lengkap sampai terunggah.',
                            ),
                          ),
                        ),
                      ],
                      if (notifier.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          notifier.errorMessage!,
                          style: TextStyle(color: scheme.error),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SummaryChip(
                            label: '${notifier.lines.length} kue',
                            color: scheme.surfaceContainerHigh,
                          ),
                          _SummaryChip(
                            label: '${notifier.countedCount} sudah diisi sisa',
                            color: scheme.surfaceContainerHigh,
                          ),
                          _SummaryChip(
                            label: notifier.mismatchCount == 0
                                ? 'Tidak ada selisih'
                                : '${notifier.mismatchCount} selisih',
                            color: notifier.mismatchCount == 0
                                ? scheme.secondaryContainer
                                : scheme.errorContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: notifier.lines.isEmpty
                      ? const Center(child: Text('Belum ada produk aktif.'))
                      : _StockTable(
                          key: ValueKey(AppDateRange.isoDate(notifier.date)),
                          date: notifier.date,
                          lines: notifier.lines,
                          tenantColumns: notifier.tenantColumns,
                        ),
                ),
              ],
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _StockTable extends StatefulWidget {
  const _StockTable({
    super.key,
    required this.date,
    required this.lines,
    required this.tenantColumns,
  });

  final DateTime date;
  final List<DailyStockLine> lines;
  final List<DailyStockTenantColumn> tenantColumns;

  @override
  State<_StockTable> createState() => _StockTableState();
}

class _StockTableState extends State<_StockTable> {
  final _opening = <String, TextEditingController>{};
  final _closing = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _StockTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _disposeControllers();
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _syncControllers() {
    for (final line in widget.lines) {
      _opening.putIfAbsent(
        line.productId,
        () => TextEditingController(text: _qtyText(line.openingQty)),
      );
      _closing.putIfAbsent(
        line.productId,
        () => TextEditingController(
          text: line.closingQty == null ? '' : _qtyText(line.closingQty!),
        ),
      );
    }
  }

  void _disposeControllers() {
    for (final controller in _opening.values) {
      controller.dispose();
    }
    for (final controller in _closing.values) {
      controller.dispose();
    }
    _opening.clear();
    _closing.clear();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<DailyStockNotifier>();
    final scheme = Theme.of(context).colorScheme;
    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final tenantCount = widget.tenantColumns.length;
    final columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(2.4),
      1: const FixedColumnWidth(88),
      2: const FixedColumnWidth(72),
    };
    for (var i = 0; i < tenantCount; i++) {
      columnWidths[3 + i] = const FixedColumnWidth(96);
    }
    columnWidths[3 + tenantCount] = const FixedColumnWidth(88);
    columnWidths[4 + tenantCount] = const FixedColumnWidth(80);

    return RefreshIndicator(
      onRefresh: () => notifier.load(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth > 32
                      ? constraints.maxWidth - 32
                      : constraints.maxWidth,
                ),
                child: Table(
                  border: AppTableStyles.tableBorderOf(context),
                  columnWidths: columnWidths,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: AppTableStyles.headerDecorationOf(context),
                      children: [
                        _Head('Kue', style: headerStyle),
                        _Head('Stok awal', style: headerStyle, center: true),
                        _Head('Kasir', style: headerStyle, center: true),
                        for (final tenant in widget.tenantColumns)
                          _Head(tenant.name, style: headerStyle, center: true),
                        _Head('Sisa', style: headerStyle, center: true),
                        _Head('Selisih', style: headerStyle, center: true),
                      ],
                    ),
                    for (final line in widget.lines)
                      TableRow(
                        decoration: BoxDecoration(
                          color: line.hasMismatch
                              ? scheme.errorContainer.withValues(alpha: 0.35)
                              : null,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Text(
                              line.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _qtyCell(
                            _opening[line.productId]!,
                            onChanged: (value) {
                              notifier.setOpening(line.productId, value);
                              setState(() {});
                            },
                          ),
                          _readCell(_qtyLabel(line.soldOwnQty)),
                          for (final tenant in widget.tenantColumns)
                            _readCell(
                              _qtyLabel(line.soldForTenant(tenant.id)),
                            ),
                          _qtyCell(
                            _closing[line.productId]!,
                            onChanged: (_) {
                              final raw = _closing[line.productId]!.text.trim();
                              notifier.setClosing(
                                line.productId,
                                raw.isEmpty
                                    ? null
                                    : CurrencyFormatter.parse(raw),
                              );
                              setState(() {});
                            },
                          ),
                          _varianceCell(line, scheme),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _qtyCell(
    TextEditingController controller, {
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        onChanged: (value) => onChanged(CurrencyFormatter.parse(value)),
      ),
    );
  }

  Widget _readCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _varianceCell(DailyStockLine line, ColorScheme scheme) {
    final closingRaw = _closing[line.productId]?.text.trim() ?? '';
    if (closingRaw.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text('—', textAlign: TextAlign.center),
      );
    }
    final opening = CurrencyFormatter.parse(
      _opening[line.productId]?.text ?? '',
    );
    final closing = CurrencyFormatter.parse(closingRaw);
    final variance = opening - line.soldQty - closing;
    final mismatch = variance.abs() > 0.0001;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        _qtyLabel(variance),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: mismatch ? scheme.error : scheme.secondary,
        ),
      ),
    );
  }

  static String _qtyText(double value) {
    if (value <= 0) return '';
    return _qtyLabel(value);
  }

  static String _qtyLabel(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _Head extends StatelessWidget {
  const _Head(this.label, {this.style, this.center = false});

  final String label;
  final TextStyle? style;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.start,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
