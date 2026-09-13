import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/partner_tenant.dart';
import '../models/payment_method.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_channel.dart';
import '../services/sale_service.dart';
import '../utils/donation_rounding.dart';

class CartLine {
  CartLine({required this.product, this.qty = 1});

  final Product product;
  double qty;

  double get lineTotal => qty * product.sellingPrice;

  SaleItem toSaleItem() {
    return SaleItem(
      productId: product.id,
      productName: product.name,
      productType: product.type,
      categoryName: product.categoryName ?? '',
      qty: qty,
      unitPrice: product.sellingPrice,
      costPrice: product.costPrice,
    );
  }
}

class PosNotifier extends ChangeNotifier {
  PosNotifier({SaleService? saleService})
    : _saleService = saleService ?? SaleService();

  final SaleService _saleService;

  final List<CartLine> _lines = [];
  bool applyServiceCharge = false;
  CheckoutPaymentMode paymentMode = CheckoutPaymentMode.cash;
  PartnerTenant? partnerTenant;
  double cashReceived = 0;
  double splitCashAmount = 0;
  bool _isSaving = false;
  String? _errorMessage;
  Sale? lastSale;
  double lastCashReceived = 0;
  double lastChange = 0;

  List<CartLine> get lines => List.unmodifiable(_lines);
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _lines.isEmpty;

  double get subtotal => _lines.fold(0, (sum, line) => sum + line.lineTotal);

  double serviceChargeAmount(AppSettings settings) {
    if (!applyServiceCharge || settings.serviceChargePercent <= 0) return 0;
    return (subtotal * settings.serviceChargePercent / 100).roundToDouble();
  }

  double total(AppSettings settings) =>
      subtotal + serviceChargeAmount(settings);

  double donationAmount(AppSettings settings) {
    if (paymentMode != CheckoutPaymentMode.cash) return 0;
    if (!settings.cashDonationRoundingEnabled) return 0;
    return DonationRounding.amount(total(settings));
  }

  double payable(AppSettings settings) =>
      total(settings) + donationAmount(settings);

  double get change {
    if (paymentMode != CheckoutPaymentMode.cash) return 0;
    final leftover = cashReceived - (lastComputedTotal);
    return leftover > 0 ? leftover : 0;
  }

  double lastComputedTotal = 0;

  double splitEdcAmount(AppSettings settings) {
    final remaining = total(settings) - splitCashAmount;
    return remaining > 0 ? remaining : 0;
  }

  void configureFromSettings(AppSettings settings) {
    applyServiceCharge = settings.serviceChargeEnabled;
    notifyListeners();
  }

  void addProduct(Product product) {
    final existing = _lines.where((l) => l.product.id == product.id);
    if (existing.isNotEmpty) {
      existing.first.qty += 1;
    } else {
      _lines.add(CartLine(product: product));
    }
    notifyListeners();
  }

  void increment(CartLine line) {
    line.qty += 1;
    notifyListeners();
  }

  void decrement(CartLine line) {
    if (line.qty <= 1) {
      _lines.remove(line);
    } else {
      line.qty -= 1;
    }
    notifyListeners();
  }

  void remove(CartLine line) {
    _lines.remove(line);
    notifyListeners();
  }

  void setApplyServiceCharge(bool value) {
    applyServiceCharge = value;
    notifyListeners();
  }

  void setPaymentMode(CheckoutPaymentMode mode) {
    paymentMode = mode;
    notifyListeners();
  }

  void setPartnerTenant(PartnerTenant? tenant) {
    partnerTenant = tenant;
    notifyListeners();
  }

  void setCashReceived(double value) {
    cashReceived = value;
    notifyListeners();
  }

  void setSplitCashAmount(double value) {
    splitCashAmount = value;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    cashReceived = 0;
    splitCashAmount = 0;
    paymentMode = CheckoutPaymentMode.cash;
    partnerTenant = null;
    _errorMessage = null;
    lastSale = null;
    notifyListeners();
  }

  Future<Sale?> checkout(AppSettings settings) async {
    _errorMessage = null;
    lastComputedTotal = payable(settings);

    if (_lines.isEmpty) {
      _errorMessage = 'Keranjang masih kosong.';
      notifyListeners();
      return null;
    }

    final payableAmount = lastComputedTotal;
    final payments = <SalePayment>[];

    switch (paymentMode) {
      case CheckoutPaymentMode.cash:
        if (cashReceived < payableAmount) {
          _errorMessage = 'Uang tunai kurang dari total.';
          notifyListeners();
          return null;
        }
        payments.add(
          SalePayment(method: PaymentMethod.cash, amount: payableAmount),
        );
      case CheckoutPaymentMode.edc:
        payments.add(
          SalePayment(method: PaymentMethod.edc, amount: payableAmount),
        );
      case CheckoutPaymentMode.split:
        if (splitCashAmount <= 0 || splitCashAmount >= payableAmount) {
          _errorMessage =
              'Isi tunai sebagian. Sisa otomatis tercatat sebagai EDC.';
          notifyListeners();
          return null;
        }
        payments.add(
          SalePayment(method: PaymentMethod.cash, amount: splitCashAmount),
        );
        payments.add(
          SalePayment(
            method: PaymentMethod.edc,
            amount: payableAmount - splitCashAmount,
          ),
        );
      case CheckoutPaymentMode.viaTenant:
        if (partnerTenant == null || partnerTenant!.id.isEmpty) {
          _errorMessage = 'Pilih tenan yang menjual produk ini.';
          notifyListeners();
          return null;
        }
        payments.add(
          SalePayment(method: PaymentMethod.receivable, amount: payableAmount),
        );
    }

    _isSaving = true;
    notifyListeners();

    try {
      final sale = await _saleService.createSale(
        items: _lines.map((line) => line.toSaleItem()).toList(),
        payments: payments,
        subtotal: subtotal,
        serviceChargePercent: applyServiceCharge
            ? settings.serviceChargePercent
            : 0,
        serviceChargeAmount: serviceChargeAmount(settings),
        total: total(settings),
        donationAmount: donationAmount(settings),
        channel: paymentMode == CheckoutPaymentMode.viaTenant
            ? SaleChannel.viaTenant
            : SaleChannel.ownCashier,
        partnerTenantId: paymentMode == CheckoutPaymentMode.viaTenant
            ? partnerTenant?.id
            : null,
        partnerTenantName: paymentMode == CheckoutPaymentMode.viaTenant
            ? (partnerTenant?.name ?? '')
            : '',
      );
      lastSale = sale;
      lastCashReceived = cashReceived;
      lastChange = cashReceived - payableAmount > 0
          ? cashReceived - payableAmount
          : 0;
      _lines.clear();
      cashReceived = 0;
      splitCashAmount = 0;
      return sale;
    } catch (e) {
      if (kDebugMode) debugPrint('Checkout failed: $e');
      _errorMessage = 'Gagal menyimpan transaksi. Cek koneksi / tabel Supabase.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
