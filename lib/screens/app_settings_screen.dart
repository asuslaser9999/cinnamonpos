import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/guards/owner_gate.dart';
import '../domain/cashier_access_policy.dart';
import '../models/app_appearance.dart';
import '../models/app_settings.dart';
import '../models/cashier_access_mode.dart';
import '../models/pos_product_image_size.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/printer_settings_notifier.dart';
import '../services/hero_banner_service.dart';
import '../theme/app_theme.dart';
import '../widgets/store_branding_header.dart';
import '../widgets/store_hero_banner.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late final TextEditingController _storeNameController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _servicePercentController;
  late AppSettings _draft = AppSettings.defaults;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController();
    _subtitleController = TextEditingController();
    _servicePercentController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyDraft(context.read<AppSettingsNotifier>().settings);
    });
  }

  void _applyDraft(AppSettings settings) {
    setState(() {
      _draft = settings;
      _storeNameController.text = settings.storeName;
      _subtitleController.text = settings.storeSubtitle;
      _servicePercentController.text = settings.serviceChargePercent == 0
          ? ''
          : settings.serviceChargePercent.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _subtitleController.dispose();
    _servicePercentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = context.read<AppSettingsNotifier>();
    notifier.clearMessages();

    final success = await notifier.save(_draft);
    if (!mounted || !success) return;

    await context.read<PrinterSettingsNotifier>().load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan berhasil disimpan.')),
    );
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickAccessTime({required bool isStart}) async {
    final initial = _parseTime(
      isStart ? _draft.cashierAccessStart : _draft.cashierAccessEnd,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Jam mulai akses kasir' : 'Jam akhir akses kasir',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _draft = _draft.copyWith(
        cashierAccessStart: isStart ? _formatTime(picked) : null,
        cashierAccessEnd: isStart ? null : _formatTime(picked),
      );
    });
  }

  Future<void> _selectAppearance(AppAppearance appearance) async {
    setState(() {
      _draft = _draft.copyWith(appearance: appearance);
    });
    await context.read<AppSettingsNotifier>().updateAppearance(appearance);
  }

  Future<void> _pickHeroBanner() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final path = await HeroBannerService().save(bytes);
    if (!mounted) return;

    final next = _draft.copyWith(
      heroBannerPath: path,
      heroBannerVersion: _draft.heroBannerVersion + 1,
    );
    setState(() => _draft = next);
    await context.read<AppSettingsNotifier>().updateHeroBanner(
      path: path,
      version: next.heroBannerVersion,
    );
  }

  Future<void> _clearHeroBanner() async {
    await HeroBannerService().clear();
    if (!mounted) return;

    final next = _draft.copyWith(
      clearHeroBanner: true,
      heroBannerVersion: _draft.heroBannerVersion + 1,
    );
    setState(() => _draft = next);
    await context.read<AppSettingsNotifier>().updateHeroBanner(
      clear: true,
      version: next.heroBannerVersion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AppSettingsNotifier>();

    if (!notifier.isLoading &&
        _draft == AppSettings.defaults &&
        notifier.settings != AppSettings.defaults) {
      _applyDraft(notifier.settings);
    }

    return OwnerGate(
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Aplikasi')),
        body: notifier.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tema Aplikasi',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gelap, terang ala apple.com, atau kasir gelap hangat '
                      'dengan palet navy–terracotta. Tersimpan di perangkat ini.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final (index, appearance)
                            in AppAppearance.values.indexed) ...[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _ThemePreviewCard(
                              appearance: appearance,
                              selected: _draft.appearance == appearance,
                              onTap: () => _selectAppearance(appearance),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_draft.hasHeroBanner)
                            StoreHeroBanner(settings: _draft, height: 140)
                          else
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: StoreBrandingHeader(
                                settings: _draft,
                                showSubtitle: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gambar form utama',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG tampil full lebar di login dan menu utama, '
                      'menggantikan icon toko. Tersimpan di perangkat ini.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickHeroBanner,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(
                              _draft.hasHeroBanner
                                  ? 'Ganti gambar'
                                  : 'Pilih JPG',
                            ),
                          ),
                        ),
                        if (_draft.hasHeroBanner) ...[
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Hapus gambar',
                            onPressed: _clearHeroBanner,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko',
                        border: OutlineInputBorder(),
                        helperText: 'Dipakai di menu utama dan header struk.',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _draft = _draft.copyWith(storeName: value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle / Tagline',
                        border: OutlineInputBorder(),
                        helperText: 'Contoh: Cinnamon POS',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _draft = _draft.copyWith(storeSubtitle: value);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tampilkan subtitle di menu utama'),
                      subtitle: const Text(
                        'Subtitle selalu tampil di halaman login.',
                      ),
                      value: _draft.showSubtitleOnDashboard,
                      onChanged: (value) {
                        setState(() {
                          _draft = _draft.copyWith(
                            showSubtitleOnDashboard: value,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Icon Toko',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemCount: StoreIconRegistry.options.length,
                      itemBuilder: (context, index) {
                        final option = StoreIconRegistry.options[index];
                        final selected = _draft.storeIconKey == option.key;

                        return Material(
                          color: selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _draft = _draft.copyWith(
                                  storeIconKey: option.key,
                                );
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  option.icon,
                                  color: selected
                                      ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: selected
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Warna Icon',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: AvatarColorRegistry.options.map((option) {
                        final selected = _draft.avatarColorKey == option.key;

                        return Semantics(
                          label: option.label,
                          button: true,
                          selected: selected,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              setState(() {
                                _draft = _draft.copyWith(
                                  avatarColorKey: option.key,
                                );
                              });
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: option.color,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Akses Kasir',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur kapan kasir dapat menggunakan menu utama. '
                      'Owner selalu memiliki akses penuh.\n\n'
                      'Pengaturan akses kasir disinkronkan ke semua perangkat '
                      'via server saat Anda simpan. Perangkat kasir akan '
                      'memperbarui otomatis saat login atau app dibuka kembali.\n\n'
                      'Branding toko (nama, ikon) dan tema tetap per perangkat.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<CashierAccessMode>(
                      groupValue: _draft.cashierAccessMode,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _draft = _draft.copyWith(cashierAccessMode: value);
                        });
                      },
                      child: Column(
                        children: [
                          ...CashierAccessMode.values.map((mode) {
                            return RadioListTile<CashierAccessMode>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(mode.label),
                              subtitle: switch (mode) {
                                CashierAccessMode.fullAccess =>
                                  const Text(
                                    'Kasir dapat menggunakan aplikasi kapan saja.',
                                  ),
                                CashierAccessMode.timeRestricted => Text(
                                  'Kasir hanya aktif pukul '
                                  '${CashierAccessPolicy.formatAccessWindow(_draft.cashierAccessStart, _draft.cashierAccessEnd)}. '
                                  'Di luar jam itu bisa login tetapi menu dinonaktifkan.',
                                ),
                                CashierAccessMode.blocked =>
                                  const Text(
                                    'Kasir tidak dapat menggunakan aplikasi sama sekali.',
                                  ),
                              },
                              value: mode,
                            );
                          }),
                        ],
                      ),
                    ),
                    if (_draft.cashierAccessMode ==
                        CashierAccessMode.timeRestricted) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickAccessTime(isStart: true),
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                'Mulai ${CashierAccessPolicy.formatTime(_draft.cashierAccessStart)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickAccessTime(isStart: false),
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                'Selesai ${CashierAccessPolicy.formatTime(_draft.cashierAccessEnd)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Biaya Service',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bisa ditambahkan per transaksi di kasir. '
                      'Default dan persentase disinkronkan ke semua perangkat.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Service aktif secara default'),
                      subtitle: const Text(
                        'Kasir tetap bisa menonaktifkan per transaksi.',
                      ),
                      value: _draft.serviceChargeEnabled,
                      onChanged: (value) {
                        setState(() {
                          _draft = _draft.copyWith(serviceChargeEnabled: value);
                        });
                      },
                    ),
                    TextFormField(
                      controller: _servicePercentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Persentase service',
                        suffixText: '%',
                        helperText: 'Contoh: 5 untuk 5% dari subtotal.',
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value) ?? 0;
                        setState(() {
                          _draft = _draft.copyWith(
                            serviceChargePercent: parsed.clamp(0, 100),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Donasi Pembulatan Tunai',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jika aktif, total tunai dibulatkan ke atas ke ribuan. '
                      'Selisih tercatat sebagai donasi. '
                      'Contoh: 87.700 menjadi 88.000 (donasi 300). '
                      'Tidak berlaku untuk EDC, campuran, atau via tenan.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aktifkan pembulatan donasi'),
                      subtitle: const Text(
                        'Disinkronkan ke semua perangkat saat Anda simpan.',
                      ),
                      value: _draft.cashDonationRoundingEnabled,
                      onChanged: (value) {
                        setState(() {
                          _draft = _draft.copyWith(
                            cashDonationRoundingEnabled: value,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tampilan Kasir',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ukuran gambar produk di layar kasir. '
                      'Tanpa gambar membuat lebih banyak produk muat tanpa scroll. '
                      'Pengaturan ini tersimpan di perangkat ini.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<PosProductImageSize>(
                      groupValue: _draft.posProductImageSize,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _draft = _draft.copyWith(posProductImageSize: value);
                        });
                      },
                      child: Column(
                        children: [
                          ...PosProductImageSize.values.map((size) {
                            return RadioListTile<PosProductImageSize>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(size.label),
                              subtitle: Text(size.description),
                              value: size,
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kasir boleh tambah/edit produk'),
                      subtitle: const Text(
                        'Termasuk buat sendiri dan titipan. Hapus produk tetap owner-only.',
                      ),
                      value: _draft.cashierCanManageOwnProducts,
                      onChanged: (value) {
                        setState(() {
                          _draft = _draft.copyWith(
                            cashierCanManageOwnProducts: value,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: notifier.isSaving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        notifier.isSaving
                            ? 'Menyimpan...'
                            : 'Simpan Pengaturan',
                      ),
                    ),
                    if (notifier.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        notifier.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.appearance,
    required this.selected,
    required this.onTap,
  });

  final AppAppearance appearance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = switch (appearance) {
      AppAppearance.dark => (
          canvas: AppColors.background,
          card: AppColors.surfaceLight,
          ink: AppColors.textPrimary,
          muted: AppColors.textMuted,
          accent: AppColors.accentBlue,
          icon: Icons.dark_mode_rounded,
        ),
      AppAppearance.bright => (
          canvas: AppleBrightColors.canvas,
          card: AppleBrightColors.white,
          ink: AppleBrightColors.ink,
          muted: AppleBrightColors.muted,
          accent: AppleBrightColors.blue,
          icon: Icons.wb_sunny_rounded,
        ),
      AppAppearance.pos => (
          canvas: PosColors.navy,
          card: PosColors.charcoal,
          ink: PosColors.ink,
          muted: PosColors.muted,
          accent: PosColors.terracotta,
          icon: Icons.point_of_sale_rounded,
        ),
    };
    final canvas = preview.canvas;
    final card = preview.card;
    final ink = preview.ink;
    final muted = preview.muted;
    final accent = preview.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 108,
                decoration: BoxDecoration(
                  color: canvas,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          preview.icon,
                          size: 16,
                          color: accent,
                        ),
                        const Spacer(),
                        Container(
                          width: 28,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(10),
                        border: appearance == AppAppearance.pos
                            ? Border.all(color: PosColors.line)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      child: appearance == AppAppearance.pos
                          ? Row(
                              children: [
                                _PreviewDot(color: PosColors.navy),
                                const SizedBox(width: 4),
                                _PreviewDot(color: PosColors.charcoal),
                                const SizedBox(width: 4),
                                _PreviewDot(color: PosColors.terracotta),
                                const SizedBox(width: 4),
                                _PreviewDot(color: PosColors.sage),
                                const SizedBox(width: 4),
                                _PreviewDot(color: PosColors.camel),
                                const Spacer(),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: PosColors.terracotta,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: ink.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 32,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: muted.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Text(
                  appearance.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
