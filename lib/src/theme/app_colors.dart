import 'package:flutter/material.dart';

class AppColors {
  static const primaryGreen = Color(0xFF34B27B);
  static const neutralLight = Color(0xFFF8F9FA);
  static const neutralDark = Color(0xFF11181C);

  static const criticalRed = Color(0xFFE74C3C);
  static const warningAmber = Color(0xFFF39C12);
  static const infoBlue = Color(0xFF3498DB);

  /// Matches web `[data-theme="dark"]` in `index.css`.
  static const darkBg = Color(0xFF171717);
  static const darkCard = Color(0xFF1E1E1E);
  static const darkBorder = Color(0xFF2E2E2E);
  static const darkMutedText = Color(0xFFA1A1AA);
  static const darkText = Color(0xFFEDEDED);
  static const darkPrimary = Color(0xFF3ECF8E);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color card(BuildContext context) =>
      isDark(context) ? darkCard : Colors.white;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : const Color(0xFFD0D5DA);

  static Color mutedText(BuildContext context) =>
      isDark(context) ? darkMutedText : Colors.black54;
}
