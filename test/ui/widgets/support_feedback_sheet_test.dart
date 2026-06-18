import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_lake/core/widgets/app_surface.dart';
import 'package:quran_lake/data/models/support_feedback.dart';
import 'package:quran_lake/ui/widgets/support_feedback_sheet.dart';

void main() {
  testWidgets('renders five topics in one grouped surface', (tester) async {
    await tester.pumpWidget(
      _testApp(
        textDirection: TextDirection.ltr,
        translations: SupportFeedbackTranslations(_englishTranslations),
      ),
    );

    expect(find.byKey(SupportFeedbackSheet.groupedTopicsKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(SupportFeedbackSheet.groupedTopicsKey),
        matching: find.byType(AppSurface),
      ),
      findsNothing,
    );
    expect(find.byType(Divider), findsNWidgets(4));
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));

    for (final topic in SupportFeedbackTopic.values) {
      final row = find.byKey(
        Key('support_feedback_topic_${topic.translationKey}'),
      );
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.byType(Container)),
        findsNothing,
      );
    }
  });

  testWidgets('returns the selected topic', (tester) async {
    SupportFeedbackTopic? selectedTopic;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  selectedTopic = await showSupportFeedbackSheet(
                    context: context,
                    translations: SupportFeedbackTranslations(
                      _englishTranslations,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('support_feedback_topic_content_issue')),
    );
    await tester.pumpAndSettle();

    expect(selectedTopic, SupportFeedbackTopic.contentIssue);
  });

  testWidgets('cancel dismisses the sheet with no selection', (tester) async {
    SupportFeedbackTopic? selectedTopic = SupportFeedbackTopic.bugReport;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  selectedTopic = await showSupportFeedbackSheet(
                    context: context,
                    translations: SupportFeedbackTranslations(
                      _englishTranslations,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(selectedTopic, isNull);
  });

  testWidgets('renders Arabic content with RTL chevrons', (tester) async {
    await tester.pumpWidget(
      _testApp(
        textDirection: TextDirection.rtl,
        translations: SupportFeedbackTranslations(_arabicTranslations),
      ),
    );

    expect(find.text('الدعم والملاحظات'), findsOneWidget);
    expect(find.text('الإبلاغ عن خلل'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNWidgets(5));
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}

Widget _testApp({
  required TextDirection textDirection,
  required SupportFeedbackTranslations translations,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: SupportFeedbackSheet(translations: translations)),
    ),
  );
}

const _englishTranslations = <String, dynamic>{
  'feedback': {
    'sheet_title': 'Support & Feedback',
    'cancel': 'Cancel',
    'topics': {
      'bug_report': {'title': 'Bug Report', 'subtitle': 'Bug subtitle'},
      'content_issue': {
        'title': 'Content Issue',
        'subtitle': 'Content subtitle',
      },
      'feature_suggestion': {
        'title': 'Feature Suggestion',
        'subtitle': 'Feature subtitle',
      },
      'technical_support': {
        'title': 'Technical Support',
        'subtitle': 'Support subtitle',
      },
      'general_feedback': {
        'title': 'General Feedback',
        'subtitle': 'General subtitle',
      },
    },
  },
};

const _arabicTranslations = <String, dynamic>{
  'feedback': {
    'sheet_title': 'الدعم والملاحظات',
    'cancel': 'إلغاء',
    'topics': {
      'bug_report': {'title': 'الإبلاغ عن خلل', 'subtitle': 'وصف الخلل'},
      'content_issue': {'title': 'مشكلة في المحتوى', 'subtitle': 'وصف المحتوى'},
      'feature_suggestion': {'title': 'اقتراح ميزة', 'subtitle': 'وصف الميزة'},
      'technical_support': {'title': 'الدعم الفني', 'subtitle': 'وصف الدعم'},
      'general_feedback': {
        'title': 'ملاحظات عامة',
        'subtitle': 'وصف الملاحظات',
      },
    },
  },
};
