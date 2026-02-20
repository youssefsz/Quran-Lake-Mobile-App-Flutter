import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/surah_provider.dart';
import '../widgets/glass_app_bar.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  Map<String, dynamic> _translations = {};
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    _translations = localeProvider.getCachedTranslations('player');
    _lastLocaleCode = localeProvider.locale.languageCode;
    _loadTranslations();
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
    final translations = await provider.getScreenTranslations('player');
    if (mounted) {
      setState(() {
        _translations = translations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final surah = audioProvider.currentSurah;
    final reciter = audioProvider.currentReciter;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: _translations['now_playing'] ?? 'Now Playing',
        centerTitle: true,
        leading: IconButton(
          iconSize: 32,
          icon: const Icon(Icons.keyboard_arrow_down, weight: 800, color: Colors.black),
          onPressed: () {
            context.read<HapticProvider>().lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 24,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder Artwork
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Image.asset('assets/icons/quran.png'),
                ),
              ),
              const SizedBox(height: 40),
              
              // Info
              Text(
                surah?.name ?? _translations['unknown_surah'] ?? 'Unknown Surah',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                reciter?.name ?? _translations['unknown_reciter'] ?? 'Unknown Reciter',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Progress Bar & Controls (Force LTR)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [
                    Slider(
                      value: audioProvider.position.inSeconds.toDouble(),
                      max: audioProvider.duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        audioProvider.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(audioProvider.position)),
                          Text(_formatDuration(audioProvider.duration)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36),
                          onPressed: () {
                            context.read<HapticProvider>().lightImpact();
                            context.read<AudioProvider>().playPrevious(context.read<SurahProvider>());
                          },
                        ),
                        const SizedBox(width: 24),
                        FloatingActionButton.large(
                          onPressed: () {
                            context.read<HapticProvider>().lightImpact();
                            if (audioProvider.isLoading) return;

                            if (audioProvider.isPlaying) {
                              audioProvider.pause();
                            } else {
                              audioProvider.resume();
                            }
                          },
                          child: audioProvider.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Icon(
                                  audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 48,
                                ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 36),
                          onPressed: () {
                            context.read<HapticProvider>().lightImpact();
                            context.read<AudioProvider>().playNext(context.read<SurahProvider>());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
