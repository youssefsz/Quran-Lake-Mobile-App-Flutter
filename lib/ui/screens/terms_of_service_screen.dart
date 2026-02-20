import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/locale_provider.dart';
import '../widgets/glass_app_bar.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
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
        title: _translations['terms'] ?? 'Terms of Service',
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
        'Please read these Terms of Service ("Terms") carefully before using the '
        'Quran Lake mobile application (the "App") operated by Quran Lake ("we", '
        '"us", or "our"). By downloading, installing, or using the App, you agree '
        'to be bound by these Terms. If you do not agree to these Terms, please do '
        'not use the App.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 1
      _heading('1. Acceptance of Terms'),
      _paragraph(
        'By accessing or using the App, you confirm that you have read, understood, '
        'and agree to be bound by these Terms and our Privacy Policy. These Terms '
        'apply to all users of the App.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 2
      _heading('2. Description of the App'),
      _paragraph(
        'Quran Lake is a free, non-commercial mobile application that provides:',
      ),
      const SizedBox(height: AppTokens.s8),
      _bulletBlock([
        'Streaming of Quran audio recitations from various reciters.',
        'A browsable directory of Quran reciters with multiple recitation styles '
            '(Moshafs) such as Hafs, Warsh, and others.',
        'Daily prayer times calculated based on your geographic location.',
        'A daily Ayah (verse) of the day feature.',
        'Background audio playback with notification controls.',
        'Bilingual interface supporting English and Arabic.',
      ]),
      _paragraph(
        'The App does not offer user accounts, social features, in-app purchases, '
        'subscriptions, or any form of paid content.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 3
      _heading('3. Eligibility'),
      _paragraph(
        'The App is available for use by individuals of all ages. The App contains '
        'exclusively religious and educational content (Quran recitations and '
        'prayer times) and does not require age verification. Minors should use '
        'the App under the guidance of a parent or legal guardian where required '
        'by applicable law.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 4
      _heading('4. License and Usage Rights'),
      const SizedBox(height: AppTokens.s12),
      _subheading('4.1 License Grant'),
      _paragraph(
        'We grant you a limited, non-exclusive, non-transferable, revocable license '
        'to download and use the App on your personal mobile device strictly in '
        'accordance with these Terms.',
      ),
      const SizedBox(height: AppTokens.s12),
      _subheading('4.2 Restrictions'),
      _paragraph('You agree not to:'),
      _bulletBlock([
        'Copy, modify, distribute, sell, or lease any part of the App.',
        'Reverse-engineer, decompile, or disassemble the App.',
        'Remove, alter, or obscure any copyright, trademark, or proprietary notices.',
        'Use the App for any unlawful or prohibited purpose.',
        'Attempt to gain unauthorized access to the App\'s systems or networks.',
        'Use the App to redistribute or re-stream Quran audio content without '
            'proper authorization from the original content providers.',
      ]),
      const SizedBox(height: AppTokens.s32),

      // 5
      _heading('5. Quran Audio Content'),
      _paragraph(
        'The Quran audio recitations available in the App are streamed from '
        'third-party servers (mp3quran.net). We do not claim ownership of these '
        'recordings. The audio content is provided for personal, non-commercial, '
        'and religious use only. All rights to the audio recordings remain with '
        'their respective reciters and content providers.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 6
      _heading('6. Prayer Times'),
      _paragraph(
        'Prayer times are calculated using the Aladhan API based on your geographic '
        'location. While we strive for accuracy, prayer times are provided as a '
        'convenience and may not perfectly match your local mosque or religious '
        'authority\'s schedule. We recommend consulting your local Islamic authority '
        'for critical prayer time decisions. We are not responsible for any '
        'inaccuracies in the prayer times displayed.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 7
      _heading('7. Third-Party Services'),
      _paragraph('The App relies on the following third-party services:'),
      const SizedBox(height: AppTokens.s8),
      _bulletBlock([
        'MP3 Quran API (mp3quran.net): For Quran reciters data and audio streaming.',
        'Aladhan API (aladhan.com): For prayer time calculations.',
        'BigDataCloud API (bigdatacloud.net): For reverse geocoding (location name lookup).',
      ]),
      _paragraph(
        'We do not control these third-party services and are not responsible for '
        'their availability, accuracy, or content. Your use of these services is '
        'also governed by their respective terms and policies. Interruptions or '
        'changes to these services may affect the App\'s functionality.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 8
      _heading('8. Intellectual Property'),
      _paragraph(
        'The App\'s design, user interface, code, and branding (including the name '
        '"Quran Lake" and associated logos) are the intellectual property of Quran '
        'Lake and are protected by applicable copyright and trademark laws. The '
        'Quran text and recitations are in the public domain or are the property '
        'of their respective reciters and publishers.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 9
      _heading('9. Disclaimers'),
      const SizedBox(height: AppTokens.s12),
      _subheading('9.1 "As Is" Basis'),
      _paragraph(
        'The App is provided on an "as is" and "as available" basis without '
        'warranties of any kind, either express or implied, including but not '
        'limited to implied warranties of merchantability, fitness for a '
        'particular purpose, or non-infringement.',
      ),
      const SizedBox(height: AppTokens.s12),
      _subheading('9.2 No Guarantee'),
      _paragraph(
        'We do not warrant that:\n'
        '• The App will be available at all times or without interruption.\n'
        '• The App will be free from errors, bugs, or vulnerabilities.\n'
        '• Audio streams will always be accessible or of consistent quality.\n'
        '• Prayer times will be perfectly accurate for every location.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 10
      _heading('10. Limitation of Liability'),
      _paragraph(
        'To the maximum extent permitted by applicable law, Quran Lake and its '
        'developers shall not be liable for any indirect, incidental, special, '
        'consequential, or punitive damages, or any loss of data, use, or profits, '
        'arising out of or related to your use of or inability to use the App, '
        'even if we have been advised of the possibility of such damages.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 11
      _heading('11. Internet Connection'),
      _paragraph(
        'The App requires an active internet connection to stream Quran audio and '
        'fetch prayer times. We are not responsible for any charges your mobile '
        'carrier or internet service provider may impose for data usage while '
        'using the App. We recommend using a Wi-Fi connection when streaming audio '
        'for extended periods.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 12
      _heading('12. App Updates'),
      _paragraph(
        'We may release updates to the App from time to time to improve '
        'functionality, fix issues, or comply with platform requirements. While we '
        'recommend keeping the App updated, we do not guarantee backward '
        'compatibility with older versions.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 13
      _heading('13. Termination'),
      _paragraph(
        'You may stop using the App at any time by uninstalling it from your '
        'device. We reserve the right to discontinue the App or any part of its '
        'functionality at any time without prior notice. Upon termination, '
        'all licenses granted to you under these Terms will immediately cease.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 14
      _heading('14. Governing Law'),
      _paragraph(
        'These Terms shall be governed by and construed in accordance with the '
        'laws of the jurisdiction in which Quran Lake operates, without regard '
        'to its conflict of law provisions. Any disputes arising from these Terms '
        'or your use of the App shall be resolved through good-faith negotiation '
        'before pursuing any formal legal proceedings.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 15
      _heading('15. Changes to These Terms'),
      _paragraph(
        'We reserve the right to modify these Terms at any time. Updated Terms '
        'will be posted within the App with a revised "Effective Date" at the top. '
        'Your continued use of the App after such changes constitutes your '
        'acceptance of the new Terms. We encourage you to review these Terms '
        'periodically.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 16
      _heading('16. Severability'),
      _paragraph(
        'If any provision of these Terms is found to be invalid or unenforceable '
        'by a court of competent jurisdiction, the remaining provisions shall '
        'continue in full force and effect.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 17
      _heading('17. Contact Us'),
      _paragraph(
        'If you have any questions or concerns about these Terms of Service, '
        'please contact us at:',
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
        'يرجى قراءة شروط الخدمة هذه ("الشروط") بعناية قبل استخدام تطبيق قرآن '
        'ليك للهاتف المحمول ("التطبيق") الذي يديره قرآن ليك ("نحن" أو "لنا"). '
        'بتحميل التطبيق أو تثبيته أو استخدامه، فإنك توافق على الالتزام بهذه '
        'الشروط. إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام التطبيق.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 1
      _heading('1. قبول الشروط'),
      _paragraph(
        'بالوصول إلى التطبيق أو استخدامه، تؤكد أنك قد قرأت وفهمت ووافقت على '
        'الالتزام بهذه الشروط وسياسة الخصوصية الخاصة بنا. تنطبق هذه الشروط على '
        'جميع مستخدمي التطبيق.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 2
      _heading('2. وصف التطبيق'),
      _paragraph('قرآن ليك هو تطبيق مجاني غير تجاري للهاتف المحمول يوفر:'),
      const SizedBox(height: AppTokens.s8),
      _bulletBlock([
        'بث تلاوات القرآن الكريم من مختلف القراء.',
        'دليل قابل للتصفح لقراء القرآن مع أساليب تلاوة متعددة (المصاحف) مثل '
            'حفص وورش وغيرها.',
        'مواقيت الصلاة اليومية المحسوبة بناءً على موقعك الجغرافي.',
        'ميزة آية اليوم.',
        'تشغيل الصوت في الخلفية مع عناصر التحكم في الإشعارات.',
        'واجهة ثنائية اللغة تدعم العربية والإنجليزية.',
      ]),
      _paragraph(
        'لا يقدم التطبيق حسابات مستخدمين أو ميزات اجتماعية أو مشتريات داخل '
        'التطبيق أو اشتراكات أو أي شكل من أشكال المحتوى المدفوع.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 3
      _heading('3. الأهلية'),
      _paragraph(
        'التطبيق متاح للاستخدام من قبل الأفراد من جميع الأعمار. يحتوي التطبيق '
        'حصرياً على محتوى ديني وتعليمي (تلاوات القرآن ومواقيت الصلاة) ولا يتطلب '
        'التحقق من العمر. يجب على القاصرين استخدام التطبيق تحت إشراف أحد الوالدين '
        'أو الوصي القانوني حيثما يتطلب القانون المعمول به.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 4
      _heading('4. الترخيص وحقوق الاستخدام'),
      const SizedBox(height: AppTokens.s12),
      _subheading('4.1 منح الترخيص'),
      _paragraph(
        'نمنحك ترخيصاً محدوداً وغير حصري وغير قابل للتحويل وقابل للإلغاء لتحميل '
        'واستخدام التطبيق على جهازك المحمول الشخصي بما يتوافق تماماً مع هذه '
        'الشروط.',
      ),
      const SizedBox(height: AppTokens.s12),
      _subheading('4.2 القيود'),
      _paragraph('توافق على عدم:'),
      _bulletBlock([
        'نسخ أو تعديل أو توزيع أو بيع أو تأجير أي جزء من التطبيق.',
        'إجراء هندسة عكسية أو تفكيك أو تحليل التطبيق.',
        'إزالة أو تغيير أو إخفاء أي إشعارات حقوق النشر أو العلامات التجارية.',
        'استخدام التطبيق لأي غرض غير قانوني أو محظور.',
        'محاولة الوصول غير المصرح به إلى أنظمة التطبيق أو شبكاته.',
        'استخدام التطبيق لإعادة توزيع أو إعادة بث محتوى القرآن الصوتي دون '
            'تصريح مناسب من مزودي المحتوى الأصليين.',
      ]),
      const SizedBox(height: AppTokens.s32),

      // 5
      _heading('5. محتوى القرآن الصوتي'),
      _paragraph(
        'تلاوات القرآن الكريم المتاحة في التطبيق يتم بثها من خوادم الطرف الثالث '
        '(mp3quran.net). نحن لا ندعي ملكية هذه التسجيلات. المحتوى الصوتي مقدم '
        'للاستخدام الشخصي وغير التجاري والديني فقط. جميع الحقوق في التسجيلات '
        'الصوتية تبقى لأصحابها من القراء ومزودي المحتوى.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 6
      _heading('6. مواقيت الصلاة'),
      _paragraph(
        'يتم حساب مواقيت الصلاة باستخدام واجهة Aladhan بناءً على موقعك الجغرافي. '
        'بينما نسعى للدقة، يتم توفير مواقيت الصلاة كوسيلة مساعدة وقد لا تتطابق '
        'تماماً مع جدول مسجدك المحلي أو سلطتك الدينية. نوصي بمراجعة سلطتك '
        'الإسلامية المحلية لقرارات مواقيت الصلاة الحرجة. نحن غير مسؤولين عن أي '
        'عدم دقة في مواقيت الصلاة المعروضة.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 7
      _heading('7. خدمات الطرف الثالث'),
      _paragraph('يعتمد التطبيق على خدمات الطرف الثالث التالية:'),
      const SizedBox(height: AppTokens.s8),
      _bulletBlock([
        'واجهة MP3 Quran (mp3quran.net): لبيانات قراء القرآن وبث الصوت.',
        'واجهة Aladhan (aladhan.com): لحسابات مواقيت الصلاة.',
        'واجهة BigDataCloud (bigdatacloud.net): للترميز الجغرافي العكسي '
            '(البحث عن اسم الموقع).',
      ]),
      _paragraph(
        'نحن لا نتحكم في خدمات الطرف الثالث هذه ولسنا مسؤولين عن توفرها أو '
        'دقتها أو محتواها. استخدامك لهذه الخدمات يخضع أيضاً لشروطها وسياساتها '
        'الخاصة. قد تؤثر الانقطاعات أو التغييرات في هذه الخدمات على وظائف التطبيق.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 8
      _heading('8. الملكية الفكرية'),
      _paragraph(
        'تصميم التطبيق وواجهة المستخدم والكود والعلامة التجارية (بما في ذلك اسم '
        '"قرآن ليك" والشعارات المرتبطة به) هي ملكية فكرية لقرآن ليك ومحمية '
        'بقوانين حقوق النشر والعلامات التجارية المعمول بها. نص القرآن والتلاوات '
        'في النطاق العام أو هي ملك لأصحابها من القراء والناشرين.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 9
      _heading('9. إخلاء المسؤولية'),
      const SizedBox(height: AppTokens.s12),
      _subheading('9.1 أساس "كما هو"'),
      _paragraph(
        'يُقدم التطبيق على أساس "كما هو" و"كما هو متاح" دون ضمانات من أي نوع، '
        'صريحة أو ضمنية، بما في ذلك على سبيل المثال لا الحصر الضمانات الضمنية '
        'للقابلية للتسويق أو الملاءمة لغرض معين أو عدم الانتهاك.',
      ),
      const SizedBox(height: AppTokens.s12),
      _subheading('9.2 عدم الضمان'),
      _paragraph(
        'نحن لا نضمن أن:\n'
        '• التطبيق سيكون متاحاً في جميع الأوقات أو دون انقطاع.\n'
        '• التطبيق سيكون خالياً من الأخطاء أو العيوب أو الثغرات الأمنية.\n'
        '• البث الصوتي سيكون دائماً متاحاً أو بجودة ثابتة.\n'
        '• مواقيت الصلاة ستكون دقيقة تماماً لكل موقع.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 10
      _heading('10. تحديد المسؤولية'),
      _paragraph(
        'إلى الحد الأقصى الذي يسمح به القانون المعمول به، لن يكون قرآن ليك '
        'ومطوروه مسؤولين عن أي أضرار غير مباشرة أو عرضية أو خاصة أو تبعية أو '
        'عقابية، أو أي فقدان للبيانات أو الاستخدام أو الأرباح، الناشئة عن أو '
        'المتعلقة باستخدامك أو عدم قدرتك على استخدام التطبيق، حتى لو تم إخطارنا '
        'بإمكانية حدوث مثل هذه الأضرار.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 11
      _heading('11. الاتصال بالإنترنت'),
      _paragraph(
        'يتطلب التطبيق اتصالاً نشطاً بالإنترنت لبث صوت القرآن وجلب مواقيت '
        'الصلاة. نحن غير مسؤولين عن أي رسوم قد يفرضها مزود خدمة الهاتف المحمول '
        'أو مزود خدمة الإنترنت الخاص بك لاستخدام البيانات أثناء استخدام التطبيق. '
        'نوصي باستخدام اتصال Wi-Fi عند بث الصوت لفترات طويلة.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 12
      _heading('12. تحديثات التطبيق'),
      _paragraph(
        'قد نصدر تحديثات للتطبيق من وقت لآخر لتحسين الوظائف أو إصلاح المشكلات '
        'أو الامتثال لمتطلبات المنصة. بينما نوصي بإبقاء التطبيق محدثاً، لا نضمن '
        'التوافق مع الإصدارات القديمة.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 13
      _heading('13. الإنهاء'),
      _paragraph(
        'يمكنك التوقف عن استخدام التطبيق في أي وقت عن طريق إلغاء تثبيته من '
        'جهازك. نحتفظ بالحق في إيقاف التطبيق أو أي جزء من وظائفه في أي وقت دون '
        'إشعار مسبق. عند الإنهاء، تنتهي فوراً جميع التراخيص الممنوحة لك بموجب '
        'هذه الشروط.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 14
      _heading('14. القانون الحاكم'),
      _paragraph(
        'تخضع هذه الشروط وتُفسر وفقاً لقوانين الولاية القضائية التي يعمل فيها '
        'قرآن ليك، بصرف النظر عن تعارض أحكامها القانونية. يتم حل أي نزاعات '
        'ناشئة عن هذه الشروط أو استخدامك للتطبيق من خلال التفاوض بحسن نية قبل '
        'اللجوء إلى أي إجراءات قانونية رسمية.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 15
      _heading('15. التغييرات على هذه الشروط'),
      _paragraph(
        'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم نشر الشروط المحدثة '
        'داخل التطبيق مع "تاريخ سريان" منقح في الأعلى. يعتبر استمرارك في استخدام '
        'التطبيق بعد هذه التغييرات قبولاً منك للشروط الجديدة. نشجعك على مراجعة '
        'هذه الشروط بشكل دوري.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 16
      _heading('16. قابلية الفصل'),
      _paragraph(
        'إذا تبين أن أي حكم من هذه الشروط غير صالح أو غير قابل للتنفيذ من قبل '
        'محكمة مختصة، فإن الأحكام المتبقية تظل سارية المفعول بالكامل.',
      ),
      const SizedBox(height: AppTokens.s32),

      // 17
      _heading('17. اتصل بنا'),
      _paragraph(
        'إذا كانت لديك أي أسئلة أو مخاوف بشأن شروط الخدمة هذه، يرجى التواصل '
        'معنا على:',
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
