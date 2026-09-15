import 'package:flutter/foundation.dart';

import '../models/product_category.dart';
import '../services/category_service.dart';

class CategoryNotifier extends ChangeNotifier {
  CategoryNotifier({CategoryService? service})
    : _service = service ?? CategoryService();

  final CategoryService _service;

  List<ProductCategory> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductCategory> get items => _items;
  List<ProductCategory> get activeItems =>
      _items.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _service.list();
    } catch (e) {
      _errorMessage = 'Gagal memuat kategori.';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(ProductCategory category) async {
    try {
      await _service.upsert(category);
      await load();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan kategori.';
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
      _errorMessage = 'Gagal menghapus kategori. Pastikan tidak dipakai produk.';
      notifyListeners();
      return false;
    }
  }
}
