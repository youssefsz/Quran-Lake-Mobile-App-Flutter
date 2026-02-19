import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/locale_provider.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  Map<String, dynamic> _translations = {};
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    _translations = localeProvider.getCachedTranslations('home');
    _lastLocaleCode = localeProvider.locale.languageCode;
    _loadTranslations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = context.watch<LocaleProvider>().locale.languageCode;
    if (_lastLocaleCode != localeCode) {
      _lastLocaleCode = localeCode;
      _loadTranslations();
    }
  }

  Future<void> _loadTranslations() async {
    final provider = context.read<LocaleProvider>();
    final translations = await provider.getScreenTranslations('home');
    if (mounted) {
      setState(() {
        _translations = translations;
      });
    }
  }

  String _t(String key, String fallback) {
    final value = _translations[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, 0, HeroIcons.home, _t('nav_home', 'Home')),
                  _buildNavItem(context, 1, HeroIcons.users, _t('nav_reciters', 'Reciters')),
                  _buildNavItem(context, 2, HeroIcons.clock, _t('nav_prayer', 'Prayer')),
                  _buildNavItem(context, 3, HeroIcons.cog6Tooth, _t('nav_settings', 'Settings')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, HeroIcons icon, String label) {
    final isSelected = widget.selectedIndex == index;
    final color = isSelected 
        ? Theme.of(context).primaryColor 
        : Theme.of(context).disabledColor;

    return GestureDetector(
      onTap: () {
        context.read<HapticProvider>().lightImpact();
        widget.onItemSelected(index);
      },
      child: Container(
        color: Colors.transparent, // Hit test behavior
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroIcon(
              icon,
              style: isSelected ? HeroIconStyle.solid : HeroIconStyle.outline,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
