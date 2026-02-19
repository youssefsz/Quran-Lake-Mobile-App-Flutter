import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/surah.dart';

class SurahListItem extends StatelessWidget {
  final Surah surah;
  final bool isPlaying;
  final bool isCurrentTrack;
  final VoidCallback onTap;

  const SurahListItem({
    super.key,
    required this.surah,
    required this.isPlaying,
    required this.isCurrentTrack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: isCurrentTrack
            ? BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.05),
                border: Border(
                  left: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 4,
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            // Number / Status
            SizedBox(
              width: 40,
              child: Center(
                child: isCurrentTrack && isPlaying
                    ? const HeroIcon(
                        HeroIcons.pause,
                        color: AppColors.primaryBlue,
                        style: HeroIconStyle.solid,
                        size: 24,
                      )
                    : isCurrentTrack
                        ? const HeroIcon(
                            HeroIcons.play,
                            color: AppColors.primaryBlue,
                            style: HeroIconStyle.solid,
                            size: 24,
                          )
                        : Text(
                            surah.id.toString(),
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.neutral400,
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
                          : AppColors.textPrimary,
                      fontWeight: isCurrentTrack ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTag(
                        context, 
                        surah.isMakkia ? 'Meccan' : 'Medinan', 
                        surah.isMakkia ? Colors.orange : Colors.green
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Play Button (if not current)
            if (!isCurrentTrack)
              HeroIcon(
                HeroIcons.playCircle,
                color: AppColors.neutral300,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
