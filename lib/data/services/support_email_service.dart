import 'package:url_launcher/url_launcher.dart';

import '../models/support_feedback.dart';

enum SupportEmailResult { sent, unavailable, failed }

abstract interface class SupportEmailLauncher {
  Future<bool> canLaunch(Uri uri);

  Future<bool> launch(Uri uri);
}

class UrlLauncherSupportEmailLauncher implements SupportEmailLauncher {
  const UrlLauncherSupportEmailLauncher();

  @override
  Future<bool> canLaunch(Uri uri) => canLaunchUrl(uri);

  @override
  Future<bool> launch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class SupportEmailService {
  static const String defaultRecipient = 'dhibi.ywsf@gmail.com';

  final SupportEmailLauncher _launcher;
  final String recipient;

  const SupportEmailService({
    SupportEmailLauncher launcher = const UrlLauncherSupportEmailLauncher(),
    this.recipient = defaultRecipient,
  }) : _launcher = launcher;

  SupportEmailDraft createDraft({
    required SupportFeedbackTopic topic,
    required SupportDiagnostics diagnostics,
    required SupportFeedbackTranslations translations,
  }) {
    final unavailable = translations.text(
      'feedback.email.unavailable',
      'Unavailable',
    );
    final topicTitle = translations.topicTitle(topic);
    final languageName = translations.text(
      'feedback.email.language_name',
      diagnostics.locale.languageCode,
    );

    String valueOrFallback(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? unavailable : trimmed;
    }

    final subject = translations
        .text('feedback.email.subject', 'Quran Lake Support - {topic}')
        .replaceAll('{topic}', topicTitle);
    final body = [
      translations.text('feedback.email.greeting', 'Hi Quran Lake Support,'),
      '',
      '${translations.text('feedback.email.request_type', 'Request Type')}: $topicTitle',
      '',
      '${translations.text('feedback.email.app', 'App')}: ${diagnostics.appName}',
      '${translations.text('feedback.email.app_version', 'App Version')}: ${valueOrFallback(diagnostics.appVersion)}',
      '${translations.text('feedback.email.build_number', 'Build Number')}: ${valueOrFallback(diagnostics.buildNumber)}',
      '${translations.text('feedback.email.platform', 'Platform')}: ${valueOrFallback(diagnostics.platform)}',
      '${translations.text('feedback.email.os_version', 'OS Version')}: ${valueOrFallback(diagnostics.osVersion)}',
      '${translations.text('feedback.email.device_manufacturer', 'Device Manufacturer')}: ${valueOrFallback(diagnostics.deviceManufacturer)}',
      '${translations.text('feedback.email.device_model', 'Device Model')}: ${valueOrFallback(diagnostics.deviceModel)}',
      '${translations.text('feedback.email.app_language', 'App Language')}: $languageName',
      '',
      '--------------------',
      '${translations.text('feedback.email.message', 'Message')}:',
      '',
    ].join('\n');

    return SupportEmailDraft(
      recipient: recipient,
      subject: subject,
      body: body,
    );
  }

  Future<SupportEmailResult> send(SupportEmailDraft draft) async {
    try {
      final uri = draft.mailtoUri;
      if (!await _launcher.canLaunch(uri)) {
        return SupportEmailResult.unavailable;
      }
      return await _launcher.launch(uri)
          ? SupportEmailResult.sent
          : SupportEmailResult.failed;
    } catch (_) {
      return SupportEmailResult.failed;
    }
  }
}
