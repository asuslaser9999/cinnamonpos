import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/sale.dart';
import '../services/receipt_builder.dart';

Future<void> showReceiptDialog(
  BuildContext context, {
  required AppSettings settings,
  required Sale sale,
}) async {
  final text = ReceiptBuilder.build(settings: settings, sale: sale);
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(sale.status.isRefunded ? 'Struk (Refund)' : 'Struk'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Struk disalin.')),
              );
            }
          },
          child: const Text('Salin'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
