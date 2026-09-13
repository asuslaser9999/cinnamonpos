import 'package:flutter/material.dart';

enum AppAppearance {
  dark(
    'dark',
    'Gelap',
    'Tema gelap yang sekarang dipakai.',
    ThemeMode.dark,
  ),
  bright(
    'bright',
    'Terang',
    'Tampilan terang bersih, terinspirasi apple.com.',
    ThemeMode.light,
  ),
  pos(
    'pos',
    'Kasir',
    'Tema gelap hangat: navy, charcoal, terracotta, sage, dan camel.',
    ThemeMode.dark,
  );

  const AppAppearance(
    this.storageKey,
    this.label,
    this.description,
    this.themeMode,
  );

  final String storageKey;
  final String label;
  final String description;
  final ThemeMode themeMode;

  static AppAppearance fromStorageKey(String? key) {
    return AppAppearance.values.firstWhere(
      (value) => value.storageKey == key,
      orElse: () => AppAppearance.dark,
    );
  }
}
