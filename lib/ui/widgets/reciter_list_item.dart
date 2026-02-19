import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/reciter.dart';
import '../../providers/haptic_provider.dart';

class ReciterListItem extends StatelessWidget {
  final Reciter reciter;
  final VoidCallback onTap;

  const ReciterListItem({
    super.key,
    required this.reciter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<HapticProvider>().lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar / Initial
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  reciter.letter.isNotEmpty ? reciter.letter[0] : '?',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primaryBlue,
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
                    reciter.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Moshaf Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${reciter.moshaf.length} ${reciter.moshaf.length == 1 ? "Recitation" : "Recitations"}',
                      style: AppTypography.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ) ?? const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            const HeroIcon(
              HeroIcons.chevronRight,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
