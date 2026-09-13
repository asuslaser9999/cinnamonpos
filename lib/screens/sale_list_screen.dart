import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/sale_list_notifier.dart';
import '../utils/currency_formatter.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/refund_sale_sheet.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleListNotifier>().load();
    });
  }

  Future<void> _pickDate() async {
    final notifier = context.read<SaleListNotifier>();
    final picked = await showDatePicker(
      context: context,
      initialDate: notifier.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      await notifier.load(date: picked);
    }
  }

  Future<void> _openSale(Sale sale) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SaleDetailSheet(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SaleListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(CurrencyFormatter.formatDate(notifier.date)),
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
                  if (notifier.sales.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Tidak ada transaksi di tanggal ini.'),
                      ),
                    )
                  else
                    ...notifier.sales.map((sale) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: sale.status.isRefunded
                            ? Theme.of(context).colorScheme.errorContainer
                            : null,
                        child: ListTile(
                          title: Text(sale.saleNumber),
                          subtitle: Text(
                            '${CurrencyFormatter.formatTime(sale.soldAt.toLocal())}'
                            ' · ${sale.paymentLabel}'
                            ' · ${sale.status.label}\n'
                            '${sale.netItemQty.toStringAsFixed(0)} pcs',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            CurrencyFormatter.format(
                              sale.status.isRefunded
                                  ? sale.refundedTotal
                                  : sale.netTotal,
                            ),
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

class _SaleDetailSheet extends StatelessWidget {
  const _SaleDetailSheet({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsNotifier>().settings;
    final notifier = context.watch<SaleListNotifier>();

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
            const SizedBox(height: 12),
            ...sale.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.productName),
                subtitle: Text(
                  '${item.remainingQty.toStringAsFixed(0)}'
                  '${item.qtyRefunded > 0 ? ' / ${item.qty.toStringAsFixed(0)}' : ''}'
                  ' x ${CurrencyFormatter.format(item.unitPrice)}'
                  '${item.qtyRefunded > 0 ? ' · refund ${item.qtyRefunded.toStringAsFixed(0)}' : ''}',
                ),
                trailing: Text(CurrencyFormatter.format(item.remainingTotal)),
              ),
            ),
            if (sale.serviceChargeAmount > 0)
              Text(
                'Service ${CurrencyFormatter.format(sale.serviceChargeAmount)}',
              ),
            if (sale.donationAmount > 0)
              Text(
                'Donasi ${CurrencyFormatter.format(sale.netDonation)}',
              ),
            Text(
              'Total ${CurrencyFormatter.format(sale.netTotal)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (sale.refundedTotal > 0)
              Text(
                'Sudah direfund ${CurrencyFormatter.format(sale.refundedTotal)}',
              ),
            if (sale.channel.isViaTenant)
              Text('Via tenan ${sale.partnerTenantName}'),
            Text(
              'Bayar ${sale.paymentLabel}'
              '${sale.cashAmount > 0 ? ' · Tunai ${CurrencyFormatter.format(sale.cashAmount)}' : ''}'
              '${sale.edcAmount > 0 ? ' · EDC ${CurrencyFormatter.format(sale.edcAmount)}' : ''}'
              '${sale.receivableAmount > 0 ? ' · Tagihan ${CurrencyFormatter.format(sale.receivableAmount)}' : ''}',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showReceiptDialog(
                context,
                settings: settings,
                sale: sale,
              ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Cetak ulang'),
            ),
            if (sale.status.canRefund) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: notifier.isRefunding
                    ? null
                    : () async {
                        final updated = await showRefundSaleSheet(
                          context,
                          sale: sale,
                        );
                        if (!context.mounted || updated == null) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Refund tersimpan.')),
                        );
                      },
                icon: const Icon(Icons.undo_rounded),
                label: Text(notifier.isRefunding ? 'Memproses...' : 'Refund'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
