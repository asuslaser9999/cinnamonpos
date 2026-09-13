import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/auth_config.dart';
import '../config/table_names.dart';
import '../models/user_role.dart';

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  String? get currentUserId => currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isAuthenticated => currentUser != null;

  Future<UserRole> getCurrentUserRole() async {
    final profile = await getCurrentProfile();
    if (profile == null) return UserRole.cashier;
    return UserRole.fromString(profile['role'] as String?);
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from(CnTables.profiles)
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (_) {
      try {
        return await _client
            .from(CnTables.profiles)
            .select('role, email')
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {
        return null;
      }
    }
  }

  Future<bool> isCurrentUserActive() async {
    final profile = await getCurrentProfile();
    if (profile == null) return true;
    return profile['is_active'] as bool? ?? true;
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final loginEmail = await _resolveLoginEmail(username);
    AuthException? lastError;

    for (final email in _loginEmailCandidates(username, loginEmail)) {
      try {
        await _client.auth.signInWithPassword(email: email, password: password);

        final profile = await getCurrentProfile();
        if (profile != null &&
            (profile['is_active'] as bool? ?? true) == false) {
          await signOut();
          throw AuthException('Akun nonaktif. Hubungi owner.');
        }
        return;
      } on AuthException catch (e) {
        lastError = e;
      }
    }

    throw AuthException(_mapLoginError(lastError?.message));
  }

  Future<String> _resolveLoginEmail(String input) async {
    final trimmed = input.trim();
    if (trimmed.contains('@')) return trimmed.toLowerCase();

    try {
      final result = await _client.rpc(
        CnTables.resolveLoginEmail,
        params: {'p_username': trimmed},
      );
      if (result != null && result.toString().trim().isNotEmpty) {
        return result.toString().trim().toLowerCase();
      }
    } catch (_) {
      // RPC belum di-deploy — fallback ke domain internal.
    }

    return usernameToInternalEmail(trimmed);
  }

  List<String> _loginEmailCandidates(String input, String primaryEmail) {
    final trimmed = input.trim().toLowerCase();
    final candidates = <String>{primaryEmail.toLowerCase()};

    if (trimmed.contains('@')) {
      candidates.add(trimmed);
    } else {
      candidates.add(usernameToInternalEmail(trimmed));
    }

    return candidates.toList();
  }

  String _mapLoginError(String? message) {
    final lower = (message ?? '').toLowerCase();
    if (lower.contains('banned') || lower.contains('ban')) {
      return 'Akun diblokir/nonaktif. Hubungi owner atau cek di Supabase.';
    }
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Username/email atau password salah.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Akun belum dikonfirmasi. Hubungi owner.';
    }
    return message ?? 'Gagal login.';
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
