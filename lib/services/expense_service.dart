import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/table_names.dart';
import '../models/expense.dart';
import '../utils/currency_formatter.dart';

class ExpenseService {
  ExpenseService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Expense>> listByPeriod(DateTime start, DateTime end) async {
    final response = await _client
        .from(CnTables.expenses)
        .select('*')
        .gte('expense_date', AppDateRange.isoDate(start))
        .lte('expense_date', AppDateRange.isoDate(end))
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Expense.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> upsert(Expense expense) async {
    final payload = expense.toJson();
    payload['created_by'] = _client.auth.currentUser?.id;
    final response = await _client
        .from(CnTables.expenses)
        .upsert(payload)
        .select()
        .single();
    return Expense.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from(CnTables.expenses).delete().eq('id', id);
  }
}
