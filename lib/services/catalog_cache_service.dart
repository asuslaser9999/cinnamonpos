import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/partner_tenant.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class CatalogCacheService {
  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  Future<void> saveProducts(List<Product> products) async {
    await _writeJson(
      'cn_cache_products.json',
      products
          .map(
            (product) => {
              'id': product.id,
              'name': product.name,
              'type': product.type.value,
              'category_id': product.categoryId,
              'category_name': product.categoryName,
              'supplier_id': product.supplierId,
              'supplier_name': product.supplierName,
              'cost_price': product.costPrice,
              'selling_price': product.sellingPrice,
              'image_url': product.imageUrl,
              'is_active': product.isActive,
            },
          )
          .toList(),
    );
  }

  Future<List<Product>> loadProducts() async {
    final rows = await _readList('cn_cache_products.json');
    return rows.map(Product.fromJson).toList();
  }

  Future<void> saveCategories(List<ProductCategory> categories) async {
    await _writeJson(
      'cn_cache_categories.json',
      categories
          .map(
            (category) => {
              'id': category.id,
              'name': category.name,
              'sort_order': category.sortOrder,
              'is_active': category.isActive,
            },
          )
          .toList(),
    );
  }

  Future<List<ProductCategory>> loadCategories() async {
    final rows = await _readList('cn_cache_categories.json');
    return rows.map(ProductCategory.fromJson).toList();
  }

  Future<void> saveTenants(List<PartnerTenant> tenants) async {
    await _writeJson(
      'cn_cache_tenants.json',
      tenants
          .map(
            (tenant) => {
              'id': tenant.id,
              'name': tenant.name,
              'notes': tenant.notes,
              'is_active': tenant.isActive,
            },
          )
          .toList(),
    );
  }

  Future<List<PartnerTenant>> loadTenants() async {
    final rows = await _readList('cn_cache_tenants.json');
    return rows.map(PartnerTenant.fromJson).toList();
  }

  Future<void> _writeJson(String name, List<Map<String, dynamic>> rows) async {
    final file = await _file(name);
    await file.writeAsString(jsonEncode(rows), flush: true);
  }

  Future<List<Map<String, dynamic>>> _readList(String name) async {
    final file = await _file(name);
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
