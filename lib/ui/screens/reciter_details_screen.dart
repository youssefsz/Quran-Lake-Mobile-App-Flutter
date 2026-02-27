import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/reciter.dart';
import '../../providers/audio_provider.dart';
import '../../providers/reciter_provider.dart';
import '../../providers/surah_provider.dart';
import '../../providers/locale_provider.dart';
import '../widgets/surah_list_item.dart';
import '../widgets/searchable_glass_app_bar.dart';
import '../widgets/mini_player.dart';

class ReciterDetailsScreen extends StatefulWidget {
  final Reciter reciter;

  const ReciterDetailsScreen({super.key, required this.reciter});

  @override
  State<ReciterDetailsScreen> createState() => _ReciterDetailsScreenState();
}

class _ReciterDetailsScreenState extends State<ReciterDetailsScreen> {
  late Reciter _reciter;
  late Moshaf _selectedMoshaf;
  String _searchQuery = '';
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    _reciter = widget.reciter;
    _selectedMoshaf = _reciter.moshaf.first;
    _lastLocaleCode = context.read<LocaleProvider>().locale.languageCode;

    // Ensure Surahs are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final surahProvider = context.read<SurahProvider>();
      if (surahProvider.surahs.isEmpty) {
        surahProvider.fetchSurahs(
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshLocaleData(localeCode);
      });
    }
  }

  Future<void> _refreshLocaleData(String localeCode) async {
    final reciterProvider = context.read<ReciterProvider>();
    final surahProvider = context.read<SurahProvider>();

    await Future.wait([
      reciterProvider.fetchReciters(language: localeCode),
      surahProvider.fetchSurahs(language: localeCode),
    ]);

    if (!mounted) return;

    final updatedReciter = reciterProvider.getReciterById(_reciter.id);
    if (updatedReciter != null) {
      setState(() {
        _reciter = updatedReciter;
        if (_reciter.moshaf.isNotEmpty) {
          final selectedId = _selectedMoshaf.id;
          final hasSelected = _reciter.moshaf.any((m) => m.id == selectedId);
          _selectedMoshaf = hasSelected
              ? _reciter.moshaf.firstWhere((m) => m.id == selectedId)
              : _reciter.moshaf.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahProvider = context.watch<SurahProvider>();
    final audioProvider = context.watch<AudioProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SearchableGlassAppBar(
        title: _reciter.name,
        searchHint: 'Search Surah...',
        onSearchChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        extraActions: [
          // Moshaf selector — only shown when multiple recitation styles exist.
          if (_reciter.moshaf.length > 1)
            PopupMenuButton<Moshaf>(
              icon: const Icon(Icons.library_music_outlined),
              tooltip: 'Recitation Style',
              onSelected: (value) {
                setState(() {
                  _selectedMoshaf = value;
                });
              },
              itemBuilder: (context) {
                return _reciter.moshaf.map((moshaf) {
                  final isSelected = moshaf.id == _selectedMoshaf.id;
                  return PopupMenuItem<Moshaf>(
                    value: moshaf,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            moshaf.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
            ),

            // Surah List
            Expanded(
              child: surahProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSurahList(surahProvider, audioProvider),
            ),

            // Mini Player
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahList(
    SurahProvider surahProvider,
    AudioProvider audioProvider,
  ) {
    final availableSurahIds = _selectedMoshaf.availableSurahs;

    // Map IDs to Surah objects and filter
    final surahs = availableSurahIds
        .map((id) {
          return surahProvider.getSurahById(id);
        })
        .where((surah) {
          if (surah == null) return false;
          if (_searchQuery.isEmpty) return true;
          return surah.name.toLowerCase().contains(_searchQuery.toLowerCase());
        })
        .toList();

    if (surahs.isEmpty) {
      return Center(
        child: Text(
          'No Surahs found',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index]!;

        final isCurrentTrack =
            audioProvider.currentSurah?.id == surah.id &&
            audioProvider.currentReciter?.id == _reciter.id;
        final isPlayingThis = isCurrentTrack && audioProvider.isPlaying;
        final isLoadingThis = isCurrentTrack && audioProvider.isLoading;

        return SurahListItem(
          surah: surah,
          isPlaying: isPlayingThis,
          isCurrentTrack: isCurrentTrack,
          isLoading: isLoadingThis,
          onTap: () {
            if (isCurrentTrack) {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
            } else {
              final url =
                  '${_selectedMoshaf.server}${surah.id.toString().padLeft(3, '0')}.mp3';
              audioProvider.play(
                url,
                reciter: _reciter,
                surah: surah,
                moshaf: _selectedMoshaf,
                surahProvider: surahProvider,
              );
            }
          },
        );
      },
    );
  }
}
