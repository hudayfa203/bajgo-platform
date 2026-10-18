import 'package:flutter/material.dart';

/// BajGo brand tokens (see docs/DESIGN_SYSTEM.md).
class BgColors {
  const BgColors._();

  static const blue = Color(0xFF1E4AD6);
  static const blueDark = Color(0xFF1638A8);
  static const night = Color(0xFF0A1230);
  static const saffron = Color(0xFFFFC21A);
  static const sky = Color(0xFF9DB8FF);
  static const cloud = Color(0xFFF3F6FC);
  static const sand = Color(0xFFFBF6EA);
  static const white = Color(0xFFFFFFFF);
  static const slate = Color(0xFF4B556E);
  static const mist = Color(0xFFD9DFEC);
  static const success = Color(0xFF13A35A);
  static const danger = Color(0xFFD93A3F);

  // Dark mode
  static const dBg = Color(0xFF060B1C);
  static const dSurface = Color(0xFF0F1833);
  static const dSurface2 = Color(0xFF17224A);
  static const dBlue = Color(0xFF5C80FF);
  static const dText = Color(0xFFF3F6FC);
  static const dText2 = Color(0xFFA9B4CF);
}

/// Shared spacing / radius scale.
class BgSpace {
  const BgSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double rButton = 14;
  static const double rCard = 20;
  static const double rSheet = 28;
  static const double rInput = 12;
}

class BgTheme {
  const BgTheme._();

  static const String display = 'BricolageGrotesque';
  static const String body = 'PlusJakartaSans';

  static TextTheme _text(Color onSurface, Color muted) {
    return TextTheme(
      displayLarge: TextStyle(
          fontFamily: display, fontSize: 32, height: 1.15, fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.5),
      headlineLarge: TextStyle(
          fontFamily: display, fontSize: 28, height: 1.2, fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.4),
      headlineMedium: TextStyle(
          fontFamily: display, fontSize: 22, height: 1.25, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.3),
      titleLarge: TextStyle(fontFamily: body, fontSize: 18, height: 1.3, fontWeight: FontWeight.w700, color: onSurface),
      titleMedium: TextStyle(fontFamily: body, fontSize: 16, height: 1.35, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: TextStyle(fontFamily: body, fontSize: 16, height: 1.45, fontWeight: FontWeight.w400, color: onSurface),
      bodyMedium: TextStyle(fontFamily: body, fontSize: 14, height: 1.45, fontWeight: FontWeight.w400, color: muted),
      labelLarge: TextStyle(fontFamily: body, fontSize: 14, height: 1.2, fontWeight: FontWeight.w700, color: onSurface),
      labelMedium: TextStyle(fontFamily: body, fontSize: 13, height: 1.2, fontWeight: FontWeight.w600, color: muted),
      labelSmall: TextStyle(fontFamily: body, fontSize: 12, height: 1.2, fontWeight: FontWeight.w500, color: muted),
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: BgColors.blue,
      onPrimary: BgColors.white,
      secondary: BgColors.saffron,
      onSecondary: BgColors.night,
      surface: BgColors.white,
      onSurface: BgColors.night,
      error: BgColors.danger,
      onError: BgColors.white,
    );
    return _base(scheme, BgColors.cloud, BgColors.night, BgColors.slate, BgColors.mist, Brightness.light);
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: BgColors.blue,
      onPrimary: BgColors.white,
      secondary: BgColors.saffron,
      onSecondary: BgColors.night,
      surface: BgColors.dSurface,
      onSurface: BgColors.dText,
      error: BgColors.danger,
      onError: BgColors.white,
    );
    return _base(scheme, BgColors.dBg, BgColors.dText, BgColors.dText2, BgColors.dSurface2, Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, Color bg, Color onSurface, Color muted, Color border, Brightness b) {
    final text = _text(onSurface, muted);
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: body,
      textTheme: text,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: text.bodyLarge?.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BgSpace.rInput),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BgSpace.rInput),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BgSpace.rInput),
          borderSide: const BorderSide(color: BgColors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BgSpace.rInput),
          borderSide: const BorderSide(color: BgColors.danger),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(BgSpace.rSheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BgColors.night,
        contentTextStyle: text.bodyLarge?.copyWith(color: BgColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BgSpace.rInput)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        side: BorderSide(color: border),
        labelStyle: text.labelMedium?.copyWith(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x1F1E4AD6),
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        height: 68,
      ),
    );
  }
}
