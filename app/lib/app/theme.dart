import 'package:flutter/material.dart';

/// Pulse color palette - Modern, minimalist design system
class PulseColors {
  PulseColors._();

  // Primary accent - Modern gradient blues
  static const Color accent = Color(0xFF6366F1); // Indigo-500
  static const Color accentLight = Color(0xFF818CF8); // Indigo-400
  static const Color accentDark = Color(0xFF4F46E5); // Indigo-600
  static const Color accentGlow = Color(0xFF8B5CF6); // Violet-500

  // Status colors - Refined palette
  static const Color healthy = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color critical = Color(0xFFEF4444); // Red-500
  static const Color unknown = Color(0xFF6B7280); // Gray-500

  // Dark theme colors - Deep, sophisticated
  static const Color darkBackground = Color(0xFF0A0A0F); // Deep navy-black
  static const Color darkSurface = Color(0xFF12121A); // Slightly lighter
  static const Color darkCard = Color(0xFF1A1A24); // Card surface
  static const Color darkCardHover = Color(0xFF1F1F2E); // Hover state
  static const Color darkBorder = Color(0xFF2A2A3A); // Subtle borders
  
  // Glass effect colors
  static const Color glassLight = Color(0x1AFFFFFF); // 10% white
  static const Color glassMedium = Color(0x33FFFFFF); // 20% white
  static const Color glassHeavy = Color(0x4DFFFFFF); // 30% white

  // Light theme colors - Clean, bright
  static const Color lightBackground = Color(0xFFF9FAFB); // Gray-50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB); // Gray-200
}

/// Pulse theme configuration - Modern, minimalist design
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
        outline: PulseColors.darkBorder,
      ),
      scaffoldBackgroundColor: PulseColors.darkBackground,
      
      // Card theme with subtle elevation and glass effect
      cardTheme: CardTheme(
        color: PulseColors.darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: PulseColors.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      
      // App bar with glassmorphism
      appBarTheme: AppBarTheme(
        backgroundColor: PulseColors.darkSurface.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      
      // Modern navigation rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: PulseColors.darkSurface,
        selectedIconTheme: const IconThemeData(
          color: PulseColors.accent,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.grey[600],
          size: 24,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: PulseColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: PulseColors.accent.withOpacity(0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Modern bottom navigation bar (for mobile)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PulseColors.darkSurface,
        indicatorColor: PulseColors.accent.withOpacity(0.15),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: PulseColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }
          return TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: PulseColors.accent,
              size: 24,
            );
          }
          return IconThemeData(
            color: Colors.grey[600],
            size: 24,
          );
        }),
      ),
      
      // Modern input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PulseColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: PulseColors.darkBorder.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: PulseColors.darkBorder.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PulseColors.accent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PulseColors.critical,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PulseColors.critical,
            width: 2,
          ),
        ),
      ),
      
      // Elevated buttons with gradient effect
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Filled buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PulseColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PulseColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Chips with modern styling
      chipTheme: ChipThemeData(
        backgroundColor: PulseColors.darkCard,
        selectedColor: PulseColors.accent.withOpacity(0.2),
        side: BorderSide(
          color: PulseColors.darkBorder.withOpacity(0.3),
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: PulseColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: PulseColors.darkBorder.withOpacity(0.3),
          ),
        ),
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: PulseColors.darkBorder.withOpacity(0.2),
        thickness: 1,
        space: 1,
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
        outline: PulseColors.lightBorder,
      ),
      scaffoldBackgroundColor: PulseColors.lightBackground,
      
      // Card theme with subtle shadow
      cardTheme: CardTheme(
        color: PulseColors.lightCard,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: PulseColors.lightBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      
      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: PulseColors.lightSurface.withOpacity(0.9),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: Colors.black87,
        ),
      ),
      
      // Navigation rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: PulseColors.lightSurface,
        selectedIconTheme: const IconThemeData(
          color: PulseColors.accent,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.grey[600],
          size: 24,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: PulseColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: PulseColors.accent.withOpacity(0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Bottom navigation bar (for mobile)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: PulseColors.lightSurface,
        indicatorColor: PulseColors.accent.withOpacity(0.1),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: PulseColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }
          return TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: PulseColors.accent,
              size: 24,
            );
          }
          return IconThemeData(
            color: Colors.grey[600],
            size: 24,
          );
        }),
      ),
      
      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: PulseColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: PulseColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PulseColors.accent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PulseColors.critical,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PulseColors.critical,
            width: 2,
          ),
        ),
      ),
      
      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Filled buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PulseColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PulseColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        selectedColor: PulseColors.accent.withOpacity(0.15),
        side: BorderSide(
          color: PulseColors.lightBorder,
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: PulseColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: PulseColors.lightBorder,
          ),
        ),
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: PulseColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
