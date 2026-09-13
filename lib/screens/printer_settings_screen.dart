import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/app_settings_notifier.dart';
import '../models/printer_settings.dart';
import '../notifiers/printer_settings_notifier.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _macController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _macController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = context.read<PrinterSettingsNotifier>();
      await notifier.load();
      if (!mounted) return;
      _nameController.text = notifier.settings.printerName;
      _macController.text = notifier.settings.printerMac;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _macController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = context.read<PrinterSettingsNotifier>();
    notifier.updateSettings(
      notifier.settings.copyWith(
        printerName: _nameController.text.trim(),
        printerMac: _macController.text.trim(),
      ),
    );
    final success = await notifier.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pengaturan printer disimpan.'
              : (notifier.errorMessage ?? 'Gagal menyimpan.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PrinterSettingsNotifier>();
    final appSettings = context.watch<AppSettingsNotifier>().settings;
    final settings = notifier.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Printer')),
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('Nama Toko (Header Struk)'),
                    subtitle: Text(
                      '${appSettings.storeName}\n'
                      'Diatur di menu Pengaturan (Owner).',
                    ),
                    isThreeLine: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: settings.paperWidthMm,
                    decoration: const InputDecoration(
                      labelText: 'Lebar Kertas',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 58, child: Text('58 mm')),
                      DropdownMenuItem(value: 80, child: Text('80 mm')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        notifier.updateSettings(
                          settings.copyWith(paperWidthMm: value),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ThermalFont>(
                    initialValue: settings.font,
                    decoration: const InputDecoration(
                      labelText: 'Font Printer',
                      border: OutlineInputBorder(),
                      helperText:
                          'Font A = standar struk. Font B = lebih kecil & rapat.',
                    ),
                    items: ThermalFont.values
                        .map(
                          (font) => DropdownMenuItem(
                            value: font,
                            child: Text(font.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        notifier.updateSettings(settings.copyWith(font: value));
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Printer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _macController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat MAC',
                      border: OutlineInputBorder(),
                      helperText: 'Contoh: 00:11:22:33:44:55',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: notifier.isSaving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(
                      notifier.isSaving ? 'Menyimpan...' : 'Simpan',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
