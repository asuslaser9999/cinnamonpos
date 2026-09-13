import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthNotifier extends ChangeNotifier {
  AuthNotifier({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _init();
  }

  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  UserRole _role = UserRole.cashier;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserRole get role => _role;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isOwner => _role.isOwner;
  bool get isCashier => _role.isCashier;

  Future<void> _init() async {
    try {
      if (_authService.isAuthenticated) {
        final isActive = await _authService.isCurrentUserActive();
        if (!isActive) {
          await _authService.signOut();
          _status = AuthStatus.unauthenticated;
        } else {
          await _loadRole();
          _status = AuthStatus.authenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auth init error: $e');
      }
      try {
        await _authService.signOut();
      } catch (_) {}
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }

    _authService.authStateChanges.listen((data) async {
      try {
        if (data.session != null) {
          await _loadRole();
          _status = AuthStatus.authenticated;
        } else {
          _role = UserRole.cashier;
          _status = AuthStatus.unauthenticated;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Auth state change error: $e');
        }
        _role = UserRole.cashier;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<void> _loadRole() async {
    try {
      _role = await _authService.getCurrentUserRole();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Load role error: $e');
      }
      _role = UserRole.cashier;
    }
  }

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(username: username, password: password);
      await _loadRole();
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Gagal login. Periksa koneksi Anda.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _role = UserRole.cashier;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
