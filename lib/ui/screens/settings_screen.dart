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
import '../../providers/adhan_provider.dart';
import '../../providers/prayer_provider.dart';
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
  bool _adhanExpanded = false;

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

  Widget _buildAdhanSettings(
    AdhanProvider adhanProvider,
    PrayerProvider prayerProvider,
    HapticProvider hapticProvider,
  ) {
    // Count enabled prayers for summary
    int enabledCount = 0;
    if (adhanProvider.isFajrEnabled) enabledCount++;
    if (adhanProvider.isSunriseEnabled) enabledCount++;
    if (adhanProvider.isDhuhrEnabled) enabledCount++;
    if (adhanProvider.isAsrEnabled) enabledCount++;
    if (adhanProvider.isMaghribEnabled) enabledCount++;
    if (adhanProvider.isIshaEnabled) enabledCount++;

    return _buildGroup([
      // Main Enable/Disable Toggle
      _buildRow(
        icon: Icons.notifications_active,
        title: _translations['adhan_enabled'] ?? 'Enable Adhan',
        subtitle: adhanProvider.isEnabled
            ? (_translations['adhan_prayers_enabled'] ??
                          '$enabledCount prayers enabled')
                      .replaceAll('{count}', enabledCount.toString()) +
                  (_translations['adhan_countdown_info'] ??
                      ' • Countdown notifications enabled')
            : (_translations['adhan_enabled_subtitle'] ??
                  'Play adhan at prayer times'),
        trailing: Switch(
          value: adhanProvider.isEnabled,
          onChanged: (value) async {
            hapticProvider.lightImpact();
            await adhanProvider.setEnabled(value);
            if (value && prayerProvider.prayerTime != null) {
              await adhanProvider.scheduleAdhanAlarms(
                prayerProvider.prayerTime!,
              );
            }
          },
        ),
      ),
      // Expandable Prayer Selection
      if (adhanProvider.isEnabled)
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s8,
          ),
          childrenPadding: EdgeInsets.zero,
          leading: Icon(Icons.settings_outlined, size: 20, color: Colors.black),
          title: Text(
            _translations['select_prayers'] ?? 'Select Prayers',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _translations['select_prayers_subtitle'] ??
                'Choose which prayers to play adhan',
            style: AppTypography.bodySmall.copyWith(color: Colors.black),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _adhanExpanded = expanded;
            });
          },
          initiallyExpanded: _adhanExpanded,
          children: [
            _buildPrayerToggle(
              icon: Icons.wb_twilight,
              title: _translations['fajr'] ?? 'Fajr',
              value: adhanProvider.isFajrEnabled,
              onChanged: (value) async {
                hapticProvider.lightImpact();
                await adhanProvider.setFajrEnabled(value);
                if (prayerProvider.prayerTime != null) {
                  await adhanProvider.scheduleAdhanAlarms(
                    prayerProvider.prayerTime!,
                  );
                }
              },
            ),
            _buildPrayerToggle(
              icon: Icons.wb_sunny_outlined,
              title: _translations['sunrise'] ?? 'Sunrise',
              value: adhanProvider.isSunriseEnabled,
              onChanged: (value) async {
                hapticProvider.lightImpact();
                await adhanProvider.setSunriseEnabled(value);
                if (prayerProvider.prayerTime != null) {
                  await adhanProvider.scheduleAdhanAlarms(
                    prayerProvider.prayerTime!,
                  );
                }
              },
            ),
            _buildPrayerToggle(
              icon: Icons.wb_sunny,
              title: _translations['dhuhr'] ?? 'Dhuhr',
              value: adhanProvider.isDhuhrEnabled,
              onChanged: (value) async {
                hapticProvider.lightImpact();
                await adhanProvider.setDhuhrEnabled(value);
                if (prayerProvider.prayerTime != null) {
                  await adhanProvider.scheduleAdhanAlarms(
                    prayerProvider.prayerTime!,
                  );
                }
              },
            ),
            _buildPrayerToggle(
              icon: Icons.wb_twilight_outlined,
              title: _translations['asr'] ?? 'Asr',
              value: adhanProvider.isAsrEnabled,
              onChanged: (value) async {
                hapticProvider.lightImpact();
                await adhanProvider.setAsrEnabled(value);
                if (prayerProvider.prayerTime != null) {
                  await adhanProvider.scheduleAdhanAlarms(
                    prayerProvider.prayerTime!,
                  );
                }
              },
            ),
            _buildPrayerToggle(
              icon: Icons.wb_sunny_outlined,
              title: _translations['maghrib'] ?? 'Maghrib',
              value: adhanProvider.isMaghribEnabled,
              onChanged: (value) async {
                hapticProvider.lightImpact();
                await adhanProvider.setMaghribEnabled(value);
                if (prayerProvider.prayerTime != null) {
                  await adhanProvider.scheduleAdhanAlarms(
                    prayerProvider.prayerTime!,
                  );
                }
              },
            ),
            _buildPrayerToggle(
              icon: Icons.nightlight_round,
              title: _translations['isha'] ?? 'Isha',
              value: adhanProvider.isIshaEnabled,
              onChanged: (value) async {
                hapticProvider.lightImpact();
                await adhanProvider.setIshaEnabled(value);
                if (prayerProvider.prayerTime != null) {
                  await adhanProvider.scheduleAdhanAlarms(
                    prayerProvider.prayerTime!,
                  );
                }
              },
            ),
          ],
        ),
      // Adhan Voice Selection
      if (adhanProvider.isEnabled)
        FutureBuilder<List<Map<String, String>>>(
          future: adhanProvider.availableAdhans,
          builder: (context, snapshot) {
            final adhans = snapshot.data ?? [];
            final currentAdhan = adhans.firstWhere(
              (a) => a['id'] == adhanProvider.sound,
              orElse: () => adhans.isNotEmpty ? adhans[0] : {'name': 'Voice 1'},
            );
            return _buildRow(
              icon: Icons.music_note,
              title: _translations['adhan_voice'] ?? 'Adhan Voice',
              subtitle:
                  _translations['adhan_voice_subtitle'] ?? 'Choose adhan voice',
              trailingText: currentAdhan['name'] ?? 'Voice 1',
              showChevron: true,
              onTap: () {
                hapticProvider.lightImpact();
                _showAdhanVoicePicker(
                  adhanProvider,
                  prayerProvider,
                  hapticProvider,
                );
              },
            );
          },
        ),
    ]);
  }

  void _showAdhanVoicePicker(
    AdhanProvider adhanProvider,
    PrayerProvider prayerProvider,
    HapticProvider hapticProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: FutureBuilder<List<Map<String, String>>>(
            future: adhanProvider.availableAdhans,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final adhans = snapshot.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _translations['adhan_voice'] ?? 'Select Adhan Voice',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  ...adhans.map((adhan) {
                    final isSelected = adhan['id'] == adhanProvider.sound;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primaryBlue : Colors.grey,
                      ),
                      title: Text(adhan['name'] ?? 'Voice'),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        color: AppColors.primaryBlue,
                        onPressed: () async {
                          hapticProvider.lightImpact();
                          await adhanProvider.previewAdhan(
                            adhan['id'] ?? 'adhan-v1',
                          );
                        },
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await adhanProvider
                            .stopAdhan(); // Stop preview if playing
                        await adhanProvider.setSound(adhan['id'] ?? 'adhan-v1');
                        if (prayerProvider.prayerTime != null) {
                          await adhanProvider.scheduleAdhanAlarms(
                            prayerProvider.prayerTime!,
                          );
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      // Stop preview when bottom sheet is dismissed (swiped down or tapped outside)
      adhanProvider.stopAdhan();
    });
  }

  Widget _buildPrayerToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s8,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
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
            AppTokens.s160,
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
            _buildSectionTitle(
              _translations['adhan_section'] ?? 'Adhan (Call to Prayer)',
            ),
            const SizedBox(height: AppTokens.s8),
            Consumer2<AdhanProvider, PrayerProvider>(
              builder: (context, adhanProvider, prayerProvider, child) {
                return _buildAdhanSettings(
                  adhanProvider,
                  prayerProvider,
                  hapticProvider,
                );
              },
            ),
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
