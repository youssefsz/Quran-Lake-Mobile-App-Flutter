import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/prayer_provider.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/app_error_widget.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Map<String, dynamic> _translations = {};
  Map<String, dynamic> _errorTranslations = {};
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    _translations = localeProvider.getCachedTranslations('prayer_times');
    _errorTranslations = localeProvider.getCachedTranslations('errors');
    _lastLocaleCode = localeProvider.locale.languageCode;
    _loadTranslations();
    // Trigger fetch if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PrayerProvider>();
      if (provider.prayerTime == null && !provider.isLoading) {
        provider.fetchPrayerTimes();
      }
    });
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
    final results = await Future.wait([
      provider.getScreenTranslations('prayer_times'),
      provider.getScreenTranslations('errors'),
    ]);
    if (mounted) {
      setState(() {
        _translations = results[0];
        _errorTranslations = results[1];
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

  String _localizedPrayerName(String name) {
    switch (name) {
      case 'Fajr':
        return _t('fajr', 'Fajr');
      case 'Sunrise':
        return _t('sunrise', 'Sunrise');
      case 'Dhuhr':
        return _t('dhuhr', 'Dhuhr');
      case 'Asr':
        return _t('asr', 'Asr');
      case 'Maghrib':
        return _t('maghrib', 'Maghrib');
      case 'Isha':
        return _t('isha', 'Isha');
      default:
        return name;
    }
  }

  Widget _getPrayerIcon(String prayerName) {
    String? assetName;
    switch (prayerName) {
      case 'Fajr':
        assetName = 'fajr.png';
        break;
      case 'Sunrise':
        assetName = 'sunrise.png';
        break;
      case 'Dhuhr':
        assetName = 'Dhuhr.png';
        break;
      case 'Asr':
        assetName = 'Asr.png';
        break;
      case 'Maghrib':
        assetName = 'Maghrib.png';
        break;
      case 'Isha':
        assetName = 'Isha.png';
        break;
    }

    if (assetName != null) {
      return Image.asset('assets/icons/$assetName', width: 24, height: 24);
    }

    return Icon(
      Icons.access_time,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: GlassAppBar(
        title: _translations['title'] ?? 'Prayer Times',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<HapticProvider>().lightImpact();
              context.read<PrayerProvider>().fetchPrayerTimes();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<PrayerProvider>(
          builder: (context, prayerProvider, child) {
            if (prayerProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (prayerProvider.hasError) {
              return AppErrorWidget(
                errorType: prayerProvider.errorType ?? AppErrorType.unknown,
                translations: _errorTranslations,
                onRetry: () {
                  context.read<HapticProvider>().lightImpact();
                  prayerProvider.fetchPrayerTimes();
                },
              );
            }
            if (prayerProvider.prayerTime == null) {
              return Center(
                child: Text(
                  _t('no_prayer_times', 'No prayer times available.'),
                ),
              );
            }

            final pt = prayerProvider.prayerTime!;
            final nextPrayer = prayerProvider.nextPrayerName;
            final timeLeft = prayerProvider.timeUntilNextPrayer;

            final hours = timeLeft.inHours.toString().padLeft(2, '0');
            final minutes = timeLeft.inMinutes
                .remainder(60)
                .toString()
                .padLeft(2, '0');
            final seconds = timeLeft.inSeconds
                .remainder(60)
                .toString()
                .padLeft(2, '0');

            final hoursLabel = _t('hours_short', 'h');
            final minutesLabel = _t('minutes_short', 'm');
            final secondsLabel = _t('seconds_short', 's');

            final timeLeftStr =
                '$hours$hoursLabel $minutes$minutesLabel $seconds$secondsLabel';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Flexible(
                        child: Text(
                          '${pt.city}, ${pt.country}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s32),

                  Text(
                    '${_t('next_prayer', 'Next Prayer')}: ${_localizedPrayerName(nextPrayer)}',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    timeLeftStr,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: AppTokens.s48),

                  _buildPrayerRow(
                    'Fajr',
                    _localizedPrayerName('Fajr'),
                    pt.fajr,
                    nextPrayer == 'Fajr',
                  ),
                  _buildPrayerRow(
                    'Sunrise',
                    _localizedPrayerName('Sunrise'),
                    pt.sunrise,
                    false,
                  ),
                  _buildPrayerRow(
                    'Dhuhr',
                    _localizedPrayerName('Dhuhr'),
                    pt.dhuhr,
                    nextPrayer == 'Dhuhr',
                  ),
                  _buildPrayerRow(
                    'Asr',
                    _localizedPrayerName('Asr'),
                    pt.asr,
                    nextPrayer == 'Asr',
                  ),
                  _buildPrayerRow(
                    'Maghrib',
                    _localizedPrayerName('Maghrib'),
                    pt.maghrib,
                    nextPrayer == 'Maghrib',
                  ),
                  _buildPrayerRow(
                    'Isha',
                    _localizedPrayerName('Isha'),
                    pt.isha,
                    nextPrayer == 'Isha',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrayerRow(
    String prayerKey,
    String name,
    String time,
    bool isNext,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTokens.s16,
        horizontal: AppTokens.s16,
      ),
      margin: const EdgeInsets.only(bottom: AppTokens.s12),
      decoration: BoxDecoration(
        color: isNext
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: isNext
            ? Border.all(color: colorScheme.primary, width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          _getPrayerIcon(prayerKey),
          const SizedBox(width: AppTokens.s16),
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            time,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext ? colorScheme.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
