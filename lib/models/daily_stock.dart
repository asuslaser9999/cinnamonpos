class DailyStockTenantColumn {
  const DailyStockTenantColumn({required this.id, required this.name});

  final String id;
  final String name;
}

class DailyStockSnapshot {
  const DailyStockSnapshot({
    required this.lines,
    required this.tenantColumns,
  });

  final List<DailyStockLine> lines;
  final List<DailyStockTenantColumn> tenantColumns;
}

class DailyStockLine {
  DailyStockLine({
    this.id = '',
    required this.productId,
    required this.productName,
    this.categoryName = '',
    this.openingQty = 0,
    this.soldOwnQty = 0,
    Map<String, double>? soldByTenant,
    this.closingQty,
    this.notes = '',
  }) : soldByTenant = soldByTenant ?? const {};

  final String id;
  final String productId;
  final String productName;
  final String categoryName;
  double openingQty;
  final double soldOwnQty;
  final Map<String, double> soldByTenant;
  double? closingQty;
  String notes;

  double get soldViaTenantQty =>
      soldByTenant.values.fold(0, (sum, qty) => sum + qty);

  double get soldQty => soldOwnQty + soldViaTenantQty;

  double soldForTenant(String tenantId) => soldByTenant[tenantId] ?? 0;

  bool get closingEntered => closingQty != null;

  double? get variance {
    if (!closingEntered) return null;
    return openingQty - soldQty - closingQty!;
  }

  bool get hasMismatch {
    final value = variance;
    if (value == null) return false;
    return value.abs() > 0.0001;
  }
}
