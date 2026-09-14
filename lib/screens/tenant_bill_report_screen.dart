import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/report_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/report_widgets.dart';

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
    final period = await ReportPeriodPicker.pick(
      context,
      start: notifier.start,
      end: notifier.end,
    );
    if (period == null || !mounted) return;
    await notifier.load(start: period.start, end: period.end);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportNotifier>();
    final report = notifier.tenantBillReport;
    final palette = context.palette;

    return ReportScaffold(
      title: 'Tagihan Tenan',
      periodLabel: CurrencyFormatter.formatPeriod(notifier.start, notifier.end),
      onPickPeriod: _pickPeriod,
      isLoading: notifier.isLoading,
      errorMessage: notifier.errorMessage,
      onRefresh: notifier.load,
      child: report == null
          ? null
          : ReportBody(
              children: [
                ReportHeroCard(
                  icon: Icons.storefront_outlined,
                  color: palette.accentTeal,
                  label: 'Total tagihan',
                  value: CurrencyFormatter.format(report.total),
                  subtitle:
                      'Produk Anda yang dijual tenan lain. '
                      'Uang belum masuk laci.',
                ),
                ReportSection(
                  title: 'Ringkasan',
                  child: ReportMetricGrid(
                    metrics: [
                      ReportMetric(
                        label: 'Qty terjual',
                        value: report.qty.toStringAsFixed(0),
                        icon: Icons.inventory_2_outlined,
                        color: palette.accentOrange,
                      ),
                      ReportMetric(
                        label: 'Subtotal',
                        value: CurrencyFormatter.format(report.subtotal),
                        icon: Icons.receipt_outlined,
                        color: palette.accentBlue,
                      ),
                      if (report.service > 0)
                        ReportMetric(
                          label: 'Service',
                          value: CurrencyFormatter.format(report.service),
                          icon: Icons.room_service_outlined,
                          color: palette.accentIndigo,
                        ),
                      ReportMetric(
                        label: 'Transaksi',
                        value: '${report.transactionCount}',
                        icon: Icons.receipt_long_outlined,
                        color: palette.accentPurple,
                      ),
                    ],
                  ),
                ),
                ReportSection(
                  title: 'Per tenan',
                  child: report.rows.isEmpty
                      ? Text(
                          'Belum ada penjualan via tenan di periode ini.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : Column(
                          children: [
                            for (final row in report.rows)
                              Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExpansionTile(
                                  title: Text(
                                    row.tenantName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${row.qty.toStringAsFixed(0)} pcs · '
                                    '${row.transactionCount} transaksi',
                                  ),
                                  trailing: Text(
                                    CurrencyFormatter.format(row.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
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
                                    for (final product in row.products)
                                      ListTile(
                                        dense: true,
                                        title: Text(product.productName),
                                        subtitle: Text(
                                          '${product.qty.toStringAsFixed(0)} pcs',
                                        ),
                                        trailing: Text(
                                          CurrencyFormatter.format(
                                            product.omzet,
                                          ),
                                        ),
                                      ),
                                  ],
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
