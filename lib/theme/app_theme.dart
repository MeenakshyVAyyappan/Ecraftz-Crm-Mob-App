import 'package:flutter/material.dart';

class AppTheme {
  // Primary Brand Colors
  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryLight = Color(0xFFE8F4FF);
  static const Color primaryDark = Color(0xFF0060CC);

  // Background Colors (Light Theme)
  static const Color bgBase = Color(0xFFF5F7FA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgSidebar = Color(0xFF0D1B2A);

  // Background Colors (Dark Theme)
  static const Color bgBaseDark = Color(0xFF080F1A);
  static const Color bgCardDark = Color(0xFF101B2B);
  static const Color bgSidebarDark = Color(0xFF0B1420);

  // Text Colors
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textMuted = Color(0xFFADB5C9);
  static const Color textSidebar = Color(0xFFCDD6F4);

  // Status Colors
  static const Color success = Color(0xFF00C896);
  static const Color successLight = Color(0xFFE6FAF5);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color warningLight = Color(0xFFFFF4E0);
  static const Color error = Color(0xFFFF453A);
  static const Color errorLight = Color(0xFFFFECEB);
  static const Color info = Color(0xFF32ADE6);
  static const Color infoLight = Color(0xFFE6F6FD);

  // Border & Divider
  static const Color border = Color(0xFFE8EDF5);
  static const Color divider = Color(0xFFF0F3F9);
  static const Color borderDark = Color(0xFF1E2E42);
  static const Color dividerDark = Color(0xFF172537);

  // Sidebar brand accent
  static const Color sidebarAccent = Color(0xFF0A84FF);

  // Responsive Colors (Adapts to Active Context)
  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF8E9CB8) : textSecondary;

  static Color textMutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF596780) : textMuted;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : border;

  static List<BoxShadow> cardShadowOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? [] : cardShadow;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: bgBase,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: success,
        surface: bgCard,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCard,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: divider,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: bgBaseDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: success,
        surface: bgCardDark,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCardDark,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: bgCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: dividerDark,
    );
  }

  // Shadow styles
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0A84FF).withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF0A84FF).withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
