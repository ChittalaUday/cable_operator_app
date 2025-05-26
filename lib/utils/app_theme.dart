import 'package:flutter/material.dart';

class AppTheme {
  static const double _borderRadius = 12.0;
  static const double _spacing = 16.0;
  static const double _cardElevation = 2.0;

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        elevation: _cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        margin: const EdgeInsets.all(_spacing / 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(_spacing),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(_spacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(_spacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(_spacing / 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        contentPadding: const EdgeInsets.all(_spacing),
      ),
    );
  }

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Colors.black54,
  );

  // Card Decorations
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Status Colors
  static const Color statusPaid = Colors.green;
  static const Color statusPending = Colors.orange;
  static const Color statusDue = Colors.red;

  // Common Paddings
  static const EdgeInsets paddingAll = EdgeInsets.all(_spacing);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(
    horizontal: _spacing,
  );
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(
    vertical: _spacing,
  );

  // Common Gaps
  static const SizedBox gapH = SizedBox(width: _spacing);
  static const SizedBox gapV = SizedBox(height: _spacing);
  static const SizedBox gapHSmall = SizedBox(width: _spacing / 2);
  static const SizedBox gapVSmall = SizedBox(height: _spacing / 2);
  static const SizedBox gapHLarge = SizedBox(width: _spacing * 2);
  static const SizedBox gapVLarge = SizedBox(height: _spacing * 2);

  // Common Metrics
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeSmall = 16.0;

  // Common Widgets
  static Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(_spacing),
      child: Text(title, style: headingMedium),
    );
  }

  static Widget buildEmptyState({
    required IconData icon,
    required String message,
    String? submessage,
  }) {
    return Center(
      child: Padding(
        padding: paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSizeLarge * 2, color: Colors.grey[400]),
            gapV,
            Text(
              message,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (submessage != null) ...[
              gapVSmall,
              Text(
                submessage,
                style: TextStyle(color: Colors.grey[500]),
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
              color: Colors.red[300],
            ),
            gapV,
            Text(
              message,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              gapV,
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
