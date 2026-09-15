import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/pending_sale.dart';

class PendingSaleQueue {
  static const _fileName = 'cn_pending_sales.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<PendingSale>> list() async {
    final file = await _file();
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      final rows = decoded is Map<String, dynamic>
          ? decoded['sales'] as List<dynamic>? ?? const []
          : decoded is List
          ? decoded
          : const [];
      return rows
          .whereType<Map>()
          .map((row) => PendingSale.fromJson(Map<String, dynamic>.from(row)))
          .where((sale) => sale.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<int> count() async => (await list()).length;

  Future<void> enqueue(PendingSale sale) async {
    final current = await list();
    if (current.any((item) => item.id == sale.id)) return;
    await _write([...current, sale]);
  }

  Future<void> remove(String id) async {
    final current = await list();
    await _write(current.where((sale) => sale.id != id).toList());
  }

  Future<void> _write(List<PendingSale> sales) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode({'sales': sales.map((sale) => sale.toJson()).toList()}),
      flush: true,
    );
  }
}
