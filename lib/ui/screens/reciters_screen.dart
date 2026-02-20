import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/haptic_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/reciter_provider.dart';
import '../widgets/reciter_list_item.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/app_error_widget.dart';
import 'reciter_details_screen.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  Map<String, dynamic> _translations = {};
  Map<String, dynamic> _errorTranslations = {};
  final TextEditingController _searchController = TextEditingController();
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    final localeProvider = context.read<LocaleProvider>();
    _translations = localeProvider.getCachedTranslations('reciters');
    _errorTranslations = localeProvider.getCachedTranslations('errors');
    _lastLocaleCode = localeProvider.locale.languageCode;
    _loadTranslations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReciterProvider>();
      if (provider.reciters.isEmpty && !provider.isLoading) {
        provider.fetchReciters(
          language: context.read<LocaleProvider>().locale.languageCode,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = context.watch<LocaleProvider>().locale.languageCode;
    if (_lastLocaleCode != localeCode) {
      _lastLocaleCode = localeCode;
      _loadTranslations();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ReciterProvider>().fetchReciters(language: localeCode);
      });
    }
  }

  Future<void> _loadTranslations() async {
    final provider = context.read<LocaleProvider>();
    final results = await Future.wait([
      provider.getScreenTranslations('reciters'),
      provider.getScreenTranslations('errors'),
    ]);
    if (mounted) {
      setState(() {
        _translations = results[0];
        _errorTranslations = results[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: _translations['title'] ?? 'Reciters'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
            ),
            // Modern Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      _translations['search_placeholder'] ??
                      'Search reciters...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.neutral400,
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                onChanged: (value) {
                  context.read<ReciterProvider>().search(value);
                },
              ),
            ),

            Expanded(
              child: Consumer<ReciterProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return _buildShimmerList();
                  }

                  if (provider.hasError) {
                    return AppErrorWidget(
                      errorType: provider.errorType ?? AppErrorType.unknown,
                      translations: _errorTranslations,
                      onRetry: () {
                        context.read<HapticProvider>().lightImpact();
                        provider.fetchReciters(
                          language: context
                              .read<LocaleProvider>()
                              .locale
                              .languageCode,
                        );
                      },
                    );
                  }

                  if (provider.reciters.isEmpty) {
                    return Center(
                      child: Text(
                        'No reciters found',
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: provider.reciters.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: AppColors.neutral200.withValues(alpha: 0.5),
                      indent: 82, // Align with text start
                      endIndent: 20,
                    ),
                    itemBuilder: (context, index) {
                      final reciter = provider.reciters[index];
                      return ReciterListItem(
                        reciter: reciter,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReciterDetailsScreen(reciter: reciter),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Shimmer.fromColors(
            baseColor: AppColors.neutral300,
            highlightColor: AppColors.neutral50,
            period: const Duration(milliseconds: 1400),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.neutral200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18,
                        width: 180,
                        color: AppColors.neutral200,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: 140,
                        color: AppColors.neutral200,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 20,
                        width: 88,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
