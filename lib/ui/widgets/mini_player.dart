import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/haptic_provider.dart';
import '../screens/full_player_screen.dart';
import '../../core/theme/app_colors.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    if (audioProvider.currentSurah == null) {
      return const SizedBox.shrink();
    }

    return OpenContainer(
      openBuilder: (context, _) => const FullPlayerScreen(),
      closedElevation: 0,
      closedShape: const RoundedRectangleBorder(),
      closedColor: Theme.of(context).scaffoldBackgroundColor,
      middleColor: Theme.of(context).scaffoldBackgroundColor,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fadeThrough,
      tappable: false,
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: () {
            context.read<HapticProvider>().lightImpact();
            openContainer();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset('assets/icons/quran.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        audioProvider.currentSurah?.name ?? 'Unknown Surah',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        audioProvider.currentReciter?.name ?? 'Unknown Reciter',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (audioProvider.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(audioProvider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
                    onPressed: () {
                      context.read<HapticProvider>().lightImpact();
                      if (audioProvider.isPlaying) {
                        audioProvider.pause();
                      } else {
                        audioProvider.resume();
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    context.read<HapticProvider>().lightImpact();
                    audioProvider.closePlayer();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
