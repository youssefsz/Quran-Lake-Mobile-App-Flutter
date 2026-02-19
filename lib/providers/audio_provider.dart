import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/reciter.dart';
import '../data/models/surah.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  Reciter? _currentReciter;
  Surah? _currentSurah;
  
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  Reciter? get currentReciter => _currentReciter;
  Surah? get currentSurah => _currentSurah;

  AudioProvider() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
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

  Future<void> play(String url, {Reciter? reciter, Surah? surah}) async {
    try {
      if (reciter != null) _currentReciter = reciter;
      if (surah != null) _currentSurah = surah;
      
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
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

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
