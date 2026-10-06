import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/note_card.dart';
import 'note_detail_screen.dart';
import 'paywall_screen.dart';
import 'recording_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesProvider = context.watch<NotesProvider>();
    final subProvider = context.watch<SubscriptionProvider>();

    final categories = ['All', 'Lecture', 'Meeting', 'Study', 'Favorites'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryIndigo, AppTheme.primaryPurple],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'EchoGemini',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // Pro Status / Upgrade Badge
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: subProvider.isPro
                    ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                    : const LinearGradient(colors: [AppTheme.primaryIndigo, AppTheme.primaryPurple]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (subProvider.isPro ? Colors.amber : AppTheme.primaryIndigo).withOpacity(0.3),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    subProvider.isPro ? Icons.star : Icons.workspace_premium,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    subProvider.isPro ? 'PRO ACTIVE' : 'UPGRADE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Free Tier quota warning banner
          if (!subProvider.isPro)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryIndigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${subProvider.remainingFreeTranscriptions} free Gemini summaries remaining',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      );
                    },
                    child: const Text(
                      'Get Unlimited',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  )
                ],
              ),
            ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => notesProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search notes, transcripts, or summaries...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryIndigo, width: 1.5),
                ),
              ),
            ),
          ),

          // Filter Category Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = (cat == 'Favorites' && notesProvider.onlyFavorites) ||
                    (cat != 'Favorites' && !notesProvider.onlyFavorites && notesProvider.selectedCategory == cat);

                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (cat == 'Favorites') {
                      notesProvider.toggleOnlyFavorites();
                    } else {
                      if (notesProvider.onlyFavorites) {
                        notesProvider.toggleOnlyFavorites();
                      }
                      notesProvider.setCategory(cat);
                    }
                  },
                  selectedColor: AppTheme.primaryIndigo,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor: isDark ? AppTheme.darkCard : Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? AppTheme.darkBorder : Colors.transparent),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // SQLite Stats & Notes Count Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${notesProvider.notes.length} ${notesProvider.notes.length == 1 ? 'recording' : 'recordings'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.storage, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Local SQLite Vault',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Note List View
          Expanded(
            child: notesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notesProvider.notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic_none_outlined,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notesProvider.searchQuery.isNotEmpty
                                  ? 'No notes matching "${notesProvider.searchQuery}"'
                                  : 'No voice notes recorded yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap the mic button at the bottom right to start recording',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => notesProvider.loadNotes(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: notesProvider.notes.length,
                          itemBuilder: (context, index) {
                            final note = notesProvider.notes[index];
                            return NoteCard(
                              note: note,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => NoteDetailScreen(note: note),
                                  ),
                                );
                              },
                              onToggleFavorite: () {
                                notesProvider.toggleFavorite(note.id, note.isFavorite);
                              },
                              onDelete: () {
                                notesProvider.deleteNote(note.id);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      // Prominent Floating Action Button with Mic Icon (Bottom Right)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 4),
        height: 68,
        width: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
              Color(0xFFEC4899), // Neon Rose
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.5),
              blurRadius: 18,
              spreadRadius: 3,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            onTap: () {
              if (!subProvider.canTranscribe) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecordingScreen()),
              );
            },
            child: Tooltip(
              message: 'Start Live Audio Recording',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle inner ring accent
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
