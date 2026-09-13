import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/partner_tenant.dart';

class PartnerTenantService {
  PartnerTenantService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<PartnerTenant>> list() async {
    final response = await _client
        .from(CnTables.partnerTenants)
        .select('*')
        .order('name');

    return (response as List<dynamic>)
        .map((row) => PartnerTenant.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<PartnerTenant> upsert(PartnerTenant tenant) async {
    final response = await _client
        .from(CnTables.partnerTenants)
        .upsert(tenant.toJson())
        .select()
        .single();
    return PartnerTenant.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from(CnTables.partnerTenants).delete().eq('id', id);
  }
}
