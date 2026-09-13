import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_defaults.dart';
import '../models/app_appearance.dart';
import '../models/app_settings.dart';
import '../models/cashier_access_mode.dart';
import '../models/pos_product_image_size.dart';

class AppSettingsService {
  static const _storeNameKey = 'cn_app_store_name';
  static const _storeSubtitleKey = 'cn_app_store_subtitle';
  static const _storeIconKey = 'cn_app_store_icon';
  static const _avatarColorKey = 'cn_app_avatar_color';
  static const _showSubtitleKey = 'cn_app_show_subtitle_dashboard';
  static const _cashierAccessModeKey = 'cn_cashier_access_mode';
  static const _cashierAccessStartKey = 'cn_cashier_access_start';
  static const _cashierAccessEndKey = 'cn_cashier_access_end';
  static const _cashierCanManageOwnProductsKey =
      'cn_cashier_can_manage_own_products';
  static const _serviceChargeEnabledKey = 'cn_service_charge_enabled';
  static const _serviceChargePercentKey = 'cn_service_charge_percent';
  static const _cashDonationRoundingKey = 'cn_cash_donation_rounding';
  static const _posProductImageSizeKey = 'cn_pos_product_image_size';
  static const _appearanceKey = 'cn_app_theme_mode';
  static const _heroBannerPathKey = 'cn_hero_banner_path';
  static const _heroBannerVersionKey = 'cn_hero_banner_version';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      storeName: prefs.getString(_storeNameKey) ?? AppDefaults.storeName,
      storeSubtitle:
          prefs.getString(_storeSubtitleKey) ?? AppDefaults.storeSubtitle,
      storeIconKey:
          prefs.getString(_storeIconKey) ?? AppSettings.defaults.storeIconKey,
      avatarColorKey:
          prefs.getString(_avatarColorKey) ??
          AppSettings.defaults.avatarColorKey,
      showSubtitleOnDashboard:
          prefs.getBool(_showSubtitleKey) ??
          AppSettings.defaults.showSubtitleOnDashboard,
      cashierAccessMode: CashierAccessMode.fromStorageKey(
        prefs.getString(_cashierAccessModeKey),
      ),
      cashierAccessStart:
          prefs.getString(_cashierAccessStartKey) ??
          AppSettings.defaults.cashierAccessStart,
      cashierAccessEnd:
          prefs.getString(_cashierAccessEndKey) ??
          AppSettings.defaults.cashierAccessEnd,
      cashierCanManageOwnProducts:
          prefs.getBool(_cashierCanManageOwnProductsKey) ??
          AppSettings.defaults.cashierCanManageOwnProducts,
      serviceChargeEnabled:
          prefs.getBool(_serviceChargeEnabledKey) ??
          AppSettings.defaults.serviceChargeEnabled,
      serviceChargePercent:
          prefs.getDouble(_serviceChargePercentKey) ??
          AppSettings.defaults.serviceChargePercent,
      cashDonationRoundingEnabled:
          prefs.getBool(_cashDonationRoundingKey) ??
          AppSettings.defaults.cashDonationRoundingEnabled,
      posProductImageSize: PosProductImageSize.fromStorageKey(
        prefs.getString(_posProductImageSizeKey),
      ),
      appearance: AppAppearance.fromStorageKey(prefs.getString(_appearanceKey)),
      heroBannerPath: prefs.getString(_heroBannerPathKey),
      heroBannerVersion: prefs.getInt(_heroBannerVersionKey) ?? 0,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_storeNameKey, settings.storeName.trim());
    await prefs.setString(_storeSubtitleKey, settings.storeSubtitle.trim());
    await prefs.setString(_storeIconKey, settings.storeIconKey);
    await prefs.setString(_avatarColorKey, settings.avatarColorKey);
    await prefs.setBool(_showSubtitleKey, settings.showSubtitleOnDashboard);
    await prefs.setString(
      _cashierAccessModeKey,
      settings.cashierAccessMode.storageKey,
    );
    await prefs.setString(_cashierAccessStartKey, settings.cashierAccessStart);
    await prefs.setString(_cashierAccessEndKey, settings.cashierAccessEnd);
    await prefs.setBool(
      _cashierCanManageOwnProductsKey,
      settings.cashierCanManageOwnProducts,
    );
    await prefs.setBool(_serviceChargeEnabledKey, settings.serviceChargeEnabled);
    await prefs.setDouble(
      _serviceChargePercentKey,
      settings.serviceChargePercent,
    );
    await prefs.setBool(
      _cashDonationRoundingKey,
      settings.cashDonationRoundingEnabled,
    );
    await prefs.setString(
      _posProductImageSizeKey,
      settings.posProductImageSize.storageKey,
    );
    await prefs.setString(_appearanceKey, settings.appearance.storageKey);
    await prefs.setString('cn_store_name', settings.storeName.trim());
    final bannerPath = settings.heroBannerPath?.trim();
    if (bannerPath == null || bannerPath.isEmpty) {
      await prefs.remove(_heroBannerPathKey);
    } else {
      await prefs.setString(_heroBannerPathKey, bannerPath);
    }
    await prefs.setInt(_heroBannerVersionKey, settings.heroBannerVersion);
  }
}
