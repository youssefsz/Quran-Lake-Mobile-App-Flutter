import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A glass-morphism app bar with an animated search mode.
///
/// Tapping the search icon smoothly crossfades the title into a text field.
/// Tapping the close icon (or clearing + unfocusing) reverts back to the title.
///
/// Uses a single [AnimationController] to drive a crossfade between the title
/// and the search input — keeping the animation simple, clean, and performant.
class SearchableGlassAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final Widget? leading;
  final List<Widget>? extraActions;
  final Color? backgroundColor;
  final bool centerTitle;

  const SearchableGlassAppBar({
    super.key,
    required this.title,
    required this.onSearchChanged,
    this.searchHint = 'Search...',
    this.leading,
    this.extraActions,
    this.backgroundColor,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchableGlassAppBar> createState() => _SearchableGlassAppBarState();
}

class _SearchableGlassAppBarState extends State<SearchableGlassAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    _controller.forward();
    // Slight delay so the widget is built before requesting focus.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _focusNode.unfocus();
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() => _isSearching = false);
        _textController.clear();
        widget.onSearchChanged('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color:
              (widget.backgroundColor ??
                      Theme.of(context).scaffoldBackgroundColor)
                  .withValues(alpha: 0.7),
          child: AppBar(
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: widget.centerTitle,
            leading: widget.leading,
            iconTheme: const IconThemeData(color: Colors.black),
            title: _buildTitle(),
            actions: _buildActions(),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        // Flip slide direction for RTL languages (e.g. Arabic).
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final direction = isRtl ? -1.0 : 1.0;

        // When animation value is 0 → title fully visible.
        // When animation value is 1 → search field fully visible.
        return Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            // Title — fades and slides out toward the start edge.
            Opacity(
              opacity: (1.0 - _animation.value).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(-20 * direction * _animation.value, 0),
                child: Text(
                  widget.title,
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // Search field — fades and slides in from the end edge.
            if (_isSearching)
              Opacity(
                opacity: _animation.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(20 * direction * (1.0 - _animation.value), 0),
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: Center(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        cursorColor: AppColors.primaryBlue,
                        cursorHeight: 22,
                        textDirection: isRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        // Match the title style so it feels like
                        // the title morphed into an editable field.
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          hintStyle: AppTypography.headlineSmall.copyWith(
                            color: AppColors.neutral400,
                            fontWeight: FontWeight.w400,
                          ),
                          // Strip ALL decoration — no background, no borders.
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: widget.onSearchChanged,
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildActions() {
    return [
      // Extra actions from the caller (hidden during search for cleanliness).
      if (!_isSearching && widget.extraActions != null) ...widget.extraActions!,

      // Search / Close icon — animated icon morph.
      AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: _isSearching
                  ? const Icon(Icons.close, key: ValueKey('close'))
                  : const Icon(Icons.search, key: ValueKey('search')),
            ),
            onPressed: _isSearching ? _closeSearch : _openSearch,
          );
        },
      ),
    ];
  }
}
