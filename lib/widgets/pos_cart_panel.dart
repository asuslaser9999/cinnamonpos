import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/partner_tenant.dart';
import '../models/payment_method.dart';
import '../models/sale.dart';
import '../notifiers/app_settings_notifier.dart';
import '../notifiers/catalog_notifiers.dart';
import '../notifiers/pos_notifier.dart';
import '../notifiers/printer_settings_notifier.dart';
import '../services/thermal_print_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'cash_payment_dialog.dart';
import 'product_image.dart';

class PosCartPanel extends StatefulWidget {
  const PosCartPanel({super.key});

  @override
  State<PosCartPanel> createState() => _PosCartPanelState();
}

class _PosCartPanelState extends State<PosCartPanel> {
  final _thermal = ThermalPrintService();

  Future<void> _printSale(
    Sale sale, {
    double? cashReceived,
    double? change,
  }) async {
    final appSettings = context.read<AppSettingsNotifier>().settings;
    final printer = context.read<PrinterSettingsNotifier>().settings;
    try {
      await _thermal.printSale(
        appSettings: appSettings,
        printerSettings: printer,
        sale: sale,
        cashReceived: cashReceived,
        change: change,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi tersimpan. Gagal cetak: $error')),
      );
    }
  }

  Future<void> _showCashChange(PosNotifier pos) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pembayaran tunai'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PayResultRow(
                label: 'Total belanja',
                value: CurrencyFormatter.format(pos.lastSale?.total ?? 0),
              ),
              if ((pos.lastSale?.donationAmount ?? 0) > 0)
                _PayResultRow(
                  label: 'Donasi pembulatan',
                  value: CurrencyFormatter.format(
                    pos.lastSale?.donationAmount ?? 0,
                  ),
                ),
              _PayResultRow(
                label: 'Dibayar',
                value: CurrencyFormatter.format(
                  (pos.lastSale?.total ?? 0) +
                      (pos.lastSale?.donationAmount ?? 0),
                ),
              ),
              _PayResultRow(
                label: 'Nominal bayar',
                value: CurrencyFormatter.format(pos.lastCashReceived),
              ),
              const SizedBox(height: 8),
              Text('Kembalian', style: Theme.of(context).textTheme.labelMedium),
              Text(
                CurrencyFormatter.format(pos.lastChange),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmViaTenant(AppSettings settings) async {
    final pos = context.read<PosNotifier>();
    if (pos.partnerTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tenan yang menjual produk ini.')),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Simpan tagihan tenan?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tenan: ${pos.partnerTenant!.name}\n'
                'Uang tidak diterima sekarang. Qty dan nominal tersimpan '
                'untuk tagihan.',
              ),
              const SizedBox(height: 12),
              ...pos.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${line.qty.toStringAsFixed(0)}× ${line.product.name}',
                        ),
                      ),
                      Text(CurrencyFormatter.format(line.lineTotal)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Subtotal ${CurrencyFormatter.format(pos.subtotal)}'),
              if (pos.serviceChargeAmount(settings) > 0)
                Text(
                  'Service ${CurrencyFormatter.format(pos.serviceChargeAmount(settings))}',
                ),
              Text(
                'Total ${CurrencyFormatter.format(pos.payable(settings))}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan tagihan'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _pay() async {
    final settings = context.read<AppSettingsNotifier>().settings;
    final pos = context.read<PosNotifier>();

    if (pos.paymentMode == CheckoutPaymentMode.viaTenant) {
      final confirmed = await _confirmViaTenant(settings);
      if (!mounted || !confirmed) return;
      final sale = await pos.checkout(settings);
      if (!mounted) return;
      if (sale == null) {
        if (pos.errorMessage != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(pos.errorMessage!)));
        }
        return;
      }
      pos.setPaymentMode(CheckoutPaymentMode.cash);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tagihan ${sale.paymentLabel} tersimpan. '
            'Uang tidak masuk laci.',
          ),
        ),
      );
      return;
    }

    if (pos.paymentMode == CheckoutPaymentMode.cash) {
      final paid = await showCashPaymentDialog(context, settings: settings);
      if (!mounted || !paid) return;
      await _showCashChange(pos);
      return;
    }

    if (pos.paymentMode == CheckoutPaymentMode.split &&
        (pos.splitCashAmount <= 0 ||
            pos.splitCashAmount >= pos.total(settings))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi bagian tunai di bawah, sisa otomatis jadi EDC.'),
        ),
      );
      return;
    }

    final sale = await pos.checkout(settings);
    if (!mounted) return;
    if (sale == null) {
      if (pos.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(pos.errorMessage!)));
      }
      return;
    }

    await _printSale(sale);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pos.paymentMode == CheckoutPaymentMode.edc
              ? 'Pembayaran EDC tersimpan. Struk dikirim ke printer.'
              : 'Transaksi campuran tersimpan. Struk dikirim ke printer.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosNotifier>();
    final settings = context.watch<AppSettingsNotifier>().settings;
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${pos.lines.length} item',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: pos.isEmpty
                ? Center(
                    child: Text(
                      'Ketuk produk untuk menambah ke tabel.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Table(
                      border: AppTableStyles.tableBorderOf(context),
                      columnWidths: const {
                        0: FlexColumnWidth(2.6),
                        1: FlexColumnWidth(1.6),
                        2: FlexColumnWidth(1.4),
                        3: FlexColumnWidth(1.6),
                        4: FixedColumnWidth(40),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: AppTableStyles.headerDecorationOf(
                            context,
                          ),
                          children: const [
                            _HeaderCell('Produk'),
                            _HeaderCell('Qty', align: TextAlign.center),
                            _HeaderCell('Harga', align: TextAlign.right),
                            _HeaderCell('Jumlah', align: TextAlign.right),
                            _HeaderCell(''),
                          ],
                        ),
                        ...pos.lines.map((line) {
                          return TableRow(
                            decoration:
                                AppTableStyles.consignmentRowDecorationOf(
                                  context,
                                  line.product.type.isConsignment,
                                ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    ProductImage(
                                      imageUrl: line.product.imageUrl,
                                      size: 36,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${line.product.name}\n${line.product.type.label}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _QtyCell(
                                qty: line.qty,
                                onMinus: () => pos.decrement(line),
                                onPlus: () => pos.increment(line),
                              ),
                              _BodyCell(
                                CurrencyFormatter.format(
                                  line.product.sellingPrice,
                                ),
                                align: TextAlign.right,
                              ),
                              _BodyCell(
                                CurrencyFormatter.format(line.lineTotal),
                                align: TextAlign.right,
                                bold: true,
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Hapus',
                                onPressed: () => pos.remove(line),
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: context.palette.accentRed,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Service ${settings.serviceChargePercent.toStringAsFixed(0)}%',
                  ),
                  subtitle: Text(
                    CurrencyFormatter.format(pos.serviceChargeAmount(settings)),
                  ),
                  value: pos.applyServiceCharge,
                  onChanged: settings.serviceChargePercent <= 0
                      ? null
                      : pos.setApplyServiceCharge,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Subtotal ${CurrencyFormatter.format(pos.subtotal)}',
                      ),
                    ),
                    Text(
                      'Total ${CurrencyFormatter.format(pos.total(settings))}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (pos.suggestedDonationAmount(settings) > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Donasi pembulatan ${CurrencyFormatter.format(pos.suggestedDonationAmount(settings))} ditanyakan saat bayar tunai.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 10),
                if (pos.paymentMode == CheckoutPaymentMode.viaTenant) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: AppShapes.borderSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VIA TENAN',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: scheme.onTertiaryContainer,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Produk dijual tenan lain. Uang tidak masuk laci.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onTertiaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PartnerTenant>(
                    // ignore: deprecated_member_use
                    value: () {
                      final tenants = context
                          .watch<PartnerTenantNotifier>()
                          .activeItems;
                      final id = pos.partnerTenant?.id;
                      if (id == null) return null;
                      for (final tenant in tenants) {
                        if (tenant.id == id) return tenant;
                      }
                      return null;
                    }(),
                    decoration: const InputDecoration(
                      labelText: 'Tenan yang menjual',
                    ),
                    items: context
                        .watch<PartnerTenantNotifier>()
                        .activeItems
                        .map(
                          (tenant) => DropdownMenuItem(
                            value: tenant,
                            child: Text(tenant.name),
                          ),
                        )
                        .toList(),
                    onChanged: pos.setPartnerTenant,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          pos.setPaymentMode(CheckoutPaymentMode.cash),
                      child: const Text('Kembali ke kasir sendiri'),
                    ),
                  ),
                ] else ...[
                  SegmentedButton<CheckoutPaymentMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: CheckoutPaymentMode.cash,
                        label: Text('Tunai'),
                      ),
                      ButtonSegment(
                        value: CheckoutPaymentMode.edc,
                        label: Text('EDC'),
                      ),
                      ButtonSegment(
                        value: CheckoutPaymentMode.split,
                        label: Text('Campuran'),
                      ),
                    ],
                    selected: {pos.paymentMode},
                    onSelectionChanged: (value) =>
                        pos.setPaymentMode(value.first),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      final tenants = context
                          .read<PartnerTenantNotifier>()
                          .activeItems;
                      if (tenants.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tambah tenan dulu di Master Tenan.'),
                          ),
                        );
                        return;
                      }
                      pos.setPaymentMode(CheckoutPaymentMode.viaTenant);
                      pos.setPartnerTenant(pos.partnerTenant ?? tenants.first);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A1F2B),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'VIA TENAN',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (pos.paymentMode == CheckoutPaymentMode.split) ...[
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bagian tunai',
                        helperText: 'Sisa otomatis menjadi EDC',
                      ),
                      onChanged: (value) => pos.setSplitCashAmount(
                        CurrencyFormatter.parse(value),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'EDC ${CurrencyFormatter.format(pos.splitEdcAmount(settings))}',
                    ),
                  ],
                ],
                if (pos.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    pos.errorMessage!,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: pos.isEmpty || pos.isSaving ? null : _pay,
                  child: Text(
                    pos.isSaving
                        ? 'Memproses...'
                        : pos.paymentMode == CheckoutPaymentMode.viaTenant
                        ? 'Simpan tagihan'
                        : 'Bayar',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayResultRow extends StatelessWidget {
  const _PayResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.align = TextAlign.left});

  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        label,
        textAlign: align,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.label, {this.align = TextAlign.left, this.bold = false});

  final String label;
  final TextAlign align;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _QtyCell extends StatelessWidget {
  const _QtyCell({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final double qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onMinus,
          icon: const Icon(Icons.remove_circle_outline, size: 20),
        ),
        Text(
          qty.toStringAsFixed(0),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline, size: 20),
        ),
      ],
    );
  }
}

