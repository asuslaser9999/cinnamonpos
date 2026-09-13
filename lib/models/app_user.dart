import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    this.displayName = '',
    this.username,
    this.role = UserRole.cashier,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String? username;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      username: json['username'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  String get roleLabel => role.isOwner ? 'Owner' : 'Kasir';

  String get statusLabel => isActive ? 'Aktif' : 'Nonaktif';
}
