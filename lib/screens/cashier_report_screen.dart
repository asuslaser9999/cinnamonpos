import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/report_notifier.dart';
import '../utils/currency_formatter.dart';

class CashierReportScreen extends StatefulWidget {
  const CashierReportScreen({super.key});

  @override
  State<CashierReportScreen> createState() => _CashierReportScreenState();
}

class _CashierReportScreenState extends State<CashierReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportNotifier>().load();
    });
  }

  Future<void> _pickPeriod() async {
    final notifier = context.read<ReportNotifier>();
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

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportNotifier>();
    final report = notifier.cashierReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kasir'),
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
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : report == null
          ? Center(child: Text(notifier.errorMessage ?? 'Tidak ada data.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MetricCard(
                  label: 'Uang tunai yang semestinya',
                  value: CurrencyFormatter.format(report.expectedCash),
                  subtitle:
                      'Yang harus ada di laci sekarang. '
                      'Penjualan via tenan tidak termasuk — biasanya dibayar '
                      'malam setelah closing atau besok pagi.',
                  emphasize: true,
                ),
                const SizedBox(height: 8),
                _MetricCard(
                  label: 'Nontunai / EDC',
                  value: CurrencyFormatter.format(report.edcTotal),
                  subtitle: 'Pembayaran kartu di kasir sendiri.',
                ),
                if (report.donationTotal > 0) ...[
                  const SizedBox(height: 8),
                  _MetricCard(
                    label: 'Donasi pembulatan',
                    value: CurrencyFormatter.format(report.donationTotal),
                    subtitle:
                        'Sudah termasuk di uang tunai yang semestinya.',
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Omzet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _MetricCard(
                  label: 'Total penjualan',
                  value: CurrencyFormatter.format(report.grossSales),
                  subtitle: 'Kasir sendiri + via tenan.',
                ),
                const SizedBox(height: 8),
                _MetricCard(
                  label: 'Kasir sendiri',
                  value: CurrencyFormatter.format(report.ownCashierTotal),
                ),
                const SizedBox(height: 8),
                _MetricCard(
                  label: 'Via tenan (belum masuk laci)',
                  value:
                      '${CurrencyFormatter.format(report.viaTenantTotal)}'
                      ' · ${report.viaTenantQty.toStringAsFixed(0)} pcs',
                  subtitle:
                      'Tagihan ke tenan. Tidak dihitung sebagai uang tunai.',
                ),
                if (report.receivableTotal > 0) ...[
                  const SizedBox(height: 8),
                  _MetricCard(
                    label: 'Tagihan tenan',
                    value: CurrencyFormatter.format(report.receivableTotal),
                  ),
                ],
                const SizedBox(height: 8),
                _MetricCard(
                  label: 'Transaksi / refund',
                  value: '${report.transactionCount} / ${report.refundCount}',
                ),
                if (report.serviceCharge > 0) ...[
                  const SizedBox(height: 8),
                  _MetricCard(
                    label: 'Service',
                    value: CurrencyFormatter.format(report.serviceCharge),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Produk terjual (kasir sendiri + via tenan)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (report.products.isEmpty)
                  const Text('Belum ada produk terjual.')
                else
                  ...report.products.map(
                    (row) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(row.productName),
                        subtitle: Text(
                          '${row.categoryName} · ${row.productType.label} · '
                          '${row.qty.toStringAsFixed(0)} pcs',
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(row.omzet),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.subtitle,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: emphasize ? scheme.primaryContainer : null,
      child: ListTile(
        title: Text(
          label,
          style: emphasize
              ? TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                )
              : null,
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: emphasize
                    ? TextStyle(color: scheme.onPrimaryContainer)
                    : null,
              ),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: emphasize ? scheme.onPrimaryContainer : null,
          ),
        ),
      ),
    );
  }
}
