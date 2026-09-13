import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../notifiers/pos_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

Future<bool> showCashPaymentDialog(
  BuildContext context, {
  required AppSettings settings,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CashPaymentDialog(settings: settings),
  );
  return result ?? false;
}

class _CashPaymentDialog extends StatefulWidget {
  const _CashPaymentDialog({required this.settings});

  final AppSettings settings;

  @override
  State<_CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends State<_CashPaymentDialog> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final pos = context.read<PosNotifier>();
    _amountController = TextEditingController(
      text: pos.cashReceived > 0
          ? CurrencyFormatter.formatGrouped(pos.cashReceived)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _payable =>
      context.read<PosNotifier>().payable(widget.settings);

  double get _received => CurrencyFormatter.parse(_amountController.text);

  double get _change {
    final leftover = _received - _payable;
    return leftover > 0 ? leftover : 0;
  }

  bool get _enough => _received >= _payable && _payable > 0;

  Future<void> _confirm() async {
    final pos = context.read<PosNotifier>();
    pos.setCashReceived(_received);
    final sale = await pos.checkout(widget.settings);
    if (!mounted) return;
    if (sale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pos.errorMessage ?? 'Gagal menyimpan.')),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosNotifier>();
    final scheme = Theme.of(context).colorScheme;
    final payable = pos.payable(widget.settings);
    final donation = pos.donationAmount(widget.settings);

    return AlertDialog(
      title: const Text('Bayar tunai'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rincian belanja',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...pos.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${line.product.name}  x${line.qty.toStringAsFixed(0)}',
                        ),
                      ),
                      Text(CurrencyFormatter.format(line.lineTotal)),
                    ],
                  ),
                ),
              ),
              const Divider(),
              _AmountRow(label: 'Subtotal', value: pos.subtotal),
              if (pos.serviceChargeAmount(widget.settings) > 0)
                _AmountRow(
                  label:
                      'Service ${widget.settings.serviceChargePercent.toStringAsFixed(0)}%',
                  value: pos.serviceChargeAmount(widget.settings),
                ),
              _AmountRow(
                label: 'Total',
                value: pos.total(widget.settings),
                emphasize: donation <= 0,
              ),
              if (donation > 0) ...[
                _AmountRow(label: 'Donasi pembulatan', value: donation),
                _AmountRow(label: 'Dibayar', value: payable, emphasize: true),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nominal bayar',
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
                onChanged: (value) {
                  pos.setCashReceived(CurrencyFormatter.parse(value));
                  setState(() {});
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    _amountController.text =
                        CurrencyFormatter.formatGrouped(payable);
                    pos.setCashReceived(payable);
                    setState(() {});
                  },
                  child: const Text('Uang pas'),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: AppShapes.borderSmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kembalian',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      CurrencyFormatter.format(_change),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (!_enough)
                      Text(
                        'Nominal bayar masih kurang dari total.',
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: pos.isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: pos.isSaving || !_enough ? null : _confirm,
          child: Text(pos.isSaving ? 'Menyimpan...' : 'Bayar'),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(CurrencyFormatter.format(value), style: style),
        ],
      ),
    );
  }
}
