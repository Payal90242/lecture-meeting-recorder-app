import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/voice_note.dart';
import '../services/audio_recorder_service.dart';
import '../services/gemini_service.dart';
import 'notes_provider.dart';
import 'subscription_provider.dart';

class RecorderProvider with ChangeNotifier {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final GeminiService _geminiService = GeminiService();
  final Uuid _uuid = const Uuid();

  RecordingState get state => _recorderService.state;
  bool get isRecording => state == RecordingState.recording;
  bool get isPaused => state == RecordingState.paused;

  int _recordDuration = 0;
  int get recordDuration => _recordDuration;

  double _currentAmplitude = 0.1;
  double get currentAmplitude => _currentAmplitude;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String _processingStatus = '';
  String get processingStatus => _processingStatus;

  String _selectedCategory = 'Lecture';
  String get selectedCategory => _selectedCategory;

  RecorderProvider() {
    _recorderService.durationStream.listen((duration) {
      _recordDuration = duration;
      notifyListeners();
    });

    _recorderService.amplitudeStream.listen((amp) {
      _currentAmplitude = amp;
      notifyListeners();
    });
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> startRecording() async {
    final success = await _recorderService.startRecording();
    if (success) {
      _recordDuration = 0;
      notifyListeners();
    }
    return success;
  }

  Future<void> pauseRecording() async {
    await _recorderService.pauseRecording();
    notifyListeners();
  }

  Future<void> resumeRecording() async {
    await _recorderService.resumeRecording();
    notifyListeners();
  }

  Future<void> cancelRecording() async {
    await _recorderService.cancelRecording();
    _recordDuration = 0;
    _isProcessing = false;
    notifyListeners();
  }

  /// Stop audio recording, send to Gemini API, save to SQLite, and update providers
  Future<VoiceNote?> stopAndProcess({
    required NotesProvider notesProvider,
    required SubscriptionProvider subscriptionProvider,
  }) async {
    final recorded = await _recorderService.stopRecording();
    if (recorded == null) {
      notifyListeners();
      return null;
    }

    final filePath = recorded['filePath'] as String;
    final durationSec = recorded['durationSeconds'] as int;

    _isProcessing = true;
    _processingStatus = 'Streaming audio to Gemini 1.5 Flash...';
    notifyListeners();

    try {
      // Step 1: Processing Status Update
      await Future.delayed(const Duration(milliseconds: 600));
      _processingStatus = 'Gemini transcribing speech to text...';
      notifyListeners();

      // Step 2: Call Gemini API
      final geminiResult = await _geminiService.processAudioNote(
        audioFilePath: filePath,
        category: _selectedCategory,
      );

      _processingStatus = 'Synthesizing smart bullet points & action items...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 3: Construct VoiceNote model
      final note = VoiceNote(
        id: _uuid.v4(),
        title: geminiResult.title,
        audioPath: filePath,
        durationSeconds: durationSec > 0 ? durationSec : 1,
        createdAt: DateTime.now(),
        transcription: geminiResult.transcription,
        summaryBullets: geminiResult.summaryBullets,
        keyTakeaways: geminiResult.keyTakeaways,
        actionItems: geminiResult.actionItems,
        category: _selectedCategory,
        isFavorite: false,
      );

      // Step 4: Persist in SQLite
      await notesProvider.addNote(note);

      // Step 5: Update subscription quota
      subscriptionProvider.incrementUsage();

      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();

      return note;
    } catch (e) {
      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _recorderService.dispose();
    super.dispose();
  }
}
