import 'package:flutter/material.dart';

import 'bg_colors.dart';

/// Type scale from DESIGN_SYSTEM.md: Display 32/40 · H1 28 · H2 22 · H3 18 ·
/// Body 16 · Label 13 (600) · Caption 12. Headings Bricolage, body Jakarta.
class BgType {
  BgType._();

  static const String heading = 'BricolageGrotesque';
  static const String body = 'PlusJakartaSans';

  static const TextStyle display = TextStyle(
    fontFamily: heading,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w800,
    color: BgColors.dText,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: heading,
    fontSize: 28,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: BgColors.dText,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: heading,
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: BgColors.dText,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: heading,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: BgColors.dText,
  );
  static const TextStyle bodyText = TextStyle(
    fontFamily: body,
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: BgColors.dText,
  );
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: body,
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w700,
    color: BgColors.dText,
  );
  static const TextStyle label = TextStyle(
    fontFamily: body,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w600,
    color: BgColors.dText2,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: body,
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: BgColors.dText2,
  );
  static const TextStyle money = TextStyle(
    fontFamily: heading,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: BgColors.dText,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Radii: button 14, card 20, sheet 28, chip 999, input 12.
class BgRadius {
  BgRadius._();
  static const double button = 14;
  static const double card = 20;
  static const double sheet = 28;
  static const double input = 12;
  static const double chip = 999;
}

class BgDurations {
  BgDurations._();
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration sheet = Duration(milliseconds: 220);
  static const Duration page = Duration(milliseconds: 400);
}

ThemeData buildDriverTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BgColors.saffron,
    onPrimary: BgColors.night,
    secondary: BgColors.dBlue,
    onSecondary: BgColors.white,
    error: BgColors.danger,
    onError: BgColors.white,
    surface: BgColors.dSurface,
    onSurface: BgColors.dText,
    surfaceContainerHighest: BgColors.dSurface2,
    outline: BgColors.dSurface2,
    tertiary: BgColors.success,
    onTertiary: BgColors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: BgColors.dBg,
    fontFamily: BgType.body,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: BgType.display,
      headlineLarge: BgType.h1,
      headlineMedium: BgType.h2,
      headlineSmall: BgType.h3,
      titleLarge: BgType.h3,
      titleMedium: BgType.bodyStrong,
      bodyLarge: BgType.bodyText,
      bodyMedium: BgType.bodyText,
      bodySmall: BgType.caption,
      labelLarge: BgType.label,
      labelMedium: BgType.label,
      labelSmall: BgType.caption,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BgColors.dBg,
      foregroundColor: BgColors.dText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: BgType.h2,
      iconTheme: IconThemeData(color: BgColors.dBlue),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BgColors.dSurface,
      hintStyle: BgType.bodyText.copyWith(color: BgColors.dText2),
      labelStyle: BgType.label,
      floatingLabelStyle: BgType.label.copyWith(color: BgColors.saffron),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BgRadius.input),
        borderSide: const BorderSide(color: BgColors.dSurface2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BgRadius.input),
        borderSide: const BorderSide(color: BgColors.dSurface2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BgRadius.input),
        borderSide: const BorderSide(color: BgColors.saffron, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BgRadius.input),
        borderSide: const BorderSide(color: BgColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BgRadius.input),
        borderSide: const BorderSide(color: BgColors.danger, width: 2),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: BgColors.dSurface2,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BgColors.dSurface2,
      contentTextStyle: BgType.bodyText,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BgRadius.input),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BgColors.dSurface,
      modalBackgroundColor: BgColors.dSurface,
      showDragHandle: true,
      dragHandleColor: BgColors.dSurface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BgRadius.sheet)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BgColors.night
            : BgColors.dText2,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BgColors.saffron
            : BgColors.dSurface2,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: BgColors.dSurface,
      selectedColor: BgColors.saffron,
      labelStyle: BgType.label.copyWith(color: BgColors.dText),
      secondaryLabelStyle: BgType.label.copyWith(color: BgColors.night),
      side: const BorderSide(color: BgColors.dSurface2),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BgColors.dSurface,
      indicatorColor: BgColors.dSurface2,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => BgType.label.copyWith(
          color: states.contains(WidgetState.selected)
              ? BgColors.saffron
              : BgColors.dText2,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? BgColors.saffron
              : BgColors.dText2,
          size: 24,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: BgColors.saffron,
      linearTrackColor: BgColors.dSurface2,
      circularTrackColor: BgColors.dSurface2,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: BgColors.dBlue,
      textColor: BgColors.dText,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
  );
}
