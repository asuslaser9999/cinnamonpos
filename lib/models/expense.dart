class Expense {
  const Expense({
    this.id = '',
    required this.expenseDate,
    required this.description,
    required this.amount,
    this.createdBy,
  });

  final String id;
  final DateTime expenseDate;
  final String description;
  final double amount;
  final String? createdBy;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      expenseDate: DateTime.tryParse(json['expense_date'] as String? ?? '') ??
          DateTime.now(),
      description: json['description'] as String? ?? '',
      amount: _toDouble(json['amount']),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final date = DateTime(
      expenseDate.year,
      expenseDate.month,
      expenseDate.day,
    );
    return {
      if (id.isNotEmpty) 'id': id,
      'expense_date':
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'description': description.trim(),
      'amount': amount,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
