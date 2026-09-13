import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/supplier.dart';

class SupplierService {
  SupplierService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Supplier>> list() async {
    final response = await _client
        .from(CnTables.suppliers)
        .select('*')
        .order('supplier_name');

    return (response as List<dynamic>)
        .map((row) => Supplier.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier> upsert(Supplier supplier) async {
    final response = await _client
        .from(CnTables.suppliers)
        .upsert(supplier.toJson())
        .select()
        .single();
    return Supplier.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from(CnTables.suppliers).delete().eq('id', id);
  }
}
