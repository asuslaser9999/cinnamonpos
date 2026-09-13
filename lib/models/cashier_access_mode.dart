enum CashierAccessMode {
  fullAccess('full', 'Akses penuh'),
  timeRestricted('time_restricted', 'Terbatas jam operasional'),
  blocked('blocked', 'Diblokir');

  const CashierAccessMode(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static CashierAccessMode fromStorageKey(String? key) {
    for (final mode in CashierAccessMode.values) {
      if (mode.storageKey == key) return mode;
    }
    return CashierAccessMode.timeRestricted;
  }
}
