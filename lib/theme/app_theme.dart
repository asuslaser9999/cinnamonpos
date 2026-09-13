import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_appearance.dart';

/// Material Design 3 shape tokens.
class AppShapes {
  AppShapes._();

  static const extraSmall = 4.0;
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 28.0;
  static const full = 999.0;

  static BorderRadius get borderSmall => BorderRadius.circular(small);
  static BorderRadius get borderMedium => BorderRadius.circular(medium);
  static BorderRadius get borderLarge => BorderRadius.circular(large);
}

/// Semantic colors aligned with M3 dark tonal palette (seed: blue).
/// Prefer [AppPalette] / [Theme.of] for screens that follow the active theme.
class AppColors {
  AppColors._();

  static const seed = Color(0xFF6BA3FF);

  // Surfaces — M3 dark elevation via tone, not shadow
  static const background = Color(0xFF121218);
  static const surface = Color(0xFF1A1A22);
  static const surfaceLight = Color(0xFF22222C);
  static const surfaceElevated = Color(0xFF2A2A36);
  static const surfaceHigh = Color(0xFF323240);

  static const border = Color(0xFF3D3D4A);
  static const borderSubtle = Color(0xFF2E2E3A);

  // Text — off-white on dark (M3 accessibility guidance)
  static const textPrimary = Color(0xFFE2E2E9);
  static const textSecondary = Color(0xFFB8B8C4);
  static const textMuted = Color(0xFF8E8E99);

  // Accents — desaturated for dark mode comfort
  static const accentBlue = Color(0xFF8AB4FF);
  static const accentPurple = Color(0xFFB8A8FF);
  static const accentPink = Color(0xFFFF9EC4);
  static const accentOrange = Color(0xFFFFB86C);
  static const accentGreen = Color(0xFF5FD99A);
  static const accentTeal = Color(0xFF5EEAD4);
  static const accentIndigo = Color(0xFF9AA3FF);
  static const accentRed = Color(0xFFFF8A8A);
  static const expenseDarkRed = Color(0xFFEF5350);

  static const tableHeaderBg = Color(0xFF2A2A36);
  static const consignmentRowBg = Color(0xFF2A241C);
  static const chipActiveBg = Color(0xFF1A3055);
  static const chipInactiveBg = Color(0xFF2E2E3A);

  static const gradientAvatar = [
    Color(0xFFFF9F43),
    Color(0xFFFF6B9D),
    Color(0xFF9B6DFF),
  ];
}

/// Apple.com-inspired light canvas.
class AppleBrightColors {
  AppleBrightColors._();

  static const canvas = Color(0xFFF5F5F7);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1D1D1F);
  static const gray = Color(0xFF6E6E73);
  static const muted = Color(0xFF86868B);
  static const line = Color(0xFFD2D2D7);
  static const hairline = Color(0xFFE8E8ED);
  static const blue = Color(0xFF0071E3);
  static const blueSoft = Color(0xFFE8F1FC);
  static const blueInk = Color(0xFF001E3C);
  static const red = Color(0xFFFF3B30);
  static const orange = Color(0xFFFF9F0A);
  static const green = Color(0xFF30D158);
  static const teal = Color(0xFF64D2FF);
  static const purple = Color(0xFFAF52DE);
  static const pink = Color(0xFFFF2D55);
  static const indigo = Color(0xFF5856D6);
  static const consignmentWash = Color(0xFFFFF4E0);
}

/// Dark kasir — navy, charcoal-teal, terracotta, sage, camel.
class PosColors {
  PosColors._();

  static const navy = Color(0xFF1B2430);
  static const charcoal = Color(0xFF2A383A);
  static const terracotta = Color(0xFFB56A32);
  static const sage = Color(0xFF7A9A96);
  static const camel = Color(0xFFD2A66E);

