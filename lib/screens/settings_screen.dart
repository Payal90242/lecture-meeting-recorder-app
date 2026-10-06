import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = GeminiService.apiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveApiKey() {
    GeminiService.setApiKey(_apiKeyController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.successGreen,
        content: Text('Gemini API Key updated successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subProvider = context.watch<SubscriptionProvider>();
    final notesProvider = context.watch<NotesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Gemini AI API Key
          _buildSectionHeader('GEMINI AI ENGINE', isDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, color: AppTheme.primaryIndigo, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Google Gemini API Key',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Used for audio transcription and smart bullet synthesis via gemini-1.5-flash.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off, size: 20),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkBackground : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: const Text('Save Key', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Subscription & RevenueCat
          _buildSectionHeader('SUBSCRIPTION & BILLING', isDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      subProvider.isPro ? Icons.verified : Icons.lock_outline,
                      color: subProvider.isPro ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subProvider.isPro ? 'EchoGemini Pro Active' : 'Free Tier',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            subProvider.isPro
                                ? 'Unlimited AI summaries & 2-hour recordings'
                                : '${subProvider.remainingFreeTranscriptions} free summaries remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!subProvider.isPro)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PaywallScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: AppTheme.primaryPurple,
                        ),
                        child: const Text('Upgrade', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const Divider(height: 24),
                // Developer Pro toggle for testing
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Developer Sandbox Pro Mode', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Simulate RevenueCat Pro subscription', style: TextStyle(fontSize: 12)),
                  value: subProvider.isPro,
                  activeColor: AppTheme.primaryIndigo,
                  onChanged: (val) {
                    subProvider.toggleDevProStatus();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: SQLite Database Info
          _buildSectionHeader('LOCAL SQLITE VAULT', isDark),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                _buildInfoRow('Database File', 'ai_voice_notes.db', isDark),
                const SizedBox(height: 10),
                _buildInfoRow('Stored Recordings', '${notesProvider.totalNotes} notes', isDark),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'Total Audio Time',
                  '${(notesProvider.totalDurationSeconds / 60).toStringAsFixed(1)} minutes',
                  isDark,
                ),
                const Divider(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All SQLite Data?'),
                        content: const Text('This will delete all saved recordings, transcripts, and summaries.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete Everything', style: TextStyle(color: AppTheme.recordingRed)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await notesProvider.clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Database reset successfully')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_sweep, color: AppTheme.recordingRed, size: 20),
                  label: const Text('Clear SQLite Database', style: TextStyle(color: AppTheme.recordingRed)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
