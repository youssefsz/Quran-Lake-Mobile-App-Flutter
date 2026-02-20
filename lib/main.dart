import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/design_system.dart';
import 'data/api/dio_client.dart';
import 'data/local_db/database_helper.dart';
import 'data/repositories/prayer_time_repository.dart';
import 'data/repositories/reciters_repository.dart';
import 'data/repositories/surah_repository.dart';
import 'data/services/location_service.dart';
import 'providers/audio_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/haptic_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/reciter_provider.dart';
import 'providers/surah_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/reciters_screen.dart';
import 'ui/screens/prayer_times_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/widgets/mini_player.dart';
import 'ui/widgets/custom_bottom_nav_bar.dart';

import 'package:quran_lake/data/repositories/ayah_repository.dart';
import 'package:quran_lake/providers/ayah_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'tn.quranlake.app.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/media_logo',
  );
  
  final dioClient = DioClient();
  final databaseHelper = DatabaseHelper();
  final locationService = LocationService();
  
  final recitersRepository = RecitersRepository(dioClient);
  final surahRepository = SurahRepository(dioClient);
  final ayahRepository = AyahRepository();
  final prayerTimeRepository = PrayerTimeRepository(
    dioClient: dioClient,
    databaseHelper: databaseHelper,
    locationService: locationService,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  
  runApp(QuranLakeApp(
    recitersRepository: recitersRepository,
    surahRepository: surahRepository,
    ayahRepository: ayahRepository,
    prayerTimeRepository: prayerTimeRepository,
    onboardingComplete: onboardingComplete,
  ));
}

class QuranLakeApp extends StatelessWidget {
  final RecitersRepository recitersRepository;
  final SurahRepository surahRepository;
  final AyahRepository ayahRepository;
  final PrayerTimeRepository prayerTimeRepository;
  final bool onboardingComplete;

  const QuranLakeApp({
    super.key,
    required this.recitersRepository,
    required this.surahRepository,
    required this.ayahRepository,
    required this.prayerTimeRepository,
    required this.onboardingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ReciterProvider(recitersRepository)),
        ChangeNotifierProvider(create: (_) => SurahProvider(surahRepository)),
        ChangeNotifierProvider(create: (_) => AyahProvider(ayahRepository)),
        ChangeNotifierProxyProvider<SurahProvider, AudioProvider>(
          create: (_) => AudioProvider(),
          update: (_, surahProvider, audioProvider) => audioProvider!..updateSurahProvider(surahProvider),
        ),
        ChangeNotifierProvider(create: (_) => HapticProvider()),
        ChangeNotifierProvider(create: (_) => PrayerProvider(prayerTimeRepository)),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Quran Lake',
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            home: onboardingComplete ? const MainScreen() : const OnboardingScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
