enum UserRole {
  owner('owner'),
  cashier('cashier');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.cashier,
    );
  }

  bool get isOwner => this == UserRole.owner;
  bool get isCashier => this == UserRole.cashier;
}
