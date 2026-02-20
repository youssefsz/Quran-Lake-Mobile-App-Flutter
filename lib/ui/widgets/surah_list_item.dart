import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/surah.dart';
import '../../providers/haptic_provider.dart';

class SurahListItem extends StatelessWidget {
  final Surah surah;
  final bool isPlaying;
  final bool isCurrentTrack;
  final bool isLoading;
  final VoidCallback onTap;

  const SurahListItem({
    super.key,
    required this.surah,
    required this.isPlaying,
    required this.isCurrentTrack,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<HapticProvider>().lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: isCurrentTrack
            ? BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            // Number
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  surah.id.toString(),
                  style: AppTypography.titleMedium.copyWith(
                    color: isCurrentTrack
                        ? AppColors.primaryBlue
                        : Colors.black,
                    fontWeight: isCurrentTrack
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: isCurrentTrack
                          ? AppColors.primaryBlue
                          : Colors.black,
                      fontWeight: isCurrentTrack
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTag(
                        context,
                        surah.isMakkia ? 'Meccan' : 'Medinan',
                        surah.isMakkia ? Colors.orange : Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Play/Pause Button
            if (isCurrentTrack)
              if (isLoading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                    ),
                  ),
                )
              else
                HeroIcon(
                  isPlaying ? HeroIcons.pause : HeroIcons.play,
                  color: AppColors.primaryBlue,
                  style: HeroIconStyle.solid,
                  size: 28,
                )
            else
              HeroIcon(
                HeroIcons.playCircle,
                color: Colors.black,
                style: HeroIconStyle.outline,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
