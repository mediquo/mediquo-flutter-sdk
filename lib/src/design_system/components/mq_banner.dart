import 'package:flutter/widgets.dart';

import '../mq_theme.dart';
import '../tokens.dart';
import 'mq_icon.dart';
import 'mq_icon_container.dart';

class MqBanner extends StatelessWidget {
  final MqIconData icon;
  final String title;
  final String? description;
  final MqTone tone;

  const MqBanner({super.key, required this.icon, required this.title, this.description, this.tone = MqTone.brand});

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final iconColor = mqToneColors(t, tone).$2;
    final style = TextStyle(fontSize: MqFontSize.sm, height: 1.35, color: t.textPrimary);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone == MqTone.error ? t.errorSubtle : t.surfaceRaised,
        borderRadius: BorderRadius.circular(MqRadius.lg),
      ),
      child: Row(
        children: [
          MqIcon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: style.copyWith(fontWeight: FontWeight.w500)),
                if (description != null) ...[const SizedBox(height: 4), Text(description!, style: style)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
