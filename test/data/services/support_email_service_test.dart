import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_lake/data/models/support_feedback.dart';
import 'package:quran_lake/data/services/support_email_service.dart';

void main() {
  group('SupportEmailService', () {
    test('creates an English draft with percent-encoded spaces', () {
      final service = SupportEmailService(launcher: _FakeLauncher());
      final draft = service.createDraft(
        topic: SupportFeedbackTopic.bugReport,
        diagnostics: _diagnostics(const Locale('en')),
        translations: SupportFeedbackTranslations(_englishTranslations),
      );

      expect(draft.subject, 'Quran Lake Support - Bug Report');
      expect(draft.body, contains('App Version: 1.0.1'));
      expect(draft.body, contains('Device Manufacturer: Apple'));
      expect(draft.body, contains('App Language: English'));
      expect(draft.mailtoUri.toString(), isNot(contains('+')));
      expect(
        draft.mailtoUri.queryParameters['body'],
        contains('Request Type: Bug Report'),
      );
    });

    test('creates an Arabic draft and localizes unavailable values', () {
      final service = SupportEmailService(launcher: _FakeLauncher());
      final draft = service.createDraft(
        topic: SupportFeedbackTopic.technicalSupport,
        diagnostics: SupportDiagnostics(
          appName: 'Quran Lake',
          appVersion: '1.0.1',
          buildNumber: '1',
          platform: 'Linux',
          locale: const Locale('ar'),
        ),
        translations: SupportFeedbackTranslations(_arabicTranslations),
      );

      expect(draft.subject, 'دعم قرآن ليك - الدعم الفني');
      expect(draft.body, contains('نوع الطلب: الدعم الفني'));
      expect(draft.body, contains('طراز الجهاز: غير متوفر'));
      expect(draft.body, contains('لغة التطبيق: العربية'));
    });

    test('returns sent when the launcher succeeds', () async {
      final launcher = _FakeLauncher();
      final service = SupportEmailService(launcher: launcher);

      final result = await service.send(_draft);

      expect(result, SupportEmailResult.sent);
      expect(launcher.launchCount, 1);
    });

    test('returns unavailable without launching', () async {
      final launcher = _FakeLauncher(canLaunchResult: false);
      final service = SupportEmailService(launcher: launcher);

      final result = await service.send(_draft);

      expect(result, SupportEmailResult.unavailable);
      expect(launcher.launchCount, 0);
    });

    test('returns failed when the launcher throws', () async {
      final launcher = _FakeLauncher(throwOnLaunch: true);
      final service = SupportEmailService(launcher: launcher);

      final result = await service.send(_draft);

      expect(result, SupportEmailResult.failed);
    });
  });
}

SupportDiagnostics _diagnostics(Locale locale) {
  return SupportDiagnostics(
    appName: 'Quran Lake',
    appVersion: '1.0.1',
    buildNumber: '1',
    platform: 'iOS',
    osVersion: '26.5',
    deviceManufacturer: 'Apple',
    deviceModel: 'iPhone 16 Pro',
    locale: locale,
  );
}

const _draft = SupportEmailDraft(
  recipient: 'support@example.com',
  subject: 'Support Request',
  body: 'Message body',
);

const _englishTranslations = <String, dynamic>{
  'feedback': {
    'topics': {
      'bug_report': {'title': 'Bug Report'},
    },
    'email': {
      'subject': 'Quran Lake Support - {topic}',
      'greeting': 'Hi Quran Lake Support,',
      'request_type': 'Request Type',
      'app': 'App',
      'app_version': 'App Version',
      'build_number': 'Build Number',
      'platform': 'Platform',
      'os_version': 'OS Version',
      'device_manufacturer': 'Device Manufacturer',
      'device_model': 'Device Model',
      'app_language': 'App Language',
      'language_name': 'English',
      'message': 'Message',
      'unavailable': 'Unavailable',
    },
  },
};

const _arabicTranslations = <String, dynamic>{
  'feedback': {
    'topics': {
      'technical_support': {'title': 'الدعم الفني'},
    },
    'email': {
      'subject': 'دعم قرآن ليك - {topic}',
      'greeting': 'مرحبًا فريق دعم قرآن ليك،',
      'request_type': 'نوع الطلب',
      'app': 'التطبيق',
      'app_version': 'إصدار التطبيق',
      'build_number': 'رقم البناء',
      'platform': 'المنصة',
      'os_version': 'إصدار نظام التشغيل',
      'device_manufacturer': 'الشركة المصنعة للجهاز',
      'device_model': 'طراز الجهاز',
      'app_language': 'لغة التطبيق',
      'language_name': 'العربية',
      'message': 'الرسالة',
      'unavailable': 'غير متوفر',
    },
  },
};

class _FakeLauncher implements SupportEmailLauncher {
  final bool canLaunchResult;
  final bool throwOnLaunch;
  int launchCount = 0;

  _FakeLauncher({this.canLaunchResult = true, this.throwOnLaunch = false});

  @override
  Future<bool> canLaunch(Uri uri) async => canLaunchResult;

  @override
  Future<bool> launch(Uri uri) async {
    launchCount++;
    if (throwOnLaunch) {
      throw StateError('Launcher failed');
    }
    return true;
  }
}
