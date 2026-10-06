import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

enum PaywallPlan { annual, monthly }

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PaywallPlan _selectedPlan = PaywallPlan.annual;
  bool _isPurchasing = false;

  void _handleSubscribe() async {
    setState(() => _isPurchasing = true);
    final subProvider = context.read<SubscriptionProvider>();

    try {
      // In production, this invokes purchases_flutter: Purchases.purchasePackage(package)
      // Here we provide instant mock verification for seamless dev test & demo
      await Future.delayed(const Duration(milliseconds: 1200));
      subProvider.toggleDevProStatus();

      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Welcome to Gemini AI Pro! Unlimited access unlocked.'),
              ],
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase error: $e')),
        );
      }
    }
  }

  void _handleRestore() async {
    setState(() => _isPurchasing = true);
    final subProvider = context.read<SubscriptionProvider>();
    final restored = await subProvider.restorePurchases();
    if (mounted) {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restored
                ? 'Purchases successfully restored!'
                : 'No active subscriptions found for this account.',
          ),
        ),
      );
      if (restored) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isPurchasing ? null : _handleRestore,
            child: const Text(
              'Restore',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryPurple),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pro Crown Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),

            // Headline
            const Text(
              'EchoGemini Pro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Turn hours of lectures & meetings into structured notes, action items, and study guides.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Feature Highlights List
            _buildFeatureRow(
              icon: Icons.all_inclusive,
              title: 'Unlimited AI Transcriptions',
              description: 'Record full 2-hour university lectures or meetings without limits.',
              isDark: isDark,
            ),
            _buildFeatureRow(
              icon: Icons.auto_awesome,
              title: 'Smart Bullet Summaries',
              description: 'Gemini 1.5 synthesizes high-yield bullet notes and homework action items.',
              isDark: isDark,
            ),
            _buildFeatureRow(
              icon: Icons.file_download_outlined,
              title: 'Markdown & PDF Export',
              description: 'Export structured lecture notes directly into Obsidian, Notion, or Drive.',
              isDark: isDark,
            ),
            _buildFeatureRow(
              icon: Icons.speed,
              title: 'Priority Audio Engine',
              description: 'Blazing fast transcription processing with zero queue wait times.',
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // Pricing Plans (RevenueCat Offerings)
            // 1. Annual Plan (Selected by default)
            GestureDetector(
              onTap: () => setState(() => _selectedPlan = PaywallPlan.annual),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedPlan == PaywallPlan.annual
                        ? AppTheme.primaryIndigo
                        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    width: _selectedPlan == PaywallPlan.annual ? 2 : 1,
                  ),
                  boxShadow: _selectedPlan == PaywallPlan.annual
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryIndigo.withOpacity(0.15),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedPlan == PaywallPlan.annual
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _selectedPlan == PaywallPlan.annual
                          ? AppTheme.primaryIndigo
                          : Colors.grey,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Annual Pass',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SAVE 50%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '3-Day Free Trial, then \$39.99/year (\$3.33/mo)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Monthly Plan
            GestureDetector(
              onTap: () => setState(() => _selectedPlan = PaywallPlan.monthly),
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedPlan == PaywallPlan.monthly
                        ? AppTheme.primaryIndigo
                        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    width: _selectedPlan == PaywallPlan.monthly ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedPlan == PaywallPlan.monthly
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _selectedPlan == PaywallPlan.monthly
                          ? AppTheme.primaryIndigo
                          : Colors.grey,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Access',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$6.99/month, billed monthly. Cancel anytime.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _handleSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryIndigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _selectedPlan == PaywallPlan.annual
                            ? 'Start 3-Day Free Trial'
                            : 'Unlock Pro Access Now',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Guarantees & Footer text
            const Text(
              'No commitment. Cancel anytime in Google Play / App Store.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Terms of Use', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                const Text('•', style: TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () {},
                  child: const Text('Privacy Policy', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryIndigo.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryIndigo, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
