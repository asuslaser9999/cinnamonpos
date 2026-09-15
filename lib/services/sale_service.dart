import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/sale.dart';
import '../models/sale_channel.dart';
import '../models/sale_status.dart';
import '../utils/currency_formatter.dart';
import '../utils/local_uuid.dart';
import '../utils/network_error.dart';
import '../utils/sale_money.dart';

class SaleService {
  SaleService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  static const _select =
      '*, cn_sale_items(*), cn_sale_payments(*), '
      'cn_sale_refunds(*, cn_sale_refund_items(*))';
  static const _selectBasic =
      '*, cn_sale_items(*), cn_sale_payments(*), cn_sale_refunds(*)';

  Future<Sale> createSale({
    String? id,
    String? saleNumber,
    DateTime? soldAt,
    String? cashierId,
    required List<SaleItem> items,
    required List<SalePayment> payments,
    required double subtotal,
    required double serviceChargePercent,
    required double serviceChargeAmount,
    required double total,
    String notes = '',
    SaleChannel channel = SaleChannel.ownCashier,
    String? partnerTenantId,
    String partnerTenantName = '',
    double donationAmount = 0,
  }) async {
    final now = soldAt ?? DateTime.now();
    final saleId = (id == null || id.isEmpty) ? newLocalUuid() : id;
    final number = (saleNumber == null || saleNumber.isEmpty)
        ? localSaleNumber(now, saleId)
        : saleNumber;
    final userId = cashierId ?? _client.auth.currentUser?.id;

    var headerExists = false;
    try {
      await _client.from(CnTables.sales).insert({
        'id': saleId,
        'sale_number': number,
        'sale_date': AppDateRange.isoDate(now),
        'sold_at': now.toUtc().toIso8601String(),
        'cashier_id': userId,
        'subtotal': subtotal,
        'service_charge_percent': serviceChargePercent,
        'service_charge_amount': serviceChargeAmount,
        'total': total,
        'donation_amount': donationAmount,
        'status': SaleStatus.paid.value,
        'notes': notes,
        'channel': channel.value,
        'partner_tenant_id': partnerTenantId,
        'partner_tenant_name': partnerTenantName,
      });
    } catch (error) {
      if (!isUniqueViolation(error)) rethrow;
      headerExists = true;
    }

    if (headerExists) {
      try {
        final existing = await fetchById(saleId);
        if (existing.items.isNotEmpty || items.isEmpty) {
          return existing;
        }
      } catch (_) {}
    }

    if (items.isNotEmpty) {
      await _client.from(CnTables.saleItems).insert(
        items
            .map((item) => item.toJson()..['sale_id'] = saleId)
            .toList(),
      );
    }

    if (payments.isNotEmpty) {
      await _client.from(CnTables.salePayments).insert(
        payments
            .map((payment) => payment.toJson()..['sale_id'] = saleId)
            .toList(),
      );
    }

    return fetchById(saleId);
  }

  Future<Sale> fetchById(String id) async {
    try {
      final response = await _client
          .from(CnTables.sales)
          .select(_select)
          .eq('id', id)
          .single();
      return Sale.fromJson(response);
    } catch (_) {
      final response = await _client
          .from(CnTables.sales)
          .select(_selectBasic)
          .eq('id', id)
          .single();
      return Sale.fromJson(response);
    }
  }

  Future<List<Sale>> listByDate(DateTime date) async {
    final iso = AppDateRange.isoDate(date);
    return _list(
      () => _client
          .from(CnTables.sales)
          .select(_select)
          .eq('sale_date', iso)
          .order('sold_at', ascending: false),
      () => _client
          .from(CnTables.sales)
          .select(_selectBasic)
          .eq('sale_date', iso)
          .order('sold_at', ascending: false),
    );
  }

