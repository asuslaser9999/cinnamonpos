enum ProductType {
  ownProduction('OWN_PRODUCTION', 'Buat Sendiri'),
  consignment('CONSIGNMENT', 'Titipan');

  const ProductType(this.value, this.label);

  final String value;
  final String label;

  static ProductType fromString(String? value) {
    return ProductType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => ProductType.ownProduction,
    );
  }

  bool get isOwnProduction => this == ProductType.ownProduction;
  bool get isConsignment => this == ProductType.consignment;
}
