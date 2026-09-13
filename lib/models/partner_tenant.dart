class PartnerTenant {
  const PartnerTenant({
    this.id = '',
    required this.name,
    this.notes = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String notes;
  final bool isActive;

  factory PartnerTenant.fromJson(Map<String, dynamic> json) {
    return PartnerTenant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name.trim(),
      'notes': notes.trim(),
      'is_active': isActive,
    };
  }
}
