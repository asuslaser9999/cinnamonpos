enum PaymentMethod {
  cash('cash', 'Tunai'),
  edc('edc', 'EDC / Nontunai'),
  receivable('receivable', 'Tagihan tenan');

  const PaymentMethod(this.value, this.label);

  final String value;
  final String label;

  static PaymentMethod fromString(String? value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }

  bool get isCash => this == PaymentMethod.cash;
  bool get isEdc => this == PaymentMethod.edc;
  bool get isReceivable => this == PaymentMethod.receivable;
}

enum CheckoutPaymentMode {
  cash,
  edc,
  split,
  viaTenant,
}
