import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';
import '../models.dart';
import 'common.dart';

class ProfessionalTile extends StatelessWidget {
  final CaseProfessional professional;

  const ProfessionalTile({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(professional: professional),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                professional.name,
                style: const TextStyle(fontSize: MqFontSize.base, fontWeight: FontWeight.w500, height: 1.5),
              ),
              const SizedBox(height: 2),
              Text(professional.detail, style: secondaryText(context)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final CaseProfessional professional;

  const _Avatar({required this.professional});

  @override
  Widget build(BuildContext context) {
    final t = MqTheme.of(context);
    final initials = Center(
      child: Text(
        professional.initials,
        style: TextStyle(fontSize: MqFontSize.base, fontWeight: FontWeight.w500, color: t.textBrand),
      ),
    );
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: t.brandSubtle, shape: BoxShape.circle),
      child: switch (professional.avatarUrl) {
        final url? => Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => initials),
        null => initials,
      },
    );
  }
}
