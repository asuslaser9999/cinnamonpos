import 'package:flutter/foundation.dart';

import '../models/daily_stock.dart';
import '../models/partner_tenant.dart';
import '../services/daily_stock_service.dart';
import '../services/partner_tenant_service.dart';
import '../services/product_service.dart';
import '../utils/currency_formatter.dart';

class DailyStockNotifier extends ChangeNotifier {
  DailyStockNotifier({
    DailyStockService? service,
    ProductService? productService,
    PartnerTenantService? tenantService,
  }) : _service = service ?? DailyStockService(),
       _productService = productService ?? ProductService(),
       _tenantService = tenantService ?? PartnerTenantService();

  final DailyStockService _service;
  final ProductService _productService;
  final PartnerTenantService _tenantService;

  DateTime _date = AppDateRange.dateOnly(DateTime.now());
  List<DailyStockLine> _lines = [];
  List<DailyStockTenantColumn> _tenantColumns = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  DateTime get date => _date;
  List<DailyStockLine> get lines => _lines;
  List<DailyStockTenantColumn> get tenantColumns => _tenantColumns;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get mismatchCount => _lines.where((line) => line.hasMismatch).length;

  int get countedCount =>
      _lines.where((line) => line.closingEntered).length;

  Future<void> load({DateTime? date}) async {
    if (date != null) _date = AppDateRange.dateOnly(date);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final products = await _productService.list();
      var tenants = <PartnerTenant>[];
      try {
        tenants = await _tenantService.list();
      } catch (error) {
        if (kDebugMode) debugPrint('Daily stock tenants failed: $error');
      }
      final snapshot = await _service.loadDay(
        date: _date,
        products: products,
        tenants: tenants,
      );
      _lines = snapshot.lines;
      _tenantColumns = snapshot.tenantColumns;
    } catch (error) {
      if (kDebugMode) debugPrint('Daily stock load failed: $error');
      _errorMessage =
          'Gagal memuat stok harian. Jalankan migrasi 006 di Supabase.';
      _lines = [];
      _tenantColumns = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setOpening(String productId, double qty) {
    final line = _lineOf(productId);
    if (line == null) return;
    line.openingQty = qty < 0 ? 0 : qty;
    notifyListeners();
  }

  void setClosing(String productId, double? qty) {
    final line = _lineOf(productId);
    if (line == null) return;
    line.closingQty = qty == null || qty < 0 ? null : qty;
    notifyListeners();
  }

  Future<bool> save() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.saveDay(date: _date, lines: _lines);
      await load();
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('Daily stock save failed: $error');
      _errorMessage =
          'Gagal menyimpan stok harian. Jalankan migrasi 006 di Supabase.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  DailyStockLine? _lineOf(String productId) {
    for (final line in _lines) {
      if (line.productId == productId) return line;
    }
    return null;
  }
}
