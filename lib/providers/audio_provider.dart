import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
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
  
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get duration => _duration;
  Duration get position => _position;
  Reciter? get currentReciter => _currentReciter;
  Surah? get currentSurah => _currentSurah;
  Moshaf? get currentMoshaf => _currentMoshaf;

  AudioProvider() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.processingStateStream.listen((state) {
      _isLoading = state == ProcessingState.loading || state == ProcessingState.buffering;
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
    
    // Auto-play next if playlist logic is implemented later
  }

  Future<void> play(String url, {Reciter? reciter, Surah? surah, Moshaf? moshaf}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (reciter != null) _currentReciter = reciter;
      if (surah != null) _currentSurah = surah;
      if (moshaf != null) _currentMoshaf = moshaf;
      
      await _audioPlayer.setUrl(url);
      _isLoading = false;
      notifyListeners();
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
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
    if (_currentSurah == null || _currentMoshaf == null) return;

    final availableSurahs = _currentMoshaf!.availableSurahs;
    if (availableSurahs.isEmpty) return;
    
    final currentIndex = availableSurahs.indexOf(_currentSurah!.id);
    if (currentIndex == -1) return;

    int nextIndex = currentIndex + 1;
    if (nextIndex >= availableSurahs.length) {
      nextIndex = 0; // Loop to start
    }

    final nextSurahId = availableSurahs[nextIndex];
    final nextSurah = surahProvider.getSurahById(nextSurahId);
    
    if (nextSurah != null) {
      final url = '${_currentMoshaf!.server}${nextSurahId.toString().padLeft(3, '0')}.mp3';
      await play(url, surah: nextSurah);
    }
  }

  Future<void> playPrevious(SurahProvider surahProvider) async {
    if (_currentSurah == null || _currentMoshaf == null) return;

    final availableSurahs = _currentMoshaf!.availableSurahs;
    if (availableSurahs.isEmpty) return;

    final currentIndex = availableSurahs.indexOf(_currentSurah!.id);
    if (currentIndex == -1) return;

    int prevIndex = currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = availableSurahs.length - 1; // Loop to end
    }

    final prevSurahId = availableSurahs[prevIndex];
    final prevSurah = surahProvider.getSurahById(prevSurahId);
    
    if (prevSurah != null) {
      final url = '${_currentMoshaf!.server}${prevSurahId.toString().padLeft(3, '0')}.mp3';
      await play(url, surah: prevSurah);
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
