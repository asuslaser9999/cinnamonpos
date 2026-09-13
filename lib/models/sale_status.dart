enum SaleStatus {
  paid('paid', 'Lunas'),
  partialRefund('partial_refund', 'Refund sebagian'),
  refunded('refunded', 'Refund');

  const SaleStatus(this.value, this.label);

  final String value;
  final String label;

  static SaleStatus fromString(String? value) {
    return SaleStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SaleStatus.paid,
    );
  }

  bool get isPaid => this == SaleStatus.paid;
  bool get isPartialRefund => this == SaleStatus.partialRefund;
  bool get isRefunded => this == SaleStatus.refunded;
  bool get isActive => isPaid || isPartialRefund;
  bool get canRefund => isActive;
}
