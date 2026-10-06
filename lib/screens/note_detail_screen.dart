import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/voice_note.dart';
import '../providers/notes_provider.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class NoteDetailScreen extends StatefulWidget {
  final VoiceNote note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayerService _playerService = AudioPlayerService();

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;

  // Track checked action items locally for interactive UI
  final Set<int> _checkedActionItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _totalDuration = Duration(seconds: widget.note.durationSeconds);

    _playerService.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });

    _playerService.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });

    _playerService.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.toString().contains('playing');
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _playerService.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _shareNote() {
    final buffer = StringBuffer();
    buffer.writeln('# ${widget.note.title}');
    buffer.writeln('Category: ${widget.note.category} | Duration: ${widget.note.formattedDuration}');
    buffer.writeln('\n## Smart Bullet Summary:');
    for (final bullet in widget.note.summaryBullets) {
      buffer.writeln('- $bullet');
    }
    if (widget.note.keyTakeaways.isNotEmpty) {
      buffer.writeln('\n## Key Takeaways:');
      for (final k in widget.note.keyTakeaways) {
        buffer.writeln('• $k');
      }
    }
    if (widget.note.actionItems.isNotEmpty) {
      buffer.writeln('\n## Action Items:');
      for (final a in widget.note.actionItems) {
        buffer.writeln('[ ] $a');
      }
    }
    buffer.writeln('\n## Full Transcript:\n${widget.note.transcription ?? "N/A"}');

    Share.share(buffer.toString(), subject: widget.note.title);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesProvider = context.watch<NotesProvider>();
    final currentNote = notesProvider.notes.firstWhere(
      (n) => n.id == widget.note.id,
      orElse: () => widget.note,
    );
    final dateStr = DateFormat('MMMM d, yyyy • h:mm a').format(currentNote.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentNote.category,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              currentNote.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: currentNote.isFavorite ? AppTheme.recordingRed : null,
            ),
            onPressed: () {
              notesProvider.toggleFavorite(currentNote.id, currentNote.isFavorite);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareNote,
          ),
        ],
      ),
      body: Column(
        children: [
          // Audio Player Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppTheme.darkCard, AppTheme.darkSurface]
                    : [Colors.white, const Color(0xFFF1F5F9)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                // Title & Date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentNote.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Playback speed pill
                    PopupMenuButton<double>(
                      initialValue: _playbackSpeed,
                      onSelected: (val) {
                        setState(() => _playbackSpeed = val);
                        _playerService.setPlaybackRate(val);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryIndigo.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryIndigo,
                          ),
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 1.0, child: Text('1.0x Normal')),
                        const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                        const PopupMenuItem(value: 1.5, child: Text('1.5x Fast')),
                        const PopupMenuItem(value: 2.0, child: Text('2.0x Double')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scrubber Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppTheme.primaryIndigo,
                    thumbColor: AppTheme.primaryIndigo,
                  ),
                  child: Slider(
                    value: _currentPosition.inSeconds
                        .clamp(0, _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 1)
                        .toDouble(),
                    max: (_totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 1).toDouble(),
                    onChanged: (val) {
                      _playerService.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),

                // Timestamps and Player Controls
                Row(
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                    const Spacer(),
                    // Skip -10s
                    IconButton(
                      icon: const Icon(Icons.replay_10, size: 22),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _playerService.skip(-10),
                    ),
                    // Play/Pause button
                    GestureDetector(
                      onTap: () {
                        if (_isPlaying) {
                          _playerService.pauseAudio();
                        } else {
                          if (currentNote.audioPath.isNotEmpty) {
                            _playerService.playAudio(currentNote.audioPath);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryIndigo,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    // Skip +10s
                    IconButton(
                      icon: const Icon(Icons.forward_10, size: 22),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _playerService.skip(10),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(_totalDuration),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs: Smart Summary vs Full Transcript
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryIndigo,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryIndigo,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 16),
                    SizedBox(width: 8),
                    Text('Smart Summary'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.subtitles_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Full Transcript'),
                  ],
                ),
              ),
            ],
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Smart Summary (Bullet Points, Key Takeaways, Action Items)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Key Takeaways callout
                    if (currentNote.keyTakeaways.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: AppTheme.primaryPurple, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Key Takeaways',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...currentNote.keyTakeaways.map((takeaway) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '•  $takeaway',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Smart Bullet Points
                    Row(
                      children: [
                        const Text(
                          'Lecture Notes & Bullet Points',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            final bullets = currentNote.summaryBullets.map((b) => '- $b').join('\n');
                            Clipboard.setData(ClipboardData(text: bullets));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bullet points copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('Copy All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...currentNote.summaryBullets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bullet = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 12),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryIndigo.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryIndigo,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                bullet,
                                style: const TextStyle(fontSize: 14, height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Action Items & Next Steps
                    if (currentNote.actionItems.isNotEmpty) ...[
                      const Text(
                        'Action Items & Deadlines',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...currentNote.actionItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final action = entry.value;
                        final isChecked = _checkedActionItems.contains(idx);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _checkedActionItems.remove(idx);
                              } else {
                                _checkedActionItems.add(idx);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? (isDark ? Colors.white10 : Colors.grey.shade100)
                                  : (isDark ? AppTheme.darkCard : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isChecked ? Icons.check_circle : Icons.circle_outlined,
                                  color: isChecked ? AppTheme.successGreen : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: isChecked ? TextDecoration.lineThrough : null,
                                      color: isChecked
                                          ? (isDark ? Colors.white38 : Colors.black38)
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),

                // TAB 2: Full Verbatim Transcript
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Verbatim Transcription',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Copy Transcript',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: currentNote.transcription ?? ''),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Full transcript copied')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      ),
                      child: SelectableText(
                        currentNote.transcription ?? 'No transcription recorded.',
                        style: const TextStyle(fontSize: 15, height: 1.6, letterSpacing: 0.2),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
