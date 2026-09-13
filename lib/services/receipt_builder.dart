import '../models/app_settings.dart';
import '../models/sale.dart';
import '../utils/currency_formatter.dart';

class ReceiptBuilder {
  ReceiptBuilder._();

  static String build({
    required AppSettings settings,
    required Sale sale,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(settings.storeName);
    if (settings.storeSubtitle.trim().isNotEmpty) {
      buffer.writeln(settings.storeSubtitle);
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('No  : ${sale.saleNumber}');
    buffer.writeln('Tgl : ${CurrencyFormatter.formatDateTime(sale.soldAt.toLocal())}');
    if (sale.status.isRefunded) {
      buffer.writeln('STATUS: REFUND');
    } else if (sale.status.isPartialRefund) {
      buffer.writeln('STATUS: REFUND SEBAGIAN');
    }
    buffer.writeln('--------------------------------');
    for (final item in sale.items) {
      buffer.writeln(item.productName);
      buffer.writeln(
        '  ${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1)} x '
        '${CurrencyFormatter.format(item.unitPrice)}'
        '  ${CurrencyFormatter.format(item.lineTotal)}',
      );
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal   ${CurrencyFormatter.format(sale.subtotal)}');
    if (sale.serviceChargeAmount > 0) {
      buffer.writeln(
        'Service ${sale.serviceChargePercent.toStringAsFixed(0)}%  '
        '${CurrencyFormatter.format(sale.serviceChargeAmount)}',
      );
    }
    buffer.writeln('TOTAL      ${CurrencyFormatter.format(sale.total)}');
    if (sale.donationAmount > 0) {
      buffer.writeln(
        'Donasi     ${CurrencyFormatter.format(sale.donationAmount)}',
      );
      buffer.writeln(
        'Dibayar    ${CurrencyFormatter.format(sale.total + sale.donationAmount)}',
      );
    }
    if (sale.refundedTotal > 0) {
      buffer.writeln(
        'Refund     ${CurrencyFormatter.format(sale.refundedTotal)}',
      );
      buffer.writeln('Sisa       ${CurrencyFormatter.format(sale.netTotal)}');
    }
    if (sale.channel.isViaTenant) {
      buffer.writeln('Via tenan  ${sale.partnerTenantName}');
    }
    buffer.writeln('Bayar      ${sale.paymentLabel}');
    if (sale.cashAmount > 0) {
      buffer.writeln('  Tunai    ${CurrencyFormatter.format(sale.cashAmount)}');
    }
    if (sale.edcAmount > 0) {
      buffer.writeln('  EDC      ${CurrencyFormatter.format(sale.edcAmount)}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Terima kasih');
    return buffer.toString();
  }
}
