import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/locale_provider.dart';
import '../widgets/glass_app_bar.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Map<String, dynamic> _translations = {};
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    _translations = localeProvider.getCachedTranslations('settings');
    _lastLocaleCode = localeProvider.locale.languageCode;
    _loadTranslations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = context.watch<LocaleProvider>().locale.languageCode;
    if (_lastLocaleCode != localeCode) {
      _lastLocaleCode = localeCode;
      _loadTranslations();
    }
  }

  Future<void> _loadTranslations() async {
    final provider = context.read<LocaleProvider>();
    final translations = await provider.getScreenTranslations('settings');
    if (mounted) {
      setState(() {
        _translations = translations;
      });
    }
  }

  bool get _isArabic => _lastLocaleCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: _translations['privacy'] ?? 'Privacy Policy',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppTokens.s16,
            kToolbarHeight + MediaQuery.of(context).padding.top + AppTokens.s16,
            AppTokens.s16,
            AppTokens.s40,
          ),
          children: _isArabic ? _buildArabicContent() : _buildEnglishContent(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // English Content
  // ---------------------------------------------------------------------------
  List<Widget> _buildEnglishContent() {
    return [
      _effectiveDate('February 20, 2026'),
      const SizedBox(height: AppTokens.s24),
      _paragraph(
        'Quran Lake ("we", "us", or "our") operates the Quran Lake mobile application '
        '(the "App"). This Privacy Policy explains how we collect, use, and protect '
        'information when you use our App. By using the App, you agree to the practices '
        'described in this policy.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 1
      _heading('1. Information We Collect'),
      const SizedBox(height: AppTokens.s12),
      _subheading('1.1 Location Data'),
      _paragraph(
        'When you use the Prayer Times feature, the App requests access to your '
        'device\'s location services (GPS). We use your geographic coordinates '
        '(latitude and longitude) solely to calculate accurate prayer times for '
        'your area and to display your city and country name. Location data is '
        'processed in real time and is not transmitted to our servers.',
      ),
      const SizedBox(height: AppTokens.s12),
      _subheading('1.2 Locally Stored Data'),
      _paragraph(
        'The App stores the following data locally on your device:\n'
        '• Prayer times cache: Cached prayer schedule data for the current day, '
        'stored in a local SQLite database to reduce network requests.\n'
        '• Language preference: Your chosen language setting (English or Arabic), '
        'stored via SharedPreferences.\n'
        '• Onboarding status: A flag indicating whether you have completed the '
        'initial setup, stored via SharedPreferences.\n'
        '• Haptic feedback preference: Your haptic feedback toggle state, stored '
        'via SharedPreferences.',
      ),
      const SizedBox(height: AppTokens.s12),
      _subheading('1.3 Information We Do Not Collect'),
      _paragraph(
        'We do not collect, store, or process any of the following:\n'
        '• Personal identification information (name, email, phone number)\n'
        '• User accounts, login credentials, or passwords\n'
        '• Payment or financial information\n'
        '• Usage analytics or behavioral tracking data\n'
        '• Advertising identifiers\n'
        '• Contacts, photos, or other device data\n'
        '• Cookies or web tracking technologies',
      ),
      const SizedBox(height: AppTokens.s32),

      // 2
      _heading('2. How We Use Information'),
      _paragraph(
        'The limited data we process is used exclusively for the following purposes:\n'
        '• Calculating and displaying accurate prayer times based on your location.\n'
        '• Displaying your city and country name on the Prayer Times screen.\n'
        '• Remembering your language and app preferences between sessions.\n'
        '• Streaming Quran audio recitations from third-party servers.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 3
      _heading('3. Third-Party Services'),
      _paragraph(
        'The App communicates with the following third-party services to provide '
        'its core functionality:',
      ),
      const SizedBox(height: AppTokens.s8),
      _bulletBlock([
        'MP3 Quran API (mp3quran.net): Used to retrieve the list of Quran reciters, '
            'available recitation styles (Moshafs), and to stream Quran audio. No personal '
            'data is sent to this service.',
        'Aladhan API (aladhan.com): Used to retrieve prayer times based on geographic '
            'coordinates. Only your latitude and longitude are sent; no personal identifiers '
            'are included.',
        'BigDataCloud API (bigdatacloud.net): Used for reverse geocoding to convert your '
            'coordinates into a human-readable city and country name. Only your latitude and '
            'longitude are sent.',
      ]),
      _paragraph(
        'Each of these services has its own privacy policy. We encourage you to review '
        'them. We do not control how these third parties handle data.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 4
      _heading('4. Data Storage and Security'),
      _paragraph(
        'All data is stored locally on your device. We do not operate any backend '
        'servers, databases, or cloud storage. The App does not transmit any personal '
        'information over the internet. Your cached prayer times and preferences remain '
        'on your device and are deleted when you uninstall the App or clear the App\'s data.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 5
      _heading('5. Data Retention'),
      _paragraph(
        'Since all data is stored locally on your device:\n'
        '• Prayer time caches are refreshed daily and overwritten automatically.\n'
        '• Preferences persist until you change them, clear the App data, or uninstall the App.\n'
        '• You can clear cached prayer times at any time from the Prayer Times screen.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 6
      _heading('6. Permissions'),
      _paragraph('The App may request the following permissions:'),
      const SizedBox(height: AppTokens.s8),
      _bulletBlock([
        'Location (When In Use): Required for the Prayer Times feature to calculate '
            'accurate prayer schedules for your area. You can deny this permission; the '
            'Prayer Times feature will not function without it, but all other App features '
            'will continue to work normally.',
        'Internet Access: Required to stream Quran audio and to fetch prayer times from '
            'external APIs.',
        'Notifications: Used to display audio playback controls in the notification area '
            'while listening to Quran recitations in the background.',
        'Background Audio: Allows Quran audio to continue playing when the App is '
            'minimized or the screen is locked.',
      ]),
      const SizedBox(height: AppTokens.s32),

      // 7
      _heading('7. Children\'s Privacy'),
      _paragraph(
        'The App is suitable for users of all ages and contains exclusively religious '
        'and educational content (Quran recitations and prayer times). We do not '
        'knowingly collect personal information from children under 13 (or the applicable '
        'age in your jurisdiction). Since the App does not collect personal information '
        'from any user, no special measures for children\'s data are necessary.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 8
      _heading('8. Your Rights'),
      _paragraph(
        'Because we do not collect or store personal data on our servers, traditional '
        'data access, correction, or deletion requests do not apply. However, you '
        'have full control over locally stored data:\n'
        '• You can clear cached data through the App or your device settings.\n'
        '• You can revoke location permission at any time through your device settings.\n'
        '• You can uninstall the App to remove all locally stored data.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 9
      _heading('9. Monetization'),
      _paragraph(
        'The App is entirely free to use. We do not display advertisements, offer '
        'in-app purchases, or use any form of monetization. The App does not contain '
        'any paid features or subscriptions.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 10
      _heading('10. Changes to This Policy'),
      _paragraph(
        'We may update this Privacy Policy from time to time. Any changes will be '
        'reflected in the App with an updated "Effective Date" at the top of this page. '
        'Your continued use of the App after changes are posted constitutes your '
        'acceptance of the updated policy.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 11
      _heading('11. Contact Us'),
      _paragraph(
        'If you have any questions, concerns, or requests regarding this Privacy '
        'Policy, please contact us at:',
      ),
      const SizedBox(height: AppTokens.s8),
      _emailLink('dhibi.ywsf@gmail.com'),
    ];
  }

  // ---------------------------------------------------------------------------
  // Arabic Content
  // ---------------------------------------------------------------------------
  List<Widget> _buildArabicContent() {
    return [
      _effectiveDate('20 فبراير 2026'),
      const SizedBox(height: AppTokens.s24),
      _paragraph(
        'يدير تطبيق قرآن ليك ("نحن" أو "لنا") تطبيق قرآن ليك للهاتف المحمول '
        '("التطبيق"). توضح سياسة الخصوصية هذه كيفية جمع المعلومات واستخدامها '
        'وحمايتها عند استخدامك للتطبيق. باستخدامك للتطبيق، فإنك توافق على '
        'الممارسات الموضحة في هذه السياسة.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 1
      _heading('1. المعلومات التي نجمعها'),
      const SizedBox(height: AppTokens.s12),
      _subheading('1.1 بيانات الموقع'),
      _paragraph(
        'عند استخدامك لميزة مواقيت الصلاة، يطلب التطبيق الوصول إلى خدمات الموقع '
        '(GPS) على جهازك. نستخدم إحداثياتك الجغرافية (خط العرض وخط الطول) فقط '
        'لحساب مواقيت الصلاة الدقيقة لمنطقتك وعرض اسم مدينتك وبلدك. تتم معالجة '
        'بيانات الموقع في الوقت الفعلي ولا يتم إرسالها إلى خوادمنا.',
      ),
      const SizedBox(height: AppTokens.s12),
      _subheading('1.2 البيانات المخزنة محلياً'),
      _paragraph(
        'يخزن التطبيق البيانات التالية محلياً على جهازك:\n'
        '• ذاكرة مواقيت الصلاة: بيانات جدول الصلاة المؤقتة لليوم الحالي، مخزنة '
        'في قاعدة بيانات SQLite محلية لتقليل طلبات الشبكة.\n'
        '• تفضيل اللغة: إعداد اللغة المختارة (العربية أو الإنجليزية)، مخزن عبر '
        'SharedPreferences.\n'
        '• حالة التعريف بالتطبيق: علامة تشير إلى إكمالك للإعداد الأولي، مخزنة '
        'عبر SharedPreferences.\n'
        '• تفضيل الاهتزاز: حالة مفتاح الاهتزاز، مخزنة عبر SharedPreferences.',
      ),
      const SizedBox(height: AppTokens.s12),
      _subheading('1.3 معلومات لا نجمعها'),
      _paragraph(
        'لا نجمع أو نخزن أو نعالج أياً مما يلي:\n'
        '• معلومات التعريف الشخصية (الاسم، البريد الإلكتروني، رقم الهاتف)\n'
        '• حسابات المستخدمين أو بيانات تسجيل الدخول أو كلمات المرور\n'
        '• معلومات الدفع أو المعلومات المالية\n'
        '• بيانات تحليلات الاستخدام أو التتبع السلوكي\n'
        '• معرفات الإعلانات\n'
        '• جهات الاتصال أو الصور أو بيانات الجهاز الأخرى\n'
        '• ملفات تعريف الارتباط أو تقنيات التتبع عبر الويب',
      ),
      const SizedBox(height: AppTokens.s32),

      // 2
      _heading('2. كيف نستخدم المعلومات'),
      _paragraph(
        'تُستخدم البيانات المحدودة التي نعالجها حصرياً للأغراض التالية:\n'
        '• حساب وعرض مواقيت الصلاة الدقيقة بناءً على موقعك.\n'
        '• عرض اسم مدينتك وبلدك في شاشة مواقيت الصلاة.\n'
        '• تذكر تفضيلات اللغة والتطبيق بين الجلسات.\n'
        '• بث تلاوات القرآن الكريم من خوادم الطرف الثالث.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 3
      _heading('3. خدمات الطرف الثالث'),
      _paragraph(
        'يتواصل التطبيق مع خدمات الطرف الثالث التالية لتوفير وظائفه الأساسية:',
      ),
      const SizedBox(height: AppTokens.s8),
      _bulletBlock([
        'واجهة MP3 Quran (mp3quran.net): تُستخدم لاسترجاع قائمة قراء القرآن '
            'وأساليب التلاوة المتاحة (المصاحف) ولبث صوت القرآن. لا يتم إرسال أي '
            'بيانات شخصية لهذه الخدمة.',
        'واجهة Aladhan (aladhan.com): تُستخدم لاسترجاع مواقيت الصلاة بناءً على '
            'الإحداثيات الجغرافية. يتم إرسال خط العرض والطول فقط؛ ولا يتم تضمين أي '
            'معرفات شخصية.',
        'واجهة BigDataCloud (bigdatacloud.net): تُستخدم للترميز الجغرافي العكسي '
            'لتحويل إحداثياتك إلى اسم مدينة وبلد مقروء. يتم إرسال خط العرض والطول فقط.',
      ]),
      _paragraph(
        'لكل من هذه الخدمات سياسة خصوصية خاصة بها. نشجعك على مراجعتها. نحن لا '
        'نتحكم في كيفية تعامل هذه الأطراف الثالثة مع البيانات.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 4
      _heading('4. تخزين البيانات والأمان'),
      _paragraph(
        'يتم تخزين جميع البيانات محلياً على جهازك. نحن لا ندير أي خوادم خلفية أو '
        'قواعد بيانات أو تخزين سحابي. لا ينقل التطبيق أي معلومات شخصية عبر '
        'الإنترنت. تبقى مواقيت الصلاة المؤقتة وتفضيلاتك على جهازك ويتم حذفها '
        'عند إلغاء تثبيت التطبيق أو مسح بيانات التطبيق.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 5
      _heading('5. الاحتفاظ بالبيانات'),
      _paragraph(
        'بما أن جميع البيانات مخزنة محلياً على جهازك:\n'
        '• يتم تحديث ذاكرة مواقيت الصلاة يومياً واستبدالها تلقائياً.\n'
        '• تستمر التفضيلات حتى تغييرها أو مسح بيانات التطبيق أو إلغاء تثبيته.\n'
        '• يمكنك مسح مواقيت الصلاة المؤقتة في أي وقت من شاشة مواقيت الصلاة.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 6
      _heading('6. الأذونات'),
      _paragraph('قد يطلب التطبيق الأذونات التالية:'),
      const SizedBox(height: AppTokens.s8),
      _bulletBlock([
        'الموقع (أثناء الاستخدام): مطلوب لميزة مواقيت الصلاة لحساب جداول الصلاة '
            'الدقيقة لمنطقتك. يمكنك رفض هذا الإذن؛ لن تعمل ميزة مواقيت الصلاة بدونه، '
            'لكن جميع ميزات التطبيق الأخرى ستستمر في العمل بشكل طبيعي.',
        'الوصول إلى الإنترنت: مطلوب لبث صوت القرآن ولجلب مواقيت الصلاة من '
            'الواجهات البرمجية الخارجية.',
        'الإشعارات: تُستخدم لعرض عناصر التحكم في تشغيل الصوت في منطقة الإشعارات '
            'أثناء الاستماع إلى تلاوات القرآن في الخلفية.',
        'الصوت في الخلفية: يسمح لصوت القرآن بالاستمرار في التشغيل عند تصغير '
            'التطبيق أو قفل الشاشة.',
      ]),
      const SizedBox(height: AppTokens.s32),

      // 7
      _heading('7. خصوصية الأطفال'),
      _paragraph(
        'التطبيق مناسب لجميع الأعمار ويحتوي حصرياً على محتوى ديني وتعليمي '
        '(تلاوات القرآن ومواقيت الصلاة). نحن لا نجمع عن قصد معلومات شخصية من '
        'الأطفال دون 13 عاماً (أو السن المطبق في نطاقك القضائي). بما أن التطبيق '
        'لا يجمع معلومات شخصية من أي مستخدم، فلا يلزم اتخاذ تدابير خاصة لبيانات '
        'الأطفال.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 8
      _heading('8. حقوقك'),
      _paragraph(
        'نظراً لأننا لا نجمع أو نخزن بيانات شخصية على خوادمنا، فإن طلبات الوصول '
        'إلى البيانات أو تصحيحها أو حذفها التقليدية لا تنطبق. ومع ذلك، لديك '
        'السيطرة الكاملة على البيانات المخزنة محلياً:\n'
        '• يمكنك مسح البيانات المؤقتة من خلال التطبيق أو إعدادات جهازك.\n'
        '• يمكنك إلغاء إذن الموقع في أي وقت من خلال إعدادات جهازك.\n'
        '• يمكنك إلغاء تثبيت التطبيق لإزالة جميع البيانات المخزنة محلياً.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 9
      _heading('9. التسييل'),
      _paragraph(
        'التطبيق مجاني بالكامل. نحن لا نعرض إعلانات أو نقدم مشتريات داخل التطبيق '
        'أو نستخدم أي شكل من أشكال التسييل. لا يحتوي التطبيق على أي ميزات مدفوعة '
        'أو اشتراكات.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 10
      _heading('10. التغييرات على هذه السياسة'),
      _paragraph(
        'قد نقوم بتحديث سياسة الخصوصية هذه من وقت لآخر. ستنعكس أي تغييرات في '
        'التطبيق مع تاريخ "تاريخ السريان" محدث في أعلى هذه الصفحة. يعتبر استمرارك '
        'في استخدام التطبيق بعد نشر التغييرات قبولاً منك للسياسة المحدثة.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 11
      _heading('11. اتصل بنا'),
      _paragraph(
        'إذا كانت لديك أي أسئلة أو مخاوف أو طلبات بخصوص سياسة الخصوصية هذه، '
        'يرجى التواصل معنا على:',
      ),
      const SizedBox(height: AppTokens.s8),
      _emailLink('dhibi.ywsf@gmail.com'),
    ];
  }

  // ---------------------------------------------------------------------------
  // Markdown-style UI widgets
  // ---------------------------------------------------------------------------

  Widget _effectiveDate(String date) {
    return Text(
      _isArabic ? 'تاريخ السريان: $date' : 'Effective Date: $date',
      style: AppTypography.labelMedium.copyWith(color: AppColors.neutral500),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: Text(
        text,
        style: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _subheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s4),
      child: Text(
        text,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.neutral700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s4),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral600,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _bulletBlock(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: AppTokens.s8,
              left: _isArabic ? 0 : AppTokens.s8,
              right: _isArabic ? AppTokens.s8 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(AppTokens.rFull),
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emailLink(String email) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri(
          scheme: 'mailto',
          path: email,
          queryParameters: {'subject': 'Quran Lake Support'},
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Text(
        email,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
