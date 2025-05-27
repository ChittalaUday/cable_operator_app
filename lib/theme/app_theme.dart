import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6366F1),
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF10B981),
      surface: Colors.white,
      background: Colors.white,
      error: Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1F2937),
      onBackground: Color(0xFF1F2937),
      onError: Colors.white,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    dividerColor: Colors.grey.shade200,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1F2937)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1F2937),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF818CF8),
    scaffoldBackgroundColor: const Color(0xFF1F2937),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF818CF8),
      secondary: Color(0xFF34D399),
      surface: Color(0xFF111827),
      background: Color(0xFF1F2937),
      error: Color(0xFFF87171),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF111827),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
    ),
    dividerColor: Colors.grey.shade800,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111827),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Status Colors
  static Color getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'active':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
      case 'inactive':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      case 'pending':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      case 'expired':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      case 'scheduled':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
      default:
        return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    }
  }
}
