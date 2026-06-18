import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_surface.dart';
import '../../data/models/support_feedback.dart';

Future<SupportFeedbackTopic?> showSupportFeedbackSheet({
  required BuildContext context,
  required SupportFeedbackTranslations translations,
}) {
  return showModalBottomSheet<SupportFeedbackTopic>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.r24)),
    ),
    builder: (context) {
      return SupportFeedbackSheet(translations: translations);
    },
  );
}

class SupportFeedbackSheet extends StatelessWidget {
  static const Key groupedTopicsKey = Key('support_feedback_group');

  final SupportFeedbackTranslations translations;

  const SupportFeedbackSheet({super.key, required this.translations});

  @override
  Widget build(BuildContext context) {
    final topics = SupportFeedbackTopic.values;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppTokens.s16,
            AppTokens.s8,
            AppTokens.s16,
            AppTokens.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(AppTokens.rFull),
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      translations.text(
                        'feedback.sheet_title',
                        'Support & Feedback',
                      ),
                      style: AppTypography.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      translations.text('feedback.cancel', 'Cancel'),
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              Flexible(
                child: SingleChildScrollView(
                  child: AppSurface(
                    key: groupedTopicsKey,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final entry in topics.indexed) ...[
                          _SupportFeedbackRow(
                            topic: entry.$2,
                            title: translations.topicTitle(entry.$2),
                            subtitle: translations.topicSubtitle(entry.$2),
                          ),
                          if (entry.$1 < topics.length - 1)
                            const Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: AppTokens.s48,
                              ),
                              child: Divider(
                                height: 1,
                                color: AppColors.neutral200,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportFeedbackRow extends StatelessWidget {
  final SupportFeedbackTopic topic;
  final String title;
  final String subtitle;

  const _SupportFeedbackRow({
    required this.topic,
    required this.title,
    required this.subtitle,
  });

  IconData get _icon {
    return switch (topic) {
      SupportFeedbackTopic.bugReport => Icons.bug_report_outlined,
      SupportFeedbackTopic.contentIssue => Icons.menu_book_outlined,
      SupportFeedbackTopic.featureSuggestion => Icons.lightbulb_outline,
      SupportFeedbackTopic.technicalSupport => Icons.support_outlined,
      SupportFeedbackTopic.generalFeedback => Icons.chat_bubble_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('support_feedback_topic_${topic.translationKey}'),
        onTap: () => Navigator.of(context).pop(topic),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          child: Row(
            children: [
              Icon(_icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Icon(
                isRtl ? Icons.chevron_left : Icons.chevron_right,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
