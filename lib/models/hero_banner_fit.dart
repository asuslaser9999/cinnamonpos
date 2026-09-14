import 'package:flutter/material.dart';

enum HeroBannerFit {
  cover(
    'cover',
    'Isi area',
    'Gambar mengisi penuh. Sisi yang lebih boleh terpotong.',
    BoxFit.cover,
  ),
  contain(
    'contain',
    'Utuh (full)',
    'Seluruh gambar tampil. Boleh ada ruang kosong di sisi.',
    BoxFit.contain,
  ),
  fill(
    'fill',
    'Regang (stretch)',
    'Ditarik sampai penuh. Proporsi boleh berubah.',
    BoxFit.fill,
  ),
  fitWidth(
    'fitWidth',
    'Sesuai lebar',
    'Mengikuti lebar layar. Tinggi boleh terpotong atau kosong.',
    BoxFit.fitWidth,
  ),
  fitHeight(
    'fitHeight',
    'Sesuai tinggi',
    'Mengikuti tinggi area. Sisi kiri/kanan boleh kosong.',
    BoxFit.fitHeight,
  );

  const HeroBannerFit(
    this.storageKey,
    this.label,
    this.description,
    this.boxFit,
  );

  final String storageKey;
  final String label;
  final String description;
  final BoxFit boxFit;

  static HeroBannerFit fromStorageKey(String? key) {
    return HeroBannerFit.values.firstWhere(
      (value) => value.storageKey == key,
      orElse: () => HeroBannerFit.cover,
    );
  }
}
