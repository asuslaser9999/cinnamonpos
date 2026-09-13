class Supplier {
  const Supplier({
    this.id = '',
    required this.supplierName,
    this.phone,
    this.notes = '',
  });

  final String id;
  final String supplierName;
  final String? phone;
  final String notes;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String? ?? '',
      supplierName: json['supplier_name'] as String? ?? '',
      phone: json['phone'] as String?,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'supplier_name': supplierName.trim(),
      'phone': phone?.trim(),
      'notes': notes.trim(),
    };
  }
}
