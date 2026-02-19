import 'package:flutter/material.dart';
import '../theme/surface_styles.dart';
import '../theme/app_tokens.dart';
import '../theme/app_colors.dart';

/// A helper widget to create styled containers (formerly glassmorphic).
///
/// This widget now renders a flat or slightly transparent container with border,
/// replacing the expensive liquid glass effect.
class AppSurface extends StatelessWidget {
  final Widget child;
  final SurfaceStyleSettings? settings;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool border;

  const AppSurface({
    super.key,
    required this.child,
    this.settings,
    this.borderRadius = AppTokens.r16,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.borderColor,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSettings = settings ?? SurfaceStyles.subtle;
    
    // Determine border
    BoxBorder? boxBorder;
    if (border) {
      final color = borderColor ?? effectiveSettings.borderColor ?? AppColors.surfaceBorder;
      final width = effectiveSettings.borderWidth ?? 1.0;
      boxBorder = Border.all(color: color, width: width);
    }

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: effectiveSettings.color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: boxBorder,
      ),
      child: child,
    );
    
    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
