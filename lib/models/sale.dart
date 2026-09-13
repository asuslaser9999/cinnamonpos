import 'payment_method.dart';
import 'product_type.dart';
import 'sale_channel.dart';
import 'sale_status.dart';

class SaleItem {
  const SaleItem({
    this.id = '',
    this.saleId = '',
    this.productId,
    required this.productName,
    required this.productType,
    this.categoryName = '',
    required this.qty,
    required this.unitPrice,
    this.costPrice = 0,
    this.qtyRefunded = 0,
  });

  final String id;
  final String saleId;
  final String? productId;
  final String productName;
  final ProductType productType;
  final String categoryName;
  final double qty;
  final double unitPrice;
  final double costPrice;
  final double qtyRefunded;

  double get remainingQty {
    final left = qty - qtyRefunded;
    return left > 0 ? left : 0;
  }

  double get lineTotal => qty * unitPrice;
  double get remainingTotal => remainingQty * unitPrice;
  double get remainingCost => remainingQty * costPrice;
  double get lineProfit => remainingQty * (unitPrice - costPrice);

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String? ?? '',
      saleId: json['sale_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String? ?? '',
      productType: ProductType.fromString(json['product_type'] as String?),
      categoryName: json['category_name'] as String? ?? '',
      qty: _toDouble(json['qty']),
      unitPrice: _toDouble(json['unit_price']),
      costPrice: _toDouble(json['cost_price']),
      qtyRefunded: _toDouble(json['qty_refunded']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (saleId.isNotEmpty) 'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'product_type': productType.value,
      'category_name': categoryName,
      'qty': qty,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'line_total': lineTotal,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class SalePayment {
  const SalePayment({
    this.id = '',
    this.saleId = '',
    required this.method,
    required this.amount,
  });

  final String id;
  final String saleId;
  final PaymentMethod method;
  final double amount;

  factory SalePayment.fromJson(Map<String, dynamic> json) {
    return SalePayment(
      id: json['id'] as String? ?? '',
      saleId: json['sale_id'] as String? ?? '',
      method: PaymentMethod.fromString(json['method'] as String?),
      amount: SaleItem._toDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (saleId.isNotEmpty) 'sale_id': saleId,
      'method': method.value,
      'amount': amount,
    };
  }
}

class SaleRefundItem {
  const SaleRefundItem({
    this.id = '',
    required this.productName,
    required this.qty,
    required this.unitPrice,
  });

  final String id;
  final String productName;
  final double qty;
  final double unitPrice;

  double get lineTotal => qty * unitPrice;

  factory SaleRefundItem.fromJson(Map<String, dynamic> json) {
    return SaleRefundItem(
      id: json['id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      qty: SaleItem._toDouble(json['qty']),
      unitPrice: SaleItem._toDouble(json['unit_price']),
    );
  }
}

class SaleRefund {
  const SaleRefund({
    this.id = '',
    required this.amount,
    this.itemsAmount = 0,
    this.serviceAmount = 0,
    this.donationAmount = 0,
    this.reason = '',
    this.refundedAt,
    this.items = const [],
  });

  final String id;
  final double amount;
  final double itemsAmount;
  final double serviceAmount;
  final double donationAmount;
  final String reason;
  final DateTime? refundedAt;
  final List<SaleRefundItem> items;

  factory SaleRefund.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['cn_sale_refund_items'] as List<dynamic>? ?? const [];
    return SaleRefund(
      id: json['id'] as String? ?? '',
      amount: SaleItem._toDouble(json['amount']),
      itemsAmount: SaleItem._toDouble(json['items_amount']),
      serviceAmount: SaleItem._toDouble(json['service_amount']),
      donationAmount: SaleItem._toDouble(json['donation_amount']),
      reason: json['reason'] as String? ?? '',
      refundedAt: DateTime.tryParse(json['refunded_at'] as String? ?? ''),
      items: itemsJson
          .map((row) => SaleRefundItem.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Sale {
  const Sale({
    this.id = '',
    required this.saleNumber,
    required this.saleDate,
    required this.soldAt,
    this.cashierId,
    required this.subtotal,
    this.serviceChargePercent = 0,
    this.serviceChargeAmount = 0,
    required this.total,
    this.donationAmount = 0,
    this.status = SaleStatus.paid,
    this.notes = '',
    this.channel = SaleChannel.ownCashier,
    this.partnerTenantId,
    this.partnerTenantName = '',
    this.items = const [],
    this.payments = const [],
    this.refunds = const [],
  });

  final String id;
  final String saleNumber;
  final DateTime saleDate;
  final DateTime soldAt;
  final String? cashierId;
  final double subtotal;
  final double serviceChargePercent;
  final double serviceChargeAmount;
  final double total;
  final double donationAmount;
  final SaleStatus status;
  final String notes;
  final SaleChannel channel;
  final String? partnerTenantId;
  final String partnerTenantName;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final List<SaleRefund> refunds;

  double get cashAmount => payments
      .where((p) => p.method.isCash)
      .fold(0, (sum, p) => sum + p.amount);

  double get edcAmount => payments
      .where((p) => p.method.isEdc)
      .fold(0, (sum, p) => sum + p.amount);

  double get receivableAmount => payments
      .where((p) => p.method.isReceivable)
      .fold(0, (sum, p) => sum + p.amount);

  double get itemQty => items.fold(0, (sum, item) => sum + item.qty);
  double get netItemQty => items.fold(0, (sum, item) => sum + item.remainingQty);

  double get refundedItemsAmount =>
      refunds.fold(0, (sum, refund) => sum + refund.itemsAmount);
  double get refundedServiceAmount =>
      refunds.fold(0, (sum, refund) => sum + refund.serviceAmount);
  double get refundedDonationAmount =>
      refunds.fold(0, (sum, refund) => sum + refund.donationAmount);
  double get refundedTotal =>
      refunds.fold(0, (sum, refund) => sum + refund.amount);

  double get netSubtotal {
    final remaining = items.fold(0.0, (sum, item) => sum + item.remainingTotal);
    if (remaining > 0) return remaining;
    return status.isRefunded ? 0 : subtotal;
  }

  double get netService {
    final leftover = serviceChargeAmount - refundedServiceAmount;
    return leftover > 0 ? leftover : 0;
  }

  double get netTotal {
    if (status.isRefunded) return 0;
    final leftover = total - (refundedItemsAmount + refundedServiceAmount);
    if (leftover > 0) return leftover;
    return netSubtotal + netService;
  }

  double get netDonation {
    if (status.isRefunded) return 0;
    final leftover = donationAmount - refundedDonationAmount;
    return leftover > 0 ? leftover : 0;
  }

  double get netCash => _afterRefund(cashAmount, refundedTotal);
  double get netEdc {
    final afterCash = refundedTotal - cashAmount;
    if (afterCash <= 0) return edcAmount;
    final leftover = edcAmount - afterCash;
    return leftover > 0 ? leftover : 0;
  }

  double get netReceivable {
    if (receivableAmount <= 0) return 0;
    final leftover = receivableAmount - refundedTotal;
    return leftover > 0 ? leftover : 0;
  }

  static double _afterRefund(double collected, double refunded) {
    final leftover = collected - refunded;
    return leftover > 0 ? leftover : 0;
  }

  String get refundReason =>
      refunds.isEmpty ? '' : refunds.last.reason;
  DateTime? get refundedAt =>
      refunds.isEmpty ? null : refunds.last.refundedAt;

  String get paymentLabel {
    if (channel.isViaTenant || receivableAmount > 0) {
      final name = partnerTenantName.trim();
      return name.isEmpty ? 'Via tenan' : 'Via $name';
    }
    final hasCash = cashAmount > 0;
    final hasEdc = edcAmount > 0;
    if (hasCash && hasEdc) return 'Campuran';
    if (hasEdc) return 'EDC';
    return 'Tunai';
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['cn_sale_items'] as List<dynamic>? ?? const [];
    final paymentsJson = json['cn_sale_payments'] as List<dynamic>? ?? const [];
    final refundsJson = json['cn_sale_refunds'] as List<dynamic>? ?? const [];

    return Sale(
      id: json['id'] as String? ?? '',
      saleNumber: json['sale_number'] as String? ?? '',
      saleDate: DateTime.tryParse(json['sale_date'] as String? ?? '') ??
          DateTime.now(),
      soldAt: DateTime.tryParse(json['sold_at'] as String? ?? '') ??
          DateTime.now(),
      cashierId: json['cashier_id'] as String?,
      subtotal: SaleItem._toDouble(json['subtotal']),
      serviceChargePercent: SaleItem._toDouble(json['service_charge_percent']),
      serviceChargeAmount: SaleItem._toDouble(json['service_charge_amount']),
      total: SaleItem._toDouble(json['total']),
      donationAmount: SaleItem._toDouble(json['donation_amount']),
      status: SaleStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String? ?? '',
      channel: SaleChannel.fromString(json['channel'] as String?),
      partnerTenantId: json['partner_tenant_id'] as String?,
      partnerTenantName: _partnerNameFromJson(json),
      items: itemsJson
          .map((row) => SaleItem.fromJson(row as Map<String, dynamic>))
          .toList(),
      payments: paymentsJson
          .map((row) => SalePayment.fromJson(row as Map<String, dynamic>))
          .toList(),
      refunds: refundsJson
          .map((row) => SaleRefund.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  static String _partnerNameFromJson(Map<String, dynamic> json) {
    final stored = json['partner_tenant_name'] as String? ?? '';
    if (stored.trim().isNotEmpty) return stored;
    final embedded = json['cn_partner_tenants'];
    if (embedded is Map<String, dynamic>) {
      return embedded['name'] as String? ?? '';
    }
    return '';
  }
}
