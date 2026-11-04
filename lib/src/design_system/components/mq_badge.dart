import 'package:flutter/widgets.dart';

import '../mq_theme.dart';
import '../tokens.dart';

enum MqBadgeTone { neutral, error }

class MqBadge extends StatelessWidget {
  final String label;
  final MqBadgeTone tone;
  final IconData? icon;

  const MqBadge({super.key, required this.label, this.tone = MqBadgeTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final (background, foreground) = switch (tone) {
      MqBadgeTone.neutral => (t.surfaceRaised, t.textPrimary),
      MqBadgeTone.error => (t.errorSubtle, t.errorStrong),
    };
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(MqRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: foreground), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w500, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
