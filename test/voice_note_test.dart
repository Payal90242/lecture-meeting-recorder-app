import 'package:flutter_test/flutter_test.dart';
import 'package:ai_voice_summarizer/models/voice_note.dart';

void main() {
  group('VoiceNote Model Tests', () {
    test('Should correctly convert to and from SQLite map representation', () {
      final note = VoiceNote(
        id: 'test-123',
        title: 'Algorithms Lecture: Dynamic Programming',
        audioPath: '/path/to/rec.m4a',
        durationSeconds: 154,
        createdAt: DateTime(2026, 10, 6, 10, 30),
        category: 'Lecture',
        isFavorite: true,
        transcription: 'Today we discuss memoization and tabulation.',
        summaryBullets: ['Memoization is top-down', 'Tabulation is bottom-up'],
        keyTakeaways: ['Optimal substructure', 'Overlapping subproblems'],
        actionItems: ['Solve Knapsack problem on LeetCode'],
      );

      final map = note.toMap();
      expect(map['id'], 'test-123');
      expect(map['duration_seconds'], 154);
      expect(map['is_favorite'], 1);

      final restoredNote = VoiceNote.fromMap(map);
      expect(restoredNote.id, note.id);
      expect(restoredNote.title, note.title);
      expect(restoredNote.formattedDuration, '02:34');
      expect(restoredNote.isFavorite, true);
      expect(restoredNote.summaryBullets.length, 2);
      expect(restoredNote.actionItems.first, 'Solve Knapsack problem on LeetCode');
    });

    test('Formatted duration handles hours and minutes accurately', () {
      final shortNote = VoiceNote(
        id: '1',
        title: 'Short',
        audioPath: '',
        durationSeconds: 45,
        createdAt: DateTime.now(),
      );
      expect(shortNote.formattedDuration, '00:45');

      final longNote = VoiceNote(
        id: '2',
        title: 'Long',
        audioPath: '',
        durationSeconds: 3665, // 1 hr, 1 min, 5 sec
        createdAt: DateTime.now(),
      );
      expect(longNote.formattedDuration, '01:01:05');
    });
  });
}
