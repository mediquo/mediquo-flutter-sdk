import 'package:flutter/widgets.dart';

import '../mq_theme.dart';
import '../tokens.dart';

enum MqBadgeTone { neutral, error }

class MqBadge extends StatelessWidget {
  final String label;
  final MqBadgeTone tone;

  const MqBadge({super.key, required this.label, this.tone = MqBadgeTone.neutral});

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final (background, foreground) = switch (tone) {
      MqBadgeTone.neutral => (t.surfaceStrong, t.textPrimary),
      MqBadgeTone.error => (t.errorSubtle, t.errorStrong),
    };
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(MqRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontSize: 12, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
