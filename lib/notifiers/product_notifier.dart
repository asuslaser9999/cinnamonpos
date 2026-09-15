import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_service.dart';

class ProductNotifier extends ChangeNotifier {
  ProductNotifier({ProductService? service})
    : _service = service ?? ProductService();

  final ProductService _service;

  List<Product> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get items => _items;
  List<Product> get activeItems => _items.where((p) => p.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _service.list();
    } catch (e) {
      _errorMessage = 'Gagal memuat produk.';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(
    Product product, {
    Uint8List? imageBytes,
    String imageExt = 'jpg',
    bool removeImage = false,
  }) async {
    try {
      await _service.upsert(
        product,
        imageBytes: imageBytes,
        imageExt: imageExt,
        removeImage: removeImage,
      );
      await load();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Save product failed: $e');
      _errorMessage =
          'Gagal menyimpan produk. Cek koneksi, kolom image_url, atau bucket storage.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivate(String id) async {
    try {
      await _service.deactivate(id);
      await load();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menonaktifkan produk.';
      notifyListeners();
      return false;
    }
  }
}
