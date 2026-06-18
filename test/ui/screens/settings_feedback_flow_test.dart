import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:quran_lake/core/theme/design_system.dart';
import 'package:quran_lake/data/models/support_feedback.dart';
import 'package:quran_lake/data/services/support_diagnostics_service.dart';
import 'package:quran_lake/data/services/support_email_service.dart';
import 'package:quran_lake/providers/haptic_provider.dart';
import 'package:quran_lake/providers/locale_provider.dart';
import 'package:quran_lake/ui/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_locale': 'en',
      'haptic_enabled': false,
    });
    PackageInfo.setMockInitialValues(
      appName: 'Quran Lake',
      packageName: 'tn.quranlake.app',
      version: '1.0.1',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('shows a localized error when email is unavailable', (
    tester,
  ) async {
    final diagnosticsProvider = _FakeDiagnosticsProvider();
    final emailService = SupportEmailService(
      launcher: _FakeEmailLauncher(canLaunchResult: false),
    );

    await tester.pumpWidget(
      _settingsApp(
        diagnosticsProvider: diagnosticsProvider,
        emailService: emailService,
      ),
    );
    await tester.pumpAndSettle();

    final settingsFeedbackRow = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.text('Support & Feedback'),
    );
    await tester.ensureVisible(settingsFeedbackRow);
    await tester.tap(settingsFeedbackRow);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('support_feedback_topic_bug_report')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not open an email app. Please try again.'),
      findsOneWidget,
    );
    expect(diagnosticsProvider.callCount, 1);
  });

  testWidgets('delays progress and prevents duplicate feedback work', (
    tester,
  ) async {
    final completer = Completer<SupportDiagnostics>();
    final diagnosticsProvider = _FakeDiagnosticsProvider(completer: completer);
    final emailService = SupportEmailService(launcher: _FakeEmailLauncher());

    await tester.pumpWidget(
      _settingsApp(
        diagnosticsProvider: diagnosticsProvider,
        emailService: emailService,
      ),
    );
    await tester.pumpAndSettle();

    final settingsFeedbackRow = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.text('Support & Feedback'),
    );
    await tester.ensureVisible(settingsFeedbackRow);
    await tester.tap(settingsFeedbackRow);
    await tester.pumpAndSettle();
    final generalFeedbackTopic = find.byKey(
      const Key('support_feedback_topic_general_feedback'),
    );
    await tester.ensureVisible(generalFeedbackTopic);
    await tester.pump();
    await tester.tap(generalFeedbackTopic);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(diagnosticsProvider.callCount, 1);

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final feedbackInkWell = find.ancestor(
      of: settingsFeedbackRow,
      matching: find.byType(InkWell),
    );
    expect(feedbackInkWell, findsNothing);
    expect(diagnosticsProvider.callCount, 1);

    completer.complete(_diagnostics);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

Widget _settingsApp({
  required SupportDiagnosticsProvider diagnosticsProvider,
  required SupportEmailService emailService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => HapticProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: SettingsScreen(
        supportDiagnosticsProvider: diagnosticsProvider,
        supportEmailService: emailService,
      ),
    ),
  );
}

const _diagnostics = SupportDiagnostics(
  appName: 'Quran Lake',
  appVersion: '1.0.1',
  buildNumber: '1',
  platform: 'iOS',
  osVersion: '26.5',
  deviceManufacturer: 'Apple',
  deviceModel: 'iPhone 16 Pro',
  locale: Locale('en'),
);

class _FakeDiagnosticsProvider implements SupportDiagnosticsProvider {
  final Completer<SupportDiagnostics>? completer;
  int callCount = 0;

  _FakeDiagnosticsProvider({this.completer});

  @override
  Future<SupportDiagnostics> collect(Locale locale) {
    callCount++;
    return completer?.future ?? Future.value(_diagnostics);
  }
}

class _FakeEmailLauncher implements SupportEmailLauncher {
  final bool canLaunchResult;

  const _FakeEmailLauncher({this.canLaunchResult = true});

  @override
  Future<bool> canLaunch(Uri uri) async => canLaunchResult;

  @override
  Future<bool> launch(Uri uri) async => true;
}
