import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/partner_tenant.dart';
import '../notifiers/catalog_notifiers.dart';
import '../widgets/entity_list_scaffold.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartnerTenantNotifier>().load();
    });
  }

  Future<void> _edit({PartnerTenant? tenant}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TenantSheet(tenant: tenant),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenan disimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PartnerTenantNotifier>();

    return EntityListScaffold(
      title: 'Master Tenan',
      isLoading: notifier.isLoading,
      onRefresh: notifier.load,
      onAdd: () => _edit(),
      errorMessage: notifier.errorMessage,
      emptyText: 'Belum ada tenan.',
      isEmpty: notifier.items.isEmpty,
      header: Text(
        'Tenan cafe lain yang kadang menjual produk Anda. '
        'Pakai di kasir lewat tombol Via Tenan.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: [
        for (final item in notifier.items)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                [
                  if (!item.isActive) 'Nonaktif',
                  if (item.notes.isNotEmpty) item.notes,
                ].join(' · '),
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _edit(tenant: item),
            ),
          ),
      ],
    );
  }
}

class _TenantSheet extends StatefulWidget {
  const _TenantSheet({this.tenant});

  final PartnerTenant? tenant;

  @override
  State<_TenantSheet> createState() => _TenantSheetState();
}

class _TenantSheetState extends State<_TenantSheet> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.tenant?.name ?? '');
    _notes = TextEditingController(text: widget.tenant?.notes ?? '');
    _active = widget.tenant?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final ok = await context.read<PartnerTenantNotifier>().save(
      PartnerTenant(
        id: widget.tenant?.id ?? '',
        name: _name.text.trim(),
        notes: _notes.text.trim(),
        isActive: _active,
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
            widget.tenant == null ? 'Tenan Baru' : 'Edit Tenan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama tenan'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Catatan'),
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
