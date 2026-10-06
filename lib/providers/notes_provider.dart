import 'package:flutter/material.dart';
import '../models/voice_note.dart';
import '../services/database_service.dart';

class NotesProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<VoiceNote> _notes = [];
  List<VoiceNote> get notes => _notes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _onlyFavorites = false;
  bool get onlyFavorites => _onlyFavorites;

  int _totalNotes = 0;
  int get totalNotes => _totalNotes;

  int _totalDurationSeconds = 0;
  int get totalDurationSeconds => _totalDurationSeconds;

  NotesProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _dbService.getAllNotes(
        searchQuery: _searchQuery,
        category: _selectedCategory,
        onlyFavorites: _onlyFavorites,
      );

      final stats = await _dbService.getDatabaseStats();
      _totalNotes = stats['totalNotes'] as int? ?? 0;
      _totalDurationSeconds = stats['totalDurationSeconds'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    loadNotes();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadNotes();
  }

  void toggleOnlyFavorites() {
    _onlyFavorites = !_onlyFavorites;
    loadNotes();
  }

  Future<void> addNote(VoiceNote note) async {
    await _dbService.insertNote(note);
    await loadNotes();
  }

  Future<void> updateNote(VoiceNote note) async {
    await _dbService.updateNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _dbService.deleteNote(id);
    await loadNotes();
  }

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    await _dbService.toggleFavorite(id, !currentStatus);
    await loadNotes();
  }

  Future<void> clearAll() async {
    await _dbService.clearAllNotes();
    await loadNotes();
  }
}
