import 'product_type.dart';
import 'sale.dart';

class SoldProductRow {
  const SoldProductRow({
    required this.productName,
    required this.productType,
    required this.categoryName,
    required this.qty,
    required this.omzet,
    this.cost = 0,
  });

  final String productName;
  final ProductType productType;
  final String categoryName;
  final double qty;
  final double omzet;
  final double cost;

  double get profit => omzet - cost;
}

class DonationRow {
  const DonationRow({
    required this.saleNumber,
    required this.soldAt,
    required this.amount,
  });

  final String saleNumber;
  final DateTime soldAt;
  final double amount;
}

class CashierReport {
  const CashierReport({
    required this.startDate,
    required this.endDate,
    required this.transactionCount,
    required this.refundCount,
    required this.grossSales,
    required this.refundAmount,
    required this.serviceCharge,
    required this.cashTotal,
    required this.edcTotal,
    required this.receivableTotal,
    required this.ownCashierTotal,
    required this.viaTenantTotal,
    required this.viaTenantCount,
    required this.viaTenantQty,
    required this.viaTenantService,
    required this.donationTotal,
    required this.donationCount,
    required this.donations,
    required this.products,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int transactionCount;
  final int refundCount;
  final double grossSales;
  final double refundAmount;
  final double serviceCharge;
  final double cashTotal;
  final double edcTotal;
  final double receivableTotal;
  final double ownCashierTotal;
  final double viaTenantTotal;
  final int viaTenantCount;
  final double viaTenantQty;
  final double viaTenantService;
  final double donationTotal;
  final int donationCount;
  final List<DonationRow> donations;
  final List<SoldProductRow> products;

  double get netSales => grossSales; // already excludes refunded

  /// Cash that should be in the drawer now. Via-tenant bills are excluded.
  double get expectedCash => cashTotal;
}

class OwnerReport {
  const OwnerReport({
    required this.cashierReport,
    required this.expenseTotal,
    required this.costOfGoods,
    required this.grossProfit,
    required this.netProfit,
    required this.ownProductionOmzet,
    required this.consignmentOmzet,
    required this.viaTenantOmzet,
    required this.receivableTotal,
  });

  final CashierReport cashierReport;
  final double expenseTotal;
  final double costOfGoods;
  final double grossProfit;
  final double netProfit;
  final double ownProductionOmzet;
  final double consignmentOmzet;
  final double viaTenantOmzet;
  final double receivableTotal;
}

class TenantBillRow {
  const TenantBillRow({
    required this.tenantId,
    required this.tenantName,
    required this.transactionCount,
    required this.qty,
    required this.subtotal,
    required this.service,
    required this.total,
    required this.products,
  });

  final String tenantId;
  final String tenantName;
  final int transactionCount;
  final double qty;
  final double subtotal;
  final double service;
  final double total;
  final List<SoldProductRow> products;
}

class TenantBillReport {
  const TenantBillReport({
    required this.startDate,
    required this.endDate,
    required this.rows,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<TenantBillRow> rows;

  double get qty => rows.fold(0, (sum, row) => sum + row.qty);
  double get subtotal => rows.fold(0, (sum, row) => sum + row.subtotal);
  double get service => rows.fold(0, (sum, row) => sum + row.service);
  double get total => rows.fold(0, (sum, row) => sum + row.total);
  int get transactionCount =>
      rows.fold(0, (sum, row) => sum + row.transactionCount);
}

class ReportAggregator {
  ReportAggregator._();

  static CashierReport buildCashier({
    required DateTime startDate,
    required DateTime endDate,
    required List<Sale> sales,
  }) {
    final paid = sales.where((s) => s.status.isActive).toList();
    final refunded = sales.where((s) => s.refunds.isNotEmpty).toList();

    final productMap = <String, SoldProductRow>{};
    for (final sale in paid) {
      for (final item in sale.items) {
        if (item.remainingQty <= 0) continue;
        final key = '${item.productId ?? item.productName}|${item.productType.value}';
        final existing = productMap[key];
        productMap[key] = SoldProductRow(
          productName: item.productName,
          productType: item.productType,
          categoryName: item.categoryName,
          qty: (existing?.qty ?? 0) + item.remainingQty,
          omzet: (existing?.omzet ?? 0) + item.remainingTotal,
          cost: (existing?.cost ?? 0) + item.remainingCost,
        );
      }
    }

    final products = productMap.values.toList()
      ..sort((a, b) => b.omzet.compareTo(a.omzet));

    final donations = paid
        .where((s) => s.netDonation > 0)
        .map(
          (s) => DonationRow(
            saleNumber: s.saleNumber,
            soldAt: s.soldAt,
            amount: s.netDonation,
          ),
        )
        .toList()
      ..sort((a, b) => b.soldAt.compareTo(a.soldAt));

    return CashierReport(
      startDate: startDate,
      endDate: endDate,
      transactionCount: paid.length,
      refundCount: refunded.length,
      grossSales: paid.fold(0, (sum, s) => sum + s.netTotal),
      refundAmount: refunded.fold(0, (sum, s) => sum + s.refundedTotal),
      serviceCharge: paid.fold(0, (sum, s) => sum + s.netService),
      cashTotal: paid.fold(0, (sum, s) => sum + s.netCash),
      edcTotal: paid.fold(0, (sum, s) => sum + s.netEdc),
      receivableTotal: paid.fold(0, (sum, s) => sum + s.netReceivable),
      ownCashierTotal: paid
          .where((s) => s.channel.isOwnCashier)
          .fold(0, (sum, s) => sum + s.netTotal),
      viaTenantTotal: paid
          .where((s) => s.channel.isViaTenant)
          .fold(0, (sum, s) => sum + s.netTotal),
      viaTenantCount: paid.where((s) => s.channel.isViaTenant).length,
      viaTenantQty: paid
          .where((s) => s.channel.isViaTenant)
          .fold(0, (sum, s) => sum + s.netItemQty),
      viaTenantService: paid
          .where((s) => s.channel.isViaTenant)
          .fold(0, (sum, s) => sum + s.netService),
      donationTotal: paid.fold(0, (sum, s) => sum + s.netDonation),
      donationCount: donations.length,
      donations: donations,
      products: products,
    );
  }

  static OwnerReport buildOwner({
    required CashierReport cashier,
    required List<Sale> sales,
    required double expenseTotal,
  }) {
    final paid = sales.where((s) => s.status.isActive);
    var cost = 0.0;
    var ownOmzet = 0.0;
    var consignmentOmzet = 0.0;
    var itemProfit = 0.0;

    for (final sale in paid) {
      for (final item in sale.items) {
        if (item.remainingQty <= 0) continue;
        cost += item.remainingCost;
        itemProfit += item.lineProfit;
        if (item.productType.isConsignment) {
          consignmentOmzet += item.remainingTotal;
        } else {
          ownOmzet += item.remainingTotal;
        }
      }
    }

    final grossProfit = itemProfit + cashier.serviceCharge;
    return OwnerReport(
      cashierReport: cashier,
      expenseTotal: expenseTotal,
      costOfGoods: cost,
      grossProfit: grossProfit,
      netProfit: grossProfit - expenseTotal,
      ownProductionOmzet: ownOmzet,
      consignmentOmzet: consignmentOmzet,
      viaTenantOmzet: cashier.viaTenantTotal,
      receivableTotal: cashier.receivableTotal,
    );
  }

  static TenantBillReport buildTenantBills({
    required DateTime startDate,
    required DateTime endDate,
    required List<Sale> sales,
  }) {
    final paid = sales
        .where((s) => s.status.isActive && s.channel.isViaTenant)
        .toList();
    final grouped = <String, List<Sale>>{};
    for (final sale in paid) {
      final key = sale.partnerTenantId ?? sale.partnerTenantName;
      grouped.putIfAbsent(key, () => []).add(sale);
    }

    final rows = grouped.entries.map((entry) {
      final group = entry.value;
      final productMap = <String, SoldProductRow>{};
      for (final sale in group) {
        for (final item in sale.items) {
          if (item.remainingQty <= 0) continue;
          final productKey =
              '${item.productId ?? item.productName}|${item.productType.value}';
          final existing = productMap[productKey];
          productMap[productKey] = SoldProductRow(
            productName: item.productName,
            productType: item.productType,
            categoryName: item.categoryName,
            qty: (existing?.qty ?? 0) + item.remainingQty,
            omzet: (existing?.omzet ?? 0) + item.remainingTotal,
            cost: (existing?.cost ?? 0) + item.remainingCost,
          );
        }
      }
      final products = productMap.values.toList()
        ..sort((a, b) => b.omzet.compareTo(a.omzet));
      return TenantBillRow(
        tenantId: entry.key,
        tenantName: group.first.partnerTenantName.trim().isEmpty
            ? 'Tenan'
            : group.first.partnerTenantName,
        transactionCount: group.length,
        qty: group.fold(0, (sum, s) => sum + s.netItemQty),
        subtotal: group.fold(0, (sum, s) => sum + s.netSubtotal),
        service: group.fold(0, (sum, s) => sum + s.netService),
        total: group.fold(0, (sum, s) => sum + s.netTotal),
        products: products,
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return TenantBillReport(
      startDate: startDate,
      endDate: endDate,
      rows: rows,
    );
  }
}
