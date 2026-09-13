import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../notifiers/catalog_notifiers.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierNotifier>().load();
    });
  }

  Future<void> _edit({Supplier? supplier}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SupplierSheet(supplier: supplier),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier disimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SupplierNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Master Supplier')),
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
                  if (notifier.errorMessage != null)
                    Text(notifier.errorMessage!),
                  if (notifier.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Belum ada supplier.')),
                    )
                  else
                    ...notifier.items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(item.supplierName),
                          subtitle: Text(
                            [
                              if ((item.phone ?? '').isNotEmpty) item.phone,
                              if (item.notes.isNotEmpty) item.notes,
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.edit_outlined),
                          onTap: () => _edit(supplier: item),
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

class _SupplierSheet extends StatefulWidget {
  const _SupplierSheet({this.supplier});

  final Supplier? supplier;

  @override
  State<_SupplierSheet> createState() => _SupplierSheetState();
}

class _SupplierSheetState extends State<_SupplierSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.supplier?.supplierName ?? '');
    _phone = TextEditingController(text: widget.supplier?.phone ?? '');
    _notes = TextEditingController(text: widget.supplier?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final ok = await context.read<SupplierNotifier>().save(
      Supplier(
        id: widget.supplier?.id ?? '',
        supplierName: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        notes: _notes.text.trim(),
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
            widget.supplier == null ? 'Supplier Baru' : 'Edit Supplier',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama supplier'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Telepon'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Catatan'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
