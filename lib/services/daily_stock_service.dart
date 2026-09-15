import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/daily_stock.dart';
import '../models/partner_tenant.dart';
import '../models/product.dart';
import '../models/sale_channel.dart';
import '../utils/currency_formatter.dart';

class DailyStockService {
  DailyStockService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DailyStockSnapshot> loadDay({
    required DateTime date,
    required List<Product> products,
    List<PartnerTenant> tenants = const [],
  }) async {
    final iso = AppDateRange.isoDate(date);
    final saved = await _listSaved(iso);
    final sold = await _soldByProduct(iso);
    final tenantColumns = _tenantColumns(tenants, sold.tenantNames);

    DailyStockLine buildLine({
      required String productId,
      required String productName,
      required String categoryName,
      required Map<String, dynamic>? row,
    }) {
      final qty = sold.byProduct[productId];
      return DailyStockLine(
        id: row?['id'] as String? ?? '',
        productId: productId,
        productName: productName,
        categoryName: categoryName,
        openingQty: _toDouble(row?['opening_qty']),
        soldOwnQty: qty?.own ?? 0,
        soldByTenant: qty?.byTenant ?? const {},
        closingQty: row == null || row['closing_qty'] == null
            ? null
            : _toDouble(row['closing_qty']),
        notes: row?['notes'] as String? ?? '',
      );
    }

    final lines = <DailyStockLine>[];
    final seen = <String>{};

    for (final product in products.where((item) => item.isActive)) {
      seen.add(product.id);
      lines.add(
        buildLine(
          productId: product.id,
          productName: product.name,
          categoryName: product.categoryName ?? '',
          row: saved[product.id],
        ),
      );
    }

    for (final productId in sold.byProduct.keys) {
      if (seen.contains(productId) || productId.isEmpty) continue;
      final product = products.where((item) => item.id == productId);
      lines.add(
        buildLine(
          productId: productId,
          productName: product.isEmpty ? 'Produk nonaktif' : product.first.name,
          categoryName:
              product.isEmpty ? '' : (product.first.categoryName ?? ''),
          row: saved[productId],
        ),
      );
    }

    lines.sort(
      (a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()),
    );
    return DailyStockSnapshot(lines: lines, tenantColumns: tenantColumns);
  }

  Future<void> saveDay({
    required DateTime date,
    required List<DailyStockLine> lines,
  }) async {
    final iso = AppDateRange.isoDate(date);
    final userId = _client.auth.currentUser?.id;
    final payload = lines
        .where(
          (line) =>
              line.openingQty > 0 ||
              line.closingEntered ||
              line.id.isNotEmpty,
        )
        .map(
          (line) => {
            'stock_date': iso,
            'product_id': line.productId,
            'opening_qty': line.openingQty,
            'closing_qty': line.closingQty,
            'notes': line.notes,
            'updated_by': userId,
          },
        )
        .toList();

    if (payload.isEmpty) return;

    await _client.from(CnTables.dailyStock).upsert(
      payload,
      onConflict: 'stock_date,product_id',
    );
  }

  Future<Map<String, Map<String, dynamic>>> _listSaved(String iso) async {
    final response = await _client
        .from(CnTables.dailyStock)
        .select()
        .eq('stock_date', iso);
    final map = <String, Map<String, dynamic>>{};
    for (final row in response as List<dynamic>) {
      final json = Map<String, dynamic>.from(row as Map);
      final productId = json['product_id'] as String? ?? '';
      if (productId.isEmpty) continue;
      map[productId] = json;
    }
    return map;
  }

  Future<_SoldByProduct> _soldByProduct(String iso) async {
    final sales = await _client
        .from(CnTables.sales)
        .select(
          'id, channel, partner_tenant_id, partner_tenant_name, '
          'cn_sale_items(product_id, qty, qty_refunded)',
        )
        .eq('sale_date', iso);

    final byProduct = <String, _SoldQty>{};
    final tenantNames = <String, String>{};

    for (final sale in sales as List<dynamic>) {
      final row = Map<String, dynamic>.from(sale as Map);
      final viaTenant =
          SaleChannel.fromString(row['channel'] as String?).isViaTenant;
      final tenantId = viaTenant ? _tenantKey(row) : '';
      if (viaTenant) {
        tenantNames[tenantId] = _tenantLabel(row);
      }
      final items = row['cn_sale_items'] as List<dynamic>? ?? const [];
      for (final raw in items) {
        final item = Map<String, dynamic>.from(raw as Map);
        final productId = item['product_id'] as String? ?? '';
        if (productId.isEmpty) continue;
        final qty = _toDouble(item['qty']);
        final refunded = _toDouble(item['qty_refunded']);
        final net = qty - refunded;
        if (net <= 0) continue;
        final current = byProduct.putIfAbsent(productId, _SoldQty.new);
        if (viaTenant) {
          current.byTenant[tenantId] = (current.byTenant[tenantId] ?? 0) + net;
        } else {
          current.own += net;
        }
      }
    }
    return _SoldByProduct(byProduct: byProduct, tenantNames: tenantNames);
  }

  List<DailyStockTenantColumn> _tenantColumns(
    List<PartnerTenant> tenants,
    Map<String, String> soldNames,
  ) {
    final columns = <String, DailyStockTenantColumn>{};
    for (final tenant in tenants.where((item) => item.isActive)) {
      if (tenant.id.isEmpty) continue;
      columns[tenant.id] = DailyStockTenantColumn(
        id: tenant.id,
        name: tenant.name.trim().isEmpty ? 'Tenan' : tenant.name.trim(),
      );
    }
    for (final entry in soldNames.entries) {
      columns.putIfAbsent(
        entry.key,
        () => DailyStockTenantColumn(id: entry.key, name: entry.value),
      );
    }
    final list = columns.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static String _tenantKey(Map<String, dynamic> row) {
    final id = (row['partner_tenant_id'] as String? ?? '').trim();
    if (id.isNotEmpty) return id;
    final name = _tenantLabel(row);
    return 'name:$name';
  }

  static String _tenantLabel(Map<String, dynamic> row) {
    final name = (row['partner_tenant_name'] as String? ?? '').trim();
    return name.isEmpty ? 'Tenan' : name;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class _SoldQty {
  double own = 0;
  final Map<String, double> byTenant = {};
}

class _SoldByProduct {
  const _SoldByProduct({
    required this.byProduct,
    required this.tenantNames,
  });

  final Map<String, _SoldQty> byProduct;
  final Map<String, String> tenantNames;
}
