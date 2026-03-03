import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:quran_lake/data/repositories/ayah_repository.dart';
import 'package:quran_lake/providers/ayah_provider.dart';
import 'package:quran_lake/data/services/adhan_service.dart';
import 'package:quran_lake/providers/adhan_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:alarm/alarm.dart';
import 'package:quran_lake/data/services/background_service.dart';
import 'package:quran_lake/data/services/foreground_service.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/main_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize timezone data for scheduled notifications
  tz.initializeTimeZones();

  // Initialize Alarm package - uses Android AlarmManager for exact alarms
  // AlarmManager ensures alarms fire even when app is closed
  await Alarm.init();

  // Set up alarm callback to cancel countdown notification when adhan fires
  Alarm.ringStream.stream.listen((alarmSettings) {
    // When adhan alarm fires, cancel the countdown notification for that prayer
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefsInstance) {
      final adhanService = AdhanService(prefsInstance);
      // Get prayer name from alarm ID
      final alarmId = alarmSettings.id;
      String? prayerName;
      switch (alarmId) {
        case 1:
          prayerName = 'Fajr';
          break;
        case 2:
          prayerName = 'Sunrise';
          break;
        case 3:
          prayerName = 'Dhuhr';
          break;
        case 4:
          prayerName = 'Asr';
          break;
        case 5:
          prayerName = 'Maghrib';
          break;
        case 6:
          prayerName = 'Isha';
          break;
      }
      if (prayerName != null) {
        adhanService.cancelCountdownForPrayer(prayerName);
        debugPrint(
          'Adhan fired for $prayerName - cancelled countdown notification',
        );
      }
    });
  });

  // Initialize background service for daily prayer time updates
  await BackgroundService.initialize();

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
  
  // Check if adhan is enabled and start foreground service
  final adhanEnabled = prefs.getBool('adhan_enabled') ?? false;
  if (adhanEnabled) {
    // Start foreground service to keep running even after app is killed
    await ForegroundService.start();
  }
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  // Initialize Adhan Service and wait for notification setup
  final adhanService = AdhanService(prefs);
  await adhanService.initialize();

  // Remove splash screen now that initialization is complete
  FlutterNativeSplash.remove();

  runApp(
    QuranLakeApp(
      recitersRepository: recitersRepository,
      surahRepository: surahRepository,
      ayahRepository: ayahRepository,
      prayerTimeRepository: prayerTimeRepository,
      adhanService: adhanService,
      onboardingComplete: onboardingComplete,
    ),
  );
}

class QuranLakeApp extends StatelessWidget {
  final RecitersRepository recitersRepository;
  final SurahRepository surahRepository;
  final AyahRepository ayahRepository;
  final PrayerTimeRepository prayerTimeRepository;
  final AdhanService adhanService;
  final bool onboardingComplete;

  const QuranLakeApp({
    super.key,
    required this.recitersRepository,
    required this.surahRepository,
    required this.ayahRepository,
    required this.prayerTimeRepository,
    required this.adhanService,
    required this.onboardingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
          create: (_) => ReciterProvider(recitersRepository),
        ),
        ChangeNotifierProvider(create: (_) => SurahProvider(surahRepository)),
        ChangeNotifierProvider(create: (_) => AyahProvider(ayahRepository)),
        ChangeNotifierProxyProvider<SurahProvider, AudioProvider>(
          create: (_) => AudioProvider(),
          update: (_, surahProvider, audioProvider) =>
              audioProvider!..updateSurahProvider(surahProvider),
        ),
        ChangeNotifierProvider(create: (_) => HapticProvider()),
        ChangeNotifierProvider(
          create: (_) => PrayerProvider(prayerTimeRepository),
        ),
        ChangeNotifierProvider(create: (_) => AdhanProvider(adhanService)),
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
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: onboardingComplete
                ? const MainScreen()
                : const OnboardingScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
