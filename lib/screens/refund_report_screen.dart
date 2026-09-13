import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/refund_report_notifier.dart';
import '../utils/currency_formatter.dart';
import '../widgets/receipt_dialog.dart';

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
    final start = await showDatePicker(
      context: context,
      initialDate: notifier.start,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Dari tanggal',
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: notifier.end.isBefore(start) ? start : notifier.end,
      firstDate: start,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Sampai tanggal',
    );
    if (end == null || !mounted) return;
    await notifier.load(start: start, end: end);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Refund'),
        actions: [
          TextButton(
            onPressed: _pickPeriod,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                CurrencyFormatter.formatPeriod(notifier.start, notifier.end),
                textAlign: TextAlign.right,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: notifier.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (notifier.errorMessage != null)
                    Text(notifier.errorMessage!),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Ringkasan',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text('Jumlah refund: ${notifier.count}'),
                          Text(
                            'Total direfund: ${CurrencyFormatter.format(notifier.totalAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (notifier.sales.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Tidak ada transaksi refund di periode ini.'),
                      ),
                    )
                  else
                    ...notifier.sales.map((sale) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: ListTile(
                          title: Text(sale.saleNumber),
                          subtitle: Text(
                            '${CurrencyFormatter.formatDateTime((sale.refundedAt ?? sale.soldAt).toLocal())}'
                            ' · ${sale.paymentLabel}\n'
                            '${sale.status.label} · ${sale.items.length} item'
                            '${sale.refundReason.isEmpty ? '' : ' · ${sale.refundReason}'}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            CurrencyFormatter.format(sale.refundedTotal),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onTap: () => _openSale(sale),
                        ),
                      );
                    }),
                ],
              ),
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
