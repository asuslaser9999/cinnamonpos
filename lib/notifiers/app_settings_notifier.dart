import 'package:flutter/foundation.dart';

import '../models/app_appearance.dart';
import '../models/app_settings.dart';
import '../models/hero_banner_fit.dart';
import '../services/app_settings_service.dart';
import '../services/remote_app_settings_service.dart';

class AppSettingsNotifier extends ChangeNotifier {
  AppSettingsNotifier({
    AppSettingsService? service,
    RemoteAppSettingsService? remoteService,
  }) : _service = service ?? AppSettingsService(),
       _remoteService = remoteService ?? RemoteAppSettingsService() {
    load();
  }

  final AppSettingsService _service;
  final RemoteAppSettingsService _remoteService;

  AppSettings _settings = AppSettings.defaults;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncingRemote = false;
  String? _successMessage;
  String? _errorMessage;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get successMessage => _successMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _service.load();
    } catch (error) {
      _errorMessage = 'Gagal memuat pengaturan: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Theme is per-device; apply and persist without waiting for the full form.
  Future<void> updateAppearance(AppAppearance appearance) async {
    final next = _settings.copyWith(appearance: appearance);
    await _service.save(next);
    _settings = next;
    notifyListeners();
  }

  /// Header JPG is per-device; persist immediately so login/dashboard update.
  Future<void> updateHeroBanner({
    String? path,
    required int version,
    bool clear = false,
  }) async {
    final next = _settings.copyWith(
      heroBannerPath: path,
      heroBannerVersion: version,
      clearHeroBanner: clear,
    );
    await _service.save(next);
    _settings = next;
    notifyListeners();
  }

  /// Banner fit is per-device; apply immediately so login/dashboard update.
  Future<void> updateHeroBannerFit(HeroBannerFit fit) async {
    final next = _settings.copyWith(heroBannerFit: fit);
    await _service.save(next);
    _settings = next;
    notifyListeners();
  }

  Future<bool> save(AppSettings settings) async {
    _isSaving = true;
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final trimmed = settings.copyWith(
        storeName: settings.storeName.trim(),
        storeSubtitle: settings.storeSubtitle.trim(),
      );
      await _service.save(trimmed);
      _settings = trimmed;

      try {
        await _remoteService.upsertCashierPolicy(trimmed);
        _successMessage = 'Pengaturan berhasil disimpan dan disinkronkan.';
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Remote settings upsert failed: $error');
        }
        _successMessage = 'Pengaturan disimpan di perangkat ini.';
        _errorMessage =
            'Gagal sinkron ke server — perangkat kasir mungkin belum terupdate.';
      }
      return true;
    } catch (error) {
      _errorMessage = 'Gagal menyimpan: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> syncFromRemote() async {
    if (_isSyncingRemote || !_remoteService.isAuthenticated) return;

    _isSyncingRemote = true;
    try {
      final remote = await _remoteService.fetchCashierPolicy();
      if (remote == null) return;

      final merged = _mergeCashierPolicy(_settings, remote);
      if (!_cashierPolicyEquals(_settings, merged)) {
        await _service.save(merged);
        _settings = merged;
        notifyListeners();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Remote settings sync failed: $error');
      }
    } finally {
      _isSyncingRemote = false;
    }
  }

  AppSettings _mergeCashierPolicy(AppSettings local, AppSettings remote) {
    return local.copyWith(
      cashierAccessMode: remote.cashierAccessMode,
      cashierAccessStart: remote.cashierAccessStart,
      cashierAccessEnd: remote.cashierAccessEnd,
      cashierCanManageOwnProducts: remote.cashierCanManageOwnProducts,
      serviceChargeEnabled: remote.serviceChargeEnabled,
      serviceChargePercent: remote.serviceChargePercent,
      cashDonationRoundingEnabled: remote.cashDonationRoundingEnabled,
    );
  }

  bool _cashierPolicyEquals(AppSettings a, AppSettings b) {
    return a.cashierAccessMode == b.cashierAccessMode &&
        a.cashierAccessStart == b.cashierAccessStart &&
        a.cashierAccessEnd == b.cashierAccessEnd &&
        a.cashierCanManageOwnProducts == b.cashierCanManageOwnProducts &&
        a.serviceChargeEnabled == b.serviceChargeEnabled &&
        a.serviceChargePercent == b.serviceChargePercent &&
        a.cashDonationRoundingEnabled == b.cashDonationRoundingEnabled;
  }

  void clearMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }
}
