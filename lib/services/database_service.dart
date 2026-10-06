import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/voice_note.dart';

/// Local SQLite Database Service to persist Voice Notes, Transcriptions, and AI Summaries.
/// Includes seamless in-memory web fallback when running on Chrome/Web.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final List<VoiceNote> _webInMemoryNotes = [];
  bool _isWebInitialized = false;

  Future<Database?> get database async {
    if (kIsWeb) {
      _initWebFallback();
      return null;
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  void _initWebFallback() {
    if (_isWebInitialized) return;
    _webInMemoryNotes.add(_createDemoNote());
    _isWebInitialized = true;
  }

  VoiceNote _createDemoNote() {
    return VoiceNote(
      id: 'demo-sample-lecture-1',
      title: 'CS301: Machine Learning & Neural Networks',
      audioPath: '',
      durationSeconds: 1420, // ~23 mins
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      category: 'Lecture',
      isFavorite: true,
      transcription:
          "Welcome everyone to Lecture 14. Today we are diving into Gradient Descent, Backpropagation, and modern Transformer architectures. In traditional backpropagation, we calculate the gradient of the loss function with respect to each weight via the chain rule. The learning rate alpha determines the step size taken towards the minimum. If alpha is too large, the optimizer oscillates or diverges. If it's too small, convergence takes forever. Next, we looked at Self-Attention mechanisms introduced in 'Attention Is All You Need'. Self-attention computes query, key, and value matrices, enabling parallel token representations across long context windows. For next Tuesday, make sure to implement the assignment 3 multi-head attention module in PyTorch.",
      summaryBullets: [
        'Reviewed fundamental Gradient Descent optimization: Step size controlled by learning rate alpha.',
        'Chain rule formulation in Backpropagation enables recursive error gradient distribution.',
        'Explored Self-Attention mechanisms: Dynamic Query (Q), Key (K), and Value (V) dot-product attention.',
        'Contrasted Transformers with RNNs: Full parallelism during training and elimination of vanishing gradients.',
        'Analyzed hyperparameter tuning strategies for AdamW and cosine decay schedulers.'
      ],
      keyTakeaways: [
        'Transformers replaced sequential recurrence with attention matrices, unlocking massive LLM scalability.',
        'Optimal learning rate warm-up is crucial to prevent early gradient explosion in deep architectures.'
      ],
      actionItems: [
        'Complete Assignment 3: PyTorch implementation of Multi-Head Self-Attention (Due Tuesday 11:59 PM).',
        'Read Sections 3.1 & 3.2 of the seminal paper "Attention Is All You Need".',
        'Prepare questions for Thursday review session on matrix multiplication optimization.'
      ],
    );
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_voice_notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        audio_path TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        transcription TEXT,
        summary_bullets TEXT,
        key_takeaways TEXT,
        action_items TEXT,
        category TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Index for fast search and sorting
    await db.execute('CREATE INDEX idx_created_at ON notes(created_at DESC)');
    await db.execute('CREATE INDEX idx_category ON notes(category)');

    // Seed initial demo lecture note for immediate out-of-the-box user experience
    await db.insert('notes', _createDemoNote().toMap());
  }

  /// Insert a newly recorded and transcribed voice note
  Future<int> insertNote(VoiceNote note) async {
    if (kIsWeb) {
      _initWebFallback();
      _webInMemoryNotes.removeWhere((n) => n.id == note.id);
      _webInMemoryNotes.insert(0, note);
      return 1;
    }

    final db = await database;
    return await db!.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing note (e.g., when Gemini finishes processing or title edited)
  Future<int> updateNote(VoiceNote note) async {
    if (kIsWeb) {
      _initWebFallback();
      final idx = _webInMemoryNotes.indexWhere((n) => n.id == note.id);
      if (idx != -1) {
        _webInMemoryNotes[idx] = note;
      }
      return 1;
    }

    final db = await database;
    return await db!.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Delete note by ID
  Future<int> deleteNote(String id) async {
    if (kIsWeb) {
      _initWebFallback();
      _webInMemoryNotes.removeWhere((n) => n.id == id);
      return 1;
    }

    final db = await database;
    return await db!.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle favorite status
  Future<int> toggleFavorite(String id, bool isFavorite) async {
    if (kIsWeb) {
      _initWebFallback();
      final idx = _webInMemoryNotes.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _webInMemoryNotes[idx] = _webInMemoryNotes[idx].copyWith(isFavorite: isFavorite);
      }
      return 1;
    }

    final db = await database;
    return await db!.update(
      'notes',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Query all notes with optional filtering and search
  Future<List<VoiceNote>> getAllNotes({
    String? searchQuery,
    String? category,
    bool? onlyFavorites,
  }) async {
    if (kIsWeb) {
      _initWebFallback();
      var list = List<VoiceNote>.from(_webInMemoryNotes);
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        list = list.where((n) {
          final titleMatch = n.title.toLowerCase().contains(query);
          final transMatch = n.transcription?.toLowerCase().contains(query) ?? false;
          final bulletsMatch = n.summaryBullets.any((b) => b.toLowerCase().contains(query));
          return titleMatch || transMatch || bulletsMatch;
        }).toList();
      }
      if (category != null && category != 'All') {
        list = list.where((n) => n.category == category).toList();
      }
      if (onlyFavorites == true) {
        list = list.where((n) => n.isFavorite).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR transcription LIKE ? OR summary_bullets LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    if (category != null && category != 'All') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (onlyFavorites == true) {
      whereClauses.add('is_favorite = 1');
    }

    final whereString = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> results = await db!.query(
      'notes',
      where: whereString,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
    );

    return results.map((map) => VoiceNote.fromMap(map)).toList();
  }

  /// Get statistics for dashboard
  Future<Map<String, dynamic>> getDatabaseStats() async {
    if (kIsWeb) {
      _initWebFallback();
      final total = _webInMemoryNotes.length;
      final dur = _webInMemoryNotes.fold<int>(0, (sum, n) => sum + n.durationSeconds);
      return {
        'totalNotes': total,
        'totalDurationSeconds': dur,
      };
    }

    final db = await database;
    final countResult = await db!.rawQuery('SELECT COUNT(*) as total_notes, SUM(duration_seconds) as total_duration FROM notes');
    final totalNotes = Sqflite.firstIntValue(countResult) ?? 0;
    final totalDuration = countResult.first['total_duration'] as int? ?? 0;

    return {
      'totalNotes': totalNotes,
      'totalDurationSeconds': totalDuration,
    };
  }

  /// Clear all data
  Future<void> clearAllNotes() async {
    if (kIsWeb) {
      _initWebFallback();
      _webInMemoryNotes.clear();
      return;
    }

    final db = await database;
    await db!.delete('notes');
  }
}
