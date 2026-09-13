import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../models/app_settings.dart';
import '../models/printer_settings.dart';
import '../models/sale.dart';
import '../utils/currency_formatter.dart';
import '../utils/esc_pos_builder.dart';

class ThermalPrintService {
  Future<List<Map<String, String>>> getPairedDevices() async {
    if (!_supportsBluetoothPrint) return [];

    await PrintBluetoothThermal.isPermissionBluetoothGranted;

    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map((device) => {'name': device.name, 'mac': device.macAdress})
        .toList();
  }

  Future<bool> connect(String macAddress) async {
    if (!_supportsBluetoothPrint || macAddress.isEmpty) return false;
    return PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  Future<bool> printSale({
    required AppSettings appSettings,
    required PrinterSettings printerSettings,
    required Sale sale,
    double? cashReceived,
    double? change,
  }) async {
    if (!_supportsBluetoothPrint) {
      throw UnsupportedError(
        'Cetak thermal Bluetooth hanya tersedia di Android.',
      );
    }
    if (!printerSettings.isConfigured) {
      throw StateError('Printer belum dikonfigurasi di Pengaturan Printer.');
    }

    final connected = await connect(printerSettings.printerMac);
    if (!connected) {
      throw StateError('Gagal terhubung ke printer Bluetooth.');
    }

    return _writeBytes(
      _buildSaleBytes(
        appSettings: appSettings,
        printerSettings: printerSettings,
        sale: sale,
        cashReceived: cashReceived,
        change: change,
      ),
    );
  }

  Future<bool> printTest(PrinterSettings settings) async {
    if (!settings.isConfigured) {
      throw StateError('Printer belum dikonfigurasi.');
    }

    final connected = await connect(settings.printerMac);
    if (!connected) {
      throw StateError('Gagal terhubung ke printer.');
    }

    final width = settings.charsPerLine;
    final esc = EscPosBuilder()
      ..reset()
      .._applyFont(settings.font)
      ..alignCenter()
      ..bold(on: true)
      ..line(settings.storeName)
      ..bold(on: false)
      ..line('TEST PRINT')
      ..separator(width)
      ..alignLeft()
      ..line('Printer OK')
      ..line('Kertas: ${settings.paperWidthMm} mm')
      ..feedAndCut();
    return _writeBytes(esc.bytes);
  }

  Future<bool> _writeBytes(List<int> bytes) async {
    return PrintBluetoothThermal.writeBytes(bytes);
  }

  List<int> _buildSaleBytes({
    required AppSettings appSettings,
    required PrinterSettings printerSettings,
    required Sale sale,
    double? cashReceived,
    double? change,
  }) {
    final width = printerSettings.charsPerLine;
    final esc = EscPosBuilder()
      ..reset()
      .._applyFont(printerSettings.font)
      ..alignCenter()
      ..bold(on: true)
      ..line(appSettings.storeName)
      ..bold(on: false);
    if (appSettings.storeSubtitle.trim().isNotEmpty) {
      esc.line(appSettings.storeSubtitle);
    }
    esc
      ..separator(width)
      ..alignLeft()
      ..line('No  : ${sale.saleNumber}')
      ..line('Tgl : ${CurrencyFormatter.formatDateTime(sale.soldAt.toLocal())}');
    if (sale.status.isRefunded) {
      esc.line('STATUS: REFUND');
    }
    esc.separator(width, char: '-');

    for (final item in sale.items) {
      esc
        ..line(item.productName)
        ..line(
          '  ${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1)} x '
          '${CurrencyFormatter.format(item.unitPrice)}'
          '  ${CurrencyFormatter.format(item.lineTotal)}',
        );
    }

    esc
      ..separator(width, char: '-')
      ..line('Subtotal  ${CurrencyFormatter.format(sale.subtotal)}');
    if (sale.serviceChargeAmount > 0) {
      esc.line(
        'Service   ${CurrencyFormatter.format(sale.serviceChargeAmount)}',
      );
    }
    esc
      ..bold(on: true)
      ..line('TOTAL     ${CurrencyFormatter.format(sale.netTotal)}')
      ..bold(on: false);
    if (sale.donationAmount > 0) {
      esc.line('Donasi    ${CurrencyFormatter.format(sale.donationAmount)}');
    }
    if (sale.refundedTotal > 0) {
      esc.line('Refund    ${CurrencyFormatter.format(sale.refundedTotal)}');
    }
    if (sale.channel.isViaTenant) {
      esc.line('Via tenan ${sale.partnerTenantName}');
    }
    esc.line('Bayar     ${sale.paymentLabel}');
    if (sale.cashAmount > 0) {
      esc.line('  Tunai   ${CurrencyFormatter.format(sale.cashAmount)}');
    }
    if (sale.edcAmount > 0) {
      esc.line('  EDC     ${CurrencyFormatter.format(sale.edcAmount)}');
    }
    if (cashReceived != null && cashReceived > 0) {
      esc.line('Diterima  ${CurrencyFormatter.format(cashReceived)}');
    }
    if (change != null && change > 0) {
      esc.line('Kembali   ${CurrencyFormatter.format(change)}');
    }
    esc
      ..separator(width)
      ..alignCenter()
      ..line('Terima kasih')
      ..feedAndCut();
    return esc.bytes;
  }

  bool get _supportsBluetoothPrint => !kIsWeb && Platform.isAndroid;
}

extension on EscPosBuilder {
  void _applyFont(ThermalFont font) {
    switch (font) {
      case ThermalFont.a:
        fontA();
      case ThermalFont.b:
        fontB();
    }
  }
}
