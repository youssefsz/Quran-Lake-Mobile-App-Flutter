import 'package:flutter/material.dart';

/// Configuration for the flat/transparent container styles (formerly glass).
class SurfaceStyleSettings {
  final Color color;
  final Color? borderColor;
  final double? borderWidth;

  const SurfaceStyleSettings({
    required this.color,
    this.borderColor,
    this.borderWidth,
  });
}

/// The centralized effect styles for the Quran Lake design system.
///
/// Defines standard `SurfaceStyleSettings` for consistent container styles across the app.
class SurfaceStyles {
  SurfaceStyles._();

  // ===========================================================================
  // Variants
  // ===========================================================================

  /// Subtle effect for overlays and cards.
  static const SurfaceStyleSettings subtle = SurfaceStyleSettings(
    color: Color(
      0xF2FFFFFF,
    ), // 95% White (Solid/Opaque look) or slightly transparent
    borderColor: Color(0xFFE2E8F0), // Slate 200
    borderWidth: 1.0,
  );

  /// Standard effect for navigation bars and modals.
  static const SurfaceStyleSettings standard = SurfaceStyleSettings(
    color: Color(0xFFFFFFFF), // Solid White
    borderColor: Color(0xFFE2E8F0), // Slate 200
    borderWidth: 1.0,
  );

  /// Heavy effect for background elements or emphasis.
  static const SurfaceStyleSettings heavy = SurfaceStyleSettings(
    color: Color(0xFFFFFFFF), // Solid White
    borderColor: Color(0xFFCBD5E1), // Slate 300
    borderWidth: 1.0,
  );

  /// "Icy" or "Frosted" effect (Replaced with a solid variant).
  static const SurfaceStyleSettings frosted = SurfaceStyleSettings(
    color: Color(0xFFF1F5F9), // Slate 100
    borderColor: Color(0xFFE2E8F0), // Slate 200
    borderWidth: 1.0,
  );
}
