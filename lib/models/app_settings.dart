import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_defaults.dart';
import '../theme/app_theme.dart';
import 'app_appearance.dart';
import 'cashier_access_mode.dart';
import 'hero_banner_fit.dart';
import 'pos_product_image_size.dart';

class StoreIconOption {
  const StoreIconOption({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

class AvatarColorOption {
  const AvatarColorOption({
    required this.key,
    required this.color,
    required this.label,
  });

  final String key;
  final Color color;
  final String label;
}

class AppSettings {
  const AppSettings({
    this.storeName = AppDefaults.storeName,
    this.storeSubtitle = AppDefaults.storeSubtitle,
    this.storeIconKey = 'storefront',
    this.avatarColorKey = 'orange',
    this.showSubtitleOnDashboard = false,
    this.cashierAccessMode = CashierAccessMode.timeRestricted,
    this.cashierAccessStart = '05:30',
    this.cashierAccessEnd = '16:30',
    this.cashierCanManageOwnProducts = false,
    this.serviceChargeEnabled = false,
    this.serviceChargePercent = 0,
    this.cashDonationRoundingEnabled = false,
    this.posProductImageSize = PosProductImageSize.normal,
    this.appearance = AppAppearance.dark,
    this.heroBannerPath,
    this.heroBannerVersion = 0,
    this.heroBannerFit = HeroBannerFit.cover,
  });

  final String storeName;
  final String storeSubtitle;
  final String storeIconKey;
  final String avatarColorKey;
  final bool showSubtitleOnDashboard;
  final CashierAccessMode cashierAccessMode;
  final String cashierAccessStart;
  final String cashierAccessEnd;
  final bool cashierCanManageOwnProducts;
  final bool serviceChargeEnabled;
  final double serviceChargePercent;
  final bool cashDonationRoundingEnabled;
  final PosProductImageSize posProductImageSize;
  final AppAppearance appearance;
  final String? heroBannerPath;
  final int heroBannerVersion;
  final HeroBannerFit heroBannerFit;

  bool get hasHeroBanner {
    final path = heroBannerPath?.trim();
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  static const defaults = AppSettings();

  IconData get storeIcon => StoreIconRegistry.resolve(storeIconKey);

  Color get avatarColor => AvatarColorRegistry.resolve(avatarColorKey);

  AppSettings copyWith({
    String? storeName,
    String? storeSubtitle,
    String? storeIconKey,
    String? avatarColorKey,
    bool? showSubtitleOnDashboard,
    CashierAccessMode? cashierAccessMode,
    String? cashierAccessStart,
    String? cashierAccessEnd,
    bool? cashierCanManageOwnProducts,
    bool? serviceChargeEnabled,
    double? serviceChargePercent,
    bool? cashDonationRoundingEnabled,
    PosProductImageSize? posProductImageSize,
    AppAppearance? appearance,
    String? heroBannerPath,
    int? heroBannerVersion,
    HeroBannerFit? heroBannerFit,
    bool clearHeroBanner = false,
  }) {
    return AppSettings(
      storeName: storeName ?? this.storeName,
      storeSubtitle: storeSubtitle ?? this.storeSubtitle,
      storeIconKey: storeIconKey ?? this.storeIconKey,
      avatarColorKey: avatarColorKey ?? this.avatarColorKey,
      showSubtitleOnDashboard:
          showSubtitleOnDashboard ?? this.showSubtitleOnDashboard,
      cashierAccessMode: cashierAccessMode ?? this.cashierAccessMode,
      cashierAccessStart: cashierAccessStart ?? this.cashierAccessStart,
      cashierAccessEnd: cashierAccessEnd ?? this.cashierAccessEnd,
      cashierCanManageOwnProducts:
          cashierCanManageOwnProducts ?? this.cashierCanManageOwnProducts,
      serviceChargeEnabled: serviceChargeEnabled ?? this.serviceChargeEnabled,
      serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
      cashDonationRoundingEnabled:
          cashDonationRoundingEnabled ?? this.cashDonationRoundingEnabled,
      posProductImageSize: posProductImageSize ?? this.posProductImageSize,
      appearance: appearance ?? this.appearance,
      heroBannerPath:
          clearHeroBanner ? null : (heroBannerPath ?? this.heroBannerPath),
      heroBannerVersion: heroBannerVersion ?? this.heroBannerVersion,
      heroBannerFit: heroBannerFit ?? this.heroBannerFit,
    );
  }
}

class StoreIconRegistry {
  StoreIconRegistry._();

  static const defaultKey = 'storefront';

  static const options = <StoreIconOption>[
    StoreIconOption(
      key: 'storefront',
      icon: Icons.storefront_rounded,
      label: 'Toko',
    ),
    StoreIconOption(key: 'store', icon: Icons.store_rounded, label: 'Gerai'),
    StoreIconOption(key: 'cake', icon: Icons.cake_rounded, label: 'Kue'),
    StoreIconOption(
      key: 'bakery',
      icon: Icons.bakery_dining_rounded,
      label: 'Bakery',
    ),
    StoreIconOption(key: 'cafe', icon: Icons.local_cafe_rounded, label: 'Kafe'),
    StoreIconOption(
      key: 'restaurant',
      icon: Icons.restaurant_rounded,
      label: 'Restoran',
    ),
    StoreIconOption(
      key: 'shopping_bag',
      icon: Icons.shopping_bag_rounded,
      label: 'Belanja',
    ),
    StoreIconOption(key: 'cookie', icon: Icons.cookie_rounded, label: 'Cookie'),
    StoreIconOption(
      key: 'lunch',
      icon: Icons.lunch_dining_rounded,
      label: 'Makanan',
    ),
    StoreIconOption(
      key: 'food_bank',
      icon: Icons.food_bank_rounded,
      label: 'Gudang',
    ),
    StoreIconOption(
      key: 'beverage',
      icon: Icons.emoji_food_beverage_rounded,
      label: 'Minuman',
    ),
    StoreIconOption(key: 'domain', icon: Icons.domain_rounded, label: 'Bisnis'),
  ];

  static IconData resolve(String? key) {
    for (final option in options) {
      if (option.key == key) return option.icon;
    }
    return options.first.icon;
  }
}

class AvatarColorRegistry {
  AvatarColorRegistry._();

  static const defaultKey = 'orange';

  static const options = <AvatarColorOption>[
    AvatarColorOption(
      key: 'orange',
      color: AppColors.accentOrange,
      label: 'Oranye',
    ),
    AvatarColorOption(key: 'blue', color: AppColors.accentBlue, label: 'Biru'),
    AvatarColorOption(
      key: 'purple',
      color: AppColors.accentPurple,
      label: 'Ungu',
    ),
    AvatarColorOption(
      key: 'green',
      color: AppColors.accentGreen,
      label: 'Hijau',
    ),
    AvatarColorOption(key: 'pink', color: AppColors.accentPink, label: 'Pink'),
    AvatarColorOption(key: 'teal', color: AppColors.accentTeal, label: 'Teal'),
  ];

  static Color resolve(String? key) {
    for (final option in options) {
      if (option.key == key) return option.color;
    }
    return options.first.color;
  }
}
