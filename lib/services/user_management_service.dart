import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

class UserManagementService {
  UserManagementService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AppUser>> listUsers() async {
    final response = await _client
        .from(CnTables.profiles)
        .select('*')
        .order('created_at');

    return (response as List<dynamic>)
        .map((row) => AppUser.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser({
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    await _invokeAdmin(
      body: {
        'action': 'create',
        'display_name': displayName,
        'username': username.trim().toLowerCase(),
        'password': password,
        'role': role.value,
      },
    );

    // Edge Function menulis ke `profiles` (Ultimate POS).
    // Sinkronkan baris yang sama ke `cn_profiles` untuk Cinnamon POS.
    await _syncCreatedUserToCnProfiles(
      username: username.trim().toLowerCase(),
      displayName: displayName,
      role: role,
    );
  }

  Future<void> updateUser({
    required String userId,
    String? displayName,
    UserRole? role,
    bool? isActive,
    String? password,
  }) async {
    if (password != null && password.isNotEmpty) {
      await _invokeAdmin(
        body: {
          'action': 'update',
          'user_id': userId,
          'password': password,
        },
      );
    }

    final payload = <String, dynamic>{};
    if (displayName != null) payload['display_name'] = displayName;
    if (role != null) payload['role'] = role.value;
    if (isActive != null) payload['is_active'] = isActive;

    if (payload.isNotEmpty) {
      await _client.from(CnTables.profiles).update(payload).eq('id', userId);
    }
  }

  Future<void> _syncCreatedUserToCnProfiles({
    required String username,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final existing = await _client
          .from(CnTables.profiles)
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (existing != null) {
        await _client.from(CnTables.profiles).update({
          'display_name': displayName,
          'role': role.value,
          'is_active': true,
        }).eq('id', existing['id']);
      }
    } catch (_) {
      // Trigger cn_handle_new_user mungkin belum di-deploy.
    }
  }

  Future<void> _invokeAdmin({required Map<String, dynamic> body}) async {
    final response = await _client.functions.invoke(
      'admin-manage-users',
      body: body,
    );

    if (response.status == 404) {
      throw 'Edge Function admin-manage-users belum di-deploy di Supabase. '
          'Deploy lewat Dashboard → Edge Functions.';
    }

    if (response.status >= 400) {
      throw _parseError(response.data, response.status);
    }

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final error = map['error'];
      if (error != null) {
        throw error.toString();
      }
    }
  }

  String _parseError(dynamic data, [int? status]) {
    if (data is Map<String, dynamic> && data['error'] != null) {
      return data['error'].toString();
    }
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (status != null) {
      return 'Gagal memproses permintaan user (HTTP $status).';
    }
    return 'Gagal memproses permintaan user.';
  }
}
