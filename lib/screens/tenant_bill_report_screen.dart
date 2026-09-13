import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/report_notifier.dart';
import '../utils/currency_formatter.dart';

class TenantBillReportScreen extends StatefulWidget {
  const TenantBillReportScreen({super.key});

  @override
  State<TenantBillReportScreen> createState() => _TenantBillReportScreenState();
}

class _TenantBillReportScreenState extends State<TenantBillReportScreen> {
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
    final report = notifier.tenantBillReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan Tenan'),
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
                Text(
                  'Produk Anda yang dijual tenan lain. '
                  'Uang belum masuk laci — ini tagihan yang bisa diminta.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _MetricCard(
                  label: 'Qty terjual',
                  value: report.qty.toStringAsFixed(0),
                ),
                const SizedBox(height: 8),
                _MetricCard(
                  label: 'Subtotal',
                  value: CurrencyFormatter.format(report.subtotal),
                ),
                if (report.service > 0) ...[
                  const SizedBox(height: 8),
                  _MetricCard(
                    label: 'Service',
                    value: CurrencyFormatter.format(report.service),
                  ),
                ],
                const SizedBox(height: 8),
                _MetricCard(
                  label: 'Total tagihan',
                  value: CurrencyFormatter.format(report.total),
                ),
                const SizedBox(height: 8),
                _MetricCard(
                  label: 'Transaksi',
                  value: '${report.transactionCount}',
                ),
                const SizedBox(height: 20),
                Text(
                  'Per tenan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (report.rows.isEmpty)
                  const Text('Belum ada penjualan via tenan di periode ini.')
                else
                  ...report.rows.map((row) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(row.tenantName),
                        subtitle: Text(
                          '${row.qty.toStringAsFixed(0)} pcs · '
                          '${row.transactionCount} transaksi',
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(row.total),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        children: [
                          ListTile(
                            dense: true,
                            title: const Text('Subtotal'),
                            trailing: Text(
                              CurrencyFormatter.format(row.subtotal),
                            ),
                          ),
                          if (row.service > 0)
                            ListTile(
                              dense: true,
                              title: const Text('Service'),
                              trailing: Text(
                                CurrencyFormatter.format(row.service),
                              ),
                            ),
                          ...row.products.map(
                            (product) => ListTile(
                              dense: true,
                              title: Text(product.productName),
                              subtitle: Text(
                                '${product.qty.toStringAsFixed(0)} pcs',
                              ),
                              trailing: Text(
                                CurrencyFormatter.format(product.omzet),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
