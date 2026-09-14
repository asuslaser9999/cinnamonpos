import 'package:flutter_test/flutter_test.dart';

import 'package:cinnamonpos/models/payment_method.dart';
import 'package:cinnamonpos/models/pos_reports.dart';
import 'package:cinnamonpos/models/product_type.dart';
import 'package:cinnamonpos/models/sale.dart';
import 'package:cinnamonpos/utils/donation_rounding.dart';

void main() {
  test('donation rounding is leftover to next thousand', () {
    expect(DonationRounding.amount(87700), 300);
    expect(DonationRounding.payable(87700), 88000);
    expect(DonationRounding.amount(88000), 0);
    expect(DonationRounding.amount(0), 0);
  });

  test('cashier report recaps opted-in donations only', () {
    final start = DateTime(2026, 9, 14);
    final withDonation = Sale(
      saleNumber: 'CN-1',
      saleDate: start,
      soldAt: start.add(const Duration(hours: 10)),
      subtotal: 87700,
      total: 87700,
      donationAmount: 300,
      payments: const [
        SalePayment(method: PaymentMethod.cash, amount: 88000),
      ],
      items: const [
        SaleItem(
          productName: 'Roti',
          productType: ProductType.ownProduction,
          qty: 1,
          unitPrice: 87700,
        ),
      ],
    );
    final declined = Sale(
      saleNumber: 'CN-2',
      saleDate: start,
      soldAt: start.add(const Duration(hours: 11)),
      subtotal: 15500,
      total: 15500,
      donationAmount: 0,
      payments: const [
        SalePayment(method: PaymentMethod.cash, amount: 15500),
      ],
      items: const [
        SaleItem(
          productName: 'Kopi',
          productType: ProductType.ownProduction,
          qty: 1,
          unitPrice: 15500,
        ),
      ],
    );

    final report = ReportAggregator.buildCashier(
      startDate: start,
      endDate: start,
      sales: [withDonation, declined],
    );

    expect(report.donationTotal, 300);
    expect(report.donationCount, 1);
    expect(report.donations.single.saleNumber, 'CN-1');
    expect(report.cashTotal, 88000 + 15500);
  });
}
