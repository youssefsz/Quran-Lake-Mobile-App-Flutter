import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/locale_provider.dart';
import '../widgets/glass_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final hapticProvider = context.watch<HapticProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: _translations['title'] ?? 'Settings',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 16),
          children: [
            ListTile(
              title: Text(_translations['language'] ?? 'Language'),
              trailing: DropdownButton<Locale>(
                value: localeProvider.locale.languageCode == 'ar' 
                    ? const Locale('ar') 
                    : const Locale('en'),
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                ],
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    localeProvider.setLocale(newLocale);
                    // The UI will rebuild, and didChangeDependencies will re-fetch strings
                  }
                },
              ),
            ),
            ListTile(
              title: Text(_translations['haptics'] ?? 'Haptic Feedback'),
              trailing: Switch(
                value: hapticProvider.isEnabled,
                onChanged: (value) {
                  if (!value) {
                    hapticProvider.lightImpact();
                    hapticProvider.setEnabled(false);
                    return;
                  }
                  hapticProvider.setEnabled(true);
                  hapticProvider.lightImpact();
                },
              ),
            ),
            ListTile(
              title: Text(_translations['theme'] ?? 'Theme'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Implement Theme Switching
              },
            ),
            ListTile(
              title: Text(_translations['clear_cache'] ?? 'Clear Cache'),
              onTap: () {
                // TODO: Implement Cache Clearing
              },
            ),
          ],
        ),
      ),
    );
  }
}
