import 'package:flutter/foundation.dart';

import '../models/partner_tenant.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/supplier.dart';
import '../services/category_service.dart';
import '../services/partner_tenant_service.dart';
import '../services/product_service.dart';
import '../services/supplier_service.dart';

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

class PartnerTenantNotifier extends ChangeNotifier {
  PartnerTenantNotifier({PartnerTenantService? service})
    : _service = service ?? PartnerTenantService();

  final PartnerTenantService _service;

  List<PartnerTenant> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PartnerTenant> get items => _items;
  List<PartnerTenant> get activeItems =>
      _items.where((item) => item.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _service.list();
    } catch (e) {
      _errorMessage = 'Gagal memuat tenan. Jalankan migrasi 004 di Supabase.';
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(PartnerTenant tenant) async {
    try {
      await _service.upsert(tenant);
      await load();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan tenan.';
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
      _errorMessage = 'Gagal menghapus tenan.';
      notifyListeners();
      return false;
    }
  }
}
