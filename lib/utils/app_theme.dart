import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const double _borderRadius = 12.0;
  static const double _spacing = 16.0;
  static const double _cardElevation = 2.0;

  // Modern Color Palette for Cable Operator App
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color accent = Color(0xFF06B6D4);
  static const Color secondary = Color(0xFF8B5CF6);

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D2D);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: surfaceLight,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: Color(0xFFDBEAFE),
        secondary: secondary,
        secondaryContainer: Color(0xFFEDE9FE),
        surface: surfaceLight,
        surfaceContainerHighest: Color(0xFFE5E7EB),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        error: Color(0xFFEF4444),
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: cardLight,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardTheme(
        elevation: _cardElevation,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        margin: const EdgeInsets.all(_spacing / 2),
        color: cardLight,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryBlue.withOpacity(0.5),
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 0.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1,
          ),
        ),
        prefixIconColor: Colors.grey.shade400,
        suffixIconColor: Colors.grey.shade400,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryBlue.withOpacity(0.3),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: _spacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: _spacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: _spacing / 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: _spacing, vertical: 8),
        tileColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardLight,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textMuted,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE5E7EB),
        selectedColor: primaryBlue.withOpacity(0.1),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: accent,
      scaffoldBackgroundColor: surfaceDark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: accent,
        primaryContainer: Color(0xFF1E3A8A),
        secondary: secondary,
        secondaryContainer: Color(0xFF6B21A8),
        surface: surfaceDark,
        surfaceContainerHighest: Color(0xFF374151),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardTheme(
        elevation: _cardElevation,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        margin: const EdgeInsets.all(_spacing / 2),
        color: cardDark,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: Color(0xFF4B5563)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: Color(0xFF4B5563)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: const EdgeInsets.all(_spacing),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        labelStyle: const TextStyle(color: Color(0xFFD1D5DB)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: accent.withOpacity(0.3),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: _spacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.5),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: _spacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: _spacing / 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: _spacing, vertical: 8),
        tileColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardDark,
        selectedItemColor: accent,
        unselectedItemColor: Color(0xFF9CA3AF),
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        elevation: 4,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF374151),
        selectedColor: accent.withOpacity(0.2),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF374151),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Updated Text Styles with modern typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.25,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.25,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.4,
  );

  // Enhanced Card Decorations
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: cardLight,
      borderRadius: BorderRadius.circular(_borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration get cardDecorationDark {
    return BoxDecoration(
      color: cardDark,
      borderRadius: BorderRadius.circular(_borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  // Cable Operator Specific Status Colors
  static const Color statusConnected =
      Color(0xFF10B981); // Green - Connected/Active
  static const Color statusDisconnected =
      Color(0xFFEF4444); // Red - Disconnected
  static const Color statusPending = Color(0xFFF59E0B); // Amber - Pending
  static const Color statusMaintenance =
      Color(0xFF8B5CF6); // Purple - Maintenance
  static const Color statusPaid = Color(0xFF10B981); // Green - Paid
  static const Color statusDue = Color(0xFFEF4444); // Red - Due/Overdue
  static const Color statusPartial =
      Color(0xFFF59E0B); // Amber - Partial Payment

  // Plan/Package Colors
  static const Color planBasic = Color(0xFF6B7280); // Gray - Basic Plan
  static const Color planStandard = Color(0xFF2563EB); // Blue - Standard Plan
  static const Color planPremium = Color(0xFF7C3AED); // Purple - Premium Plan
  static const Color planUltimate = Color(0xFFDC2626); // Red - Ultimate Plan

  // Common Paddings (keeping your existing structure)
  static const EdgeInsets paddingAll = EdgeInsets.all(_spacing);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(
    horizontal: _spacing,
  );
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(
    vertical: _spacing,
  );

  // Common Gaps (keeping your existing structure)
  static const SizedBox gapH = SizedBox(width: _spacing);
  static const SizedBox gapV = SizedBox(height: _spacing);
  static const SizedBox gapHSmall = SizedBox(width: _spacing / 2);
  static const SizedBox gapVSmall = SizedBox(height: _spacing / 2);
  static const SizedBox gapHLarge = SizedBox(width: _spacing * 2);
  static const SizedBox gapVLarge = SizedBox(height: _spacing * 2);

  // Common Metrics (keeping your existing structure)
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeSmall = 16.0;

  // Enhanced Common Widgets
  static Widget buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(_spacing),
      child: Text(
        title,
        style: headingMedium.copyWith(color: color),
      ),
    );
  }

  static Widget buildEmptyState({
    required IconData icon,
    required String message,
    String? submessage,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSizeLarge * 2,
              color: iconColor ?? textMuted,
            ),
            gapV,
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (submessage != null) ...[
              gapVSmall,
              Text(
                submessage,
                style: const TextStyle(color: textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
    String? submessage,
  }) {
    return Center(
      child: Padding(
        padding: paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: iconSizeLarge * 2,
              color: statusDisconnected,
            ),
            gapV,
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (submessage != null) ...[
              gapVSmall,
              Text(
                submessage,
                style: const TextStyle(color: textMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              gapV,
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // New Cable Operator Specific Widgets
  static Widget buildServiceStatusChip({
    required String status,
    required bool isActive,
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'connected':
      case 'active':
        statusColor = statusConnected;
        statusIcon = Icons.wifi;
        break;
      case 'disconnected':
      case 'inactive':
        statusColor = statusDisconnected;
        statusIcon = Icons.wifi_off;
        break;
      case 'maintenance':
        statusColor = statusMaintenance;
        statusIcon = Icons.build;
        break;
      default:
        statusColor = statusPending;
        statusIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPlanBadge({
    required String planName,
    required String planType,
  }) {
    Color planColor;

    switch (planType.toLowerCase()) {
      case 'basic':
        planColor = planBasic;
        break;
      case 'standard':
        planColor = planStandard;
        break;
      case 'premium':
        planColor = planPremium;
        break;
      case 'ultimate':
        planColor = planUltimate;
        break;
      default:
        planColor = planStandard;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: planColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        planName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
