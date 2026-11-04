import 'package:flutter/cupertino.dart';

import '../mq_theme.dart';
import '../tokens.dart';

/// `mq-textarea`, on [CupertinoTextField] for native editing and selection.
class MqTextarea extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? placeholder;
  final int? maxLength;
  final int minLines;
  final int maxLines;

  const MqTextarea({
    super.key,
    required this.controller,
    this.label,
    this.placeholder,
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 6,
  });

  @override
  State<MqTextarea> createState() => _MqTextareaState();
}

class _MqTextareaState extends State<MqTextarea> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final focused = _focus.hasFocus;
    final field = CupertinoTextField(
      controller: widget.controller,
      focusNode: _focus,
      placeholder: widget.placeholder,
      maxLength: widget.maxLength,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      cursorColor: t.brand,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      style: TextStyle(color: t.textPrimary, fontFamily: t.fontFamily, fontSize: MqFontSize.sm, height: 1.5),
      placeholderStyle: TextStyle(color: t.textSecondary, fontFamily: t.fontFamily, fontSize: MqFontSize.sm),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(MqRadius.md),
        // Border plus ring on focus, as on web: a 1px colour change alone is too faint.
        border: Border.all(color: focused ? t.brand : t.borderDefault, width: focused ? 2 : 1),
      ),
    );
    final label = widget.label;
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: t.textPrimary,
            fontFamily: t.fontFamily,
            fontSize: MqFontSize.sm,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
