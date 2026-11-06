import 'package:flutter/widgets.dart';

import '../mq_theme.dart';
import '../tokens.dart';
import 'mq_icon.dart';

enum MqTone { neutral, brand, success, error }

class MqIconContainer extends StatelessWidget {
  final MqIconData icon;
  final MqTone tone;
  final double size;

  const MqIconContainer({super.key, required this.icon, this.tone = MqTone.neutral, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = mqToneColors(MqTheme.of(context), tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(MqRadius.xl)),
      child: Center(child: MqIcon(icon, size: size / 2, color: foreground)),
    );
  }
}

(Color, Color) mqToneColors(MqTheme t, MqTone tone) => switch (tone) {
      MqTone.neutral => (t.surfaceStrong, t.textPrimary),
      MqTone.brand => (t.brandSubtle, t.textBrand),
      MqTone.success => (t.successSubtle, t.successStrong),
      MqTone.error => (t.errorSubtle, t.errorStrong),
    };
