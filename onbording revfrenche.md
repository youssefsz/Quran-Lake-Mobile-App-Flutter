import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';

import '../../data/services/preferences_service.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/haptics_service.dart';
import '../home/home_screen.dart';

/// Main onboarding screen with page view
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final HapticsService _haptics = HapticsService();
  int _currentPage = 0;
  bool _hasRequestedTracking = false;

  PreferencesService get _prefs => context.read<PreferencesService>();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _haptics.selection(_prefs);

    // Request ATT permission when user moves from language selection (page 0) to welcome page (page 1)
    // This ensures the app is fully visible and in an active state
    // Apple-compliant: shown before any tracking occurs
    if (page == 2 && !_hasRequestedTracking) {
      _requestTrackingPermission();
    }
  }

  /// Request App Tracking Transparency permission on iOS
  /// Called during onboarding for better user experience and Apple compliance
  Future<void> _requestTrackingPermission() async {
    if (!Platform.isIOS) return;
    if (_hasRequestedTracking) return;

    _hasRequestedTracking = true;

    // Small delay to ensure the page transition completes
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;

      if (status == TrackingStatus.notDetermined) {
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('ATT permission result: $result');
      } else {
        debugPrint('ATT already determined: $status');
      }
    } catch (e) {
      debugPrint('Error requesting tracking authorization: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      // Pages: 0=Language, 1=Welcome, 2=Clients, 3=Invoices, 4=Share
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _haptics.mediumImpact(_prefs);
      _completeOnboarding();
    }
  }

  Future<void> _skipOnboarding() async {
    _haptics.lightImpact(_prefs);
    // Request tracking when skipping (if not already requested)
    // MUST await to ensure prompt is shown before navigating away
    if (!_hasRequestedTracking) {
      await _requestTrackingPermission();
    }
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await _prefs.setOnboardingCompleted(true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(showPaywall: false),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(opacity: fadeAnimation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == 4; // 5 pages total (0-4)

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: localeProvider.getScreenTranslations('onboarding'),
          builder: (context, snapshot) {
            final translations = snapshot.data ?? {};
            final skipText = translations['actions']?['skip'] ?? 'Skip';
            final continueText =
                translations['actions']?['continue'] ?? 'Continue';
            final getStartedText =
                translations['actions']?['getStarted'] ?? 'Get Started';

            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    // Skip button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextButton(
                          onPressed: _skipOnboarding,
                          child: Text(
                            skipText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Page content
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        children: [
                          // Page 0: Language Selection
                          const _LanguageSelectionPage(),
                          // Page 1: Welcome with Logo & Theme Selector
                          const _WelcomePage(),
                          // Page 2: Manage Clients with Live UI Preview
                          const _ClientsPreviewPage(),
                          // Page 3: Track Payments with Live UI Preview
                          const _InvoiceListPreviewPage(),
                          // Page 4: Share & Print with Live UI Preview
                          const _SharePreviewPage(),
                        ],
                      ),
                    ),

                    // Page indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5, // 5 pages total
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.2,
                                    ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Action button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            isLastPage ? getStartedText : continueText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// PAGE 0: Language Selection
// =============================================================================

class _LanguageSelectionPage extends StatefulWidget {
  const _LanguageSelectionPage();

  @override
  State<_LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<_LanguageSelectionPage> {
  Map<String, dynamic> _translations = {};
  bool _isLoading = true;
  final HapticsService _haptics = HapticsService();

  PreferencesService get _prefs => context.read<PreferencesService>();

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    final localeProvider = context.read<LocaleProvider>();
    final translations = await localeProvider.getScreenTranslations(
      'onboarding',
    );
    if (mounted) {
      setState(() {
        _translations = translations;
        _isLoading = false;
      });
    }
  }

  String _t(String key) {
    return _getNestedValue(_translations, key) ?? key;
  }

  dynamic _getNestedValue(Map<String, dynamic> map, String key) {
    final keys = key.split('.');
    dynamic value = map;
    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return null;
      }
    }
    return value;
  }

  Future<void> _selectLanguage(String languageCode) async {
    _haptics.selection(_prefs);
    final localeProvider = context.read<LocaleProvider>();
    await localeProvider.setLocale(Locale(languageCode));
    await localeProvider.markLanguageAsSelected(languageCode);

    // Reload translations and refresh the page
    await _loadTranslations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            _t('languageSelection.title'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            _t('languageSelection.subtitle'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Language selection buttons
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              final currentLang = localeProvider.currentLocale.languageCode;

              return Column(
                children: [
                  // English Button
                  _LanguageButton(
                    language: _t('languageSelection.english'),
                    languageCode: 'en',
                    flag: '🇬🇧',
                    isSelected: currentLang == 'en',
                    onTap: () => _selectLanguage('en'),
                  ),
                  const SizedBox(height: 16),

                  // French Button
                  _LanguageButton(
                    language: _t('languageSelection.french'),
                    languageCode: 'fr',
                    flag: '🇫🇷',
                    isSelected: currentLang == 'fr',
                    onTap: () => _selectLanguage('fr'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Language selection button widget
class _LanguageButton extends StatelessWidget {
  final String language;
  final String languageCode;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.language,
    required this.languageCode,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.cardTheme.color,
          ),
          child: Row(
            children: [
              // Flag emoji (no background, clean and simple)
              Text(flag, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 20),

              // Language name
              Expanded(
                child: Text(
                  language,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),

              // Checkmark for selected
              if (isSelected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PAGE 1: Welcome Page with Logo & Theme Selector
// =============================================================================

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: localeProvider.getScreenTranslations('onboarding'),
          builder: (context, snapshot) {
            final translations = snapshot.data ?? {};

            final title =
                translations['welcome']?['title'] ?? 'Create Invoices';
            final subtitle =
                translations['welcome']?['subtitle'] ??
                'Generate professional invoices in seconds with our clean, intuitive interface.';
            final themeTitle =
                translations['welcome']?['themeTitle'] ?? 'Choose your theme';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Title
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),
                  _ThemeSelector(themeTitleText: themeTitle),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// PAGE 2: Manage Clients with Live UI Preview
// =============================================================================

class _ClientsPreviewPage extends StatelessWidget {
  const _ClientsPreviewPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: localeProvider.getScreenTranslations('onboarding'),
          builder: (context, snapshot) {
            final translations = snapshot.data ?? {};

            final title = translations['clients']?['title'] ?? 'Manage Clients';
            final subtitle =
                translations['clients']?['subtitle'] ??
                'Keep track of all your clients and their information in one place.';
            final previewTranslations = Map<String, dynamic>.from(
              translations['previews'] ?? {},
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Live UI Preview in Device Frame - flexible to adapt to available space
                  Flexible(
                    child: _DeviceFrame(
                      child: _ClientsPreview(translations: previewTranslations),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Live preview of clients list matching actual app UI
class _ClientsPreview extends StatelessWidget {
  final Map<String, dynamic> translations;

  const _ClientsPreview({required this.translations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample client data
    final clients = [
      {'name': 'Acme Corporation', 'email': 'billing@acme.com'},
      {'name': 'Tech Solutions Ltd', 'email': 'accounts@techsol.io'},
      {'name': 'Global Innovations', 'email': 'finance@global.co'},
    ];

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header matching real app
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                HeroIcon(
                  HeroIcons.arrowLeft,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  translations['clients'] ?? 'Clients',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Client list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: HeroIcon(
                        HeroIcons.user,
                        size: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    title: Text(
                      client['name']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      client['email']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeroIcon(
                          HeroIcons.pencil,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        HeroIcon(
                          HeroIcons.trash,
                          size: 14,
                          color: theme.colorScheme.error.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add button at bottom
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(
                    HeroIcons.plus,
                    size: 14,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    translations['addNewClient'] ?? 'Add New Client',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAGE 3: Track Payments with Live UI Preview
// =============================================================================

class _InvoiceListPreviewPage extends StatelessWidget {
  const _InvoiceListPreviewPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: localeProvider.getScreenTranslations('onboarding'),
          builder: (context, snapshot) {
            final translations = snapshot.data ?? {};

            final title =
                translations['invoices']?['title'] ?? 'Track Payments';
            final subtitle =
                translations['invoices']?['subtitle'] ??
                'Monitor paid and unpaid invoices to stay on top of your finances.';
            final previewTranslations = Map<String, dynamic>.from(
              translations['previews'] ?? {},
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Live UI Preview in Device Frame - flexible to adapt to available space
                  Flexible(
                    child: _DeviceFrame(
                      child: _InvoiceListPreview(
                        translations: previewTranslations,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Live preview of invoice list matching actual app UI
class _InvoiceListPreview extends StatelessWidget {
  final Map<String, dynamic> translations;

  const _InvoiceListPreview({required this.translations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample invoice data
    final invoices = [
      {
        'client': 'Acme Corp',
        'date': translations['dateToday'] ?? 'Today',
        'id': '001',
        'amount': '\$1,250',
      },
      {
        'client': 'Tech Solutions',
        'date': 'Dec 24',
        'id': '002',
        'amount': '\$890',
      },
      {
        'client': 'Global Inc',
        'date': 'Dec 22',
        'id': '003',
        'amount': '\$2,100',
      },
    ];

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header matching real app
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                HeroIcon(
                  HeroIcons.cog6Tooth,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
                Expanded(
                  child: Text(
                    translations['invoices'] ?? 'Invoices',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                HeroIcon(
                  HeroIcons.moon,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.onSurface,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      '${translations['unpaid'] ?? 'Unpaid'} (3)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${translations['paid'] ?? 'Paid'} (5)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Invoice list card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  children: [
                    // Header with total
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            translations['balanceDue'] ?? 'Balance due',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          Text(
                            '\$4,240',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.colorScheme.outline),

                    // Invoice items
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoices.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: theme.colorScheme.outline,
                        ),
                        itemBuilder: (context, index) {
                          final inv = invoices[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv['client']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '${inv['date']} • ${inv['id']}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.5),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  inv['amount']!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                HeroIcon(
                                  HeroIcons.chevronRight,
                                  size: 12,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Create invoice button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Create invoice',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Theme Selector Widget
// =============================================================================

// =============================================================================
// PAGE 4: Share & Print with Live UI Preview
// =============================================================================

class _SharePreviewPage extends StatelessWidget {
  const _SharePreviewPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: localeProvider.getScreenTranslations('onboarding'),
          builder: (context, snapshot) {
            final translations = snapshot.data ?? {};

            final title = translations['share']?['title'] ?? 'Share & Print';
            final subtitle =
                translations['share']?['subtitle'] ??
                'Export invoices as PDF and share them directly with your clients.';
            final previewTranslations = Map<String, dynamic>.from(
              translations['previews'] ?? {},
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Live UI Preview in Device Frame - flexible to adapt to available space
                  Flexible(
                    child: _DeviceFrame(
                      child: _SharePreview(translations: previewTranslations),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Live preview of PDF export screen matching actual app UI
class _SharePreview extends StatelessWidget {
  final Map<String, dynamic> translations;

  const _SharePreview({required this.translations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header matching real app
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                HeroIcon(
                  HeroIcons.xMark,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  '${translations['invoice'] ?? 'Invoice'} #001',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Invoice document preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Ribbon
                    Container(height: 12, color: theme.colorScheme.primary),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'INVOICE',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      '#INV-2024-001',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.business,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMockTextColumn(
                                  'Bill To:',
                                  'Acme Corp.\n123 Business Way\nNew York, NY',
                                ),
                                _buildMockTextColumn(
                                  'Date:',
                                  'Jan 12, 2024\nDue in 30 days',
                                  alignment: CrossAxisAlignment.end,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Items Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'DESCRIPTION',
                                      style: TextStyle(
                                        fontSize: 6,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'QTY',
                                      style: TextStyle(
                                        fontSize: 6,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontSize: 6,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Table Rows
                            _buildMockTableRow(0),
                            _buildMockTableRow(1),
                            _buildMockTableRow(2),
                            const Spacer(),
                            // Grand Total
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 6,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  Text(
                                    '\$3,450.00',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTextColumn(
    String label,
    String content, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 5,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          content,
          style: TextStyle(
            fontSize: 6,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
          textAlign: alignment == CrossAxisAlignment.end
              ? TextAlign.right
              : TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildMockTableRow(int index) {
    final descriptions = [
      'Premium Service Fee',
      'Project Consultation',
      'Design Assets',
    ];
    final amounts = ['\$1,200', '\$850', '\$1,400'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              descriptions[index],
              style: TextStyle(fontSize: 7, color: Colors.grey.shade800),
            ),
          ),
          Expanded(
            child: Text(
              '1',
              style: TextStyle(fontSize: 7, color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              amounts[index],
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED COMPONENTS
// =============================================================================

/// Device frame wrapper for UI previews
class _DeviceFrame extends StatelessWidget {
  final Widget child;

  const _DeviceFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Calculate responsive dimensions with max constraints for iPad
    // Use min of 55% width or a max width to prevent too large frames
    final maxFrameWidth = 280.0; // Max width for frame
    final calculatedWidth = screenSize.width * 0.55;
    final frameWidth = calculatedWidth > maxFrameWidth
        ? maxFrameWidth
        : calculatedWidth;

    // Calculate height with aspect ratio but constrain to available space
    // Leave room for title, description, page indicator, and button (~200px)
    final availableHeight = screenSize.height - 280;
    final calculatedHeight = frameWidth * 1.8; // Phone aspect ratio (~9:16)
    final frameHeight = calculatedHeight > availableHeight
        ? availableHeight
        : calculatedHeight;

    return Container(
      width: frameWidth,
      height: frameHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: IgnorePointer(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300, // Base design width
              height: 540, // Base design height (phone ratio)
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cupertino-style theme selector with Auto/Light/Dark options
class _ThemeSelector extends StatelessWidget {
  final String themeTitleText;

  const _ThemeSelector({this.themeTitleText = 'Choose your theme'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final haptics = HapticsService();
    final prefs = context.read<PreferencesService>();

    final int selectedIndex = switch (themeProvider.themeMode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };

    return Column(
      children: [
        Text(
          themeTitleText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: localeProvider.getScreenTranslations('onboarding'),
          builder: (context, snapshot) {
            final translations = snapshot.data ?? {};
            final autoLabel = translations['actions']?['themeAuto'] ?? 'Auto';
            final lightLabel =
                translations['actions']?['themeLight'] ?? 'Light';
            final darkLabel = translations['actions']?['themeDark'] ?? 'Dark';

            return SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: selectedIndex,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                thumbColor: theme.brightness == Brightness.dark
                    ? const Color(0xFF3A3A3C)
                    : Colors.white,
                padding: const EdgeInsets.all(4),
                children: {
                  0: _buildSegment(
                    context,
                    autoLabel,
                    HeroIcons.computerDesktop,
                  ),
                  1: _buildSegment(context, lightLabel, HeroIcons.sun),
                  2: _buildSegment(context, darkLabel, HeroIcons.moon),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  final mode = switch (value) {
                    0 => ThemeMode.system,
                    1 => ThemeMode.light,
                    2 => ThemeMode.dark,
                    _ => ThemeMode.system,
                  };
                  haptics.selection(prefs);
                  themeProvider.setThemeMode(mode);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSegment(BuildContext context, String label, HeroIcons icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(icon, size: 18, color: theme.colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
