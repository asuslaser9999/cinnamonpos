import 'sale.dart';
import 'sale_channel.dart';
import 'sale_status.dart';

class PendingSale {
  const PendingSale({
    required this.id,
    required this.saleNumber,
    required this.soldAt,
    this.cashierId,
    required this.items,
    required this.payments,
    required this.subtotal,
    this.serviceChargePercent = 0,
    this.serviceChargeAmount = 0,
    required this.total,
    this.donationAmount = 0,
    this.notes = '',
    this.channel = SaleChannel.ownCashier,
    this.partnerTenantId,
    this.partnerTenantName = '',
  });

  final String id;
  final String saleNumber;
  final DateTime soldAt;
  final String? cashierId;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final double subtotal;
  final double serviceChargePercent;
  final double serviceChargeAmount;
  final double total;
  final double donationAmount;
  final String notes;
  final SaleChannel channel;
  final String? partnerTenantId;
  final String partnerTenantName;

  Sale toSale() {
    return Sale(
      id: id,
      saleNumber: saleNumber,
      saleDate: DateTime(soldAt.year, soldAt.month, soldAt.day),
      soldAt: soldAt,
      cashierId: cashierId,
      subtotal: subtotal,
      serviceChargePercent: serviceChargePercent,
      serviceChargeAmount: serviceChargeAmount,
      total: total,
      donationAmount: donationAmount,
      status: SaleStatus.paid,
      notes: notes,
      channel: channel,
      partnerTenantId: partnerTenantId,
      partnerTenantName: partnerTenantName,
      items: items,
      payments: payments,
    );
  }

  factory PendingSale.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final paymentsJson = json['payments'] as List<dynamic>? ?? const [];
    return PendingSale(
      id: json['id'] as String? ?? '',
      saleNumber: json['sale_number'] as String? ?? '',
      soldAt:
          DateTime.tryParse(json['sold_at'] as String? ?? '') ?? DateTime.now(),
      cashierId: json['cashier_id'] as String?,
      items: itemsJson
          .map((row) => SaleItem.fromJson(row as Map<String, dynamic>))
          .toList(),
      payments: paymentsJson
          .map((row) => SalePayment.fromJson(row as Map<String, dynamic>))
          .toList(),
      subtotal: _toDouble(json['subtotal']),
      serviceChargePercent: _toDouble(json['service_charge_percent']),
      serviceChargeAmount: _toDouble(json['service_charge_amount']),
      total: _toDouble(json['total']),
      donationAmount: _toDouble(json['donation_amount']),
      notes: json['notes'] as String? ?? '',
      channel: SaleChannel.fromString(json['channel'] as String?),
      partnerTenantId: json['partner_tenant_id'] as String?,
      partnerTenantName: json['partner_tenant_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_number': saleNumber,
      'sold_at': soldAt.toIso8601String(),
      'cashier_id': cashierId,
      'items': items
          .map(
            (item) => {
              'product_id': item.productId,
              'product_name': item.productName,
              'product_type': item.productType.value,
              'category_name': item.categoryName,
              'qty': item.qty,
              'unit_price': item.unitPrice,
              'cost_price': item.costPrice,
              'line_total': item.lineTotal,
            },
          )
          .toList(),
      'payments': payments
          .map(
            (payment) => {
              'method': payment.method.value,
              'amount': payment.amount,
            },
          )
          .toList(),
      'subtotal': subtotal,
      'service_charge_percent': serviceChargePercent,
      'service_charge_amount': serviceChargeAmount,
      'total': total,
      'donation_amount': donationAmount,
      'notes': notes,
      'channel': channel.value,
      'partner_tenant_id': partnerTenantId,
      'partner_tenant_name': partnerTenantName,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
