import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/currency_formatter.dart';

class ExpenseNotifier extends ChangeNotifier {
  ExpenseNotifier({ExpenseService? service})
    : _service = service ?? ExpenseService();

  final ExpenseService _service;

  DateTime _start = AppDateRange.dateOnly(DateTime.now());
  DateTime _end = AppDateRange.dateOnly(DateTime.now());
  List<Expense> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime get start => _start;
  DateTime get end => _end;
  List<Expense> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get total => _items.fold(0, (sum, e) => sum + e.amount);

  Future<void> load({DateTime? start, DateTime? end}) async {
    if (start != null) _start = AppDateRange.dateOnly(start);
    if (end != null) _end = AppDateRange.dateOnly(end);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _service.listByPeriod(_start, _end);
    } catch (e) {
      _errorMessage = 'Gagal memuat pengeluaran.';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Expense expense) async {
    try {
      await _service.upsert(expense);
      await load();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan pengeluaran.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _service.delete(id);
      await load();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus pengeluaran.';
      notifyListeners();
      return false;
    }
  }
}
