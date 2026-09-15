import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pending_sale.dart';
import '../services/pending_sale_queue.dart';
import '../services/sale_service.dart';
import '../utils/network_error.dart';

class OfflineSyncNotifier extends ChangeNotifier {
  OfflineSyncNotifier({
    PendingSaleQueue? queue,
    SaleService? saleService,
  }) : queue = queue ?? PendingSaleQueue(),
       _saleService = saleService ?? SaleService() {
    refreshCount();
  }

  final PendingSaleQueue queue;
  final SaleService _saleService;

  Timer? _timer;
  int _pendingCount = 0;
  bool _isSyncing = false;
  String? _lastMessage;

  int get pendingCount => _pendingCount;
  bool get isSyncing => _isSyncing;
  String? get lastMessage => _lastMessage;
  bool get hasPending => _pendingCount > 0;

  Future<void> refreshCount() async {
    _pendingCount = await queue.count();
    notifyListeners();
  }

  void startAutoSync() {
    _timer ??= Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(flush());
    });
    unawaited(flush());
  }

  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> enqueue(PendingSale sale) async {
    await queue.enqueue(sale);
    await refreshCount();
  }

  Future<int> flush() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    notifyListeners();

    var uploaded = 0;
    try {
      final pending = await queue.list();
      _pendingCount = pending.length;
      for (final sale in pending) {
        try {
          await _saleService
              .createSale(
                id: sale.id,
                saleNumber: sale.saleNumber,
                soldAt: sale.soldAt,
                cashierId: sale.cashierId,
                items: sale.items,
                payments: sale.payments,
                subtotal: sale.subtotal,
                serviceChargePercent: sale.serviceChargePercent,
                serviceChargeAmount: sale.serviceChargeAmount,
                total: sale.total,
                donationAmount: sale.donationAmount,
                notes: sale.notes,
                channel: sale.channel,
                partnerTenantId: sale.partnerTenantId,
                partnerTenantName: sale.partnerTenantName,
              )
              .timeout(supabaseCallTimeout);
          await queue.remove(sale.id);
          uploaded += 1;
        } catch (error) {
          if (isNetworkError(error)) {
            _lastMessage = null;
            break;
          }
          if (kDebugMode) debugPrint('Pending sale sync failed: $error');
          _lastMessage =
              'Ada transaksi antrian yang gagal diunggah. Coba lagi nanti.';
          break;
        }
      }
      _pendingCount = await queue.count();
      if (uploaded > 0 && _pendingCount == 0) {
        _lastMessage = 'Transaksi offline sudah terunggah.';
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
    return uploaded;
  }

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}
