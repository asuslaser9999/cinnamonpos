import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/report_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/report_widgets.dart';

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
    final report = notifier.cashierReport;
    final palette = context.palette;

    return ReportScaffold(
      title: 'Laporan Kasir',
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
                  icon: Icons.payments_rounded,
                  color: palette.accentGreen,
                  label: 'Uang tunai yang semestinya',
                  value: CurrencyFormatter.format(report.expectedCash),
                  subtitle:
                      'Yang harus ada di laci sekarang, termasuk donasi. '
                      'Penjualan via tenan tidak termasuk.',
                ),
                ReportSection(
                  title: 'Pembayaran',
                  child: ReportMetricGrid(
                    metrics: [
                      ReportMetric(
                        label: 'Nontunai / EDC',
                        value: CurrencyFormatter.format(report.edcTotal),
                        subtitle: 'Kartu di kasir sendiri',
                        icon: Icons.credit_card_outlined,
                        color: palette.accentBlue,
                      ),
                      if (report.receivableTotal > 0)
                        ReportMetric(
                          label: 'Tagihan tenan',
                          value: CurrencyFormatter.format(
                            report.receivableTotal,
                          ),
                          icon: Icons.storefront_outlined,
                          color: palette.accentTeal,
                        ),
                    ],
                  ),
                ),
                ReportSection(
                  title: 'Donasi',
                  subtitle: 'Pembulatan yang dipilih pelanggan saat bayar tunai',
                  child: ReportDonationRecap(
                    total: report.donationTotal,
                    count: report.donationCount,
                    donations: report.donations,
                  ),
                ),
                ReportSection(
                  title: 'Omzet',
                  child: ReportMetricGrid(
                    metrics: [
                      ReportMetric(
                        label: 'Total penjualan',
                        value: CurrencyFormatter.format(report.grossSales),
                        subtitle: 'Kasir sendiri + via tenan',
                        icon: Icons.trending_up_rounded,
                        color: palette.accentGreen,
                      ),
                      ReportMetric(
                        label: 'Kasir sendiri',
                        value: CurrencyFormatter.format(report.ownCashierTotal),
                        icon: Icons.point_of_sale_rounded,
                        color: palette.accentOrange,
                      ),
                      ReportMetric(
                        label: 'Via tenan',
                        value: CurrencyFormatter.format(report.viaTenantTotal),
                        subtitle:
                            '${report.viaTenantQty.toStringAsFixed(0)} pcs · belum masuk laci',
                        icon: Icons.storefront_outlined,
                        color: palette.accentTeal,
                      ),
                      ReportMetric(
                        label: 'Transaksi / refund',
                        value:
                            '${report.transactionCount} / ${report.refundCount}',
                        icon: Icons.receipt_long_outlined,
                        color: palette.accentPurple,
                      ),
                      if (report.serviceCharge > 0)
                        ReportMetric(
                          label: 'Service',
                          value: CurrencyFormatter.format(report.serviceCharge),
                          icon: Icons.room_service_outlined,
                          color: palette.accentIndigo,
                        ),
                    ],
                  ),
                ),
                ReportSection(
                  title: 'Produk terjual',
                  subtitle: 'Kasir sendiri + via tenan',
                  child: report.products.isEmpty
                      ? Text(
                          'Belum ada produk terjual.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : Column(
                          children: [
                            for (final row in report.products)
                              ReportProductTile(
                                name: row.productName,
                                detail:
                                    '${row.categoryName} · ${row.productType.label} · '
                                    '${row.qty.toStringAsFixed(0)} pcs',
                                amount: CurrencyFormatter.format(row.omzet),
                              ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
