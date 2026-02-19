import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool centerTitle;

  const GlassAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: (backgroundColor ?? Theme.of(context).scaffoldBackgroundColor).withOpacity(0.95),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.black,
          ),
        ),
        centerTitle: centerTitle,
        leading: leading,
        actions: actions,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
