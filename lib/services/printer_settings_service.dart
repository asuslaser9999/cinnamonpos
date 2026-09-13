import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_defaults.dart';
import '../models/printer_settings.dart';

class PrinterSettingsService {
  static const _storeNameKey = 'cn_store_name';
  static const _printerNameKey = 'cn_printer_name';
  static const _printerMacKey = 'cn_printer_mac';
  static const _paperWidthKey = 'cn_paper_width_mm';
  static const _fontKey = 'cn_printer_font';

  Future<PrinterSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return PrinterSettings(
      storeName: prefs.getString(_storeNameKey) ??
          prefs.getString('cn_app_store_name') ??
          AppDefaults.storeName,
      printerName: prefs.getString(_printerNameKey) ?? '',
      printerMac: prefs.getString(_printerMacKey) ?? '',
      paperWidthMm: prefs.getInt(_paperWidthKey) ?? 58,
      font: ThermalFont.fromString(prefs.getString(_fontKey)),
    );
  }

  Future<void> save(PrinterSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeNameKey, settings.storeName);
    await prefs.setString(_printerNameKey, settings.printerName);
    await prefs.setString(_printerMacKey, settings.printerMac);
    await prefs.setInt(_paperWidthKey, settings.paperWidthMm);
    await prefs.setString(_fontKey, settings.font.name);
  }
}
