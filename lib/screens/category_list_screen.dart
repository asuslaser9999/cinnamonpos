import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_category.dart';
import '../notifiers/catalog_notifiers.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryNotifier>().load();
    });
  }

  Future<void> _edit({ProductCategory? category}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategorySheet(category: category),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori disimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CategoryNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Produk')),
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
                      child: Center(child: Text('Belum ada kategori.')),
                    )
                  else
                    ...notifier.items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            item.isActive ? 'Aktif' : 'Nonaktif',
                          ),
                          trailing: const Icon(Icons.edit_outlined),
                          onTap: () => _edit(category: item),
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

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({this.category});

  final ProductCategory? category;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final TextEditingController _name;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _active = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final ok = await context.read<CategoryNotifier>().save(
      ProductCategory(
        id: widget.category?.id ?? '',
        name: _name.text.trim(),
        isActive: _active,
        sortOrder: widget.category?.sortOrder ?? 0,
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
            widget.category == null ? 'Kategori Baru' : 'Edit Kategori',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama kategori'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Aktif'),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          FilledButton(onPressed: _save, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
