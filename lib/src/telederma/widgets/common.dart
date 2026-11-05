import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String formatDateTime(DateTime d) {
  final year = d.year == DateTime.now().year ? '' : ' ${d.year}';
  final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}$year · $time';
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

TextStyle secondaryText(BuildContext context, {double fontSize = MqFontSize.sm}) =>
    TextStyle(fontSize: fontSize, height: 1.35, color: MqTheme.of(context).textSecondary);

const headingStyle = TextStyle(fontSize: MqFontSize.lg, fontWeight: FontWeight.w500, height: 1.35);

const titleStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.2);

class CaseImageView extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  const CaseImageView({super.key, this.url, this.size = 64, this.radius = MqRadius.lg});

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final placeholder = Center(child: MqIcon(MqIcons.camera, size: size < 64 ? 20 : 24, color: t.textSecondary));
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: t.surfaceStrong, borderRadius: BorderRadius.circular(radius)),
      child:
          url == null ? placeholder : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
    );
  }
}

class NumberedStep extends StatelessWidget {
  final int number;
  final String text;

  const NumberedStep({super.key, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: MqTheme.of(context).surfaceStrong, shape: BoxShape.circle),
          child: Text('$number', style: const TextStyle(fontSize: MqFontSize.xs)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: MqFontSize.sm, height: 1.35))),
      ],
    );
  }
}

class BottomActions extends StatelessWidget {
  final List<Widget> children;

  const BottomActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: MqTheme.of(context).borderDefault))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(height: 8), child],
          ],
        ),
      ),
    );
  }
}

class ScreenHero extends StatelessWidget {
  final MqIconData icon;
  final MqTone tone;
  final String title;
  final String description;
  final bool centered;

  const ScreenHero({
    super.key,
    required this.icon,
    this.tone = MqTone.neutral,
    required this.title,
    required this.description,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        MqIconContainer(icon: icon, tone: tone, size: 48),
        const SizedBox(height: 12),
        Text(title, textAlign: align, style: titleStyle),
        const SizedBox(height: 12),
        Text(description, textAlign: align, style: secondaryText(context, fontSize: MqFontSize.base)),
      ],
    );
  }
}
