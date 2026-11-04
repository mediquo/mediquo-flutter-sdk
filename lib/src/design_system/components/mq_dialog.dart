import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../mq_theme.dart';
import '../tokens.dart';
import 'mq_button.dart';

/// Confirmation dialog: the system alert on iOS, an `mq-dialog` elsewhere.
/// Resolves true when the patient confirms.
Future<bool> showMqConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final platform = Theme.of(context).platform;
  final confirmed = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
      ? await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelLabel)),
              CupertinoDialogAction(
                isDestructiveAction: destructive,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        )
      : await showDialog<bool>(
          context: context,
          builder: (context) => _MqDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            destructive: destructive,
          ),
        );
  return confirmed ?? false;
}

class _MqDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  const _MqDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    return Dialog(
      backgroundColor: t.background,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MqRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: MqFontSize.lg, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(fontSize: MqFontSize.sm, color: t.textSecondary)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: MqButton(
                    label: cancelLabel,
                    variant: MqButtonVariant.outline,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MqButton(
                    label: confirmLabel,
                    variant: destructive ? MqButtonVariant.negative : MqButtonVariant.primary,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
