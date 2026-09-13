enum SaleChannel {
  ownCashier('own_cashier', 'Kasir sendiri'),
  viaTenant('via_tenant', 'Via tenan');

  const SaleChannel(this.value, this.label);

  final String value;
  final String label;

  static SaleChannel fromString(String? value) {
    return SaleChannel.values.firstWhere(
      (item) => item.value == value,
      orElse: () => SaleChannel.ownCashier,
    );
  }

  bool get isOwnCashier => this == SaleChannel.ownCashier;
  bool get isViaTenant => this == SaleChannel.viaTenant;
}
