import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// [p] on the 0-100 scale Legit.Health uses.
String formatPercent(double p) => '${p.round()} %';

TextStyle secondaryText(BuildContext context, {double fontSize = 14}) =>
    TextStyle(fontSize: fontSize, height: 1.35, color: MqTheme.of(context).textSecondary);

class CaseImageView extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  const CaseImageView({super.key, this.url, this.size = 64, this.radius = MqRadius.lg});

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final placeholder = Icon(Icons.image_outlined, size: (size * 0.32).clamp(16, 40), color: t.textDisabled);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.borderDefault),
      ),
      child:
          url == null ? placeholder : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
    );
  }
}
