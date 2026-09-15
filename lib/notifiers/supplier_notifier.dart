import 'package:flutter/foundation.dart';

import '../models/supplier.dart';
import '../services/supplier_service.dart';

class SupplierNotifier extends ChangeNotifier {
  SupplierNotifier({SupplierService? service})
    : _service = service ?? SupplierService();

  final SupplierService _service;

  List<Supplier> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Supplier> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _service.list();
    } catch (e) {
      _errorMessage = 'Gagal memuat supplier.';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Supplier supplier) async {
    try {
      await _service.upsert(supplier);
      await load();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan supplier.';
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
      _errorMessage = 'Gagal menghapus supplier.';
      notifyListeners();
      return false;
    }
  }
}
