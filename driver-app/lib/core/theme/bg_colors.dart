import 'package:flutter/material.dart';

/// BajGo colour tokens (docs/DESIGN_SYSTEM.md, packages/brand/BajGo_Colours.json).
///
/// The driver app is dark by default: `dBg` background, `dSurface` cards,
/// Saffron primary actions with Night text. Never white on Saffron.
class BgColors {
  BgColors._();

  // Brand palette
  static const Color blue = Color(0xFF1E4AD6);
  static const Color blueDark = Color(0xFF1638A8);
  static const Color night = Color(0xFF0A1230);
  static const Color saffron = Color(0xFFFFC21A);
  static const Color sky = Color(0xFF9DB8FF);
  static const Color cloud = Color(0xFFF3F6FC);
  static const Color sand = Color(0xFFFBF6EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color slate = Color(0xFF4B556E);
  static const Color mist = Color(0xFFD9DFEC);
  static const Color success = Color(0xFF13A35A);
  static const Color danger = Color(0xFFD93A3F);

  // Dark mode
  static const Color dBg = Color(0xFF060B1C);
  static const Color dSurface = Color(0xFF0F1833);
  static const Color dSurface2 = Color(0xFF17224A);
  static const Color dBlue = Color(0xFF5C80FF);
  static const Color dText = Color(0xFFF3F6FC);
  static const Color dText2 = Color(0xFFA9B4CF);

  /// Saffron pressed state (slightly darker, still Night text on it).
  static const Color saffronDark = Color(0xFFE6AD0A);
}
