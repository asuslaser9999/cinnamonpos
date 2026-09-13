import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/user_management_service.dart';

class UserManagementNotifier extends ChangeNotifier {
  UserManagementNotifier({UserManagementService? service})
    : _service = service ?? UserManagementService();

  final UserManagementService _service;

  List<AppUser> _users = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _service.listUsers();
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar user.';
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _service.createUser(
        displayName: displayName,
        username: username,
        password: password,
        role: role,
      );
      _successMessage = 'User berhasil ditambahkan.';
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser({
    required String userId,
    required String displayName,
    required UserRole role,
    required bool isActive,
    String? password,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _service.updateUser(
        userId: userId,
        displayName: displayName,
        role: role,
        isActive: isActive,
        password: password,
      );
      _successMessage = 'User berhasil diperbarui.';
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
