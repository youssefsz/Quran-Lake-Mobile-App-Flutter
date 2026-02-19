import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_tokens.dart';
import 'component_styles.dart';

import 'package:flutter/services.dart';

/// The centralized theme configuration for the Quran Lake application.
///
/// This theme strictly adheres to the "Blue-ish glassmorphism" aesthetic.
/// It enforces the use of specific fonts, colors, and component styles.
class AppTheme {
  AppTheme._();

  // ===========================================================================
  // Light Theme (Single Theme System)
  // ===========================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // -----------------------------------------------------------------------
      // Color Scheme
      // -----------------------------------------------------------------------
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.softBlue,
        onPrimaryContainer: AppColors.neutral900,
        
        secondary: AppColors.secondaryCyan,
        onSecondary: AppColors.textInverse,
        secondaryContainer: AppColors.faintBlue,
        onSecondaryContainer: AppColors.neutral900,
        
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        
        error: AppColors.error,
        onError: AppColors.textInverse,
        
        outline: AppColors.neutral300,
        outlineVariant: AppColors.neutral200,
      ),

      // -----------------------------------------------------------------------
      // Typography
      // -----------------------------------------------------------------------
      textTheme: AppTypography.textTheme,
      
      // -----------------------------------------------------------------------
      // Scaffold & App Background
      // -----------------------------------------------------------------------
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      
      // -----------------------------------------------------------------------
      // AppBar Theme (Global)
      // -----------------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSmall,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Android: Dark icons
          statusBarBrightness: Brightness.light, // iOS: Dark icons (for light background)
        ),
      ),

      // -----------------------------------------------------------------------
      // Component Themes
      // -----------------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ComponentStyles.primaryButton,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ComponentStyles.secondaryButton,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ComponentStyles.ghostButton,
      ),
      inputDecorationTheme: ComponentStyles.inputDecorationTheme,
      cardTheme: ComponentStyles.cardTheme,
      dividerTheme: ComponentStyles.dividerTheme,
      
      // -----------------------------------------------------------------------
      // Icon Theme
      // -----------------------------------------------------------------------
      iconTheme: const IconThemeData(
        color: AppColors.neutral600,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.primaryBlue,
        size: 24,
      ),
      
      // -----------------------------------------------------------------------
      // Other
      // -----------------------------------------------------------------------
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashColor: AppColors.softBlue.withOpacity(0.1),
      highlightColor: AppColors.softBlue.withOpacity(0.05),
    );
  }
}
