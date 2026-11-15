import 'package:flutter/widgets.dart';

import '../mq_theme.dart';
import '../tokens.dart';
import 'mq_icon_container.dart';

class MqBadge extends StatelessWidget {
  final String label;
  final MqTone tone;

  const MqBadge({super.key, required this.label, this.tone = MqTone.neutral});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = mqToneColors(MqTheme.of(context), tone);
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
