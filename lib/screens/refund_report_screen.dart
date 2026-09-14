import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/refund_report_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/report_widgets.dart';

class RefundReportScreen extends StatefulWidget {
  const RefundReportScreen({super.key});

  @override
  State<RefundReportScreen> createState() => _RefundReportScreenState();
}

class _RefundReportScreenState extends State<RefundReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RefundReportNotifier>().load();
    });
  }

  Future<void> _pickPeriod() async {
    final notifier = context.read<RefundReportNotifier>();
    final period = await ReportPeriodPicker.pick(
      context,
      start: notifier.start,
      end: notifier.end,
    );
    if (period == null || !mounted) return;
    await notifier.load(start: period.start, end: period.end);
  }

  Future<void> _openSale(Sale sale) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RefundDetailSheet(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<RefundReportNotifier>();
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    return ReportScaffold(
      title: 'Laporan Refund',
      periodLabel: CurrencyFormatter.formatPeriod(notifier.start, notifier.end),
      onPickPeriod: _pickPeriod,
      isLoading: notifier.isLoading,
      errorMessage: notifier.errorMessage,
      onRefresh: notifier.load,
      child: ReportBody(
        children: [
          ReportHeroCard(
            icon: Icons.undo_rounded,
            color: palette.accentRed,
            label: 'Total direfund',
            value: CurrencyFormatter.format(notifier.totalAmount),
            subtitle: '${notifier.count} transaksi refund di periode ini',
          ),
          if (notifier.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              notifier.errorMessage!,
              style: TextStyle(color: scheme.error),
            ),
          ],
          ReportSection(
            title: 'Transaksi',
            child: notifier.sales.isEmpty
                ? Text(
                    'Tidak ada transaksi refund di periode ini.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : Column(
                    children: [
                      for (final sale in notifier.sales)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: scheme.errorContainer,
                          child: ListTile(
                            title: Text(
                              sale.saleNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                            subtitle: Text(
                              '${CurrencyFormatter.formatDateTime((sale.refundedAt ?? sale.soldAt).toLocal())}'
                              ' · ${sale.paymentLabel}\n'
                              '${sale.status.label} · ${sale.items.length} item'
                              '${sale.refundReason.isEmpty ? '' : ' · ${sale.refundReason}'}',
                              style: TextStyle(color: scheme.onErrorContainer),
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              CurrencyFormatter.format(sale.refundedTotal),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                            onTap: () => _openSale(sale),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RefundDetailSheet extends StatelessWidget {
  const _RefundDetailSheet({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsNotifier>().settings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(sale.saleNumber, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${CurrencyFormatter.formatDateTime(sale.soldAt.toLocal())} · ${sale.status.label}',
            ),
            if (sale.refundedAt != null)
              Text(
                'Refund: ${CurrencyFormatter.formatDateTime(sale.refundedAt!.toLocal())}',
              ),
            if (sale.refundReason.isNotEmpty)
              Text('Alasan: ${sale.refundReason}'),
            const SizedBox(height: 12),
            ...sale.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.productName),
                subtitle: Text(
                  '${item.qty.toStringAsFixed(0)} x ${CurrencyFormatter.format(item.unitPrice)}',
                ),
                trailing: Text(CurrencyFormatter.format(item.lineTotal)),
              ),
            ),
            if (sale.serviceChargeAmount > 0)
              Text(
                'Service ${CurrencyFormatter.format(sale.serviceChargeAmount)}',
              ),
            Text(
              'Direfund ${CurrencyFormatter.format(sale.refundedTotal)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!sale.status.isRefunded)
              Text('Sisa ${CurrencyFormatter.format(sale.netTotal)}'),
            Text(
              'Bayar ${sale.paymentLabel}'
              '${sale.cashAmount > 0 ? ' · Tunai ${CurrencyFormatter.format(sale.cashAmount)}' : ''}'
              '${sale.edcAmount > 0 ? ' · EDC ${CurrencyFormatter.format(sale.edcAmount)}' : ''}',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showReceiptDialog(
                context,
                settings: settings,
                sale: sale,
              ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Lihat struk'),
            ),
          ],
        ),
      ),
    );
  }
}
