import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../providers/recorder_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_visualizer.dart';
import 'note_detail_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-start recording upon opening screen (1-tap recording)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecorderProvider>().startRecording();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final recorder = context.watch<RecorderProvider>();
    final notesProvider = context.read<NotesProvider>();
    final subProvider = context.read<SubscriptionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = ['Lecture', 'Meeting', 'Study', 'Memo'];

    return WillPopScope(
      onWillPop: () async {
        if (recorder.isRecording) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Discard Recording?'),
              content: const Text('Exiting now will cancel and delete this recording.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Recording')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard', style: TextStyle(color: AppTheme.recordingRed)),
                ),
              ],
            ),
          );
          if (shouldDiscard == true) {
            await recorder.cancelRecording();
            return true;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Audio Recording'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (recorder.isRecording) {
                await recorder.cancelRecording();
              }
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Category Selector Pill
                    Text(
                      'RECORDING CATEGORY',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: categories.map((cat) {
                        final isSelected = recorder.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => recorder.setCategory(cat),
                            selectedColor: AppTheme.primaryPurple,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const Spacer(),

                    // Large Glowing Timer
                    Text(
                      _formatTimer(recorder.recordDuration),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Recording status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: recorder.isPaused
                            ? Colors.amber.withOpacity(0.15)
                            : AppTheme.recordingRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: recorder.isPaused ? Colors.amber : AppTheme.recordingRed,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: recorder.isPaused ? Colors.amber : AppTheme.recordingRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            recorder.isPaused ? 'PAUSED' : 'RECORDING ACTIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: recorder.isPaused ? Colors.amber : AppTheme.recordingRed,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Real-time Mic Amplitude Waveform Visualizer
                    WaveformVisualizer(
                      amplitude: recorder.currentAmplitude,
                      isRecording: recorder.isRecording,
                    ),

                    const Spacer(),

                    // Glowing Pulsing Mic Orb
                    ScaleTransition(
                      scale: recorder.isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: recorder.isPaused
                                ? [Colors.amber, Colors.orange]
                                : [AppTheme.recordingRed, const Color(0xFFDC2626)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (recorder.isPaused ? Colors.amber : AppTheme.recordingRed).withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          recorder.isPaused ? Icons.pause : Icons.mic,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Action Controls Bar (Cancel, Pause/Resume, Stop & Summarize)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel
                        IconButton.filledTonal(
                          iconSize: 28,
                          padding: const EdgeInsets.all(16),
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () async {
                            await recorder.cancelRecording();
                            if (mounted) Navigator.pop(context);
                          },
                        ),

                        // Stop & Summarize with Gemini
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryIndigo,
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 6,
                          ),
                          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          label: const Text(
                            'Stop & Summarize',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          onPressed: () async {
                            final note = await recorder.stopAndProcess(
                              notesProvider: notesProvider,
                              subscriptionProvider: subProvider,
                            );

                            if (mounted && note != null) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => NoteDetailScreen(note: note),
                                ),
                              );
                            }
                          },
                        ),

                        // Pause / Resume
                        IconButton.filledTonal(
                          iconSize: 28,
                          padding: const EdgeInsets.all(16),
                          icon: Icon(
                            recorder.isPaused ? Icons.play_arrow : Icons.pause,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () {
                            if (recorder.isPaused) {
                              recorder.resumeRecording();
                            } else {
                              recorder.pauseRecording();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // AI Processing Overlay with Progress Animation
            if (recorder.isProcessing)
              Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.4)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryIndigo, AppTheme.primaryPurple],
                            ),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Gemini AI is Thinking',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          recorder.processingStatus.isNotEmpty
                              ? recorder.processingStatus
                              : 'Transcribing & synthesizing notes...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const LinearProgressIndicator(
                          color: AppTheme.primaryPurple,
                          backgroundColor: Colors.white12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