  static const canvas = navy;
  static const panel = charcoal;
  static const key = Color(0xFF334446);
  static const ink = Color(0xFFF0E6D8);
  static const gray = Color(0xFFB8C5C2);
  static const muted = Color(0xFF9AABA8);
  static const line = Color(0xFF3E4E50);
  static const hairline = Color(0xFF243033);
  static const sky = sage;
  static const skySoft = Color(0xFF1F3534);
  static const skyInk = Color(0xFFD5E8E4);
  static const yellow = camel;
  static const green = sage;
  static const teal = sage;
  static const purple = camel;
  static const pink = terracotta;
  static const indigo = camel;
  static const red = Color(0xFFE07A5F);
  static const orange = terracotta;
  static const consignmentWash = Color(0xFF3A3220);
  static const snack = navy;
  static const cream = Color(0xFFFFF6EC);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.textMuted,
    required this.tableHeaderBg,
    required this.consignmentRowBg,
    required this.accentBlue,
    required this.accentPurple,
    required this.accentPink,
    required this.accentOrange,
    required this.accentGreen,
    required this.accentTeal,
    required this.accentIndigo,
    required this.accentRed,
  });

  final Color textMuted;
  final Color tableHeaderBg;
  final Color consignmentRowBg;
  final Color accentBlue;
  final Color accentPurple;
  final Color accentPink;
  final Color accentOrange;
  final Color accentGreen;
  final Color accentTeal;
  final Color accentIndigo;
  final Color accentRed;

  static const dark = AppPalette(
    textMuted: AppColors.textMuted,
    tableHeaderBg: AppColors.tableHeaderBg,
    consignmentRowBg: AppColors.consignmentRowBg,
    accentBlue: AppColors.accentBlue,
    accentPurple: AppColors.accentPurple,
    accentPink: AppColors.accentPink,
    accentOrange: AppColors.accentOrange,
    accentGreen: AppColors.accentGreen,
    accentTeal: AppColors.accentTeal,
    accentIndigo: AppColors.accentIndigo,
    accentRed: AppColors.accentRed,
  );

  static const bright = AppPalette(
    textMuted: AppleBrightColors.muted,
    tableHeaderBg: AppleBrightColors.hairline,
    consignmentRowBg: AppleBrightColors.consignmentWash,
    accentBlue: AppleBrightColors.blue,
    accentPurple: AppleBrightColors.purple,
    accentPink: AppleBrightColors.pink,
    accentOrange: AppleBrightColors.orange,
    accentGreen: AppleBrightColors.green,
    accentTeal: AppleBrightColors.teal,
    accentIndigo: AppleBrightColors.indigo,
    accentRed: AppleBrightColors.red,
  );

  static const pos = AppPalette(
    textMuted: PosColors.muted,
    tableHeaderBg: PosColors.key,
    consignmentRowBg: PosColors.consignmentWash,
    accentBlue: PosColors.sky,
    accentPurple: PosColors.purple,
    accentPink: PosColors.pink,
    accentOrange: PosColors.orange,
    accentGreen: PosColors.green,
    accentTeal: PosColors.teal,
    accentIndigo: PosColors.indigo,
    accentRed: PosColors.red,
  );

  @override
  AppPalette copyWith({
    Color? textMuted,
    Color? tableHeaderBg,
    Color? consignmentRowBg,
    Color? accentBlue,
    Color? accentPurple,
    Color? accentPink,
    Color? accentOrange,
    Color? accentGreen,
    Color? accentTeal,
    Color? accentIndigo,
    Color? accentRed,
  }) {
    return AppPalette(
      textMuted: textMuted ?? this.textMuted,
      tableHeaderBg: tableHeaderBg ?? this.tableHeaderBg,
      consignmentRowBg: consignmentRowBg ?? this.consignmentRowBg,
      accentBlue: accentBlue ?? this.accentBlue,
      accentPurple: accentPurple ?? this.accentPurple,
      accentPink: accentPink ?? this.accentPink,
      accentOrange: accentOrange ?? this.accentOrange,
      accentGreen: accentGreen ?? this.accentGreen,
      accentTeal: accentTeal ?? this.accentTeal,
      accentIndigo: accentIndigo ?? this.accentIndigo,
      accentRed: accentRed ?? this.accentRed,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      tableHeaderBg: Color.lerp(tableHeaderBg, other.tableHeaderBg, t)!,
      consignmentRowBg: Color.lerp(consignmentRowBg, other.consignmentRowBg, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      accentPink: Color.lerp(accentPink, other.accentPink, t)!,
      accentOrange: Color.lerp(accentOrange, other.accentOrange, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      accentTeal: Color.lerp(accentTeal, other.accentTeal, t)!,
      accentIndigo: Color.lerp(accentIndigo, other.accentIndigo, t)!,
      accentRed: Color.lerp(accentRed, other.accentRed, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

class AppTableStyles {
  AppTableStyles._();

  static TableBorder tableBorderOf(BuildContext context) {
    final side = BorderSide(color: Theme.of(context).colorScheme.outlineVariant);
    return TableBorder(
      horizontalInside: side,
      verticalInside: side,
      top: side,
      bottom: side,
      left: side,
      right: side,
    );
  }

  static BoxDecoration headerDecorationOf(BuildContext context) =>
      BoxDecoration(color: context.palette.tableHeaderBg);

  static BoxDecoration? consignmentRowDecorationOf(
    BuildContext context,
    bool isConsignment,
  ) {
    if (!isConsignment) return null;
    return BoxDecoration(color: context.palette.consignmentRowBg);
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
      surface: AppColors.background,
    ).copyWith(
      surface: AppColors.background,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceLight,
      surfaceContainerHigh: AppColors.surfaceElevated,
      surfaceContainerHighest: AppColors.surfaceHigh,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderSubtle,
      primary: AppColors.accentBlue,
      onPrimary: const Color(0xFF0D1B33),
      primaryContainer: const Color(0xFF1A3055),
      onPrimaryContainer: const Color(0xFFD6E6FF),
      secondary: AppColors.accentPurple,
      onSecondary: const Color(0xFF1A1228),
      secondaryContainer: const Color(0xFF2A2240),
      onSecondaryContainer: const Color(0xFFE4D6FF),
      tertiary: AppColors.accentOrange,
      onTertiary: const Color(0xFF1A1208),
      tertiaryContainer: const Color(0xFF3A2818),
      onTertiaryContainer: const Color(0xFFFFE0B8),
      error: AppColors.accentRed,
      onError: const Color(0xFF3A0A0A),
      errorContainer: const Color(0xFF4A1515),
      onErrorContainer: const Color(0xFFFFDAD6),
    );

    return _build(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      palette: AppPalette.dark,
      overlay: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  static ThemeData get bright {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppleBrightColors.blue,
      brightness: Brightness.light,
      surface: AppleBrightColors.canvas,
    ).copyWith(
      surface: AppleBrightColors.canvas,
      surfaceContainerLowest: AppleBrightColors.canvas,
      surfaceContainerLow: AppleBrightColors.white,
      surfaceContainer: AppleBrightColors.white,
      surfaceContainerHigh: AppleBrightColors.white,
      surfaceContainerHighest: AppleBrightColors.hairline,
      onSurface: AppleBrightColors.ink,
      onSurfaceVariant: AppleBrightColors.gray,
      outline: AppleBrightColors.line,
      outlineVariant: AppleBrightColors.hairline,
      primary: AppleBrightColors.blue,
      onPrimary: AppleBrightColors.white,
      primaryContainer: AppleBrightColors.blueSoft,
      onPrimaryContainer: AppleBrightColors.blueInk,
      secondary: AppleBrightColors.purple,
      onSecondary: AppleBrightColors.white,
      secondaryContainer: const Color(0xFFF6E8FF),
      onSecondaryContainer: const Color(0xFF3B0A55),
      tertiary: AppleBrightColors.orange,
      onTertiary: AppleBrightColors.ink,
      tertiaryContainer: const Color(0xFFFFF1D6),
      onTertiaryContainer: const Color(0xFF4A2E00),
      error: AppleBrightColors.red,
      onError: AppleBrightColors.white,
      errorContainer: const Color(0xFFFFE5E3),
      onErrorContainer: const Color(0xFF5C0804),
    );

    return _build(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      palette: AppPalette.bright,
      overlay: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppleBrightColors.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      letterSpacingTight: true,
      filledButtonRadius: 14,
    );
  }

  static ThemeData get pos {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: PosColors.terracotta,
      brightness: Brightness.dark,
      surface: PosColors.canvas,
    ).copyWith(
      surface: PosColors.canvas,
      surfaceContainerLowest: PosColors.canvas,
      surfaceContainerLow: PosColors.panel,
      surfaceContainer: PosColors.panel,
      surfaceContainerHigh: PosColors.key,
      surfaceContainerHighest: const Color(0xFF3A4A4C),
      onSurface: PosColors.ink,
      onSurfaceVariant: PosColors.gray,
      outline: PosColors.line,
      outlineVariant: PosColors.hairline,
      primary: PosColors.terracotta,
      onPrimary: PosColors.cream,
      primaryContainer: const Color(0xFF5C3218),
      onPrimaryContainer: const Color(0xFFFFE4C8),
      secondary: PosColors.sage,
      onSecondary: PosColors.navy,
      secondaryContainer: PosColors.skySoft,
      onSecondaryContainer: PosColors.skyInk,
      tertiary: PosColors.camel,
      onTertiary: PosColors.navy,
      tertiaryContainer: PosColors.consignmentWash,
      onTertiaryContainer: const Color(0xFFF6E4C4),
      error: PosColors.red,
      onError: PosColors.navy,
      errorContainer: const Color(0xFF4A2218),
      onErrorContainer: const Color(0xFFFFDAD0),
    );

    return _build(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      palette: AppPalette.pos,
      overlay: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: PosColors.canvas,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      filledButtonRadius: 10,
      cardRadius: 12,
      cardBorder: true,
      inputFill: PosColors.key,
      dialogBackground: PosColors.panel,
      snackBarBackground: PosColors.snack,
      snackBarForeground: PosColors.ink,
    );
  }

  static ThemeData forAppearance(AppAppearance appearance) {
    return switch (appearance) {
      AppAppearance.dark => dark,
      AppAppearance.bright => bright,
      AppAppearance.pos => pos,
    };
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required AppPalette palette,
    required SystemUiOverlayStyle overlay,
    bool letterSpacingTight = false,
    double filledButtonRadius = AppShapes.medium,
    double? cardRadius,
    bool? cardBorder,
    Color? inputFill,
    Color? dialogBackground,
    Color? snackBarBackground,
    Color? snackBarForeground,
  }) {
    final baseText = brightness == Brightness.dark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    final headlineTracking = letterSpacingTight ? -0.6 : 0.0;
    final resolvedCardRadius =
        cardRadius ?? (brightness == Brightness.light ? 18.0 : AppShapes.medium);
    final resolvedCardBorder =
        cardBorder ?? brightness == Brightness.dark;
    final resolvedInputFill = inputFill ??
        (brightness == Brightness.light
            ? AppleBrightColors.white
            : colorScheme.surfaceContainerHigh);
    final resolvedDialog = dialogBackground ??
        (brightness == Brightness.light
            ? AppleBrightColors.white
            : colorScheme.surfaceContainerHigh);
    final resolvedSnackBg = snackBarBackground ??
        (brightness == Brightness.light
            ? AppleBrightColors.ink
            : colorScheme.surfaceContainerHighest);
    final resolvedSnackFg = snackBarForeground ??
        (brightness == Brightness.light
            ? AppleBrightColors.white
            : colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: headlineTracking,
          color: colorScheme.onSurface,
        ),
        systemOverlayStyle: overlay,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(resolvedCardRadius),
          side: BorderSide(
            color: resolvedCardBorder
                ? colorScheme.outline
                : Colors.transparent,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderSmall),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: resolvedInputFill,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: palette.textMuted),
        border: OutlineInputBorder(
          borderRadius: AppShapes.borderSmall,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderSmall,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderSmall,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderSmall,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderSmall,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: palette.textMuted,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(filledButtonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppShapes.borderSmall,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHigh,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outlineVariant),
        checkmarkColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderSmall),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: brightness == Brightness.light ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderLarge),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: resolvedSnackBg,
        contentTextStyle: TextStyle(color: resolvedSnackFg),
        shape: RoundedRectangleBorder(borderRadius: AppShapes.borderSmall),
        behavior: SnackBarBehavior.floating,
        actionTextColor: colorScheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: colorScheme.onSurface),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: resolvedDialog,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: headlineTracking,
        ),
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            brightness == Brightness.light ? 20 : AppShapes.large,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: resolvedDialog,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      textTheme: baseText.copyWith(
        headlineSmall: baseText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: headlineTracking,
          color: colorScheme.onSurface,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: headlineTracking,
          color: colorScheme.onSurface,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleSmall: baseText.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(color: colorScheme.onSurface),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        bodySmall: baseText.bodySmall?.copyWith(color: palette.textMuted),
      ),
    );
  }
}
