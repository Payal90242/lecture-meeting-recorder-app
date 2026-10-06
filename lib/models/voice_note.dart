import 'dart:convert';

/// Represents a recorded audio note with transcription and AI-generated summaries.
class VoiceNote {
  final String id;
  final String title;
  final String audioPath;
  final int durationSeconds;
  final DateTime createdAt;
  final String? transcription;
  final List<String> summaryBullets;
  final List<String> keyTakeaways;
  final List<String> actionItems;
  final String category; // 'Lecture', 'Meeting', 'Study', 'Idea', 'Quick Memo'
  final bool isFavorite;
  final bool isProcessing;

  const VoiceNote({
    required this.id,
    required this.title,
    required this.audioPath,
    required this.durationSeconds,
    required this.createdAt,
    this.transcription,
    this.summaryBullets = const [],
    this.keyTakeaways = const [],
    this.actionItems = const [],
    this.category = 'Lecture',
    this.isFavorite = false,
    this.isProcessing = false,
  });

  /// Formatted duration string (e.g., "04:23" or "01:15:30")
  String get formattedDuration {
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    if (durationSeconds >= 3600) {
      final hours = (durationSeconds ~/ 3600).toString().padLeft(2, '0');
      final minutes = ((durationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'audio_path': audioPath,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
      'transcription': transcription,
      'summary_bullets': jsonEncode(summaryBullets),
      'key_takeaways': jsonEncode(keyTakeaways),
      'action_items': jsonEncode(actionItems),
      'category': category,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// Create from SQLite map
  factory VoiceNote.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic rawJson) {
      if (rawJson == null) return [];
      try {
        final decoded = jsonDecode(rawJson as String);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return [];
    }

    return VoiceNote(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Untitled Note',
      audioPath: map['audio_path'] as String? ?? '',
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      transcription: map['transcription'] as String?,
      summaryBullets: parseList(map['summary_bullets']),
      keyTakeaways: parseList(map['key_takeaways']),
      actionItems: parseList(map['action_items']),
      category: map['category'] as String? ?? 'Lecture',
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isProcessing: false,
    );
  }

  VoiceNote copyWith({
    String? id,
    String? title,
    String? audioPath,
    int? durationSeconds,
    DateTime? createdAt,
    String? transcription,
    List<String>? summaryBullets,
    List<String>? keyTakeaways,
    List<String>? actionItems,
    String? category,
    bool? isFavorite,
    bool? isProcessing,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      transcription: transcription ?? this.transcription,
      summaryBullets: summaryBullets ?? this.summaryBullets,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      actionItems: actionItems ?? this.actionItems,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
