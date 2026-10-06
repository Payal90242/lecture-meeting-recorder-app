import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// State of the audio recording
enum RecordingState { idle, recording, paused, stopped }

/// Handles microphone recording, real-time decibel amplitude metering, and file storage.
class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;

  String? _currentRecordingPath;
  String? get currentRecordingPath => _currentRecordingPath;

  int _recordDurationSeconds = 0;
  int get recordDurationSeconds => _recordDurationSeconds;

  Timer? _timer;
  StreamSubscription<Amplitude>? _amplitudeSub;

  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  final StreamController<int> _durationController = StreamController<int>.broadcast();
  Stream<int> get durationStream => _durationController.stream;

  /// Check and request microphone permission
  Future<bool> checkPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Start 1-tap microphone recording
  Future<bool> startRecording() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return false;

      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        final recordingsDir = io.Directory(p.join(directory.path, 'recordings'));
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }

        final fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _currentRecordingPath = p.join(recordingsDir.path, fileName);
      } else {
        _currentRecordingPath = '';
      }
      _recordDurationSeconds = 0;

      // Audio recording configuration optimized for speech clarity and Gemini processing
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1, // Mono is ideal for voice notes and smaller file size
      );

      await _audioRecorder.start(config, path: _currentRecordingPath ?? '');
      _state = RecordingState.recording;

      // Start elapsed timer
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordDurationSeconds++;
        _durationController.add(_recordDurationSeconds);
      });

      // Stream live amplitude for real-time waveform UI
      _amplitudeSub?.cancel();
      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        // Amplitude in dBFS typically -60 to 0 dBFS. Normalize to 0.0 - 1.0 range
        final currentDb = amp.current;
        final normalized = ((currentDb + 60.0) / 60.0).clamp(0.05, 1.0);
        _amplitudeController.add(normalized);
      });

      return true;
    } catch (e) {
      _state = RecordingState.idle;
      return false;
    }
  }

  /// Pause current recording
  Future<void> pauseRecording() async {
    if (_state == RecordingState.recording) {
      await _audioRecorder.pause();
      _timer?.cancel();
      _state = RecordingState.paused;
    }
  }

  /// Resume paused recording
  Future<void> resumeRecording() async {
    if (_state == RecordingState.paused) {
      await _audioRecorder.resume();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordDurationSeconds++;
        _durationController.add(_recordDurationSeconds);
      });
      _state = RecordingState.recording;
    }
  }

  /// Stop recording and return filepath and duration
  Future<Map<String, dynamic>?> stopRecording() async {
    try {
      _timer?.cancel();
      _amplitudeSub?.cancel();

      final path = await _audioRecorder.stop();
      _state = RecordingState.stopped;

      final result = {
        'filePath': path ?? _currentRecordingPath ?? '',
        'durationSeconds': _recordDurationSeconds,
      };

      _state = RecordingState.idle;
      return result;
    } catch (e) {
      _state = RecordingState.idle;
      return null;
    }
  }

  /// Cancel and discard the current recording
  Future<void> cancelRecording() async {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    try {
      await _audioRecorder.stop();
      if (!kIsWeb && _currentRecordingPath != null && _currentRecordingPath!.isNotEmpty) {
        final file = io.File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
    _state = RecordingState.idle;
    _recordDurationSeconds = 0;
  }

  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _amplitudeController.close();
    _durationController.close();
    _audioRecorder.dispose();
  }
}
