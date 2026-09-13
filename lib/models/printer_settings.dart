import '../core/constants/app_defaults.dart';

enum ThermalFont {
  a('Font A (Standar)'),
  b('Font B (Kecil)');

  const ThermalFont(this.label);

  final String label;

  static ThermalFont fromString(String? value) {
    return ThermalFont.values.firstWhere(
      (font) => font.name == value,
      orElse: () => ThermalFont.a,
    );
  }
}

class PrinterSettings {
  const PrinterSettings({
    this.storeName = AppDefaults.storeName,
    this.printerName = '',
    this.printerMac = '',
    this.paperWidthMm = 58,
    this.font = ThermalFont.a,
  });

  final String storeName;
  final String printerName;
  final String printerMac;
  final int paperWidthMm;
  final ThermalFont font;

  int get charsPerLine {
    final isWide = paperWidthMm >= 80;
    return switch (font) {
      ThermalFont.a => isWide ? 48 : 32,
      ThermalFont.b => isWide ? 64 : 42,
    };
  }

  bool get isConfigured => printerMac.isNotEmpty;

  PrinterSettings copyWith({
    String? storeName,
    String? printerName,
    String? printerMac,
    int? paperWidthMm,
    ThermalFont? font,
  }) {
    return PrinterSettings(
      storeName: storeName ?? this.storeName,
      printerName: printerName ?? this.printerName,
      printerMac: printerMac ?? this.printerMac,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      font: font ?? this.font,
    );
  }
}
