import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../data/models/reciter.dart';
import '../data/models/surah.dart';
import 'surah_provider.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  Reciter? _currentReciter;
  Surah? _currentSurah;
  Moshaf? _currentMoshaf;
  SurahProvider? _surahProvider;

  LoopMode _loopMode = LoopMode.off;
  bool _shuffleModeEnabled = false;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;

  Uri? _artUri;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get duration => _duration;
  Duration get position => _position;
  Reciter? get currentReciter => _currentReciter;
  Surah? get currentSurah => _currentSurah;
  Moshaf? get currentMoshaf => _currentMoshaf;
  LoopMode get loopMode => _loopMode;
  bool get shuffleModeEnabled => _shuffleModeEnabled;
  double get playbackSpeed => _playbackSpeed;
  double get volume => _volume;

  AudioProvider() {
    _init();
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.processingStateStream.listen((state) {
      _isLoading =
          state == ProcessingState.loading ||
          state == ProcessingState.buffering;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });

    // Listen to current index to update currentSurah when track changes automatically
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _currentMoshaf != null && _surahProvider != null) {
        final availableSurahs = _currentMoshaf!.availableSurahs;
        if (index < availableSurahs.length) {
          final surahId = availableSurahs[index];
          _currentSurah = _surahProvider!.getSurahById(surahId);
          notifyListeners();
        }
      }
    });

    _audioPlayer.loopModeStream.listen((mode) {
      _loopMode = mode;
      notifyListeners();
    });

    _audioPlayer.shuffleModeEnabledStream.listen((enabled) {
      _shuffleModeEnabled = enabled;
      notifyListeners();
    });

    _audioPlayer.speedStream.listen((speed) {
      _playbackSpeed = speed;
      notifyListeners();
    });

    _audioPlayer.volumeStream.listen((vol) {
      _volume = vol;
      notifyListeners();
    });
  }

  Future<void> _init() async {
    // Configure AudioSession for background playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);

    try {
      final byteData = await rootBundle.load('assets/icons/quran.png');
      final file = File('${Directory.systemTemp.path}/quran_art.png');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      _artUri = Uri.file(file.path);
    } catch (e) {
      debugPrint('Error loading artwork: $e');
    }
  }

  void updateSurahProvider(SurahProvider surahProvider) {
    _surahProvider = surahProvider;
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(mode);
  }

  Future<void> toggleShuffle() async {
    final enable = !shuffleModeEnabled;
    if (enable) {
      await _audioPlayer.shuffle();
    }
    await _audioPlayer.setShuffleModeEnabled(enable);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  Future<void> play(
    String url, {
    Reciter? reciter,
    Surah? surah,
    Moshaf? moshaf,
    SurahProvider? surahProvider,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Check if we are playing from the same Moshaf/Reciter context
      bool sameContext =
          _currentReciter?.id == reciter?.id &&
          _currentMoshaf?.id == moshaf?.id;

      if (reciter != null) _currentReciter = reciter;
      if (surah != null) _currentSurah = surah;
      if (moshaf != null) _currentMoshaf = moshaf;

      if (sameContext &&
          _audioPlayer.sequence.isNotEmpty &&
          surah != null &&
          moshaf != null) {
        // Just seek to the correct index in the existing playlist
        final availableSurahs = moshaf.availableSurahs;
        final index = availableSurahs.indexOf(surah.id);
        if (index != -1) {
          await _audioPlayer.seek(Duration.zero, index: index);
          await _audioPlayer.play();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // If context changed or no playlist, build a new one
      if (moshaf != null && surahProvider != null && surah != null) {
        final availableSurahs = moshaf.availableSurahs;
        final initialIndex = availableSurahs.indexOf(surah.id);

        // ignore: deprecated_member_use
        final playlist = ConcatenatingAudioSource(
          children: availableSurahs.map((surahId) {
            final s = surahProvider.getSurahById(surahId);
            final surahName = s?.name ?? 'Surah $surahId';
            final surahUrl =
                '${moshaf.server}${surahId.toString().padLeft(3, '0')}.mp3';

            // Provide a default asset image for the artwork
            final artUri =
                _artUri ?? Uri.parse('asset:///assets/icons/quran.png');

            return AudioSource.uri(
              Uri.parse(surahUrl),
              tag: MediaItem(
                id: surahUrl,
                album: moshaf.name,
                title: surahName,
                artist: reciter?.name ?? 'Unknown Reciter',
                artUri: artUri,
                extras: {'surah_id': surahId},
              ),
            );
          }).toList(),
        );

        await _audioPlayer.setAudioSource(
          playlist,
          initialIndex: initialIndex != -1 ? initialIndex : 0,
        );
      } else {
        // Fallback for single URL play (legacy or specific use case)
        final artUri = _artUri ?? Uri.parse('asset:///assets/icons/quran.png');
        final mediaItem = MediaItem(
          id: url,
          album: _currentMoshaf?.name ?? 'Quran Lake',
          title: _currentSurah?.name ?? 'Unknown Surah',
          artist: _currentReciter?.name ?? 'Unknown Reciter',
          artUri: artUri,
        );

        final audioSource = AudioSource.uri(Uri.parse(url), tag: mediaItem);

        await _audioPlayer.setAudioSource(audioSource);
      }

      _isLoading = false;
      notifyListeners();
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> closePlayer() async {
    await _audioPlayer.stop();
    _currentSurah = null;
    _currentReciter = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  Future<void> playNext(SurahProvider surahProvider) async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    } else {
      // Loop or stop
    }
  }

  Future<void> playPrevious(SurahProvider surahProvider) async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    } else {
      // Loop or stop
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
