import 'package:flutter/foundation.dart';

import '../models/partner_tenant.dart';
import '../services/partner_tenant_service.dart';

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