  Future<List<Sale>> listByPeriod(DateTime start, DateTime end) async {
    return _list(
      () => _client
          .from(CnTables.sales)
          .select(_select)
          .gte('sale_date', AppDateRange.isoDate(start))
          .lte('sale_date', AppDateRange.isoDate(end))
          .order('sold_at', ascending: false),
      () => _client
          .from(CnTables.sales)
          .select(_selectBasic)
          .gte('sale_date', AppDateRange.isoDate(start))
          .lte('sale_date', AppDateRange.isoDate(end))
          .order('sold_at', ascending: false),
    );
  }

  Future<List<Sale>> listRefundedByPeriod(DateTime start, DateTime end) async {
    final statuses = [
      SaleStatus.refunded.value,
      SaleStatus.partialRefund.value,
    ];
    return _list(
      () => _client
          .from(CnTables.sales)
          .select(_select)
          .inFilter('status', statuses)
          .gte('sale_date', AppDateRange.isoDate(start))
          .lte('sale_date', AppDateRange.isoDate(end))
          .order('sold_at', ascending: false),
      () => _client
          .from(CnTables.sales)
          .select(_selectBasic)
          .eq('status', SaleStatus.refunded.value)
          .gte('sale_date', AppDateRange.isoDate(start))
          .lte('sale_date', AppDateRange.isoDate(end))
          .order('sold_at', ascending: false),
    );
  }

  Future<List<Sale>> _list(
    Future<dynamic> Function() primary,
    Future<dynamic> Function() fallback,
  ) async {
    try {
      final response = await primary();
      return (response as List<dynamic>)
          .map((row) => Sale.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await fallback();
      return (response as List<dynamic>)
          .map((row) => Sale.fromJson(row as Map<String, dynamic>))
          .toList();
    }
  }

  Future<Sale> refund({
    required Sale sale,
    required Map<String, double> qtyByItemId,
    String reason = '',
  }) async {
    if (!sale.status.canRefund) {
      throw 'Transaksi ini sudah direfund penuh.';
    }

    final lines = <({SaleItem item, double qty, double lineTotal})>[];
    var itemsAmount = 0.0;
    for (final item in sale.items) {
      final qty = qtyByItemId[item.id] ?? 0;
      if (qty <= 0) continue;
      if (qty > item.remainingQty) {
        throw 'Qty refund ${item.productName} melebihi sisa.';
      }
      final lineTotal = qty * item.unitPrice;
      itemsAmount += lineTotal;
      lines.add((item: item, qty: qty, lineTotal: lineTotal));
    }
    if (lines.isEmpty) {
      throw 'Pilih produk dan qty yang direfund.';
    }

    final serviceAmount = serviceOnItems(
      itemsAmount,
      sale.serviceChargePercent,
    );
    final remainingAfter = sale.items.every((item) {
      final extra = qtyByItemId[item.id] ?? 0;
      return item.remainingQty - extra <= 0;
    });
    final donationAmount = remainingAfter ? sale.netDonation : 0.0;
    final amount = itemsAmount + serviceAmount + donationAmount;
    final userId = _client.auth.currentUser?.id;

    final inserted = await _client.from(CnTables.saleRefunds).insert({
      'sale_id': sale.id,
      'cashier_id': userId,
      'amount': amount,
      'items_amount': itemsAmount,
      'service_amount': serviceAmount,
      'donation_amount': donationAmount,
      'reason': reason,
    }).select().single();
    final refundId = inserted['id'] as String;

    try {
      await _client.from(CnTables.saleRefundItems).insert(
        lines
            .map(
              (line) => {
                'refund_id': refundId,
                'sale_item_id': line.item.id,
                'product_name': line.item.productName,
                'qty': line.qty,
                'unit_price': line.item.unitPrice,
                'line_total': line.lineTotal,
              },
            )
            .toList(),
      );
    } catch (_) {}

    for (final line in lines) {
      await _client
          .from(CnTables.saleItems)
          .update({'qty_refunded': line.item.qtyRefunded + line.qty})
          .eq('id', line.item.id);
    }

    await _client.from(CnTables.sales).update({
      'status': remainingAfter
          ? SaleStatus.refunded.value
          : SaleStatus.partialRefund.value,
    }).eq('id', sale.id);

    return fetchById(sale.id);
  }
}
