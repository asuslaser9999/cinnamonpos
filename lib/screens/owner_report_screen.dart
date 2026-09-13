import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/guards/owner_gate.dart';
import '../notifiers/report_notifier.dart';
import '../utils/currency_formatter.dart';

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
    final report = notifier.ownerReport;

    return OwnerGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Owner'),
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
                  _row('Penjualan', report.cashierReport.grossSales),
                  _row('Kasir sendiri', report.cashierReport.ownCashierTotal),
                  _row('Via tenan', report.viaTenantOmzet),
                  _row('Buat sendiri', report.ownProductionOmzet),
                  _row('Titipan', report.consignmentOmzet),
                  _row('Service', report.cashierReport.serviceCharge),
                  _row('Tunai (diterima)', report.cashierReport.cashTotal),
                  _row('Nontunai / EDC', report.cashierReport.edcTotal),
                  _row('Tagihan tenan', report.receivableTotal),
                  if (report.cashierReport.donationTotal > 0)
                    _row('Donasi pembulatan', report.cashierReport.donationTotal),
                  _row('HPP / modal', report.costOfGoods),
                  _row('Laba kotor', report.grossProfit),
                  _row('Pengeluaran', report.expenseTotal),
                  _row('Laba bersih', report.netProfit, emphasize: true),
                  const SizedBox(height: 16),
                  Text(
                    'Laba kotor = omzet produk − HPP + service, termasuk via tenan. '
                    'Tunai + EDC = uang di tangan. Tagihan tenan belum diterima. '
                    'Laba bersih = laba kotor − pengeluaran.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _row(String label, double value, {bool emphasize = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: Text(
          CurrencyFormatter.format(value),
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
