import 'package:flutter/material.dart';

/// Pulse color palette
class PulseColors {
  PulseColors._();

  // Primary accent - Electric blue
  static const Color accent = Color(0xFF00BFFF);
  static const Color accentLight = Color(0xFF33CCFF);
  static const Color accentDark = Color(0xFF0099CC);

  // Status colors
  static const Color healthy = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color critical = Color(0xFFF44336);
  static const Color unknown = Color(0xFF9E9E9E);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);

  // Light theme colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
}

/// Pulse theme configuration
class PulseTheme {
  PulseTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: PulseColors.accent,
        secondary: PulseColors.accentLight,
        surface: PulseColors.darkSurface,
        error: PulseColors.critical,
      ),
      scaffoldBackgroundColor: PulseColors.darkBackground,
      cardTheme: CardTheme(
        color: PulseColors.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PulseColors.darkSurface,
        elevation: 0,
        centerTitle: false,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: PulseColors.darkSurface,
        selectedIconTheme: const IconThemeData(color: PulseColors.accent),
        unselectedIconTheme: IconThemeData(color: Colors.grey[400]),
        indicatorColor: PulseColors.accent.withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PulseColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PulseColors.accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: PulseColors.darkCard,
        selectedColor: PulseColors.accent.withOpacity(0.3),
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: PulseColors.accent,
        secondary: PulseColors.accentDark,
        surface: PulseColors.lightSurface,
        error: PulseColors.critical,
      ),
      scaffoldBackgroundColor: PulseColors.lightBackground,
      cardTheme: CardTheme(
        color: PulseColors.lightCard,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PulseColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.black87,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: PulseColors.lightSurface,
        selectedIconTheme: const IconThemeData(color: PulseColors.accent),
        unselectedIconTheme: IconThemeData(color: Colors.grey[600]),
        indicatorColor: PulseColors.accent.withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PulseColors.accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
