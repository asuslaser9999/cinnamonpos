import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/guards/owner_gate.dart';
import '../notifiers/report_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/report_widgets.dart';

class OwnerReportScreen extends StatefulWidget {
  const OwnerReportScreen({super.key});

  @override
  State<OwnerReportScreen> createState() => _OwnerReportScreenState();
}

class _OwnerReportScreenState extends State<OwnerReportScreen> {
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
    final report = notifier.ownerReport;
    final palette = context.palette;

    return OwnerGate(
      child: ReportScaffold(
        title: 'Laporan Owner',
        periodLabel: CurrencyFormatter.formatPeriod(
          notifier.start,
          notifier.end,
        ),
        onPickPeriod: _pickPeriod,
        isLoading: notifier.isLoading,
        errorMessage: notifier.errorMessage,
        onRefresh: notifier.load,
        child: report == null
            ? null
            : ReportBody(
                children: [
                  ReportHeroCard(
                    icon: Icons.assessment_rounded,
                    color: palette.accentPurple,
                    label: 'Laba bersih',
                    value: CurrencyFormatter.format(report.netProfit),
                    subtitle:
                        'Laba kotor − pengeluaran. Donasi tidak masuk laba.',
                  ),
                  ReportSection(
                    title: 'Omzet',
                    child: ReportMetricGrid(
                      metrics: [
                        ReportMetric(
                          label: 'Penjualan',
                          value: CurrencyFormatter.format(
                            report.cashierReport.grossSales,
                          ),
                          icon: Icons.trending_up_rounded,
                          color: palette.accentGreen,
                        ),
                        ReportMetric(
                          label: 'Kasir sendiri',
                          value: CurrencyFormatter.format(
                            report.cashierReport.ownCashierTotal,
                          ),
                          icon: Icons.point_of_sale_rounded,
                          color: palette.accentOrange,
                        ),
                        ReportMetric(
                          label: 'Via tenan',
                          value: CurrencyFormatter.format(report.viaTenantOmzet),
                          icon: Icons.storefront_outlined,
                          color: palette.accentTeal,
                        ),
                        ReportMetric(
                          label: 'Buat sendiri',
                          value: CurrencyFormatter.format(
                            report.ownProductionOmzet,
                          ),
                          icon: Icons.bakery_dining_outlined,
                          color: palette.accentPink,
                        ),
                        ReportMetric(
                          label: 'Titipan',
                          value: CurrencyFormatter.format(
                            report.consignmentOmzet,
                          ),
                          icon: Icons.inventory_2_outlined,
                          color: palette.accentIndigo,
                        ),
                        if (report.cashierReport.serviceCharge > 0)
                          ReportMetric(
                            label: 'Service',
                            value: CurrencyFormatter.format(
                              report.cashierReport.serviceCharge,
                            ),
                            icon: Icons.room_service_outlined,
                            color: palette.accentBlue,
                          ),
                      ],
                    ),
                  ),
                  ReportSection(
                    title: 'Uang di tangan',
                    subtitle: 'Tagihan tenan belum diterima',
                    child: ReportMetricGrid(
                      metrics: [
                        ReportMetric(
                          label: 'Tunai (diterima)',
                          value: CurrencyFormatter.format(
                            report.cashierReport.cashTotal,
                          ),
                          subtitle: 'Termasuk donasi pembulatan',
                          icon: Icons.payments_rounded,
                          color: palette.accentGreen,
                        ),
                        ReportMetric(
                          label: 'Nontunai / EDC',
                          value: CurrencyFormatter.format(
                            report.cashierReport.edcTotal,
                          ),
                          icon: Icons.credit_card_outlined,
                          color: palette.accentBlue,
                        ),
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
                    subtitle:
                        'Pembulatan yang dipilih pelanggan. Bukan omzet toko.',
                    child: ReportDonationRecap(
                      total: report.cashierReport.donationTotal,
                      count: report.cashierReport.donationCount,
                      donations: report.cashierReport.donations,
                    ),
                  ),
                  ReportSection(
                    title: 'Laba',
                    subtitle:
                        'Laba kotor = omzet produk − HPP + service, termasuk via tenan.',
                    child: ReportMetricGrid(
                      metrics: [
                        ReportMetric(
                          label: 'HPP / modal',
                          value: CurrencyFormatter.format(report.costOfGoods),
                          icon: Icons.shopping_bag_outlined,
                          color: palette.accentOrange,
                        ),
                        ReportMetric(
                          label: 'Laba kotor',
                          value: CurrencyFormatter.format(report.grossProfit),
                          icon: Icons.stacked_line_chart_rounded,
                          color: palette.accentGreen,
                        ),
                        ReportMetric(
                          label: 'Pengeluaran',
                          value: CurrencyFormatter.format(report.expenseTotal),
                          icon: Icons.money_off_outlined,
                          color: palette.accentRed,
                        ),
                        ReportMetric(
                          label: 'Laba bersih',
                          value: CurrencyFormatter.format(report.netProfit),
                          icon: Icons.account_balance_wallet_outlined,
                          color: palette.accentPurple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
