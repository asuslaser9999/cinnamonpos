import 'product_type.dart';

class Product {
  const Product({
    this.id = '',
    required this.name,
    required this.type,
    required this.categoryId,
    this.categoryName,
    this.supplierId,
    this.supplierName,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final ProductType type;
  final String categoryId;
  final String? categoryName;
  final String? supplierId;
  final String? supplierName;
  final double costPrice;
  final double sellingPrice;
  final String? imageUrl;
  final bool isActive;

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = _asMap(json['cn_product_categories']);
    final supplier = _asMap(json['cn_suppliers']);

    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: ProductType.fromString(json['type'] as String?),
      categoryId: json['category_id'] as String? ?? '',
      categoryName:
          json['category_name'] as String? ?? category?['name'] as String?,
      supplierId: json['supplier_id'] as String?,
      supplierName:
          json['supplier_name'] as String? ??
          supplier?['supplier_name'] as String?,
      costPrice: _toDouble(json['cost_price']),
      sellingPrice: _toDouble(json['selling_price']),
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name.trim(),
      'type': type.value,
      'category_id': categoryId,
      'supplier_id': type.isConsignment ? supplierId : null,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    ProductType? type,
    String? categoryId,
    String? categoryName,
    String? supplierId,
    String? supplierName,
    double? costPrice,
    double? sellingPrice,
    String? imageUrl,
    bool? isActive,
    bool clearSupplier = false,
    bool clearImage = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      isActive: isActive ?? this.isActive,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
