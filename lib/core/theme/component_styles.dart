import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_tokens.dart';

/// The centralized component style definitions for the Quran Lake design system.
///
/// Defines styles for Buttons, Inputs, Cards, and other core components.
class ComponentStyles {
  ComponentStyles._();

  // ===========================================================================
  // Button Styles
  // ===========================================================================

  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: AppColors.textInverse,
    elevation: 0,
    textStyle: AppTypography.labelLarge,
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.s24,
      vertical: AppTokens.s16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.r12),
    ),
    minimumSize: const Size(0, 48), // Comfortable touch target
  ).copyWith(
    // Add subtle shadow on hover/focus if needed, but keeping it flat for modern look
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white.withOpacity(0.1);
      }
      return null;
    }),
  );

  static final ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primaryBlue,
    side: const BorderSide(color: AppColors.neutral300, width: 1.0),
    textStyle: AppTypography.labelLarge,
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.s24,
      vertical: AppTokens.s16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.r12),
    ),
    minimumSize: const Size(0, 48),
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return AppColors.primaryBlue.withOpacity(0.05);
      }
      return null;
    }),
  );

  static final ButtonStyle ghostButton = TextButton.styleFrom(
    foregroundColor: AppColors.primaryBlue,
    textStyle: AppTypography.labelLarge,
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.s16,
      vertical: AppTokens.s12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.r8),
    ),
  );

  // ===========================================================================
  // Input Decoration Theme
  // ===========================================================================

  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppTokens.s16,
      vertical: AppTokens.s16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.r12),
      borderSide: const BorderSide(color: AppColors.neutral300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.r12),
      borderSide: const BorderSide(color: AppColors.neutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.r12),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.r12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.r12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.neutral400),
    labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.neutral600),
    floatingLabelStyle: AppTypography.labelSmall.copyWith(color: AppColors.primaryBlue),
  );

  // ===========================================================================
  // Card Theme
  // ===========================================================================

  static final CardThemeData cardTheme = CardThemeData(
    color: AppColors.surface,
    elevation: 0, // Using manual shadows or surface effect instead
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.r16),
      side: const BorderSide(color: AppColors.neutral200, width: 1),
    ),
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
  );

  // ===========================================================================
  // Divider Theme
  // ===========================================================================
  
  static final DividerThemeData dividerTheme = DividerThemeData(
    color: AppColors.neutral200,
    thickness: 1,
    space: AppTokens.s24,
  );

  // ===========================================================================
  // Navigation Bar Theme (Standard)
  // ===========================================================================
  
  static final NavigationBarThemeData navigationBarTheme = NavigationBarThemeData(
    backgroundColor: Colors.transparent, // Using Surface container underneath
    indicatorColor: AppColors.softBlue.withOpacity(0.3),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppTypography.labelSmall.copyWith(color: AppColors.primaryBlue);
      }
      return AppTypography.labelSmall.copyWith(color: AppColors.neutral500);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primaryBlue, size: 24);
      }
      return const IconThemeData(color: AppColors.neutral500, size: 24);
    }),
    elevation: 0,
    height: 64, // Modern, compact height
  );
}
