import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../notifiers/expense_notifier.dart';
import '../utils/currency_formatter.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseNotifier>().load();
    });
  }

  Future<void> _pickPeriod() async {
    final notifier = context.read<ExpenseNotifier>();
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

  Future<void> _edit({Expense? expense}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseSheet(expense: expense),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengeluaran disimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ExpenseNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: notifier.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Total pengeluaran'),
                      trailing: Text(
                        CurrencyFormatter.format(notifier.total),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (notifier.errorMessage != null)
                    Text(notifier.errorMessage!),
                  if (notifier.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Belum ada pengeluaran.')),
                    )
                  else
                    ...notifier.items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(item.description),
                          subtitle: Text(
                            CurrencyFormatter.formatDate(item.expenseDate),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(item.amount),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () => _edit(expense: item),
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({this.expense});

  final Expense? expense;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _desc;
  late final TextEditingController _amount;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.expense?.description ?? '');
    _amount = TextEditingController(
      text: widget.expense == null
          ? ''
          : widget.expense!.amount.toStringAsFixed(0),
    );
    _date = widget.expense?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_desc.text.trim().isEmpty) return;
    final ok = await context.read<ExpenseNotifier>().save(
      Expense(
        id: widget.expense?.id ?? '',
        expenseDate: _date,
        description: _desc.text.trim(),
        amount: CurrencyFormatter.parse(_amount.text),
      ),
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.expense == null ? 'Pengeluaran Baru' : 'Edit Pengeluaran',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tanggal'),
            subtitle: Text(CurrencyFormatter.formatDate(_date)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Keterangan'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
