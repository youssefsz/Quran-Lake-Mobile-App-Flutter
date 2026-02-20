import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/audio_provider.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/surah_provider.dart';
import '../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: _translations['now_playing'] ?? 'Now Playing',
        centerTitle: true,
        leading: IconButton(
          iconSize: 32,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            weight: 800,
            color: AppColors.neutral800,
          ),
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
              // Artwork
              Expanded(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Image.asset('assets/icons/quran.png'),
                    ),
                  ),
                ),
              ),

              // Info
              Column(
                children: [
                  Text(
                    surah?.name ??
                        _translations['unknown_surah'] ??
                        'Unknown Surah',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reciter?.name ??
                        _translations['unknown_reciter'] ??
                        'Unknown Reciter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Progress Bar & Controls
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primaryBlue,
                        inactiveTrackColor: AppColors.neutral200,
                        thumbColor: AppColors.primaryBlue,
                        overlayColor: AppColors.primaryBlue.withValues(
                          alpha: 0.1,
                        ),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: audioProvider.position.inSeconds
                            .toDouble()
                            .clamp(
                              0,
                              audioProvider.duration.inSeconds.toDouble(),
                            ),
                        max: audioProvider.duration.inSeconds.toDouble(),
                        onChanged: (value) {
                          audioProvider.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(audioProvider.position),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                          Text(
                            _formatDuration(audioProvider.duration),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Shuffle Button
                        IconButton(
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: audioProvider.shuffleModeEnabled
                                ? AppColors.primaryBlue
                                : AppColors.neutral400,
                          ),
                          onPressed: () {
                            context.read<HapticProvider>().lightImpact();
                            audioProvider.toggleShuffle();
                          },
                        ),

                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                size: 40,
                              ),
                              color: AppColors.neutral800,
                              onPressed: () {
                                context.read<HapticProvider>().lightImpact();
                                context.read<AudioProvider>().playPrevious(
                                  context.read<SurahProvider>(),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    context
                                        .read<HapticProvider>()
                                        .lightImpact();
                                    if (audioProvider.isLoading) return;

                                    if (audioProvider.isPlaying) {
                                      audioProvider.pause();
                                    } else {
                                      audioProvider.resume();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(40),
                                  child: Center(
                                    child: audioProvider.isLoading
                                        ? const SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : Icon(
                                            audioProvider.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 40,
                              ),
                              color: AppColors.neutral800,
                              onPressed: () {
                                context.read<HapticProvider>().lightImpact();
                                context.read<AudioProvider>().playNext(
                                  context.read<SurahProvider>(),
                                );
                              },
                            ),
                          ],
                        ),

                        // Loop Button
                        IconButton(
                          icon: Icon(
                            _getLoopIcon(audioProvider.loopMode),
                            color: audioProvider.loopMode == LoopMode.off
                                ? AppColors.neutral400
                                : AppColors.primaryBlue,
                          ),
                          onPressed: () {
                            context.read<HapticProvider>().lightImpact();
                            _cycleLoopMode(audioProvider);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Extra Controls: Speed & Volume (Integrated)
                    Row(
                      children: [
                        // Speed Control
                        Material(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _cycleSpeed(audioProvider),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                '${audioProvider.playbackSpeed}x',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Volume Slider
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  audioProvider.volume == 0
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_down_rounded,
                                  size: 20,
                                  color: AppColors.neutral500,
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.neutral800,
                                      inactiveTrackColor: AppColors.neutral200,
                                      thumbColor: AppColors.neutral800,
                                      overlayColor: AppColors.neutral800
                                          .withValues(alpha: 0.1),
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                    ),
                                    child: Slider(
                                      value: audioProvider.volume,
                                      onChanged: (value) {
                                        audioProvider.setVolume(value);
                                      },
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.volume_up_rounded,
                                  size: 20,
                                  color: AppColors.neutral500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLoopIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Icons.repeat_rounded;
      case LoopMode.all:
        return Icons.repeat_rounded;
      case LoopMode.one:
        return Icons.repeat_one_rounded;
    }
  }

  void _cycleLoopMode(AudioProvider provider) {
    switch (provider.loopMode) {
      case LoopMode.off:
        provider.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        provider.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        provider.setLoopMode(LoopMode.off);
        break;
    }
  }

  void _cycleSpeed(AudioProvider provider) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(provider.playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    provider.setPlaybackSpeed(speeds[nextIndex]);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
