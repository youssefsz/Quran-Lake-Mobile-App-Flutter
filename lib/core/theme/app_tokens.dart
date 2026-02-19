import 'package:flutter/material.dart';

/// The centralized design tokens for the Quran Lake design system.
///
/// Defines core values for spacing, radii, shadows, and blurs to ensure consistency.
class AppTokens {
  AppTokens._();

  // ===========================================================================
  // Spacing Scale (4pt Grid)
  // ===========================================================================

  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;
  static const double s80 = 80.0;
  static const double s96 = 96.0;

  // ===========================================================================
  // Border Radius Scale
  // ===========================================================================

  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;
  static const double rFull = 9999.0;

  static const Radius radius4 = Radius.circular(r4);
  static const Radius radius8 = Radius.circular(r8);
  static const Radius radius12 = Radius.circular(r12);
  static const Radius radius16 = Radius.circular(r16);
  static const Radius radius24 = Radius.circular(r24);
  static const Radius radius32 = Radius.circular(r32);
  static const Radius radiusFull = Radius.circular(rFull);

  // ===========================================================================
  // Elevation / Shadows (Subtle, Blue-tinted)
  // ===========================================================================

  // Soft shadow for cards and floating elements
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F0F172A), // 6% Opacity Navy
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x140F172A), // 8% Opacity Navy
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0F0F172A), // 6% Opacity Navy
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A0F172A), // 10% Opacity Navy
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x0F0F172A), // 6% Opacity Navy
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];

  // ===========================================================================
  // Surface Effect Constants
  // ===========================================================================

  static const double surfaceBlurSm = 5.0;
  static const double surfaceBlurMd = 10.0;
  static const double surfaceBlurLg = 20.0;
  static const double surfaceBlurXl = 40.0;

  static const double surfaceOpacityLow = 0.1;
  static const double surfaceOpacityMedium = 0.2;
  static const double surfaceOpacityHigh = 0.6;

  // ===========================================================================
  // Animation Durations
  // ===========================================================================

  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);

  static const Curve curveEaseOut = Curves.easeOutCubic;
  static const Curve curveEaseIn = Curves.easeInCubic;
  static const Curve curveStandard = Curves.easeInOutCubic;
}
