import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/ayah_provider.dart';
import '../../providers/reciter_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/surah_provider.dart';
import '../../providers/adhan_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/surah.dart';
import 'package:heroicons/heroicons.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/app_error_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _translations = {};
  Map<String, dynamic> _errorTranslations = {};
  String? _lastLocaleCode;

  /// Translates a prayer name key (e.g. 'Fajr') to the localized string.
  String _translatePrayerName(String name) {
    final key = name.toLowerCase();
    return _translations[key] ?? name;
  }

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    final localeCode = localeProvider.locale.languageCode;
    _translations = localeProvider.getCachedTranslations('home');
    _errorTranslations = localeProvider.getCachedTranslations('errors');
    _lastLocaleCode = localeCode;
    _loadTranslations();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkPermissions();

      if (!mounted) return;

      final prayerProvider = context.read<PrayerProvider>();
      final adhanProvider = context.read<AdhanProvider>();
      if (prayerProvider.prayerTime == null && !prayerProvider.isLoading) {
        prayerProvider.fetchPrayerTimes().then((_) {
          // Schedule adhan alarms when prayer times are fetched
          if (prayerProvider.prayerTime != null && adhanProvider.isEnabled) {
            adhanProvider.scheduleAdhanAlarms(prayerProvider.prayerTime!);
            // Show countdown notification on app open if prayer is within 0-120 minutes
            adhanProvider.checkAndShowCountdownOnAppOpen(prayerProvider.prayerTime!);
          }
        });
      } else if (prayerProvider.prayerTime != null && adhanProvider.isEnabled) {
        // If prayer times are already loaded, check and show countdown notification
        adhanProvider.checkAndShowCountdownOnAppOpen(prayerProvider.prayerTime!);
      }

      final ayahProvider = context.read<AyahProvider>();
      if (ayahProvider.ayah == null && !ayahProvider.isLoading) {
        ayahProvider.fetchRandomAyah();
      }

      final surahProvider = context.read<SurahProvider>();
      if (surahProvider.surahs.isEmpty && !surahProvider.isLoading) {
        surahProvider.fetchSurahs(language: localeCode);
      }

      final reciterProvider = context.read<ReciterProvider>();
      if (reciterProvider.reciters.isEmpty && !reciterProvider.isLoading) {
        reciterProvider.fetchReciters(language: localeCode);
      }
    });
  }

  // Reload translations if the locale changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = context.watch<LocaleProvider>().locale.languageCode;
    if (_lastLocaleCode != localeCode) {
      _lastLocaleCode = localeCode;
      _loadTranslations();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SurahProvider>().fetchSurahs(language: localeCode);
        context.read<ReciterProvider>().fetchReciters(language: localeCode);
      });
    }
  }

  Future<void> _checkPermissions() async {
    // Proactively request permissions on app start
    await [Permission.location, Permission.notification].request();
  }

  Future<void> _loadTranslations() async {
    final provider = context.read<LocaleProvider>();
    final results = await Future.wait([
      provider.getScreenTranslations('home'),
      provider.getScreenTranslations('errors'),
    ]);
    if (mounted) {
      setState(() {
        _translations = results[0];
        _errorTranslations = results[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: _translations['title'] ?? 'Home Dashboard'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
            left: 16,
            right: 16,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNextPrayerWidget(),
              const SizedBox(height: 24),

              Text(
                _translations['ayah_of_day'] ?? 'Ayah of the Day',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildAyahCard(),
              const SizedBox(height: 24),
              _buildQuickSurahsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextPrayerWidget() {
    return Consumer<PrayerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildNextPrayerShimmer();
        }
        if (provider.prayerTime == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              _translations['prayer_not_available'] ??
                  'Prayer times not available. Pull to refresh in Prayer Times screen.',
            ),
          );
        }

        final pt = provider.prayerTime!;
        final nextPrayer = provider.nextPrayerName;
        final timeLeft = provider.timeUntilNextPrayer;
        final timeLeftStr =
            '${timeLeft.inHours.toString().padLeft(2, '0')}h ${timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}m ${timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}s';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title and Time Left
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _translations['next_prayer'] ?? 'Next Prayer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _translatePrayerName(nextPrayer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeLeftStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${pt.city}, ${pt.country}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Horizontal Scroll of Prayer Times
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPrayerTimeItem(
                      'Fajr',
                      _translatePrayerName('Fajr'),
                      pt.fajr,
                      nextPrayer == 'Fajr',
                    ),
                    _buildPrayerTimeItem(
                      'Sunrise',
                      _translatePrayerName('Sunrise'),
                      pt.sunrise,
                      false,
                    ),
                    _buildPrayerTimeItem(
                      'Dhuhr',
                      _translatePrayerName('Dhuhr'),
                      pt.dhuhr,
                      nextPrayer == 'Dhuhr',
                    ),
                    _buildPrayerTimeItem(
                      'Asr',
                      _translatePrayerName('Asr'),
                      pt.asr,
                      nextPrayer == 'Asr',
                    ),
                    _buildPrayerTimeItem(
                      'Maghrib',
                      _translatePrayerName('Maghrib'),
                      pt.maghrib,
                      nextPrayer == 'Maghrib',
                    ),
                    _buildPrayerTimeItem(
                      'Isha',
                      _translatePrayerName('Isha'),
                      pt.isha,
                      nextPrayer == 'Isha',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Widget _buildPrayerTimeItem(
    String prayerKey,
    String name,
    String time,
    bool isNext,
  ) {
    // Clean time string "05:30 (BST)" -> "05:30"
    final cleanTime = time.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _getPrayerIcon(prayerKey),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: isNext
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cleanTime,
            style: TextStyle(
              color: isNext
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahCard() {
    return Consumer2<AyahProvider, LocaleProvider>(
      builder: (context, ayahProvider, localeProvider, child) {
        if (ayahProvider.isLoading) {
          return _buildAyahShimmer();
        }
        if (ayahProvider.hasError) {
          return AppErrorWidget(
            errorType: ayahProvider.errorType ?? AppErrorType.unknown,
            translations: _errorTranslations,
            compact: true,
            onRetry: () {
              context.read<HapticProvider>().lightImpact();
              ayahProvider.fetchRandomAyah();
            },
          );
        }
        if (ayahProvider.ayah == null) {
          return const SizedBox.shrink();
        }

        final ayah = ayahProvider.ayah!;
        final isArabic = localeProvider.locale.languageCode == 'ar';
        final surahName = isArabic ? ayah.surahName : ayah.surahEnglishName;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$surahName: ${ayah.numberInSurah}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ayah.text,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    height: 2.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<HapticProvider>().lightImpact();
                      final reciterProvider = context.read<ReciterProvider>();
                      final surahProvider = context.read<SurahProvider>();
                      final audioProvider = context.read<AudioProvider>();

                      if (reciterProvider.reciters.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _translations['reciters_not_loaded'] ??
                                  'Reciters not loaded yet. Please wait.',
                            ),
                          ),
                        );
                        return;
                      }

                      final surah = surahProvider.getSurahById(
                        ayah.surahNumber,
                      );
                      if (surah == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _translations['surah_not_found'] ??
                                  'Surah details not found.',
                            ),
                          ),
                        );
                        return;
                      }

                      final defaultReciter = reciterProvider.reciters.first;
                      if (defaultReciter.moshaf.isNotEmpty) {
                        final moshaf = defaultReciter.moshaf.first;
                        final url =
                            '${moshaf.server}${surah.id.toString().padLeft(3, '0')}.mp3';
                        audioProvider.play(
                          url,
                          reciter: defaultReciter,
                          surah: surah,
                          moshaf: moshaf,
                          surahProvider: surahProvider,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      (_translations['listen_to'] ?? 'Listen to {surahName}')
                          .toString()
                          .replaceAll('{surahName}', surahName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
  }

  Widget _buildNextPrayerShimmer() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.35),
        highlightColor: Colors.white.withValues(alpha: 0.85),
        period: const Duration(milliseconds: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 80, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 28, width: 140, color: Colors.white),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(height: 20, width: 80, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 120, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 72,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahShimmer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Shimmer.fromColors(
          baseColor: AppColors.neutral300,
          highlightColor: AppColors.neutral50,
          period: const Duration(milliseconds: 1400),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 12,
                  width: 140,
                  color: AppColors.neutral200,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 16,
                width: double.infinity,
                color: AppColors.neutral200,
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: double.infinity,
                color: AppColors.neutral200,
              ),
              const SizedBox(height: 12),
              Container(height: 16, width: 220, color: AppColors.neutral200),
              const SizedBox(height: 24),
              Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSurahsSection() {
    final surahProvider = context.watch<SurahProvider>();
    if (surahProvider.isLoading) {
      return _buildQuickSurahsShimmer();
    }

    if (surahProvider.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              _translations['quick_surahs'] ?? 'Quick Surahs',
              style: AppTypography.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          AppErrorWidget(
            errorType: surahProvider.errorType ?? AppErrorType.unknown,
            translations: _errorTranslations,
            compact: true,
            onRetry: () {
              context.read<HapticProvider>().lightImpact();
              final localeCode = context
                  .read<LocaleProvider>()
                  .locale
                  .languageCode;
              surahProvider.fetchSurahs(language: localeCode);
            },
          ),
        ],
      );
    }

    // IDs for Quick Surahs: Al-Kahf (18), Yaseen (36), Al-Waqi'a (56), Al-Mulk (67)
    final quickSurahIds = [18, 36, 56, 67];
    final quickSurahs = surahProvider.surahs
        .where((s) => quickSurahIds.contains(s.id))
        .toList();

    if (quickSurahs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            _translations['quick_surahs'] ?? 'Quick Surahs',
            style: AppTypography.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: quickSurahs
              .map((surah) => _buildQuickSurahTile(surah))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickSurahTile(Surah surah) {
    // Watch AudioProvider for playback state
    final audioProvider = context.watch<AudioProvider>();
    final isCurrentTrack = audioProvider.currentSurah?.id == surah.id;
    final isPlaying = isCurrentTrack && audioProvider.isPlaying;
    final isLoading = isCurrentTrack && audioProvider.isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<HapticProvider>().lightImpact();

            // If current track, toggle play/pause
            if (isCurrentTrack) {
              if (isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
              return;
            }

            final reciterProvider = context.read<ReciterProvider>();

            if (reciterProvider.reciters.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _translations['reciters_not_loaded'] ??
                        'Reciters not loaded yet. Please wait.',
                  ),
                ),
              );
              return;
            }

            final defaultReciter = reciterProvider.reciters.first;
            if (defaultReciter.moshaf.isNotEmpty) {
              final moshaf = defaultReciter.moshaf.first;
              final url =
                  '${moshaf.server}${surah.id.toString().padLeft(3, '0')}.mp3';
              audioProvider.play(
                url,
                reciter: defaultReciter,
                surah: surah,
                moshaf: moshaf,
                surahProvider: context.read<SurahProvider>(),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Image.asset('assets/icons/quran.png', width: 32, height: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(_translations['surah_label'] ?? 'Surah {id}').toString().replaceAll('{id}', surah.id.toString())} • ${surah.isMakkia ? (_translations['meccan'] ?? 'Meccan') : (_translations['medinan'] ?? 'Medinan')}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  )
                else if (isCurrentTrack)
                  HeroIcon(
                    isPlaying ? HeroIcons.pause : HeroIcons.play,
                    color: AppColors.primaryBlue,
                    style: HeroIconStyle.solid,
                    size: 28,
                  )
                else
                  HeroIcon(
                    HeroIcons.playCircle,
                    color: AppColors.textPrimary,
                    style: HeroIconStyle.outline,
                    size: 32,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shimmer loading skeleton for the Quick Surahs section.
  /// Mirrors the real tile layout: icon, name + subtitle, and play button.
  Widget _buildQuickSurahsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            _translations['quick_surahs'] ?? 'Quick Surahs',
            style: AppTypography.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(4, (index) => _buildQuickSurahTileShimmer()),
      ],
    );
  }

  /// A single shimmer placeholder tile that mirrors [_buildQuickSurahTile].
  Widget _buildQuickSurahTileShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Shimmer.fromColors(
          baseColor: AppColors.neutral300,
          highlightColor: AppColors.neutral50,
          period: const Duration(milliseconds: 1400),
          child: Row(
            children: [
              // Icon placeholder (matches the 32×32 quran icon)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              // Text placeholders (title + subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Play button placeholder (matches the 32×32 play icon)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
