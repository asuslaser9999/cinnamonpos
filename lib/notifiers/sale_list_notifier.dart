import 'package:flutter/foundation.dart';

import '../models/sale.dart';
import '../services/sale_service.dart';
import '../utils/currency_formatter.dart';

class SaleListNotifier extends ChangeNotifier {
  SaleListNotifier({SaleService? service})
    : _service = service ?? SaleService();

  final SaleService _service;

  DateTime _date = AppDateRange.dateOnly(DateTime.now());
  List<Sale> _sales = [];
  bool _isLoading = false;
  bool _isRefunding = false;
  String? _errorMessage;

  DateTime get date => _date;
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  bool get isRefunding => _isRefunding;
  String? get errorMessage => _errorMessage;

  Future<void> load({DateTime? date}) async {
    if (date != null) _date = AppDateRange.dateOnly(date);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _sales = await _service.listByDate(_date);
    } catch (e) {
      _errorMessage = 'Gagal memuat transaksi.';
      _sales = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Sale?> refund(
    Sale sale, {
    required Map<String, double> qtyByItemId,
    String reason = '',
  }) async {
    _isRefunding = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _service.refund(
        sale: sale,
        qtyByItemId: qtyByItemId,
        reason: reason,
      );
      await load();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isRefunding = false;
      notifyListeners();
    }
  }
}
