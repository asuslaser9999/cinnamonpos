import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/app_settings.dart';
import '../models/cashier_access_mode.dart';

/// Pengaturan akses kasir yang disinkronkan ke Supabase (semua perangkat).
class RemoteAppSettingsService {
  RemoteAppSettingsService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _singletonId = 'default';

  bool get isAuthenticated => _client.auth.currentSession != null;

  Future<AppSettings?> fetchCashierPolicy() async {
    if (!isAuthenticated) return null;

    final response = await _client
        .from(CnTables.storeAppSettings)
        .select()
        .eq('id', _singletonId)
        .maybeSingle();

    if (response == null) return null;

    return AppSettings(
      cashierAccessMode: CashierAccessMode.fromStorageKey(
        response['cashier_access_mode'] as String?,
      ),
      cashierAccessStart: response['cashier_access_start'] as String? ?? '05:30',
      cashierAccessEnd: response['cashier_access_end'] as String? ?? '16:30',
      cashierCanManageOwnProducts:
          response['cashier_can_manage_own_products'] as bool? ?? false,
      serviceChargeEnabled:
          response['service_charge_enabled'] as bool? ?? false,
      serviceChargePercent: _toDouble(response['service_charge_percent']),
      cashDonationRoundingEnabled:
          response['cash_donation_rounding_enabled'] as bool? ?? false,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> upsertCashierPolicy(AppSettings settings) async {
    if (!isAuthenticated) return;

    final userId = _client.auth.currentUser?.id;

    final payload = <String, dynamic>{
      'id': _singletonId,
      'cashier_access_mode': settings.cashierAccessMode.storageKey,
      'cashier_access_start': settings.cashierAccessStart,
      'cashier_access_end': settings.cashierAccessEnd,
      'cashier_can_manage_own_products': settings.cashierCanManageOwnProducts,
      'updated_by': ?userId,
    };

    try {
      await _client.from(CnTables.storeAppSettings).upsert({
        ...payload,
        'service_charge_enabled': settings.serviceChargeEnabled,
        'service_charge_percent': settings.serviceChargePercent,
        'cash_donation_rounding_enabled': settings.cashDonationRoundingEnabled,
      });
    } catch (_) {
      await _client.from(CnTables.storeAppSettings).upsert(payload);
    }
  }
}
