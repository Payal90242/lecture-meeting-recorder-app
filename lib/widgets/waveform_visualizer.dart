import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dynamic live audio waveform visualizer responding to mic amplitude
class WaveformVisualizer extends StatelessWidget {
  final double amplitude;
  final bool isRecording;
  final int barCount;

  const WaveformVisualizer({
    super.key,
    required this.amplitude,
    required this.isRecording,
    this.barCount = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          final factor = sin((index / barCount) * pi);
          final dynamicHeight = isRecording
              ? (12 + (amplitude * 65 * factor) + (index % 3 == 0 ? 8 : -4))
                  .clamp(8.0, 85.0)
              : 8.0;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 4,
            height: dynamicHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isRecording
                    ? [
                        AppTheme.primaryPurple,
                        AppTheme.accentNeon,
                      ]
                    : [
                        Colors.grey.withOpacity(0.3),
                        Colors.grey.withOpacity(0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isRecording
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
