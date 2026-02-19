import 'package:flutter/material.dart';

/// The centralized color palette for the Quran Lake design system.
///
/// This system uses a deep navy to soft blue palette with slate neutrals.
/// It strictly avoids gradients and keeps a refined, spiritual aesthetic.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ===========================================================================
  // Core Palette
  // ===========================================================================

  // Primary: Royal Blue (User preferred)
  // Used for primary actions, heavy text, and strong branding elements.
  static const Color primaryBlue = Color(0xFF3B82F6); // Blue 500

  // Secondary: Cyan/Turquoise
  // Used for accents, active states, and highlights. Complements the Blue for a "Lake" vibe.
  static const Color secondaryCyan = Color(0xFF06B6D4); // Cyan 500
  static const Color softBlue = Color(0xFFBFDBFE); // Blue 200
  static const Color faintBlue = Color(0xFFEFF6FF); // Blue 50

  // ===========================================================================
  // Neutral Scale (Slate - Blue Grey)
  // ===========================================================================

  static const Color neutral900 = Color(0xFF0F172A); // Slate 900
  static const Color neutral800 = Color(0xFF1E293B); // Slate 800
  static const Color neutral700 = Color(0xFF334155); // Slate 700
  static const Color neutral600 = Color(0xFF475569); // Slate 600
  static const Color neutral500 = Color(0xFF64748B); // Slate 500
  static const Color neutral400 = Color(0xFF94A3B8); // Slate 400
  static const Color neutral300 = Color(0xFFCBD5E1); // Slate 300
  static const Color neutral200 = Color(0xFFE2E8F0); // Slate 200
  static const Color neutral100 = Color(0xFFF1F5F9); // Slate 100
  static const Color neutral50 = Color(0xFFF8FAFC); // Slate 50

  // ===========================================================================
  // Semantic & Surface Colors
  // ===========================================================================

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Very light blue-grey
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Colors.white;

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF3B82F6);

  // Feedback (Muted/Professional)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // ===========================================================================
  // Surface System Colors
  // ===========================================================================

  // Base color for surface layers (usually white with low opacity)
  static const Color surfaceBase = Color(0xFFFFFFFF);
  
  // Border for surface elements to give definition
  static const Color surfaceBorder = Color(0x4DFFFFFF); // 30% White
  
  // Shadow for surface elements to give depth
  static const Color surfaceShadow = Color(0x1A0F172A); // 10% Navy
}
