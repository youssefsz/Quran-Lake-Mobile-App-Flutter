import 'dart:ui';

enum SupportFeedbackTopic {
  bugReport,
  contentIssue,
  featureSuggestion,
  technicalSupport,
  generalFeedback;

  String get translationKey {
    return switch (this) {
      SupportFeedbackTopic.bugReport => 'bug_report',
      SupportFeedbackTopic.contentIssue => 'content_issue',
      SupportFeedbackTopic.featureSuggestion => 'feature_suggestion',
      SupportFeedbackTopic.technicalSupport => 'technical_support',
      SupportFeedbackTopic.generalFeedback => 'general_feedback',
    };
  }
}

class SupportDiagnostics {
  final String appName;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String? osVersion;
  final String? deviceManufacturer;
  final String? deviceModel;
  final Locale locale;

  const SupportDiagnostics({
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.locale,
    this.osVersion,
    this.deviceManufacturer,
    this.deviceModel,
  });
}

class SupportEmailDraft {
  final String recipient;
  final String subject;
  final String body;

  const SupportEmailDraft({
    required this.recipient,
    required this.subject,
    required this.body,
  });

  Uri get mailtoUri {
    return Uri.parse(
      'mailto:$recipient'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
  }
}

class SupportFeedbackTranslations {
  final Map<String, dynamic> values;

  const SupportFeedbackTranslations(this.values);

  String text(String path, String fallback) {
    dynamic value = values;
    for (final key in path.split('.')) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return fallback;
      }
    }
    return value is String && value.isNotEmpty ? value : fallback;
  }

  String topicTitle(SupportFeedbackTopic topic) {
    return text(
      'feedback.topics.${topic.translationKey}.title',
      _englishTopicTitle(topic),
    );
  }

  String topicSubtitle(SupportFeedbackTopic topic) {
    return text(
      'feedback.topics.${topic.translationKey}.subtitle',
      _englishTopicSubtitle(topic),
    );
  }

  String _englishTopicTitle(SupportFeedbackTopic topic) {
    return switch (topic) {
      SupportFeedbackTopic.bugReport => 'Bug Report',
      SupportFeedbackTopic.contentIssue => 'Content Issue',
      SupportFeedbackTopic.featureSuggestion => 'Feature Suggestion',
      SupportFeedbackTopic.technicalSupport => 'Technical Support',
      SupportFeedbackTopic.generalFeedback => 'General Feedback',
    };
  }

  String _englishTopicSubtitle(SupportFeedbackTopic topic) {
    return switch (topic) {
      SupportFeedbackTopic.bugReport =>
        'Something is broken or not behaving correctly.',
      SupportFeedbackTopic.contentIssue =>
        'Report an issue with Quran text, reciters, or other content.',
      SupportFeedbackTopic.featureSuggestion =>
        'Suggest a new feature or improvement.',
      SupportFeedbackTopic.technicalSupport =>
        'Get help with audio, prayer times, location, or app setup.',
      SupportFeedbackTopic.generalFeedback =>
        'Share anything else with the Quran Lake team.',
    };
  }
}
