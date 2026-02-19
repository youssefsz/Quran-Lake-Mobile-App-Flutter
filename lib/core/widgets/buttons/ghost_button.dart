import 'package:flutter/material.dart';
import '../../theme/component_styles.dart';

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = ComponentStyles.ghostButton;
    
    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: Text(label),
      );
    }
    
    return TextButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}
