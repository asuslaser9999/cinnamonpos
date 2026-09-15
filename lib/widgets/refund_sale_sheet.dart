import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../notifiers/sale_list_notifier.dart';
import '../utils/currency_formatter.dart';
import '../utils/sale_money.dart';

Future<Sale?> showRefundSaleSheet(BuildContext context, {required Sale sale}) {
  final notifier = context.read<SaleListNotifier>();
  return showModalBottomSheet<Sale>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider<SaleListNotifier>.value(
      value: notifier,
      child: _RefundSaleSheet(sale: sale),
    ),
  );
}

class _RefundSaleSheet extends StatefulWidget {
  const _RefundSaleSheet({required this.sale});

  final Sale sale;

  @override
  State<_RefundSaleSheet> createState() => _RefundSaleSheetState();
}

class _RefundSaleSheetState extends State<_RefundSaleSheet> {
  late final Map<String, double> _qty;
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _qty = {for (final item in widget.sale.items) item.id: 0};
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  double get _itemsAmount {
    var total = 0.0;
    for (final item in widget.sale.items) {
      total += (_qty[item.id] ?? 0) * item.unitPrice;
    }
    return total;
  }

  double get _serviceAmount =>
      serviceOnItems(_itemsAmount, widget.sale.serviceChargePercent);

  bool get _refundsAllRemaining {
    return widget.sale.items.every((item) {
      return item.remainingQty - (_qty[item.id] ?? 0) <= 0;
    });
  }

  double get _donationAmount =>
      _refundsAllRemaining ? widget.sale.netDonation : 0;

  double get _refundTotal =>
      _itemsAmount + _serviceAmount + _donationAmount;

  void _refundAll() {
    setState(() {
      for (final item in widget.sale.items) {
        _qty[item.id] = item.remainingQty;
      }
    });
  }

  Future<void> _submit() async {
    if (_itemsAmount <= 0) return;
    final notifier = context.read<SaleListNotifier>();
    final updated = await notifier.refund(
      widget.sale,
      qtyByItemId: Map<String, double>.from(_qty),
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notifier.errorMessage ?? 'Gagal refund.')),
      );
      return;
    }
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SaleListNotifier>();
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Refund ${widget.sale.saleNumber}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Service ikut 5% dari nilai barang yang dikembalikan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...widget.sale.items.map((item) {
              final selected = _qty[item.id] ?? 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.productName),
                subtitle: Text(
                  'Sisa ${item.remainingQty.toStringAsFixed(0)} × '
                  '${CurrencyFormatter.format(item.unitPrice)}',
                ),
                trailing: item.remainingQty <= 0
                    ? const Text('Sudah refund')
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: selected <= 0
                                ? null
                                : () => setState(() => _qty[item.id] = selected - 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(selected.toStringAsFixed(0)),
                          IconButton(
                            onPressed: selected >= item.remainingQty
                                ? null
                                : () => setState(() => _qty[item.id] = selected + 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _refundAll,
                child: const Text('Refund semua sisa'),
              ),
            ),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Alasan (opsional)',
              ),
            ),
            const SizedBox(height: 12),
            Text('Barang ${CurrencyFormatter.format(_itemsAmount)}'),
            if (_serviceAmount > 0)
              Text('Service ${CurrencyFormatter.format(_serviceAmount)}'),
            if (_donationAmount > 0)
              Text('Donasi ${CurrencyFormatter.format(_donationAmount)}'),
            Text(
              'Dikembalikan ${CurrencyFormatter.format(_refundTotal)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: notifier.isRefunding || _itemsAmount <= 0
                  ? null
                  : _submit,
              child: Text(
                notifier.isRefunding ? 'Memproses...' : 'Proses refund',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
