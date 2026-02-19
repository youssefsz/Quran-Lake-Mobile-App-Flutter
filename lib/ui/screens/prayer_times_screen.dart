import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/prayer_provider.dart';
import '../widgets/glass_app_bar.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Map<String, dynamic> _translations = {};
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    _translations = localeProvider.getCachedTranslations('prayer_times');
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
    final translations = await provider.getScreenTranslations('prayer_times');
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
        title: _translations['title'] ?? 'Prayer Times',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PrayerProvider>().fetchPrayerTimes();
            },
          )
        ],
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, prayerProvider, child) {
          if (prayerProvider.isLoading) {
             return const Center(child: CircularProgressIndicator());
          }
          if (prayerProvider.errorMessage != null) {
             return Center(child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Text(prayerProvider.errorMessage!, textAlign: TextAlign.center),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: () => prayerProvider.fetchPrayerTimes(), 
                     child: const Text('Retry')
                   )
                 ],
               ),
             ));
          }
          if (prayerProvider.prayerTime == null) {
             return const Center(child: Text("No prayer times available."));
          }

          final pt = prayerProvider.prayerTime!;
          final nextPrayer = prayerProvider.nextPrayerName;
          final timeLeft = prayerProvider.timeUntilNextPrayer;
          
          final hours = timeLeft.inHours;
          final minutes = timeLeft.inMinutes.remainder(60);
          final timeLeftStr = '${hours}h ${minutes}m';

          return SingleChildScrollView(
            padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 20, left: 16, right: 16, bottom: 100),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${pt.city}, ${pt.country}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Text('Next Prayer: $nextPrayer', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(timeLeftStr, style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )),
                
                const SizedBox(height: 48),
                
                _buildPrayerRow('Fajr', pt.fajr, nextPrayer == 'Fajr'),
                _buildPrayerRow('Sunrise', pt.sunrise, false),
                _buildPrayerRow('Dhuhr', pt.dhuhr, nextPrayer == 'Dhuhr'),
                _buildPrayerRow('Asr', pt.asr, nextPrayer == 'Asr'),
                _buildPrayerRow('Maghrib', pt.maghrib, nextPrayer == 'Maghrib'),
                _buildPrayerRow('Isha', pt.isha, nextPrayer == 'Isha'),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildPrayerRow(String name, String time, bool isNext) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNext ? colorScheme.primaryContainer.withOpacity(0.3) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: isNext ? Border.all(color: colorScheme.primary, width: 2) : Border.all(color: Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name, 
            style: TextStyle(
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              fontSize: 18,
              color: isNext ? colorScheme.primary : Colors.black87,
            )
          ),
          Text(
            time, 
            style: TextStyle(
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              fontSize: 18,
              color: isNext ? colorScheme.primary : Colors.black87,
            )
          ),
        ],
      ),
    );
  }
}
