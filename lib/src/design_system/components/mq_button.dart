import 'package:flutter/cupertino.dart';

import '../mq_theme.dart';
import '../tokens.dart';

enum MqButtonVariant { primary, secondary, outline, ghost, negative }

/// `mq-button`. Built on [CupertinoButton] for the native press feedback
/// (opacity, no ripple) on every platform.
class MqButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MqButtonVariant variant;
  final IconData? icon;
  final bool expand;

  const MqButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MqButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final (background, foreground, border) = switch (variant) {
      MqButtonVariant.primary => (t.brand, t.textOnBrand, null),
      MqButtonVariant.secondary => (t.surfaceRaised, t.textPrimary, null),
      MqButtonVariant.outline => (t.background, t.textPrimary, t.borderDefault),
      MqButtonVariant.ghost => (null, t.textPrimary, null),
      MqButtonVariant.negative => (t.errorStrong, t.textInverse, null),
    };
    final radius = BorderRadius.circular(MqRadius.md);
    final button = CupertinoButton(
      onPressed: onPressed,
      color: background,
      disabledColor: background ?? const Color(0x00000000),
      borderRadius: radius,
      minimumSize: const Size(MqControlSize.md, MqControlSize.md),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: foreground), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontFamily: t.fontFamily,
                fontSize: MqFontSize.sm,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.35,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: border == null
          ? button
          : DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: border)),
              child: button,
            ),
    );
  }
}
