import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../domain/cashier_product_policy.dart';
import '../models/product.dart';
import '../models/product_type.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/catalog_notifiers.dart';
import '../utils/currency_formatter.dart';
import '../widgets/product_image.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductNotifier>().load();
      context.read<CategoryNotifier>().load();
      context.read<SupplierNotifier>().load();
    });
  }

  Future<void> _edit({Product? product}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductSheet(product: product),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk disimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductNotifier>();
    final auth = context.watch<AuthNotifier>();
    final settings = context.watch<AppSettingsNotifier>().settings;
    final canAdd = CashierProductPolicy.canManageProducts(
      isOwner: auth.isOwner,
      settings: settings,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Master Produk')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: products.load,
        child: products.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (products.errorMessage != null) Text(products.errorMessage!),
                  if (products.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Belum ada produk.')),
                    )
                  else
                    ...products.items.map((item) {
                      final canEdit = CashierProductPolicy.canManageProducts(
                        isOwner: auth.isOwner,
                        settings: settings,
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ProductImage(
                            imageUrl: item.imageUrl,
                            size: 52,
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.categoryName ?? '-'} · ${item.type.label}'
                            '${item.supplierName != null ? ' · ${item.supplierName}' : ''}\n'
                            '${CurrencyFormatter.format(item.sellingPrice)}'
                            '${item.isActive ? '' : ' · Nonaktif'}',
                          ),
                          isThreeLine: true,
                          trailing: canEdit
                              ? const Icon(Icons.edit_outlined)
                              : null,
                          onTap: canEdit ? () => _edit(product: item) : null,
                        ),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}

class _ProductSheet extends StatefulWidget {
  const _ProductSheet({this.product});

  final Product? product;

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  late final TextEditingController _name;
  late final TextEditingController _selling;
  late final TextEditingController _cost;
  late ProductType _type;
  String? _categoryId;
  String? _supplierId;
  late bool _active;
  Uint8List? _pendingImage;
  String _pendingExt = 'jpg';
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _selling = TextEditingController(
      text: product == null ? '' : product.sellingPrice.toStringAsFixed(0),
    );
    _cost = TextEditingController(
      text: product == null ? '' : product.costPrice.toStringAsFixed(0),
    );
    _type = product?.type ?? ProductType.ownProduction;
    _categoryId = product?.categoryId;
    _supplierId = product?.supplierId;
    _active = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _selling.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 82,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final name = picked.name.toLowerCase();
    final ext = name.endsWith('.png')
        ? 'png'
        : name.endsWith('.webp')
        ? 'webp'
        : 'jpg';
    if (!mounted) return;
    setState(() {
      _pendingImage = bytes;
      _pendingExt = ext;
      _removeImage = false;
    });
  }

  Future<void> _save() async {
    final auth = context.read<AuthNotifier>();
    if (_name.text.trim().isEmpty || _categoryId == null) return;
    if (_type.isConsignment && (_supplierId == null || _supplierId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk titipan wajib punya supplier.')),
      );
      return;
    }

    final selling = CurrencyFormatter.parse(_selling.text);
    final existingCost = widget.product?.costPrice ?? 0;
    final cost = CashierProductPolicy.resolveCostPriceForSave(
      isOwner: auth.isOwner,
      type: _type,
      isEditing: widget.product != null,
      sellingPrice: selling,
      parsedCostFromField: CurrencyFormatter.parse(_cost.text),
      existingCostPrice: existingCost,
    );

    final ok = await context.read<ProductNotifier>().save(
      Product(
        id: widget.product?.id ?? '',
        name: _name.text.trim(),
        type: _type,
        categoryId: _categoryId!,
        supplierId: _type.isConsignment ? _supplierId : null,
        sellingPrice: selling,
        costPrice: cost,
        imageUrl: _removeImage ? null : widget.product?.imageUrl,
        isActive: _active,
      ),
      imageBytes: _pendingImage,
      imageExt: _pendingExt,
      removeImage: _removeImage && _pendingImage == null,
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryNotifier>().activeItems;
    final suppliers = context.watch<SupplierNotifier>().items;
    final auth = context.watch<AuthNotifier>();
    final showCost = auth.isOwner || _type.isConsignment;
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.product == null ? 'Produk Baru' : 'Edit Produk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: ProductImage(
                imageUrl: _removeImage ? null : widget.product?.imageUrl,
                bytes: _pendingImage,
                size: 120,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Pilih gambar'),
                  ),
                ),
                if (_pendingImage != null ||
                    (!_removeImage &&
                        (widget.product?.imageUrl ?? '').isNotEmpty)) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Hapus gambar',
                    onPressed: () {
                      setState(() {
                        _pendingImage = null;
                        _removeImage = true;
                      });
                    },
                    icon: const Icon(Icons.hide_image_outlined),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama produk'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Jenis'),
              items: ProductType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: categories.any((c) => c.id == _categoryId)
                  ? _categoryId
                  : null,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            if (_type.isConsignment) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: suppliers.any((s) => s.id == _supplierId)
                    ? _supplierId
                    : null,
                decoration: const InputDecoration(labelText: 'Supplier'),
                items: suppliers
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.supplierName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _supplierId = value),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _selling,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga jual'),
            ),
            if (showCost) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _type.isConsignment
                      ? 'Harga modal / bayar supplier'
                      : 'Harga modal',
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Modal buat sendiri diisi otomatis (setengah harga jual) '
                  'untuk produk baru.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
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
      ),
    );
  }
}
