import 'package:flutter/foundation.dart';

import '../models/sale.dart';
import '../services/sale_service.dart';
import '../utils/currency_formatter.dart';

class RefundReportNotifier extends ChangeNotifier {
  RefundReportNotifier({SaleService? service})
    : _service = service ?? SaleService();

  final SaleService _service;

  DateTime _start = AppDateRange.dateOnly(DateTime.now());
  DateTime _end = AppDateRange.dateOnly(DateTime.now());
  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime get start => _start;
  DateTime get end => _end;
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get count => _sales.length;
  double get totalAmount =>
      _sales.fold(0, (sum, sale) => sum + sale.refundedTotal);

  Future<void> load({DateTime? start, DateTime? end}) async {
    if (start != null) _start = AppDateRange.dateOnly(start);
    if (end != null) _end = AppDateRange.dateOnly(end);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _sales = await _service.listRefundedByPeriod(_start, _end);
    } catch (e) {
      if (kDebugMode) debugPrint('Refund report failed: $e');
      _errorMessage = 'Gagal memuat laporan refund.';
      _sales = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
