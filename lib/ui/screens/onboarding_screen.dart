import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_lake/core/theme/design_system.dart';
import 'package:quran_lake/providers/locale_provider.dart';
import 'package:quran_lake/ui/screens/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<String, dynamic> _translations = {};
  
  // Track permission states to update UI instantly
  bool _notificationGranted = false;
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notifStatus = await Permission.notification.status;
    final locStatus = await Permission.location.status;
    
    if (mounted) {
      setState(() {
        _notificationGranted = notifStatus.isGranted;
        _locationGranted = locStatus.isGranted;
      });
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }
  
  Future<void> _handleBottomButtonPress() async {
    // Page 0: Welcome & Language -> Next (Skip Notif if iOS/Granted)
    if (_currentPage == 0) {
       // Logic handles skipping in next step logic implicitly by page list structure?
       // No, we need to know where to go.
       // On iOS, next page is Location.
       // On Android, next page is Notification (unless granted).
       
       if (Platform.isIOS) {
          // Check if Location is already granted, if so finish?
          final locStatus = await Permission.location.status;
          if (locStatus.isGranted) {
             _completeOnboarding();
          } else {
             _nextPage();
          }
       } else {
          // Android
          final notifStatus = await Permission.notification.status;
          if (notifStatus.isGranted) {
             // Skip Notif Page
             final locStatus = await Permission.location.status;
             if (locStatus.isGranted) {
                _completeOnboarding();
             } else {
                // Jump to Location (Page 2)
                _pageController.jumpToPage(2);
             }
          } else {
             _nextPage();
          }
       }
       return;
    }
    
    // Page 1: 
    // iOS: Location Page
    // Android: Notification Page
    if (_currentPage == 1) {
       if (Platform.isIOS) {
          // Handle Location (Same as Page 2 on Android)
          if (_locationGranted) {
            _completeOnboarding();
          } else {
            final status = await Permission.location.request();
            setState(() { _locationGranted = status.isGranted; });
            if (status.isGranted) {
               _completeOnboarding();
            } else if (status.isPermanentlyDenied) {
               if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_translations['enable_loc_msg'] ?? 'Please enable location')));
            }
          }
       } else {
          // Handle Notification (Android)
          if (_notificationGranted) {
            _nextPage();
          } else {
            final status = await Permission.notification.request();
            setState(() { _notificationGranted = status.isGranted; });
            if (status.isGranted) {
               final locStatus = await Permission.location.status;
               if (locStatus.isGranted) {
                  _completeOnboarding();
               } else {
                  _nextPage();
               }
            } else if (status.isPermanentlyDenied) {
               if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_translations['enable_notif_msg'] ?? 'Please enable notifications')));
            }
          }
       }
       return;
    }
    
    // Page 2: Location (Android only)
    if (_currentPage == 2 && !Platform.isIOS) {
        if (_locationGranted) {
          _completeOnboarding();
        } else {
          final status = await Permission.location.request();
          setState(() { _locationGranted = status.isGranted; });
          if (status.isGranted) {
             _completeOnboarding();
          } else if (status.isPermanentlyDenied) {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_translations['enable_loc_msg'] ?? 'Please enable location')));
          }
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: localeProvider.getScreenTranslations('onboarding'),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _translations = snapshot.data!;
            }
            
            final pages = [
              _buildWelcomePage(localeProvider),
              if (!Platform.isIOS) _buildNotificationPage(),
              _buildLocationPage(),
            ];

            // Determine button text based on page and state
            String buttonText = _translations['continue_button'] ?? 'Continue';
            
            // Map current page index to logical page type
            // 0: Welcome & Language
            // 1: Notification (Android only) OR Location (iOS)
            // 2: Location (Android only)
            
            if (_currentPage == 0) {
               buttonText = _translations['get_started'] ?? 'Get Started';
            } else {
               // Logic for dynamic pages
               if (Platform.isIOS) {
                  // Page 1 is Location on iOS
                  if (_currentPage == 1) {
                     buttonText = _locationGranted
                      ? (_translations['continue_button'] ?? 'Continue')
                      : (_translations['allow_location'] ?? 'Allow Location');
                  }
               } else {
                  // Android: Page 1 is Notif, Page 2 is Loc
                  if (_currentPage == 1) {
                     buttonText = _notificationGranted 
                      ? (_translations['continue_button'] ?? 'Continue')
                      : (_translations['allow_notifications'] ?? 'Allow Notifications');
                  } else if (_currentPage == 2) {
                     buttonText = _locationGranted
                      ? (_translations['continue_button'] ?? 'Continue')
                      : (_translations['allow_location'] ?? 'Allow Location');
                  }
               }
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            // Prevent skipping permissions by swiping
                            if (Platform.isIOS) {
                               // iOS: Page 1 is Location
                               if (index == 1 && !_locationGranted && _currentPage == 0) {
                                  // Moving from Welcome to Location: Allowed
                               }
                            } else {
                               // Android: Page 1 is Notif, Page 2 is Loc
                               if (index == 1 && !_notificationGranted && _currentPage == 0) {
                                   // Moving from Welcome to Notification: Allowed
                               }
                               
                               // If trying to go to Location (2) without Notification (1) permission
                               if (index == 2 && !_notificationGranted) {
                                   // Snap back to Notification page
                                   _pageController.jumpToPage(1);
                                   return;
                               }
                            }
                            
                            _currentPage = index;
                            // Check permissions again when entering pages
                            _checkPermissions();
                          });
                        },
                        children: pages,
                      ),
                    ),
                    
                    // Page indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppColors.primaryBlue
                                  : AppColors.neutral300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Bottom Action Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: buttonText,
                          onPressed: _handleBottomButtonPress,
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

  Widget _buildWelcomePage(LocaleProvider localeProvider) {
    final isEn = localeProvider.locale.languageCode == 'en';
    final isAr = localeProvider.locale.languageCode == 'ar';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _translations['welcome_title'] ?? 'Welcome to Quran Lake',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _translations['welcome_subtitle'] ?? 'Your companion for Quran recitation and prayer times.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Language Selection (Compact)
          Text(
            _translations['select_language'] ?? 'Choose your language',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: 16),
          _CompactLanguageButton(
            language: 'English',
            flag: '🇺🇸',
            isSelected: isEn,
            onTap: () => localeProvider.setLocale(const Locale('en')),
          ),
          const SizedBox(height: 12),
          _CompactLanguageButton(
            language: 'العربية',
            flag: '🇸🇦',
            isSelected: isAr,
            onTap: () => localeProvider.setLocale(const Locale('ar')),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active_rounded,
            size: 80,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 40),
          Text(
            _translations['notification_title'] ?? 'Stay Updated',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _translations['notification_desc'] ?? 'Enable notifications to get prayer time alerts and daily reminders.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 80,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 40),
          Text(
            _translations['location_title'] ?? 'Accurate Prayer Times',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _translations['location_desc'] ?? 'We need your location to calculate accurate prayer times for your area.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CompactLanguageButton extends StatelessWidget {
  final String language;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactLanguageButton({
    required this.language,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, // Full width
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.neutral300,
            width: isSelected ? 3 : 2,
          ),
          // No shadow as requested
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                language,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
               Container(
                 padding: const EdgeInsets.all(4),
                 decoration: BoxDecoration(
                   color: AppColors.primaryBlue,
                   shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
               ),
          ],
        ),
      ),
    );
  }
}
