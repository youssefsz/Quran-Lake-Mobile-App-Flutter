import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/services/app_review_service.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/locale_provider.dart';
import '../widgets/glass_app_bar.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _LanguageOption {
  final Locale locale;
  final String label;
  final String flag;

  const _LanguageOption({
    required this.locale,
    required this.label,
    required this.flag,
  });
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _translations = {};
  String? _lastLocaleCode;
  String? _appVersion;

  static const String _supportEmail = 'dhibi.ywsf@gmail.com';
  static const String _aboutUrl = 'https://youssef.tn/quranlake/';
  static const List<_LanguageOption> _languageOptions = [
    _LanguageOption(locale: Locale('en'), label: 'English', flag: '🇬🇧'),
    _LanguageOption(locale: Locale('ar'), label: 'العربية', flag: '🇸🇦'),
  ];

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    _translations = localeProvider.getCachedTranslations('settings');
    _lastLocaleCode = localeProvider.locale.languageCode;
    _loadTranslations();
    _loadAppVersion();
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
    final translations = await provider.getScreenTranslations('settings');
    if (mounted) {
      setState(() {
        _translations = translations;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Quran Lake Support'},
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelMedium.copyWith(
          color: Colors.black,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> items) {
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.neutral200),
            items[i],
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    String? trailingText,
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTokens.s2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppTokens.s8),
          ],
          ...(trailing == null ? const <Widget>[] : <Widget>[trailing]),
          if (trailing == null && showChevron)
            const Icon(Icons.chevron_right, color: Colors.black),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        child: content,
      ),
    );
  }

  _LanguageOption _currentLanguage(Locale locale) {
    return _languageOptions.firstWhere(
      (option) => option.locale.languageCode == locale.languageCode,
      orElse: () => _languageOptions.first,
    );
  }

  Future<void> _showLanguagePicker(LocaleProvider localeProvider) async {
    final current = _currentLanguage(localeProvider.locale);
    final initialIndex = _languageOptions.indexWhere(
      (option) => option.locale.languageCode == current.locale.languageCode,
    );
    int selectedIndex = initialIndex < 0 ? 0 : initialIndex;
    final controller = FixedExtentScrollController(initialItem: selectedIndex);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.r24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s8,
              AppTokens.s16,
              AppTokens.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(AppTokens.rFull),
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _translations['language'] ?? 'Language',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final selected = _languageOptions[selectedIndex];
                        Navigator.of(context).pop();
                        Future.delayed(const Duration(milliseconds: 250), () {
                          localeProvider.setLocale(selected.locale);
                        });
                      },
                      child: Text(
                        _translations['done'] ?? 'Done',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 260,
                  child: CupertinoPicker(
                    scrollController: controller,
                    itemExtent: 56,
                    onSelectedItemChanged: (index) {
                      selectedIndex = index;
                    },
                    children: _languageOptions
                        .map(
                          (option) => Center(
                            child: Text(
                              '${option.flag}  ${option.label}',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final hapticProvider = context.watch<HapticProvider>();
    final versionText = _appVersion ?? '--';
    final currentLanguage = _currentLanguage(localeProvider.locale);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: _translations['title'] ?? 'Settings'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppTokens.s16,
            kToolbarHeight + MediaQuery.of(context).padding.top + AppTokens.s16,
            AppTokens.s16,
            AppTokens.s24,
          ),
          children: [
            _buildSectionTitle(
              _translations['preferences_section'] ?? 'Preferences',
            ),
            const SizedBox(height: AppTokens.s8),
            _buildGroup([
              _buildRow(
                icon: Icons.language,
                title: _translations['language'] ?? 'Language',
                subtitle:
                    _translations['language_subtitle'] ?? 'Choose app language',
                trailingText: currentLanguage.label,
                showChevron: true,
                onTap: () {
                  hapticProvider.lightImpact();
                  _showLanguagePicker(localeProvider);
                },
              ),
              _buildRow(
                icon: Icons.vibration,
                title: _translations['haptics'] ?? 'Haptic Feedback',
                subtitle:
                    _translations['haptics_subtitle'] ?? 'Light tap feedback',
                trailing: Switch(
                  value: hapticProvider.isEnabled,
                  onChanged: (value) {
                    if (!value) {
                      hapticProvider.lightImpact();
                      hapticProvider.setEnabled(false);
                      return;
                    }
                    hapticProvider.setEnabled(true);
                    hapticProvider.lightImpact();
                  },
                ),
              ),
            ]),
            const SizedBox(height: AppTokens.s24),
            _buildSectionTitle(_translations['support_section'] ?? 'Support'),
            const SizedBox(height: AppTokens.s8),
            _buildGroup([
              _buildRow(
                icon: Icons.email_outlined,
                title:
                    _translations['support_feedback'] ?? 'Support & Feedback',
                subtitle:
                    _translations['support_feedback_subtitle'] ??
                    'Email us anytime',
                showChevron: true,
                onTap: () {
                  hapticProvider.lightImpact();
                  _openEmail();
                },
              ),
              _buildRow(
                icon: Icons.star_outline,
                title: _translations['rate_app'] ?? 'Rate this App',
                subtitle:
                    _translations['rate_app_subtitle'] ?? 'Share your feedback',
                showChevron: true,
                onTap: () async {
                  hapticProvider.lightImpact();
                  final appReviewService = AppReviewService();
                  // Directly open the store listing. This is compliant with Apple HIG.
                  // It does NOT trigger the quota-limited review prompt.
                  await appReviewService.openStoreListing();
                },
              ),
            ]),
            const SizedBox(height: AppTokens.s24),
            _buildSectionTitle(_translations['legal_section'] ?? 'Legal'),
            const SizedBox(height: AppTokens.s8),
            _buildGroup([
              _buildRow(
                icon: Icons.privacy_tip_outlined,
                title: _translations['privacy'] ?? 'Privacy Policy',
                subtitle:
                    _translations['privacy_subtitle'] ??
                    'How we handle your data',
                showChevron: true,
                onTap: () {
                  hapticProvider.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              _buildRow(
                icon: Icons.article_outlined,
                title: _translations['terms'] ?? 'Terms of Service',
                subtitle: _translations['terms_subtitle'] ?? 'Read the terms',
                showChevron: true,
                onTap: () {
                  hapticProvider.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: AppTokens.s24),
            _buildSectionTitle(_translations['about_section'] ?? 'About'),
            const SizedBox(height: AppTokens.s8),
            _buildGroup([
              _buildRow(
                icon: Icons.info_outline,
                title: _translations['about'] ?? 'About This App',
                subtitle:
                    _translations['about_subtitle'] ??
                    'Learn more about Quran Lake',
                showChevron: true,
                onTap: () {
                  hapticProvider.lightImpact();
                  _openUrl(_aboutUrl);
                },
              ),
              _buildRow(
                icon: Icons.verified_outlined,
                title: _translations['app_version'] ?? 'App Version',
                subtitle:
                    _translations['app_version_subtitle'] ?? 'Current build',
                trailingText: versionText,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
