import 'package:flutter/material.dart';
import 'package:quran_lake/ui/screens/home_screen.dart';
import 'package:quran_lake/ui/screens/reciters_screen.dart';
import 'package:quran_lake/ui/screens/prayer_times_screen.dart';
import 'package:quran_lake/ui/screens/settings_screen.dart';
import 'package:quran_lake/ui/widgets/mini_player.dart';
import 'package:quran_lake/ui/widgets/custom_bottom_nav_bar.dart';

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
