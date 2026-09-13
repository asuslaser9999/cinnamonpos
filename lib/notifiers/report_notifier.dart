import 'package:flutter/foundation.dart';

import '../models/pos_reports.dart';
import '../services/expense_service.dart';
import '../services/sale_service.dart';
import '../utils/currency_formatter.dart';

class ReportNotifier extends ChangeNotifier {
  ReportNotifier({
    SaleService? saleService,
    ExpenseService? expenseService,
  }) : _saleService = saleService ?? SaleService(),
       _expenseService = expenseService ?? ExpenseService();

  final SaleService _saleService;
  final ExpenseService _expenseService;

  DateTime _start = AppDateRange.dateOnly(DateTime.now());
  DateTime _end = AppDateRange.dateOnly(DateTime.now());
  CashierReport? cashierReport;
  OwnerReport? ownerReport;
  TenantBillReport? tenantBillReport;
  bool isLoading = false;
  String? errorMessage;

  DateTime get start => _start;
  DateTime get end => _end;

  Future<void> load({DateTime? start, DateTime? end}) async {
    if (start != null) _start = AppDateRange.dateOnly(start);
    if (end != null) _end = AppDateRange.dateOnly(end);
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final sales = await _saleService.listByPeriod(_start, _end);
      final expenses = await _expenseService.listByPeriod(_start, _end);
      cashierReport = ReportAggregator.buildCashier(
        startDate: _start,
        endDate: _end,
        sales: sales,
      );
      ownerReport = ReportAggregator.buildOwner(
        cashier: cashierReport!,
        sales: sales,
        expenseTotal: expenses.fold(0, (sum, e) => sum + e.amount),
      );
      tenantBillReport = ReportAggregator.buildTenantBills(
        startDate: _start,
        endDate: _end,
        sales: sales,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Report load failed: $e');
      errorMessage = 'Gagal memuat laporan.';
      cashierReport = null;
      ownerReport = null;
      tenantBillReport = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
