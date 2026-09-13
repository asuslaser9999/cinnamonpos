enum PosProductImageSize {
  normal('normal', 'Sedang', 'Ukuran gambar seperti sekarang.'),
  compact('compact', 'Kecil', 'Gambar lebih kecil, lebih banyak produk di layar.'),
  hidden('hidden', 'Tanpa gambar', 'Hanya nama dan harga, muat paling banyak.');

  const PosProductImageSize(this.storageKey, this.label, this.description);

  final String storageKey;
  final String label;
  final String description;

  static PosProductImageSize fromStorageKey(String? key) {
    return PosProductImageSize.values.firstWhere(
      (value) => value.storageKey == key,
      orElse: () => PosProductImageSize.normal,
    );
  }
}
