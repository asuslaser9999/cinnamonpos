import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/product.dart';

class ProductService {
  ProductService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Product>> list({bool activeOnly = false}) async {
    final query = _client.from(CnTables.products).select('*');
    final response = activeOnly
        ? await query.eq('is_active', true).order('name')
        : await query.order('name');

    final names = await _lookupNames();
    return (response as List<dynamic>).map((row) {
      final json = Map<String, dynamic>.from(row as Map);
      json['category_name'] = names.categories[json['category_id']];
      json['supplier_name'] = names.suppliers[json['supplier_id']];
      return Product.fromJson(json);
    }).toList();
  }

  Future<Product> upsert(
    Product product, {
    Uint8List? imageBytes,
    String imageExt = 'jpg',
    bool removeImage = false,
  }) async {
    final payload = Map<String, dynamic>.from(product.toJson())
      ..remove('image_url');
    final response = await _client
        .from(CnTables.products)
        .upsert(payload)
        .select('*')
        .single();
    var saved = await _mapRow(response);

    if (removeImage && (saved.imageUrl ?? '').isNotEmpty) {
      await _deleteStoredImage(saved.id);
      saved = await _setImageUrl(saved.id, null);
    }

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final url = await _uploadImage(saved.id, imageBytes, imageExt);
      saved = await _setImageUrl(saved.id, url);
    }

    return saved;
  }

  Future<Product> _mapRow(Map<String, dynamic> row) async {
    final names = await _lookupNames();
    final json = Map<String, dynamic>.from(row);
    json['category_name'] = names.categories[json['category_id']];
    json['supplier_name'] = names.suppliers[json['supplier_id']];
    return Product.fromJson(json);
  }

  Future<Product> _setImageUrl(String id, String? url) async {
    final response = await _client
        .from(CnTables.products)
        .update({'image_url': url})
        .eq('id', id)
        .select('*')
        .single();
    return _mapRow(Map<String, dynamic>.from(response));
  }

  Future<String> _uploadImage(
    String productId,
    Uint8List bytes,
    String ext,
  ) async {
    final meta = _imageUploadMeta(ext);
    final path = '$productId.${meta.ext}';
    await _client.storage
        .from(CnTables.productImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: meta.contentType,
          ),
        );
    return _client.storage
        .from(CnTables.productImagesBucket)
        .getPublicUrl(path);
  }

  /// Supabase accepts `image/jpeg`, not the unofficial `image/jpg`.
  ({String ext, String contentType}) _imageUploadMeta(String ext) {
    switch (ext.toLowerCase().replaceFirst('.', '')) {
      case 'png':
        return (ext: 'png', contentType: 'image/png');
      case 'webp':
        return (ext: 'webp', contentType: 'image/webp');
      case 'jpg':
      case 'jpeg':
      default:
        return (ext: 'jpg', contentType: 'image/jpeg');
    }
  }

  Future<void> _deleteStoredImage(String productId) async {
    try {
      await _client.storage.from(CnTables.productImagesBucket).remove([
        '$productId.jpg',
        '$productId.png',
        '$productId.webp',
      ]);
    } catch (_) {}
  }

  Future<({Map<String, String> categories, Map<String, String> suppliers})>
  _lookupNames() async {
    final categories = <String, String>{};
    final suppliers = <String, String>{};
    try {
      final rows = await _client
          .from(CnTables.productCategories)
          .select('id, name');
      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final id = map['id'] as String?;
        final name = map['name'] as String?;
        if (id != null && name != null) categories[id] = name;
      }
    } catch (_) {}
    try {
      final rows = await _client
          .from(CnTables.suppliers)
          .select('id, supplier_name');
      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final id = map['id'] as String?;
        final name = map['supplier_name'] as String?;
        if (id != null && name != null) suppliers[id] = name;
      }
    } catch (_) {}
    return (categories: categories, suppliers: suppliers);
  }

  Future<void> deactivate(String id) async {
    await _client.from(CnTables.products).update({'is_active': false}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _deleteStoredImage(id);
    await _client.from(CnTables.products).delete().eq('id', id);
  }
}
