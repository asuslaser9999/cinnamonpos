import '../models/app_settings.dart';
import '../models/cashier_access_mode.dart';

/// Evaluates whether a cashier may use the app or menu based on owner settings.
class CashierAccessPolicy {
  CashierAccessPolicy._();

  static bool isFullyBlocked({
    required bool isOwner,
    required AppSettings settings,
  }) {
    if (isOwner) return false;
    return settings.cashierAccessMode == CashierAccessMode.blocked;
  }

  static bool isMenuEnabled({
    required bool isOwner,
    required AppSettings settings,
    DateTime? now,
  }) {
    if (isOwner) return true;

    switch (settings.cashierAccessMode) {
      case CashierAccessMode.fullAccess:
        return true;
      case CashierAccessMode.blocked:
        return false;
      case CashierAccessMode.timeRestricted:
        return isWithinAccessWindow(
          now ?? DateTime.now(),
          settings.cashierAccessStart,
          settings.cashierAccessEnd,
        );
    }
  }

  static bool isWithinAccessWindow(DateTime now, String start, String end) {
    final startMinutes = parseTimeToMinutes(start);
    final endMinutes = parseTimeToMinutes(end);
    final currentMinutes = now.hour * 60 + now.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }

    return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
  }

  static int parseTimeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  static String formatTime(String hhmm) => hhmm.replaceAll(':', '.');

  static String formatAccessWindow(String start, String end) {
    return '${formatTime(start)} – ${formatTime(end)}';
  }

  static String cashierBadgeLabel({
    required AppSettings settings,
    required bool menuEnabled,
  }) {
    switch (settings.cashierAccessMode) {
      case CashierAccessMode.fullAccess:
        return 'Kasir · Akses penuh';
      case CashierAccessMode.blocked:
        return 'Kasir · Akses diblokir';
      case CashierAccessMode.timeRestricted:
        if (menuEnabled) {
          return 'Kasir · Jam operasional '
              '${formatAccessWindow(settings.cashierAccessStart, settings.cashierAccessEnd)}';
        }
        return 'Kasir · Di luar jam operasional';
    }
  }

  static Duration? timeUntilNextBoundary({
    required AppSettings settings,
    DateTime? now,
  }) {
    if (settings.cashierAccessMode != CashierAccessMode.timeRestricted) {
      return null;
    }

    final current = now ?? DateTime.now();
    final startMinutes = parseTimeToMinutes(settings.cashierAccessStart);
    final endMinutes = parseTimeToMinutes(settings.cashierAccessEnd);
    final currentMinutes = current.hour * 60 + current.minute;
    final currentSecondOffset = currentMinutes * 60 + current.second;

    final boundaries = <int>[startMinutes * 60, endMinutes * 60];
    if (startMinutes > endMinutes) {
      boundaries.add(24 * 60 * 60);
    }

    for (final boundary in boundaries) {
      if (boundary > currentSecondOffset) {
        return Duration(seconds: boundary - currentSecondOffset);
      }
    }

    final nextDayStart =
        (24 * 60 * 60) - currentSecondOffset + startMinutes * 60;
    return Duration(seconds: nextDayStart);
  }
}
