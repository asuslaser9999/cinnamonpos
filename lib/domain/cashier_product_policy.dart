import '../models/app_settings.dart';
import '../models/product.dart';
import '../models/product_type.dart';

class CashierProductPolicy {
  CashierProductPolicy._();

  static bool canManageProducts({
    required bool isOwner,
    required AppSettings settings,
  }) {
    if (isOwner) return true;
    return settings.cashierCanManageOwnProducts;
  }

  static bool canDeleteProduct({required bool isOwner}) => isOwner;

  static double resolveCostPriceForSave({
    required bool isOwner,
    required ProductType type,
    required bool isEditing,
    required double sellingPrice,
    required double parsedCostFromField,
    required double existingCostPrice,
  }) {
    if (isOwner || type.isConsignment) {
      return parsedCostFromField;
    }

    if (isEditing) {
      return existingCostPrice;
    }

    if (sellingPrice <= 0) return 0;
    return sellingPrice / 2;
  }

  static bool canSeeCost({
    required bool isOwner,
    required Product product,
  }) {
    if (isOwner) return true;
    return product.type.isConsignment;
  }
}
