import 'package:flutter/material.dart';

class AppColors {
  static const primaryGreen = Color(0xFF34B27B);
  static const neutralLight = Color(0xFFF8F9FA);
  static const neutralDark = Color(0xFF11181C);

  static const criticalRed = Color(0xFFE74C3C);
  static const warningAmber = Color(0xFFF39C12);
  static const infoBlue = Color(0xFF3498DB);

  static const darkCard = Color(0xFF1C2329);
  static const darkBorder = Color(0xFF7A8490);
  static const darkMutedText = Color(0xFFC5CDD4);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color card(BuildContext context) =>
      isDark(context) ? darkCard : Colors.white;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : const Color(0xFFD0D5DA);

  static Color mutedText(BuildContext context) =>
      isDark(context) ? darkMutedText : Colors.black54;
}
