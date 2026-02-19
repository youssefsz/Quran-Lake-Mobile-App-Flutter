import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/ayah_provider.dart';
import '../../providers/surah_provider.dart';
import '../../providers/reciter_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/haptic_provider.dart';
import '../widgets/glass_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _translations = {};
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    final localeCode = localeProvider.locale.languageCode;
    _translations = localeProvider.getCachedTranslations('home');
    _lastLocaleCode = localeCode;
    _loadTranslations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prayerProvider = context.read<PrayerProvider>();
      if (prayerProvider.prayerTime == null && !prayerProvider.isLoading) {
        prayerProvider.fetchPrayerTimes();
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

  Future<void> _loadTranslations() async {
    final provider = context.read<LocaleProvider>();
    final translations = await provider.getScreenTranslations('home');
    if (mounted) {
      setState(() {
        _translations = translations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: _translations['title'] ?? 'Home Dashboard',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 20, left: 16, right: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNextPrayerWidget(),
            const SizedBox(height: 24),
            
            Text(_translations['ayah_of_day'] ?? 'Ayah of the Day', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildAyahCard(),
            const SizedBox(height: 24),
          ],
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
            child: const Text("Prayer times not available. Pull to refresh in Prayer Times screen."),
          );
        }
        
        final pt = provider.prayerTime!;
        final nextPrayer = provider.nextPrayerName;
        final timeLeft = provider.timeUntilNextPrayer;
        final timeLeftStr = '${timeLeft.inHours.toString().padLeft(2, '0')}h ${timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}m ${timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}s';

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
                          'Next Prayer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextPrayer,
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
                            Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${pt.city}, ${pt.country}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
                    _buildPrayerTimeItem('Fajr', pt.fajr, nextPrayer == 'Fajr'),
                    _buildPrayerTimeItem('Sunrise', pt.sunrise, false),
                    _buildPrayerTimeItem('Dhuhr', pt.dhuhr, nextPrayer == 'Dhuhr'),
                    _buildPrayerTimeItem('Asr', pt.asr, nextPrayer == 'Asr'),
                    _buildPrayerTimeItem('Maghrib', pt.maghrib, nextPrayer == 'Maghrib'),
                    _buildPrayerTimeItem('Isha', pt.isha, nextPrayer == 'Isha'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrayerTimeItem(String name, String time, bool isNext) {
    // Clean time string "05:30 (BST)" -> "05:30"
    final cleanTime = time.replaceAll(RegExp(r'\s*\(.*\)'), '').trim();
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isNext ? Colors.white : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              color: isNext ? Theme.of(context).colorScheme.primary : Colors.white,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cleanTime,
            style: TextStyle(
              color: isNext ? Theme.of(context).colorScheme.primary : Colors.white,
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
        if (ayahProvider.errorMessage != null) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('Error: ${ayahProvider.errorMessage}'),
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
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
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
                  style: GoogleFonts.amiri(fontSize: 28, height: 2.0, fontWeight: FontWeight.w500, color: Colors.black),
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
                          const SnackBar(content: Text('Reciters not loaded yet. Please wait.')),
                        );
                        return;
                      }

                      final surah = surahProvider.getSurahById(ayah.surahNumber);
                      if (surah == null) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Surah details not found.')),
                        );
                        return;
                      }

                      final defaultReciter = reciterProvider.reciters.first;
                      if (defaultReciter.moshaf.isNotEmpty) {
                         final moshaf = defaultReciter.moshaf.first;
                         final url = '${moshaf.server}${surah.id.toString().padLeft(3, '0')}.mp3';
                         audioProvider.play(url, reciter: defaultReciter, surah: surah);
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    label: Text('Listen to $surahName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        baseColor: Colors.white.withOpacity(0.35),
        highlightColor: Colors.white.withOpacity(0.85),
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
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
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
                child: Container(height: 12, width: 140, color: AppColors.neutral200),
              ),
              const SizedBox(height: 16),
              Container(height: 16, width: double.infinity, color: AppColors.neutral200),
              const SizedBox(height: 12),
              Container(height: 16, width: double.infinity, color: AppColors.neutral200),
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
}
