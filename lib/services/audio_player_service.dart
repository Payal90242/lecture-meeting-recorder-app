import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Audio Player Service for playback of recorded voice notes and lectures.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  PlayerState get playerState => _playerState;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  double _playbackRate = 1.0;
  double get playbackRate => _playbackRate;

  String? _currentlyPlayingPath;
  String? get currentlyPlayingPath => _currentlyPlayingPath;

  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  AudioPlayerService() {
    _player.onPositionChanged.listen((p) => _position = p);
    _player.onDurationChanged.listen((d) => _duration = d);
    _player.onPlayerStateChanged.listen((s) => _playerState = s);
    _player.onPlayerComplete.listen((_) {
      _position = Duration.zero;
      _playerState = PlayerState.completed;
    });
  }

  Future<void> playAudio(String filePath) async {
    try {
      if (_currentlyPlayingPath != filePath) {
        await _player.stop();
        _currentlyPlayingPath = filePath;
        await _player.play(DeviceFileSource(filePath));
      } else {
        await _player.resume();
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> pauseAudio() async {
    await _player.pause();
  }

  Future<void> resumeAudio() async {
    await _player.resume();
  }

  Future<void> stopAudio() async {
    await _player.stop();
    _currentlyPlayingPath = null;
    _position = Duration.zero;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skip(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    if (target < Duration.zero) {
      await seek(Duration.zero);
    } else if (target > _duration) {
      await seek(_duration);
    } else {
      await seek(target);
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate;
    await _player.setPlaybackRate(rate);
  }

  void dispose() {
    _player.dispose();
  }
}
