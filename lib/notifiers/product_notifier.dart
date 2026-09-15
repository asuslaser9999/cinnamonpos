import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/catalog_cache_service.dart';
import '../services/product_service.dart';
import '../utils/network_error.dart';

class ProductNotifier extends ChangeNotifier {
  ProductNotifier({
    ProductService? service,
    CatalogCacheService? cache,
  }) : _service = service ?? ProductService(),
       _cache = cache ?? CatalogCacheService();

  final ProductService _service;
  final CatalogCacheService _cache;

  List<Product> _items = [];
  bool _isLoading = false;
  bool _usingCache = false;
  String? _errorMessage;

  List<Product> get items => _items;
  List<Product> get activeItems => _items.where((p) => p.isActive).toList();
  bool get isLoading => _isLoading;
  bool get usingCache => _usingCache;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _usingCache = false;
    notifyListeners();
    try {
      _items = await _service.list().timeout(supabaseCallTimeout);
      await _cache.saveProducts(_items);
    } catch (e) {
      final cached = await _cache.loadProducts();
      if (cached.isNotEmpty) {
        _items = cached;
        _usingCache = true;
        _errorMessage =
            'Mode offline: memakai daftar produk tersimpan di perangkat ini.';
      } else {
        _items = [];
        _errorMessage = isNetworkError(e)
            ? 'Tidak ada katalog. Butuh internet sekali untuk unduh produk.'
            : 'Gagal memuat produk.';
      }
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
