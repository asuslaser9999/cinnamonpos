import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/product_category.dart';

class CategoryService {
  CategoryService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ProductCategory>> list({bool activeOnly = false}) async {
    final query = _client.from(CnTables.productCategories).select('*');
    final response = activeOnly
        ? await query.eq('is_active', true).order('sort_order').order('name')
        : await query.order('sort_order').order('name');
    return (response as List<dynamic>)
        .map((row) => ProductCategory.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ProductCategory> upsert(ProductCategory category) async {
    final response = await _client
        .from(CnTables.productCategories)
        .upsert(category.toJson())
        .select()
        .single();
    return ProductCategory.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from(CnTables.productCategories).delete().eq('id', id);
  }
}
