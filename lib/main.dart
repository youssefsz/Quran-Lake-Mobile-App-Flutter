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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.quran_lake.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
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
  
  runApp(QuranLakeApp(
    recitersRepository: recitersRepository,
    surahRepository: surahRepository,
    ayahRepository: ayahRepository,
    prayerTimeRepository: prayerTimeRepository,
  ));
}

class QuranLakeApp extends StatelessWidget {
  final RecitersRepository recitersRepository;
  final SurahRepository surahRepository;
  final AyahRepository ayahRepository;
  final PrayerTimeRepository prayerTimeRepository;

  const QuranLakeApp({
    super.key,
    required this.recitersRepository,
    required this.surahRepository,
    required this.ayahRepository,
    required this.prayerTimeRepository,
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
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RecitersScreen(),
    PrayerTimesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Note: In a real app we'd localize these labels too, likely in a 'navigation.json' or shared.
    // For now, I'll stick to English for tabs or update them later.
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayer(),
                  CustomBottomNavBar(
                    selectedIndex: _currentIndex,
                    onItemSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
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
